from sqlalchemy.orm import Session
from app.models.asesor_model import Asesor

class AsesorRepository:
    @staticmethod
    def get_by_id(db: Session, id_asesor: str) -> Asesor:
        return db.query(Asesor).filter(Asesor.id_asesor == id_asesor).first()

    @staticmethod
    def get_by_usuario_id(db: Session, id_usuario: str) -> Asesor:
        return db.query(Asesor).filter(Asesor.id_usuario == id_usuario).first()

    @staticmethod
    def get_by_codigo(db: Session, codigo: str) -> Asesor:
        return db.query(Asesor).filter(Asesor.codigo_empleado == codigo).first()
