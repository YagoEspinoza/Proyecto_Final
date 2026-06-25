from fastapi import APIRouter, Depends, status, Body
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import require_roles
from app.models.usuario_model import Usuario
from app.repositories.solicitud_repository import SolicitudRepository
from app.schemas.solicitud_schema import SolicitudCreditoSchema
from app.services.comite_service import ComiteService
from app.services.desembolso_service import DesembolsoService
from app.core.exceptions import ResourceNotFoundException
from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel

router = APIRouter(prefix="/comite", tags=["Supervisor / Comité"])

class AprobarRequest(BaseModel):
    monto_aprobado: Optional[Decimal] = None

class CondicionarRequest(BaseModel):
    condicion_adicional: str

class RechazarRequest(BaseModel):
    motivo_rechazo: str

@router.get("/solicitudes", response_model=List[SolicitudCreditoSchema])
def list_solicitudes(
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return SolicitudRepository.get_solicitudes_comite(db)

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoSchema)
def get_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
    return solicitud

@router.post("/solicitudes/{id_solicitud}/recibir")
def recibir_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return ComiteService.recibir_solicitud(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/evaluar")
def evaluar_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return ComiteService.evaluar_solicitud(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/aprobar")
def aprobar_solicitud(
    id_solicitud: str,
    payload: AprobarRequest,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return ComiteService.aprobar_solicitud(db, id_solicitud, payload.monto_aprobado)

@router.post("/solicitudes/{id_solicitud}/condicionar")
def condicionar_solicitud(
    id_solicitud: str,
    payload: CondicionarRequest,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return ComiteService.condicionar_solicitud(db, id_solicitud, payload.condicion_adicional)

@router.post("/solicitudes/{id_solicitud}/rechazar")
def rechazar_solicitud(
    id_solicitud: str,
    payload: RechazarRequest,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return ComiteService.rechazar_solicitud(db, id_solicitud, payload.motivo_rechazo)

@router.post("/solicitudes/{id_solicitud}/desembolsar")
def desembolsar_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    return DesembolsoService.desembolsar_solicitud(db, id_solicitud)
