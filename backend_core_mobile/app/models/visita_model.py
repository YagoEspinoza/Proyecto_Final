from sqlalchemy import Column, String, ForeignKey, DateTime, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class VisitaCliente(Base):
    __tablename__ = "visitas_cliente"
    id_visita = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cartera = Column(UUID(as_uuid=True), ForeignKey("cartera_diaria.id_cartera", ondelete="CASCADE"), nullable=False)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    resultado = Column(String(50), nullable=False)
    observacion = Column(String)
    lat = Column(Numeric(10, 7), nullable=False)
    lng = Column(Numeric(10, 7), nullable=False)
    fecha_hora = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
