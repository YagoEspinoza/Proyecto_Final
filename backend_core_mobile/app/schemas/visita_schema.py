from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from decimal import Decimal
from uuid import UUID

class VisitaCreate(BaseModel):
    id_cartera: str
    resultado: str
    observacion: Optional[str] = ""
    lat: Decimal
    lng: Decimal

class VisitaClienteSchema(BaseModel):
    id_visita: UUID
    id_cartera: UUID
    id_asesor: UUID
    id_cliente: UUID
    resultado: str
    observacion: Optional[str] = None
    lat: Decimal
    lng: Decimal
    fecha_hora: datetime

    class Config:
        from_attributes = True
