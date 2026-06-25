from sqlalchemy.orm import Session
from app.repositories.solicitud_repository import SolicitudRepository
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.credito_repository import CreditoRepository
from app.repositories.cuenta_repository import CuentaRepository
from app.models.cuenta_model import CuentaAhorro
from app.models.credito_model import Credito
from app.models.cronograma_model import CronogramaPago
from app.models.movimiento_model import Movimiento
from app.models.notificacion_model import Notificacion
from app.models.sync_model import SyncOutbox, SyncLog
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from datetime import date, datetime
import uuid
import random
import calendar
from decimal import Decimal, ROUND_HALF_UP

def add_months(sourcedate, months):
    month = sourcedate.month - 1 + months
    year = sourcedate.year + month // 12
    month = month % 12 + 1
    day = min(sourcedate.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)

class DesembolsoService:
    @staticmethod
    def desembolsar_solicitud(db: Session, id_solicitud: str) -> dict:
        # 1. Obtener la solicitud
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        if solicitud.estado not in ["APROBADO", "CONDICIONADO"]:
            raise BusinessRuleException(detail=f"La solicitud no puede ser desembolsada en estado {solicitud.estado}")

        monto_aprobado = solicitud.monto_aprobado or solicitud.monto_solicitado

        # 2. Obtener cliente y cuenta de ahorros
        cliente = ClienteRepository.get_by_id(db, solicitud.id_cliente)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")

        cuenta = db.query(CuentaAhorro).filter(
            CuentaAhorro.id_cliente == cliente.id_cliente,
            CuentaAhorro.estado == "ACTIVO"
        ).first()

        if not cuenta:
            raise BusinessRuleException(detail="El cliente no cuenta con una cuenta de ahorros activa para el desembolso")

        # 3. Obtener producto de credito
        producto_obj = CreditoRepository.get_producto_by_id(db, solicitud.id_producto_credito)
        producto_nombre = producto_obj.nombre if producto_obj else "Credito Consumo"

        # 4. Actualizar cuenta de ahorros
        cuenta.saldo_disponible += monto_aprobado
        cuenta.saldo_contable += monto_aprobado
        db.add(cuenta)

        # 5. Cambiar estado de solicitud
        solicitud.estado = "DESEMBOLSADO"
        db.add(solicitud)

        # 6. Crear cr_creditos
        tea_dec = float(solicitud.tea_referencial) / 100.0
        tem = (1.0 + tea_dec) ** (1.0 / 12.0) - 1.0
        
        # Calcular cuota
        plazo = solicitud.plazo_meses
        tem_val = Decimal(str(tem))
        monto_dec = Decimal(str(monto_aprobado))
        
        # Formula cuota: cuota = (monto * tem) / (1 - (1 + tem)^(-plazo))
        if tem == 0:
            cuota_estimada = monto_dec / plazo
        else:
            cuota_estimada = (monto_dec * tem_val) / (1 - (1 + tem_val) ** (-plazo))
        
        id_credito = uuid.uuid4()
        num_credito = f"CRD-{date.today().year}-{random.randint(100000, 999999)}"
        
        credito = Credito(
            id_credito=id_credito,
            id_solicitud=solicitud.id_solicitud,
            id_cliente=cliente.id_cliente,
            numero_credito=num_credito,
            producto=producto_nombre,
            monto_desembolsado=monto_aprobado,
            saldo_capital=monto_aprobado,
            plazo_meses=plazo,
            tea=solicitud.tea_referencial,
            tem=Decimal(str(round(tem, 6))),
            cuota_mensual=Decimal(str(round(float(cuota_estimada), 2))),
            fecha_desembolso=date.today(),
            dia_pago=date.today().day,
            estado="ACTIVO"
        )
        db.add(credito)

        # 7. Crear cr_cronograma_pagos
        saldo_actual = monto_dec
        cuota_float = float(cuota_estimada)
        
        for i in range(1, plazo + 1):
            fecha_cuota = add_months(date.today(), i)
            interes = saldo_actual * tem_val
            
            # Redondeo de interes
            interes = interes.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
            
            if i == plazo:
                capital = saldo_actual
                monto_cuota = capital + interes
                saldo = Decimal("0.00")
            else:
                capital = Decimal(str(round(cuota_float, 2))) - interes
                capital = capital.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
                monto_cuota = capital + interes
                saldo = saldo_actual - capital
            
            cuota_pago = CronogramaPago(
                id_cuota=uuid.uuid4(),
                id_credito=id_credito,
                numero_cuota=i,
                fecha_pago=fecha_cuota,
                monto_cuota=monto_cuota,
                capital=capital,
                interes=interes,
                saldo=saldo,
                estado="PENDIENTE",
                monto_pagado=Decimal("0.00")
            )
            db.add(cuota_pago)
            saldo_actual = saldo

        # 8. Crear cr_movimientos (DESEMBOLSO_CREDITO)
        movimiento = Movimiento(
            id_movimiento=uuid.uuid4(),
            id_cliente=cliente.id_cliente,
            id_cuenta=cuenta.id_cuenta,
            id_credito=id_credito,
            tipo_movimiento="DESEMBOLSO_CREDITO",
            descripcion=f"Desembolso credito {num_credito}",
            monto=monto_aprobado,
            moneda=solicitud.moneda,
            canal="SISTEMA_CORE"
        )
        db.add(movimiento)

        # 9. Crear notificacion
        notificacion = Notificacion(
            id_notificacion=uuid.uuid4(),
            id_usuario=cliente.id_usuario,
            titulo="Crédito Desembolsado",
            mensaje=f"Su solicitud {solicitud.numero_expediente} ha sido desembolsada. Se abonó {solicitud.moneda} {monto_aprobado} en su cta {cuenta.numero_cuenta}.",
            tipo="CREDITO",
            leida=False
        )
        db.add(notificacion)

        # 10. Crear evento outbox y sync log
        outbox_event = SyncOutbox(
            id_evento=uuid.uuid4(),
            tipo_evento="DESEMBOLSO_COMPLETO",
            entidad="cr_creditos",
            entidad_id=id_credito,
            payload={
                "id_solicitud": str(solicitud.id_solicitud),
                "id_credito": str(id_credito),
                "numero_credito": num_credito,
                "monto_desembolsado": float(monto_aprobado)
            },
            estado="PENDIENTE",
            intentos=0
        )
        db.add(outbox_event)
        
        # Debemos hacer un flush para obtener el id del evento
        db.flush()

        sync_log = SyncLog(
            id_log=uuid.uuid4(),
            id_evento=outbox_event.id_evento,
            accion="DESEMBOLSO_CREDITO",
            resultado="EXITOSO",
            detalle=f"Se desembolso el credito {num_credito} al cliente DNI {cliente.documento}"
        )
        db.add(sync_log)

        db.commit()

        return {
            "id_credito": str(id_credito),
            "numero_credito": num_credito,
            "monto_desembolsado": float(monto_aprobado),
            "cuenta_destino": cuenta.numero_cuenta,
            "estado": "DESEMBOLSADO"
        }
