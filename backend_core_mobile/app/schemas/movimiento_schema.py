from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from decimal import Decimal
from uuid import UUID

class MovimientoSchema(BaseModel):
    id_movimiento: UUID
    id_cliente: UUID
    id_cuenta: Optional[UUID] = None
    id_credito: Optional[UUID] = None
    tipo_movimiento: str
    descripcion: Optional[str] = None
    monto: Decimal
    moneda: str
    fecha_movimiento: datetime
    canal: str

    class Config:
        from_attributes = True

class TransferenciaRequest(BaseModel):
    cuenta_origen_id: str
    cuenta_destino_numero: str
    monto: Decimal
    descripcion: Optional[str] = None

class PagoCreditoRequest(BaseModel):
    cuenta_origen_id: str
    id_credito: str
    id_cuota: str
    monto: Decimal

class OperacionResponse(BaseModel):
    id_operacion: str
    tipo_operacion: str
    monto: Decimal
    moneda: str
    estado: str
    created_at: datetime
