from pydantic import BaseModel
from typing import Optional
from datetime import date
from decimal import Decimal
from uuid import UUID

class CronogramaPagoSchema(BaseModel):
    id_cuota: UUID
    id_credito: UUID
    numero_cuota: int
    fecha_pago: date
    monto_cuota: Decimal
    capital: Decimal
    interes: Decimal
    saldo: Decimal
    estado: str
    fecha_pago_real: Optional[date] = None
    monto_pagado: Decimal

    class Config:
        from_attributes = True
