from sqlalchemy.orm import Session
from app.repositories.solicitud_repository import SolicitudRepository
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.credito_repository import CreditoRepository
from app.repositories.asesor_repository import AsesorRepository
from app.models.solicitud_model import SolicitudCredito
from app.models.cartera_model import CarteraDiaria
from app.models.asesor_model import Asesor
from app.schemas.solicitud_schema import SolicitudCreate
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from typing import List
from datetime import datetime, date
import uuid
import random

class SolicitudService:
    @staticmethod
    def crear_solicitud(db: Session, id_usuario: str, request: SolicitudCreate, canal_origen: str = "CLIENTE") -> SolicitudCredito:
        if request.documento_cliente:
            cliente = ClienteRepository.get_by_documento(db, request.documento_cliente)
        else:
            cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
            
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")

        producto = CreditoRepository.get_producto_by_id(db, request.id_producto_credito)
        if not producto:
            raise ResourceNotFoundException(detail="Producto de credito no encontrado")

        # Validaciones de montos y plazos
        if request.monto_solicitado < producto.monto_minimo or request.monto_solicitado > producto.monto_maximo:
            raise BusinessRuleException(detail=f"Monto fuera de los limites permitidos ({producto.monto_minimo} - {producto.monto_maximo})")
        if request.plazo_meses < producto.plazo_minimo or request.plazo_meses > producto.plazo_maximo:
            raise BusinessRuleException(detail=f"Plazo fuera de los limites permitidos ({producto.plazo_minimo} - {producto.plazo_maximo})")

        # Seleccionar tasa (con o sin seguro)
        tea = producto.tea_con_seguro if request.con_seguro_desgravamen else producto.tea_sin_seguro

        # Formula Francesa
        tea_dec = float(tea) / 100.0
        tem = (1.0 + tea_dec) ** (1.0 / 12.0) - 1.0
        monto_float = float(request.monto_solicitado)
        plazo = request.plazo_meses
        cuota = (monto_float * tem) / (1.0 - (1.0 + tem) ** (-plazo))

        # Asignar un asesor de la misma agencia (o cualquiera si no hay)
        asesor = db.query(Asesor).filter(Asesor.id_agencia == cliente.id_agencia, Asesor.estado == "ACTIVO").first()
        if not asesor:
            asesor = db.query(Asesor).filter(Asesor.estado == "ACTIVO").first()

        id_asesor = asesor.id_asesor if asesor else None

        # Generar expediente
        num_exp = f"EXP-{datetime.now().year}-{random.randint(100000, 999999)}"

        negocio = ClienteRepository.get_negocio_by_cliente_id(db, cliente.id_cliente)
        if not negocio:
            raise BusinessRuleException(detail="El cliente debe registrar un negocio antes de solicitar un credito")

        solicitud = SolicitudCredito(
            id_solicitud=uuid.uuid4(),
            numero_expediente=num_exp,
            id_cliente=cliente.id_cliente,
            id_negocio=negocio.id_negocio,
            id_asesor=id_asesor,
            id_producto_credito=producto.id_producto_credito,
            canal_origen=canal_origen,
            monto_solicitado=request.monto_solicitado,
            plazo_meses=request.plazo_meses,
            moneda=producto.moneda,
            tea_referencial=tea,
            con_seguro_desgravamen=request.con_seguro_desgravamen,
            garantia=request.garantia,
            destino_credito=request.destino_credito,
            cuota_estimada=cuota,
            estado="ENVIADO" if canal_origen == "CLIENTE" else "BORRADOR",
            lat_captura=request.lat_captura,
            lng_captura=request.lng_captura
        )
        
        SolicitudRepository.create(db, solicitud)

        # Si nace desde el Cliente, se asigna automaticamente a la cartera diaria del asesor
        if canal_origen == "CLIENTE" and id_asesor:
            cartera = CarteraDiaria(
                id_cartera=uuid.uuid4(),
                id_asesor=id_asesor,
                id_cliente=cliente.id_cliente,
                id_solicitud=solicitud.id_solicitud,
                fecha_asignacion=date.today(),
                tipo_gestion="NUEVA_SOLICITUD",
                prioridad="ALTA",
                score_prioridad=95,
                estado_visita="PENDIENTE"
            )
            db.add(cartera)
            db.commit()

        return solicitud

    @staticmethod
    def get_solicitudes_cliente(db: Session, id_usuario: str) -> List[SolicitudCredito]:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        return SolicitudRepository.get_solicitudes_by_cliente_id(db, cliente.id_cliente)
