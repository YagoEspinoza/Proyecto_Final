from sqlalchemy.orm import Session
from app.models.documento_model import SolicitudDocumento
from typing import List

class DocumentoRepository:
    @staticmethod
    def get_by_id(db: Session, id_documento: str) -> SolicitudDocumento:
        return db.query(SolicitudDocumento).filter(SolicitudDocumento.id_documento == id_documento).first()

    @staticmethod
    def get_documentos_by_solicitud_id(db: Session, id_solicitud: str) -> List[SolicitudDocumento]:
        return db.query(SolicitudDocumento).filter(SolicitudDocumento.id_solicitud == id_solicitud).all()

    @staticmethod
    def create(db: Session, documento: SolicitudDocumento) -> SolicitudDocumento:
        db.add(documento)
        db.commit()
        db.refresh(documento)
        return documento

    @staticmethod
    def update(db: Session, db_obj: SolicitudDocumento, obj_in: dict) -> SolicitudDocumento:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
