from pydantic import BaseModel
from typing import Optional
from datetime import date
from decimal import Decimal
from uuid import UUID

class CuentaAhorroSchema(BaseModel):
    id_cuenta: UUID
    numero_cuenta: str
    cci: str
    moneda: str
    saldo_disponible: Decimal
    saldo_contable: Decimal
    estado: str

    class Config:
        from_attributes = True

class TarjetaSchema(BaseModel):
    id_tarjeta: UUID
    numero_enmascarado: str
    tipo_tarjeta: str
    marca: Optional[str]
    estado: str
    fecha_vencimiento: date

    class Config:
        from_attributes = True
