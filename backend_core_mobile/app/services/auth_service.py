from datetime import datetime, timedelta, timezone
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from app.core.security import verify_password, create_access_token
from app.repositories.usuario_repository import UsuarioRepository
from app.repositories.cliente_repository import ClienteRepository
from app.repositories.asesor_repository import AsesorRepository
from app.schemas.auth_schema import LoginRequest, LoginResponse, UserResponse
from app.core.exceptions import CredentialsException, BusinessRuleException

class AuthService:
    @staticmethod
    def login(db: Session, request: LoginRequest) -> LoginResponse:
        # Identificar si es login de cliente (por DNI) o colaborador (por codigo_empleado)
        user = None
        if request.documento:
            user = UsuarioRepository.get_by_documento(db, request.documento)
        elif request.codigo_empleado:
            user = UsuarioRepository.get_by_codigo_empleado(db, request.codigo_empleado)
            
        if not user:
            raise CredentialsException(detail="Usuario no encontrado")
            
        # Validar si el usuario esta bloqueado
        now_utc = datetime.now(timezone.utc)
        if user.bloqueado_hasta:
            # Asegurar que bloqueado_hasta tiene zona horaria
            bloqueado_hasta = user.bloqueado_hasta
            if bloqueado_hasta.tzinfo is None:
                bloqueado_hasta = bloqueado_hasta.replace(tzinfo=timezone.utc)
            if now_utc < bloqueado_hasta:
                rem_min = int((bloqueado_hasta - now_utc).total_seconds() / 60)
                raise BusinessRuleException(
                    detail=f"Usuario bloqueado por multiples intentos fallidos. Intente en {rem_min + 1} minutos."
                )
            else:
                # Resetear bloqueo si ya paso el tiempo
                user.bloqueado_hasta = None
                user.intentos_fallidos = 0
                db.commit()

        # Verificar contraseña
        if not verify_password(request.password, user.password_hash):
            user.intentos_fallidos += 1
            if user.intentos_fallidos >= 5:
                user.bloqueado_hasta = now_utc + timedelta(minutes=30)
                db.commit()
                raise BusinessRuleException(
                    detail="Ha superado el numero maximo de intentos fallidos. Cuenta bloqueada por 30 minutos."
                )
            db.commit()
            raise CredentialsException(detail=f"Contraseña incorrecta. Intentos restantes: {5 - user.intentos_fallidos}")

        # Login exitoso: resetear intentos fallidos
        user.intentos_fallidos = 0
        user.bloqueado_hasta = None
        user.ultimo_login = now_utc
        db.commit()

        # Obtener nombre del usuario (de Cliente o Asesor)
        nombre_completo = user.rol
        if user.rol == "CLIENTE":
            cliente = ClienteRepository.get_by_usuario_id(db, user.id_usuario)
            if cliente:
                nombre_completo = f"{cliente.nombres} {cliente.apellidos}"
        elif user.rol in ["ASESOR", "SUPERVISOR", "ADMIN"]:
            asesor = AsesorRepository.get_by_usuario_id(db, user.id_usuario)
            if asesor:
                nombre_completo = f"{asesor.nombres} {asesor.apellidos}"

        # Crear JWT Token
        access_token = create_access_token(data={"sub": user.documento, "rol": user.rol})
        
        return LoginResponse(
            access_token=access_token,
            usuario=UserResponse(
                id_usuario=str(user.id_usuario),
                rol=user.rol,
                nombre=nombre_completo,
                documento=user.documento,
                codigo_empleado=user.codigo_empleado
            )
        )
