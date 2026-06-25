from sqlalchemy.orm import Session
from app.models.cuenta_model import CuentaAhorro, Tarjeta
from typing import List

class CuentaRepository:
    @staticmethod
    def get_by_id(db: Session, id_cuenta: str) -> CuentaAhorro:
        return db.query(CuentaAhorro).filter(CuentaAhorro.id_cuenta == id_cuenta).first()

    @staticmethod
    def get_by_numero(db: Session, numero_cuenta: str) -> CuentaAhorro:
        return db.query(CuentaAhorro).filter(CuentaAhorro.numero_cuenta == numero_cuenta).first()

    @staticmethod
    def get_cuentas_by_cliente_id(db: Session, id_cliente: str) -> List[CuentaAhorro]:
        return db.query(CuentaAhorro).filter(CuentaAhorro.id_cliente == id_cliente).all()

    @staticmethod
    def get_tarjetas_by_cliente_id(db: Session, id_cliente: str) -> List[Tarjeta]:
        return db.query(Tarjeta).filter(Tarjeta.id_cliente == id_cliente).all()

    @staticmethod
    def update(db: Session, db_obj: CuentaAhorro, obj_in: dict) -> CuentaAhorro:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
