from sqlalchemy.orm import Session
from app.models.cliente_model import Cliente, NegocioCliente

class ClienteRepository:
    @staticmethod
    def get_by_id(db: Session, id_cliente: str) -> Cliente:
        return db.query(Cliente).filter(Cliente.id_cliente == id_cliente).first()

    @staticmethod
    def get_by_usuario_id(db: Session, id_usuario: str) -> Cliente:
        return db.query(Cliente).filter(Cliente.id_usuario == id_usuario).first()

    @staticmethod
    def get_by_documento(db: Session, documento: str) -> Cliente:
        return db.query(Cliente).filter(Cliente.documento == documento).first()

    @staticmethod
    def get_negocio_by_cliente_id(db: Session, id_cliente: str) -> NegocioCliente:
        return db.query(NegocioCliente).filter(NegocioCliente.id_cliente == id_cliente).first()
