from pydantic import BaseModel
from typing import Optional

class AsesorSchema(BaseModel):
    id_asesor: str
    codigo_empleado: str
    nombres: str
    apellidos: str
    telefono: Optional[str]
    cargo: Optional[str]
    estado: str

    class Config:
        from_attributes = True
