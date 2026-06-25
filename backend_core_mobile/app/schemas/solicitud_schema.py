from pydantic import BaseModel
from typing import Optional, List, Any
from datetime import datetime
from decimal import Decimal
from uuid import UUID

class SolicitudCreate(BaseModel):
    id_producto_credito: str
    monto_solicitado: Decimal
    plazo_meses: int
    con_seguro_desgravamen: bool = True
    garantia: Optional[str] = "Sola firma"
    destino_credito: Optional[str] = ""
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None
    documento_cliente: Optional[str] = None

class SolicitudUpdate(BaseModel):
    monto_solicitado: Optional[Decimal] = None
    monto_aprobado: Optional[Decimal] = None
    plazo_meses: Optional[int] = None
    con_seguro_desgravamen: Optional[bool] = None
    garantia: Optional[str] = None
    destino_credito: Optional[str] = None
    estado: Optional[str] = None
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None

class PreevaluacionResponse(BaseModel):
    id_solicitud: UUID
    capacidad_pago: Decimal
    ratio_cuota: Decimal
    resultado_preevaluacion: str
    puntaje_preevaluacion: int

class BuroResponse(BaseModel):
    id_solicitud: UUID
    documento: str
    calificacion: str
    entidades_deuda: int
    deuda_total: Decimal
    mayor_mora_dias: int
    esta_inhabilitado: bool
    resultado: str

class SolicitudFirmaRequest(BaseModel):
    firma_base64: str

class SolicitudCreditoSchema(BaseModel):
    id_solicitud: UUID
    numero_expediente: str
    id_cliente: UUID
    id_negocio: UUID
    id_asesor: Optional[UUID] = None
    id_producto_credito: UUID
    canal_origen: str
    monto_solicitado: Decimal
    monto_aprobado: Optional[Decimal] = None
    plazo_meses: int
    moneda: str
    tea_referencial: Decimal
    con_seguro_desgravamen: bool
    garantia: Optional[str] = None
    destino_credito: Optional[str] = None
    cuota_estimada: Decimal
    estado: str
    resultado_preevaluacion: Optional[str] = None
    puntaje_preevaluacion: Optional[int] = None
    resultado_buro: Optional[str] = None
    motivo_rechazo: Optional[str] = None
    condicion_adicional: Optional[str] = None
    firma_cliente_base64: Optional[str] = None
    lat_captura: Optional[Decimal] = None
    lng_captura: Optional[Decimal] = None
    pendiente_sync: bool
    created_at: datetime
    updated_at: datetime
    cliente_nombre: Optional[str] = None

    class Config:
        from_attributes = True

class SolicitudDetalleResponse(BaseModel):
    solicitud: SolicitudCreditoSchema
    cliente: Optional[Any] = None 
    negocio: Optional[Any] = None 
    consultas_buro: List[Any] = []
    documentos: List[Any] = [] 
