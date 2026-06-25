from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import require_roles
from app.models.usuario_model import Usuario
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.solicitud_repository import SolicitudRepository
from app.schemas.cliente_schema import ClienteSchema
from app.schemas.cuenta_schema import CuentaAhorroSchema as CuentaSchema
from app.schemas.movimiento_schema import MovimientoSchema, TransferenciaRequest, PagoCreditoRequest, OperacionResponse
from app.schemas.credito_schema import CreditoSchema
from app.schemas.cronograma_schema import CronogramaPagoSchema as CronogramaSchema
from app.schemas.solicitud_schema import SolicitudCreate, SolicitudCreditoSchema
from app.services.cuenta_service import CuentaService
from app.services.movimiento_service import MovimientoService
from app.services.credito_service import CreditoService
from app.services.solicitud_service import SolicitudService
from app.services.notificacion_service import NotificacionService
from app.core.exceptions import ResourceNotFoundException
from typing import List

router = APIRouter(prefix="/cliente", tags=["Cliente / Homebanking"])

@router.get("/perfil", response_model=ClienteSchema)
def get_perfil(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    cliente = ClienteRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not cliente:
        raise ResourceNotFoundException(detail="Perfil del cliente no encontrado")
    return cliente

@router.get("/cuentas", response_model=List[CuentaSchema])
def get_cuentas(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CuentaService.get_cuentas_cliente(db, current_user.id_usuario)

@router.get("/movimientos", response_model=List[MovimientoSchema])
def get_movimientos(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return MovimientoService.get_movimientos_cliente(db, current_user.id_usuario)

@router.get("/tarjetas")
def get_tarjetas(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CuentaService.get_tarjetas_cliente(db, current_user.id_usuario)

@router.get("/creditos", response_model=List[CreditoSchema])
def get_creditos(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CreditoService.get_creditos_cliente(db, current_user.id_usuario)

@router.get("/creditos/{id_credito}", response_model=CreditoSchema)
def get_credito(
    id_credito: str,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CreditoService.get_credito_detalle(db, id_credito)

@router.get("/creditos/{id_credito}/cronograma", response_model=List[CronogramaSchema])
def get_cronograma(
    id_credito: str,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CreditoService.get_cronograma_credito(db, id_credito)

@router.get("/notificaciones")
def get_notificaciones(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return NotificacionService.get_notificaciones_usuario(db, current_user.id_usuario)

@router.post("/solicitudes", response_model=SolicitudCreditoSchema, status_code=status.HTTP_201_CREATED)
def crear_solicitud(
    request: SolicitudCreate,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return SolicitudService.crear_solicitud(db, current_user.id_usuario, request, canal_origen="CLIENTE")

@router.get("/solicitudes", response_model=List[SolicitudCreditoSchema])
def get_solicitudes(
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return SolicitudService.get_solicitudes_cliente(db, current_user.id_usuario)

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoSchema)
def get_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
    cliente = ClienteRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not cliente or solicitud.id_cliente != cliente.id_cliente:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
    return solicitud

@router.post("/operaciones/transferencia", response_model=OperacionResponse)
def realizar_transferencia(
    request: TransferenciaRequest,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CuentaService.ejecutar_transferencia(db, current_user.id_usuario, request)

@router.post("/operaciones/pago-credito", response_model=OperacionResponse)
def pagar_credito(
    request: PagoCreditoRequest,
    current_user: Usuario = require_roles(["CLIENTE"]),
    db: Session = Depends(get_db)
):
    return CreditoService.pagar_cuota(db, current_user.id_usuario, request)
