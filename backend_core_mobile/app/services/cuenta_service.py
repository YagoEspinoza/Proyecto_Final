from sqlalchemy.orm import Session
from app.repositories.cuenta_repository import CuentaRepository
from app.repositories.movimiento_repository import MovimientoRepository
from app.repositories.cliente_repository import ClienteRepository
from app.models.cuenta_model import CuentaAhorro, Tarjeta
from app.models.movimiento_model import Movimiento, OperacionCliente
from app.schemas.movimiento_schema import TransferenciaRequest, OperacionResponse
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from typing import List
import uuid

class CuentaService:
    @staticmethod
    def get_cuentas_cliente(db: Session, id_usuario: str) -> List[CuentaAhorro]:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        return CuentaRepository.get_cuentas_by_cliente_id(db, cliente.id_cliente)

    @staticmethod
    def get_tarjetas_cliente(db: Session, id_usuario: str) -> List[Tarjeta]:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        return CuentaRepository.get_tarjetas_by_cliente_id(db, cliente.id_cliente)

    @staticmethod
    def ejecutar_transferencia(db: Session, id_usuario: str, request: TransferenciaRequest) -> OperacionResponse:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")

        cuenta_origen = CuentaRepository.get_by_id(db, request.cuenta_origen_id)
        if not cuenta_origen or cuenta_origen.id_cliente != cliente.id_cliente:
            raise ResourceNotFoundException(detail="Cuenta de origen no encontrada o no pertenece al cliente")

        if cuenta_origen.saldo_disponible < request.monto:
            raise BusinessRuleException(detail="Saldo insuficiente para realizar la transferencia")

        cuenta_destino = CuentaRepository.get_by_numero(db, request.cuenta_destino_numero)
        
        # Debitar origen
        cuenta_origen.saldo_disponible -= request.monto
        cuenta_origen.saldo_contable -= request.monto
        db.add(cuenta_origen)

        # Si la cuenta de destino es interna (existe en el sistema)
        if cuenta_destino:
            cuenta_destino.saldo_disponible += request.monto
            cuenta_destino.saldo_contable += request.monto
            db.add(cuenta_destino)

        # Crear Operacion
        operacion = OperacionCliente(
            id_operacion=uuid.uuid4(),
            id_cliente=cliente.id_cliente,
            tipo_operacion="TRANSFERENCIA",
            cuenta_origen=cuenta_origen.id_cuenta,
            cuenta_destino=request.cuenta_destino_numero,
            monto=request.monto,
            moneda=cuenta_origen.moneda,
            descripcion=request.descripcion or f"Transferencia a cuenta {request.cuenta_destino_numero}",
            estado="PROCESADA"
        )
        MovimientoRepository.create_operacion(db, operacion)

        # Registrar movimiento en origen
        mov_origen = Movimiento(
            id_movimiento=uuid.uuid4(),
            id_cliente=cliente.id_cliente,
            id_cuenta=cuenta_origen.id_cuenta,
            tipo_movimiento="TRANSFERENCIA",
            descripcion=request.descripcion or f"Transferencia enviada a cta {request.cuenta_destino_numero}",
            monto=-request.monto,  # Negativo representará salida
            moneda=cuenta_origen.moneda,
            canal="APP_MOVIL"
        )
        MovimientoRepository.create_movimiento(db, mov_origen)

        # Si la cuenta destino es interna, registrar movimiento de deposito en destino
        if cuenta_destino:
            mov_destino = Movimiento(
                id_movimiento=uuid.uuid4(),
                id_cliente=cuenta_destino.id_cliente,
                id_cuenta=cuenta_destino.id_cuenta,
                tipo_movimiento="DEPOSITO",
                descripcion=f"Transferencia recibida de cta {cuenta_origen.numero_cuenta}",
                monto=request.monto,
                moneda=cuenta_destino.moneda,
                canal="APP_MOVIL"
            )
            MovimientoRepository.create_movimiento(db, mov_destino)

        db.commit()

        return OperacionResponse(
            id_operacion=str(operacion.id_operacion),
            tipo_operacion=operacion.tipo_operacion,
            monto=operacion.monto,
            moneda=operacion.moneda,
            estado=operacion.estado,
            created_at=operacion.created_at
        )
