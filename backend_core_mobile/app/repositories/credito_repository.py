from sqlalchemy.orm import Session
from app.models.credito_model import Credito, ProductoCredito
from typing import List

class CreditoRepository:
    @staticmethod
    def get_by_id(db: Session, id_credito: str) -> Credito:
        return db.query(Credito).filter(Credito.id_credito == id_credito).first()

    @staticmethod
    def get_creditos_by_cliente_id(db: Session, id_cliente: str) -> List[Credito]:
        return db.query(Credito).filter(Credito.id_cliente == id_cliente).all()

    @staticmethod
    def get_producto_by_id(db: Session, id_producto: str) -> ProductoCredito:
        return db.query(ProductoCredito).filter(ProductoCredito.id_producto_credito == id_producto).first()

    @staticmethod
    def get_productos_activos(db: Session) -> List[ProductoCredito]:
        return db.query(ProductoCredito).filter(ProductoCredito.estado == "ACTIVO").all()

    @staticmethod
    def create_credito(db: Session, credito: Credito) -> Credito:
        db.add(credito)
        db.commit()
        db.refresh(credito)
        return credito

    @staticmethod
    def update_credito(db: Session, db_obj: Credito, obj_in: dict) -> Credito:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
