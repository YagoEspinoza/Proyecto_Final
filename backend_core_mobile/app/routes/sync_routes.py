from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import require_roles
from app.models.usuario_model import Usuario
from app.services.sync_service import SyncService
from typing import List

router = APIRouter(prefix="/sync", tags=["Sync"])

@router.get("/outbox")
def get_outbox(
    current_user: Usuario = require_roles(["ADMIN", "SUPERVISOR", "ASESOR"]),
    db: Session = Depends(get_db)
):
    events = SyncService.get_pending_events(db)
    return [{
        "id_evento": str(e.id_evento),
        "tipo_evento": e.tipo_evento,
        "entidad": e.entidad,
        "entidad_id": str(e.entidad_id),
        "payload": e.payload,
        "estado": e.estado,
        "intentos": e.intentos,
        "error": e.error,
        "created_at": e.created_at
    } for e in events]

@router.post("/procesar")
def procesar_outbox(
    current_user: Usuario = require_roles(["ADMIN", "SUPERVISOR"]),
    db: Session = Depends(get_db)
):
    return SyncService.procesar_outbox(db)

@router.get("/log")
def get_sync_log(
    current_user: Usuario = require_roles(["ADMIN", "SUPERVISOR"]),
    db: Session = Depends(get_db)
):
    logs = SyncService.get_logs(db)
    return [{
        "id_log": str(l.id_log),
        "id_evento": str(l.id_evento) if l.id_evento else None,
        "accion": l.accion,
        "resultado": l.resultado,
        "detalle": l.detalle,
        "created_at": l.created_at
    } for l in logs]
