from sqlalchemy import Column, String, ForeignKey, DateTime, Date, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class CuentaAhorro(Base):
    __tablename__ = "cuentas_ahorro"
    id_cuenta = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    numero_cuenta = Column(String(30), unique=True, nullable=False)
    cci = Column(String(30), unique=True, nullable=False)
    moneda = Column(String(3), default="PEN")
    saldo_disponible = Column(Numeric(12, 2), default=0.00)
    saldo_contable = Column(Numeric(12, 2), default=0.00)
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class Tarjeta(Base):
    __tablename__ = "tarjetas"
    id_tarjeta = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    numero_enmascarado = Column(String(30), nullable=False)
    tipo_tarjeta = Column(String(30), nullable=False)
    marca = Column(String(30))
    estado = Column(String(20), default="ACTIVO")
    fecha_vencimiento = Column(Date, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
