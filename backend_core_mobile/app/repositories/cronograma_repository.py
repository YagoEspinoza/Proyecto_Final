from sqlalchemy.orm import Session
from app.models.cronograma_model import CronogramaPago
from typing import List

class CronogramaRepository:
    @staticmethod
    def get_by_id(db: Session, id_cuota: str) -> CronogramaPago:
        return db.query(CronogramaPago).filter(CronogramaPago.id_cuota == id_cuota).first()

    @staticmethod
    def get_cronograma_by_credito_id(db: Session, id_credito: str) -> List[CronogramaPago]:
        return db.query(CronogramaPago).filter(CronogramaPago.id_credito == id_credito).order_by(CronogramaPago.numero_cuota).all()

    @staticmethod
    def create_cronograma(db: Session, cronograma: List[CronogramaPago]) -> List[CronogramaPago]:
        db.add_all(cronograma)
        db.commit()
        return cronograma

    @staticmethod
    def update_cuota(db: Session, db_obj: CronogramaPago, obj_in: dict) -> CronogramaPago:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
