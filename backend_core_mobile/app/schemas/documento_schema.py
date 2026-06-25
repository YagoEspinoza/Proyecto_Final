from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class SolicitudDocumentoSchema(BaseModel):
    id_documento: str
    id_solicitud: str
    tipo_documento: str
    nombre_archivo: str
    storage_path: str
    url_publica: Optional[str] = None
    estado_validacion: str
    created_at: datetime

    class Config:
        from_attributes = True
