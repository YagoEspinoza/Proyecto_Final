from sqlalchemy.orm import Session
from app.models.solicitud_model import SolicitudCredito
from app.models.cliente_model import Cliente
from typing import List

class SolicitudRepository:
    @staticmethod
    def get_by_id(db: Session, id_solicitud: str) -> SolicitudCredito:
        s = db.query(SolicitudCredito).filter(SolicitudCredito.id_solicitud == id_solicitud).first()
        if s:
            cliente = db.query(Cliente).filter(Cliente.id_cliente == s.id_cliente).first()
            if cliente:
                s.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
        return s

    @staticmethod
    def get_solicitudes_by_cliente_id(db: Session, id_cliente: str) -> List[SolicitudCredito]:
        solicitudes = db.query(SolicitudCredito).filter(SolicitudCredito.id_cliente == id_cliente).all()
        for s in solicitudes:
            cliente = db.query(Cliente).filter(Cliente.id_cliente == s.id_cliente).first()
            if cliente:
                s.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
        return solicitudes

    @staticmethod
    def get_solicitudes_by_asesor_id(db: Session, id_asesor: str) -> List[SolicitudCredito]:
        solicitudes = db.query(SolicitudCredito).filter(SolicitudCredito.id_asesor == id_asesor).all()
        for s in solicitudes:
            cliente = db.query(Cliente).filter(Cliente.id_cliente == s.id_cliente).first()
            if cliente:
                s.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
        return solicitudes

    @staticmethod
    def get_solicitudes_comite(db: Session) -> List[SolicitudCredito]:
        solicitudes = db.query(SolicitudCredito).filter(
            SolicitudCredito.estado.in_(['ENVIADO', 'RECIBIDO_COMITE', 'EN_EVALUACION', 'APROBADO', 'CONDICIONADO', 'RECHAZADO', 'DESEMBOLSADO'])
        ).all()
        for s in solicitudes:
            cliente = db.query(Cliente).filter(Cliente.id_cliente == s.id_cliente).first()
            if cliente:
                s.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
            else:
                s.cliente_nombre = "Desconocido"
        return solicitudes

    @staticmethod
    def create(db: Session, solicitud: SolicitudCredito) -> SolicitudCredito:
        db.add(solicitud)
        db.commit()
        db.refresh(solicitud)
        cliente = db.query(Cliente).filter(Cliente.id_cliente == solicitud.id_cliente).first()
        if cliente:
            solicitud.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
        return solicitud

    @staticmethod
    def update(db: Session, db_obj: SolicitudCredito, obj_in: dict) -> SolicitudCredito:
        for field in obj_in:
            if hasattr(db_obj, field):
                setattr(db_obj, field, obj_in[field])
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        cliente = db.query(Cliente).filter(Cliente.id_cliente == db_obj.id_cliente).first()
        if cliente:
            db_obj.cliente_nombre = f"{cliente.nombres} {cliente.apellidos}"
        return db_obj
