from sqlalchemy.orm import Session
from app.models.usuario_model import Usuario

class UsuarioRepository:
    @staticmethod
    def get_by_id(db: Session, id_usuario: str) -> Usuario:
        return db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()

    @staticmethod
    def get_by_documento(db: Session, documento: str) -> Usuario:
        return db.query(Usuario).filter(Usuario.documento == documento).first()

    @staticmethod
    def get_by_codigo_empleado(db: Session, codigo_empleado: str) -> Usuario:
        return db.query(Usuario).filter(Usuario.codigo_empleado == codigo_empleado).first()

    @staticmethod
    def update(db: Session, db_obj: Usuario, obj_in: dict) -> Usuario:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj
