from sqlalchemy.orm import Session
from app.models.movimiento_model import Movimiento, OperacionCliente
from typing import List

class MovimientoRepository:
    @staticmethod
    def get_movimientos_by_cliente_id(db: Session, id_cliente: str) -> List[Movimiento]:
        return db.query(Movimiento).filter(Movimiento.id_cliente == id_cliente).order_by(Movimiento.fecha_movimiento.desc()).all()

    @staticmethod
    def create_movimiento(db: Session, movimiento: Movimiento) -> Movimiento:
        db.add(movimiento)
        db.commit()
        db.refresh(movimiento)
        return movimiento

    @staticmethod
    def create_operacion(db: Session, operacion: OperacionCliente) -> OperacionCliente:
        db.add(operacion)
        db.commit()
        db.refresh(operacion)
        return operacion

    @staticmethod
    def update_operacion(db: Session, db_obj: OperacionCliente, obj_in: dict) -> OperacionCliente:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
