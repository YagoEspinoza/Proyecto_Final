from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import get_current_user
from app.models.usuario_model import Usuario
from app.schemas.auth_schema import LoginRequest, LoginResponse, UserResponse
from app.services.auth_service import AuthService
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.asesor_repository import AsesorRepository

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    return AuthService.login(db, request)

@router.post("/logout")
def logout(current_user: Usuario = Depends(get_current_user)):
    return {"message": "Sesión cerrada correctamente"}

@router.get("/me", response_model=UserResponse)
def get_me(current_user: Usuario = Depends(get_current_user), db: Session = Depends(get_db)):
    nombre_completo = current_user.rol
    if current_user.rol == "CLIENTE":
        cliente = ClienteRepository.get_by_usuario_id(db, current_user.id_usuario)
        if cliente:
            nombre_completo = f"{cliente.nombres} {cliente.apellidos}"
    elif current_user.rol in ["ASESOR", "SUPERVISOR", "ADMIN"]:
        asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
        if asesor:
            nombre_completo = f"{asesor.nombres} {asesor.apellidos}"
            
    return UserResponse(
        id_usuario=str(current_user.id_usuario),
        rol=current_user.rol,
        nombre=nombre_completo,
        documento=current_user.documento,
        codigo_empleado=current_user.codigo_empleado
    )
