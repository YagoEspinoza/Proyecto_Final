from sqlalchemy import Column, String, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class SolicitudDocumento(Base):
    __tablename__ = "solicitudes_documentos"
    id_documento = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud", ondelete="CASCADE"), nullable=False)
    tipo_documento = Column(String(50), nullable=False)
    nombre_archivo = Column(String(200), nullable=False)
    storage_path = Column(String, nullable=False)
    url_publica = Column(String, nullable=True)
    estado_validacion = Column(String(30), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
