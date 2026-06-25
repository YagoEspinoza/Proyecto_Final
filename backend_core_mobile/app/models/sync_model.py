from sqlalchemy import Column, String, ForeignKey, DateTime, Integer
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.database.connection import Base

class ListaInhabilitados(Base):
    __tablename__ = "listas_inhabilitados"
    id_lista = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    documento = Column(String(15), unique=True, nullable=False)
    motivo = Column(String)
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class SyncOutbox(Base):
    __tablename__ = "sync_outbox"
    id_evento = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    tipo_evento = Column(String(80), nullable=False)
    entidad = Column(String(80), nullable=False)
    entidad_id = Column(UUID(as_uuid=True), nullable=False)
    payload = Column(JSONB, nullable=False)
    estado = Column(String(30), default="PENDIENTE")
    intentos = Column(Integer, default=0)
    error = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    procesado_at = Column(DateTime(timezone=True))

class SyncLog(Base):
    __tablename__ = "sync_log"
    id_log = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_evento = Column(UUID(as_uuid=True), ForeignKey("sync_outbox.id_evento", ondelete="SET NULL"), nullable=True)
    accion = Column(String(100), nullable=False)
    resultado = Column(String(30), nullable=False)
    detalle = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
