from sqlalchemy.orm import Session
from app.models.notificacion_model import Notificacion
from app.core.exceptions import ResourceNotFoundException
from typing import List
import uuid

class NotificacionService:
    @staticmethod
    def get_notificaciones_usuario(db: Session, id_usuario: str) -> List[Notificacion]:
        return db.query(Notificacion).filter(
            Notificacion.id_usuario == id_usuario
        ).order_by(Notificacion.created_at.desc()).all()

    @staticmethod
    def crear_notificacion(db: Session, id_usuario: str, titulo: str, mensaje: str, tipo: str = "GENERAL") -> Notificacion:
        notif = Notificacion(
            id_notificacion=uuid.uuid4(),
            id_usuario=id_usuario,
            titulo=titulo,
            mensaje=mensaje,
            tipo=tipo,
            leida=False
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif

    @staticmethod
    def marcar_leida(db: Session, id_usuario: str, id_notificacion: str) -> Notificacion:
        notif = db.query(Notificacion).filter(
            Notificacion.id_notificacion == id_notificacion,
            Notificacion.id_usuario == id_usuario
        ).first()
        if not notif:
            raise ResourceNotFoundException(detail="Notificacion no encontrada")
        
        notif.leida = True
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif
