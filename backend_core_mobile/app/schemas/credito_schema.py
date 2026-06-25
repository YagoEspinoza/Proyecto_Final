from pydantic import BaseModel
from typing import Optional, List
from datetime import date
from decimal import Decimal
from app.schemas.cronograma_schema import CronogramaPagoSchema
from uuid import UUID

class ProductoCreditoSchema(BaseModel):
    id_producto_credito: UUID
    codigo: str
    nombre: str
    tipo: Optional[str]
    tea_con_seguro: Decimal
    tea_sin_seguro: Decimal
    monto_minimo: Decimal
    monto_maximo: Decimal
    plazo_minimo: int
    plazo_maximo: int
    moneda: str
    estado: str

    class Config:
        from_attributes = True

class CreditoSchema(BaseModel):
    id_credito: UUID
    id_solicitud: UUID
    id_cliente: UUID
    numero_credito: str
    producto: str
    monto_desembolsado: Decimal
    saldo_capital: Decimal
    plazo_meses: int
    tea: Decimal
    tem: Decimal
    cuota_mensual: Decimal
    fecha_desembolso: date
    dia_pago: int
    estado: str

    class Config:
        from_attributes = True

class CreditoDetalleResponse(BaseModel):
    credito: CreditoSchema
    cronograma: List[CronogramaPagoSchema]
