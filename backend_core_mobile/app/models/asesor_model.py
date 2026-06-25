from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class Asesor(Base):
    __tablename__ = "asesores"
    id_asesor = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    id_agencia = Column(UUID(as_uuid=True), ForeignKey("agencias.id_agencia", ondelete="SET NULL"), nullable=True)
    codigo_empleado = Column(String(20), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    telefono = Column(String(20))
    cargo = Column(String(80))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
