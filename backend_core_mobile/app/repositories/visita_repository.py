from sqlalchemy.orm import Session
from app.models.visita_model import VisitaCliente

class VisitaRepository:
    @staticmethod
    def create(db: Session, visita: VisitaCliente) -> VisitaCliente:
        db.add(visita)
        db.commit()
        db.refresh(visita)
        return visita
