from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class ProductoCredito(Base):
    __tablename__ = "productos_credito"
    id_producto_credito = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    codigo = Column(String(30), unique=True, nullable=False)
    nombre = Column(String(120), nullable=False)
    tipo = Column(String(50))
    tea_con_seguro = Column(Numeric(5, 2), nullable=False)
    tea_sin_seguro = Column(Numeric(5, 2), nullable=False)
    monto_minimo = Column(Numeric(12, 2), nullable=False)
    monto_maximo = Column(Numeric(12, 2), nullable=False)
    plazo_minimo = Column(Integer, nullable=False)
    plazo_maximo = Column(Integer, nullable=False)
    moneda = Column(String(3), default="PEN")
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Credito(Base):
    __tablename__ = "cr_creditos"
    id_credito = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    numero_credito = Column(String(30), unique=True, nullable=False)
    producto = Column(String(120), nullable=False)
    monto_desembolsado = Column(Numeric(12, 2), nullable=False)
    saldo_capital = Column(Numeric(12, 2), nullable=False)
    plazo_meses = Column(Integer, nullable=False)
    tea = Column(Numeric(5, 2), nullable=False)
    tem = Column(Numeric(8, 6), nullable=False)
    cuota_mensual = Column(Numeric(12, 2), nullable=False)
    fecha_desembolso = Column(Date, nullable=False)
    dia_pago = Column(Integer, nullable=False)
    estado = Column(String(30), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
