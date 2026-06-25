from sqlalchemy import Column, String, ForeignKey, DateTime, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class Movimiento(Base):
    __tablename__ = "cr_movimientos"
    id_movimiento = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    id_cuenta = Column(UUID(as_uuid=True), ForeignKey("cuentas_ahorro.id_cuenta", ondelete="SET NULL"), nullable=True)
    id_credito = Column(UUID(as_uuid=True), ForeignKey("cr_creditos.id_credito", ondelete="SET NULL"), nullable=True)
    tipo_movimiento = Column(String(50), nullable=False)
    descripcion = Column(String)
    monto = Column(Numeric(12, 2), nullable=False)
    moneda = Column(String(3), default="PEN")
    fecha_movimiento = Column(DateTime(timezone=True), server_default=func.now())
    canal = Column(String(30), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class OperacionCliente(Base):
    __tablename__ = "operaciones_cliente"
    id_operacion = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    tipo_operacion = Column(String(50), nullable=False)
    cuenta_origen = Column(UUID(as_uuid=True), ForeignKey("cuentas_ahorro.id_cuenta", ondelete="SET NULL"), nullable=True)
    cuenta_destino = Column(String(30))
    id_credito = Column(UUID(as_uuid=True), ForeignKey("cr_creditos.id_credito", ondelete="SET NULL"), nullable=True)
    monto = Column(Numeric(12, 2), nullable=False)
    moneda = Column(String(3), default="PEN")
    descripcion = Column(String)
    estado = Column(String(30), default="PENDIENTE")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
