from sqlalchemy.orm import Session
from app.models.cartera_model import CarteraDiaria
from typing import List
from datetime import date

class CarteraRepository:
    @staticmethod
    def get_by_id(db: Session, id_cartera: str) -> CarteraDiaria:
        return db.query(CarteraDiaria).filter(CarteraDiaria.id_cartera == id_cartera).first()

    @staticmethod
    def get_cartera_hoy(db: Session, id_asesor: str) -> List[CarteraDiaria]:
        res = db.query(CarteraDiaria).filter(
            CarteraDiaria.id_asesor == id_asesor,
            CarteraDiaria.fecha_asignacion == date.today()
        ).all()
        if not res:
            res = db.query(CarteraDiaria).filter(
                CarteraDiaria.id_asesor == id_asesor
            ).all()
        return res

    @staticmethod
    def create(db: Session, cartera: CarteraDiaria) -> CarteraDiaria:
        db.add(cartera)
        db.commit()
        db.refresh(cartera)
        return cartera

    @staticmethod
    def update(db: Session, db_obj: CarteraDiaria, obj_in: dict) -> CarteraDiaria:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
