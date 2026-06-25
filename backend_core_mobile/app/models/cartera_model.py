from sqlalchemy import Column, String, ForeignKey, DateTime, Date, Integer, Boolean, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class CarteraDiaria(Base):
    __tablename__ = "cartera_diaria"
    id_cartera = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud", ondelete="SET NULL"), nullable=True)
    fecha_asignacion = Column(Date, server_default=func.current_date())
    tipo_gestion = Column(String(50), nullable=False)
    prioridad = Column(String(20), nullable=False)
    score_prioridad = Column(Integer, default=0)
    estado_visita = Column(String(30), default="PENDIENTE")
    resultado_visita = Column(String(50))
    observacion_visita = Column(String)
    lat_visita = Column(Numeric(10, 7))
    lng_visita = Column(Numeric(10, 7))
    timestamp_visita = Column(DateTime(timezone=True))
    pendiente_sync = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
