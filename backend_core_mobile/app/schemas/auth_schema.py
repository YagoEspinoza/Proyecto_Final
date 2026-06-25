from pydantic import BaseModel
from typing import Optional

class LoginRequest(BaseModel):
    documento: Optional[str] = None
    codigo_empleado: Optional[str] = None
    password: str

class UserResponse(BaseModel):
    id_usuario: str
    rol: str
    nombre: str
    documento: str
    codigo_empleado: Optional[str] = None

class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UserResponse
