from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Date, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class Cliente(Base):
    __tablename__ = "clientes"
    id_cliente = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_usuario = Column(UUID(as_uuid=True), ForeignKey("usuarios.id_usuario", ondelete="CASCADE"), nullable=False)
    id_agencia = Column(UUID(as_uuid=True), ForeignKey("agencias.id_agencia", ondelete="SET NULL"), nullable=True)
    documento = Column(String(15), unique=True, nullable=False)
    nombres = Column(String(100), nullable=False)
    apellidos = Column(String(100), nullable=False)
    telefono = Column(String(20))
    correo = Column(String(120))
    direccion = Column(String)
    distrito = Column(String(100))
    provincia = Column(String(100))
    departamento = Column(String(100))
    fecha_nacimiento = Column(Date)
    estado_civil = Column(String(30))
    ocupacion = Column(String(100))
    tipo_cliente = Column(String(30))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class NegocioCliente(Base):
    __tablename__ = "negocios_cliente"
    id_negocio = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    nombre_comercial = Column(String(150))
    giro_negocio = Column(String(100))
    antiguedad_meses = Column(Integer)
    ingreso_mensual = Column(Numeric(12, 2), nullable=False)
    gasto_mensual = Column(Numeric(12, 2), nullable=False)
    direccion_negocio = Column(String)
    lat_negocio = Column(Numeric(10, 7))
    lng_negocio = Column(Numeric(10, 7))
    estado = Column(String(20), default="ACTIVO")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
