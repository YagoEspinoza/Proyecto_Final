from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
from app.database.connection import Base

class AuditoriaEvento(Base):
    __tablename__ = "auditoria_eventos"
    id_auditoria = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="SET NULL"), nullable=True)
    accion = Column(String(100), nullable=False)
    entidad = Column(String(100), nullable=False)
    entidad_id = Column(UUID(as_uuid=True), nullable=True)
    ip = Column(String(80))
    user_agent = Column(String)
    detalle = Column(JSONB)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
