from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from app.database.connection import Base

class SolicitudCredito(Base):
    __tablename__ = "solicitudes_credito"
    id_solicitud = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    numero_expediente = Column(String(30), unique=True, nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    id_negocio = Column(UUID(as_uuid=True), ForeignKey("negocios_cliente.id_negocio", ondelete="CASCADE"), nullable=False)
    id_asesor = Column(UUID(as_uuid=True), ForeignKey("asesores.id_asesor", ondelete="SET NULL"), nullable=True)
    id_producto_credito = Column(UUID(as_uuid=True), ForeignKey("productos_credito.id_producto_credito", ondelete="CASCADE"), nullable=False)
    canal_origen = Column(String(30), nullable=False)
    monto_solicitado = Column(Numeric(12, 2), nullable=False)
    monto_aprobado = Column(Numeric(12, 2), nullable=True)
    plazo_meses = Column(Integer, nullable=False)
    moneda = Column(String(3), default="PEN")
    tea_referencial = Column(Numeric(5, 2), nullable=False)
    con_seguro_desgravamen = Column(Boolean, default=True)
    garantia = Column(String(50))
    destino_credito = Column(String)
    cuota_estimada = Column(Numeric(12, 2), nullable=False)
    estado = Column(String(30), default="BORRADOR")
    resultado_preevaluacion = Column(String(30))
    puntaje_preevaluacion = Column(Integer)
    resultado_buro = Column(String(30))
    motivo_rechazo = Column(String)
    condicion_adicional = Column(String)
    firma_cliente_base64 = Column(String)
    lat_captura = Column(Numeric(10, 7))
    lng_captura = Column(Numeric(10, 7))
    pendiente_sync = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class ConsultaBuro(Base):
    __tablename__ = "consultas_buro"
    id_consulta = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    id_solicitud = Column(UUID(as_uuid=True), ForeignKey("solicitudes_credito.id_solicitud", ondelete="CASCADE"), nullable=False)
    id_cliente = Column(UUID(as_uuid=True), ForeignKey("clientes.id_cliente", ondelete="CASCADE"), nullable=False)
    documento = Column(String(15), nullable=False)
    calificacion = Column(String(30), nullable=False)
    entidades_deuda = Column(Integer, default=0)
    deuda_total = Column(Numeric(12, 2), default=0.00)
    mayor_mora_dias = Column(Integer, default=0)
    esta_inhabilitado = Column(Boolean, default=False)
    resultado = Column(String(30), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
