from pydantic import BaseModel
from typing import Optional, Any, Dict
from datetime import datetime

class SyncOutboxSchema(BaseModel):
    id_evento: str
    tipo_evento: str
    entidad: str
    entidad_id: str
    payload: Dict[str, Any]
    estado: str
    intentos: int
    error: Optional[str] = None
    created_at: datetime
    procesado_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class SyncLogSchema(BaseModel):
    id_log: str
    id_evento: Optional[str] = None
    accion: str
    resultado: str
    detalle: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
