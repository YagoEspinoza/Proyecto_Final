from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

class CarteraDiariaSchema(BaseModel):
    id_cartera: UUID
    id_asesor: UUID
    id_cliente: UUID
    id_solicitud: Optional[UUID] = None
    fecha_asignacion: date
    tipo_gestion: str
    prioridad: str
    score_prioridad: int
    estado_visita: str
    resultado_visita: Optional[str] = None
    observacion_visita: Optional[str] = None
    lat_visita: Optional[Decimal] = None
    lng_visita: Optional[Decimal] = None
    timestamp_visita: Optional[datetime] = None
    pendiente_sync: bool

    class Config:
        from_attributes = True
