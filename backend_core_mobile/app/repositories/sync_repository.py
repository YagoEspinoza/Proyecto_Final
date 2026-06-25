from sqlalchemy.orm import Session
from app.models.sync_model import SyncOutbox, SyncLog, ListaInhabilitados
from typing import List

class SyncRepository:
    @staticmethod
    def get_outbox_pendientes(db: Session) -> List[SyncOutbox]:
        return db.query(SyncOutbox).filter(SyncOutbox.estado == "PENDIENTE").order_by(SyncOutbox.created_at).all()

    @staticmethod
    def create_outbox(db: Session, outbox: SyncOutbox) -> SyncOutbox:
        db.add(outbox)
        db.commit()
        db.refresh(outbox)
        return outbox

    @staticmethod
    def update_outbox(db: Session, db_obj: SyncOutbox, obj_in: dict) -> SyncOutbox:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    @staticmethod
    def create_log(db: Session, log: SyncLog) -> SyncLog:
        db.add(log)
        db.commit()
        db.refresh(log)
        return log

    @staticmethod
    def is_inhabilitado(db: Session, documento: str) -> bool:
        inhab = db.query(ListaInhabilitados).filter(
            ListaInhabilitados.documento == documento,
            ListaInhabilitados.estado == "ACTIVO"
        ).first()
        return inhab is not None
