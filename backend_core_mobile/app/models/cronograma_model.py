from sqlalchemy import Column, Integer, DateTime, ForeignKey, Date, Numeric, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class CronogramaPago(Base):
    __tablename__ = "cr_cronograma_pagos"
    id_cuota = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_credito = Column(UUID(as_uuid=True), ForeignKey("cr_creditos.id_credito", ondelete="CASCADE"), nullable=False)
    numero_cuota = Column(Integer, nullable=False)
    fecha_pago = Column(Date, nullable=False)
    monto_cuota = Column(Numeric(12, 2), nullable=False)
    capital = Column(Numeric(12, 2), nullable=False)
    interes = Column(Numeric(12, 2), nullable=False)
    saldo = Column(Numeric(12, 2), nullable=False)
    estado = Column(String(30), default="PENDIENTE")
    fecha_pago_real = Column(Date, nullable=True)
    monto_pagado = Column(Numeric(12, 2), default=0.00)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
