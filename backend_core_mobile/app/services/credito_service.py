from sqlalchemy.orm import Session
from app.repositories.credito_repository import CreditoRepository
from app.repositories.cronograma_repository import CronogramaRepository
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.cuenta_repository import CuentaRepository
from app.repositories.movimiento_repository import MovimientoRepository
from app.models.credito_model import Credito
from app.models.movimiento_model import Movimiento, OperacionCliente
from app.schemas.movimiento_schema import PagoCreditoRequest, OperacionResponse
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from typing import List
from datetime import date, datetime
import uuid

class CreditoService:
    @staticmethod
    def get_creditos_cliente(db: Session, id_usuario: str) -> List[Credito]:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        return CreditoRepository.get_creditos_by_cliente_id(db, cliente.id_cliente)

    @staticmethod
    def get_credito_detalle(db: Session, id_credito: str) -> Credito:
        credito = CreditoRepository.get_by_id(db, id_credito)
        if not credito:
            raise ResourceNotFoundException(detail="Credito no encontrado")
        return credito

    @staticmethod
    def get_cronograma_credito(db: Session, id_credito: str) -> list:
        return CronogramaRepository.get_cronograma_by_credito_id(db, id_credito)

    @staticmethod
    def pagar_cuota(db: Session, id_usuario: str, request: PagoCreditoRequest) -> OperacionResponse:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")

        cuenta = CuentaRepository.get_by_id(db, request.cuenta_origen_id)
        if not cuenta or cuenta.id_cliente != cliente.id_cliente:
            raise ResourceNotFoundException(detail="Cuenta de origen no encontrada o no pertenece al cliente")

        credito = CreditoRepository.get_by_id(db, request.id_credito)
        if not credito or credito.id_cliente != cliente.id_cliente:
            raise ResourceNotFoundException(detail="Credito no encontrado o no pertenece al cliente")

        cuota = CronogramaRepository.get_by_id(db, request.id_cuota)
        if not cuota or cuota.id_credito != credito.id_credito:
            raise ResourceNotFoundException(detail="Cuota no encontrada")

        if cuota.estado == "PAGADA":
            raise BusinessRuleException(detail="La cuota ya se encuentra pagada")

        if cuenta.saldo_disponible < request.monto:
            raise BusinessRuleException(detail="Saldo insuficiente para pagar la cuota")

        # Debitar de cuenta
        cuenta.saldo_disponible -= request.monto
        cuenta.saldo_contable -= request.monto
        db.add(cuenta)

        # Actualizar cuota
        cuota.monto_pagado += request.monto
        if cuota.monto_pagado >= cuota.monto_cuota:
            cuota.estado = "PAGADA"
            cuota.monto_pagado = cuota.monto_cuota
        else:
            cuota.estado = "PARCIAL"
        cuota.fecha_pago_real = date.today()
        db.add(cuota)

        # Actualizar saldo capital del credito (solo si la cuota pasa a pagada de forma logica simplificada)
        if cuota.estado == "PAGADA":
            credito.saldo_capital -= cuota.capital
            if credito.saldo_capital < 0:
                credito.saldo_capital = 0
            db.add(credito)

        # Registrar Operacion
        operacion = OperacionCliente(
            id_operacion=uuid.uuid4(),
            id_cliente=cliente.id_cliente,
            tipo_operacion="PAGO_CREDITO",
            cuenta_origen=cuenta.id_cuenta,
            id_credito=credito.id_credito,
            monto=request.monto,
            moneda=cuenta.moneda,
            descripcion=f"Pago cuota {cuota.numero_cuota} de credito {credito.numero_credito}",
            estado="PROCESADA"
        )
        MovimientoRepository.create_operacion(db, operacion)

        # Registrar Movimiento
        mov = Movimiento(
            id_movimiento=uuid.uuid4(),
            id_cliente=cliente.id_cliente,
            id_cuenta=cuenta.id_cuenta,
            id_credito=credito.id_credito,
            tipo_movimiento="PAGO_CUOTA",
            descripcion=f"Pago cuota {cuota.numero_cuota} de credito {credito.numero_credito}",
            monto=-request.monto,
            moneda=cuenta.moneda,
            canal="APP_MOVIL"
        )
        MovimientoRepository.create_movimiento(db, mov)

        db.commit()

        return OperacionResponse(
            id_operacion=str(operacion.id_operacion),
            tipo_operacion=operacion.tipo_operacion,
            monto=operacion.monto,
            moneda=operacion.moneda,
            estado=operacion.estado,
            created_at=operacion.created_at
        )
