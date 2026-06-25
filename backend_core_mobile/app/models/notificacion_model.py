from sqlalchemy import Column, String, ForeignKey, DateTime, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class Notificacion(Base):
    __tablename__ = "notificaciones"
    id_notificacion = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    titulo = Column(String(150), nullable=False)
    mensaje = Column(String, nullable=False)
    tipo = Column(String(50))
    leida = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
