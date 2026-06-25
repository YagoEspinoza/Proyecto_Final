from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from typing import List
from app.core.exceptions import CredentialsException, RoleNotAuthorizedException
from app.core.security import decode_access_token
from app.database.session import get_db
from app.models.usuario_model import Usuario

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login", auto_error=False)

def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> Usuario:
    if not token:
        raise CredentialsException(detail="Not authenticated")
    payload = decode_access_token(token)
    if not payload:
        raise CredentialsException()
    
    documento: str = payload.get("sub")
    if documento is None:
        raise CredentialsException()
    
    user = db.query(Usuario).filter(Usuario.documento == documento).first()
    if user is None:
        raise CredentialsException()
        
    if user.estado != "ACTIVO":
        raise CredentialsException(detail="User account is locked or inactive")
        
    return user

class RoleChecker:
    def __init__(self, allowed_roles: List[str]):
        self.allowed_roles = allowed_roles

    def __call__(self, current_user: Usuario = Depends(get_current_user)) -> Usuario:
        if current_user.rol not in self.allowed_roles:
            raise RoleNotAuthorizedException(
                detail=f"Role '{current_user.rol}' not authorized. Allowed: {self.allowed_roles}"
            )
        return current_user

def require_roles(roles: List[str]):
    return Depends(RoleChecker(roles))
