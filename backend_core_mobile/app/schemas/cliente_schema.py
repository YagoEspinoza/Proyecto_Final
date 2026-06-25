from pydantic import BaseModel
from typing import Optional, List
from datetime import date
from decimal import Decimal
from uuid import UUID

class NegocioSchema(BaseModel):
    id_negocio: UUID
    nombre_comercial: Optional[str]
    giro_negocio: Optional[str]
    antiguedad_meses: Optional[int]
    ingreso_mensual: Decimal
    gasto_mensual: Decimal
    direccion_negocio: Optional[str]
    lat_negocio: Optional[Decimal]
    lng_negocio: Optional[Decimal]

    class Config:
        from_attributes = True

class ClienteSchema(BaseModel):
    id_cliente: UUID
    documento: str
    nombres: str
    apellidos: str
    telefono: Optional[str]
    correo: Optional[str]
    direccion: Optional[str]
    distrito: Optional[str]
    provincia: Optional[str]
    departamento: Optional[str]
    fecha_nacimiento: Optional[date]
    estado_civil: Optional[str]
    ocupacion: Optional[str]
    tipo_cliente: Optional[str]
    estado: str

    class Config:
        from_attributes = True

class ClienteFichaResponse(BaseModel):
    cliente: ClienteSchema
    negocios: List[NegocioSchema]
