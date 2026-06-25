from fastapi import FastAPI, Depends, status, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.exceptions import CredentialsException, RoleNotAuthorizedException, BusinessRuleException, ResourceNotFoundException
from app.database.session import get_db
from app.routes import auth_routes, cliente_routes, asesor_routes, comite_routes, sync_routes, admin_routes
import time

app = FastAPI(
    title=settings.APP_NAME,
    debug=settings.APP_DEBUG,
    version="1.0.0"
)

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Montar carpeta de subidas estáticas
app.mount("/static", StaticFiles(directory="uploads"), name="static")

# Manejadores de excepciones globales personalizados
@app.exception_handler(CredentialsException)
def credentials_exception_handler(request: Request, exc: CredentialsException):
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": exc.detail},
        headers={"WWW-Authenticate": "Bearer"},
    )

@app.exception_handler(RoleNotAuthorizedException)
def role_not_authorized_handler(request: Request, exc: RoleNotAuthorizedException):
    return JSONResponse(
        status_code=status.HTTP_403_FORBIDDEN,
        content={"detail": exc.detail},
    )

@app.exception_handler(BusinessRuleException)
def business_rule_handler(request: Request, exc: BusinessRuleException):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": exc.detail},
    )

@app.exception_handler(ResourceNotFoundException)
def resource_not_found_handler(request: Request, exc: ResourceNotFoundException):
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": exc.detail},
    )

# Incluir Rutas de API
app.include_router(auth_routes.router)
app.include_router(cliente_routes.router)
app.include_router(asesor_routes.router)
app.include_router(comite_routes.router)
app.include_router(sync_routes.router)
app.include_router(admin_routes.router)

@app.get("/health", tags=["Health"])
def health_check(db: Session = Depends(get_db)):
    try:
        # Verificar conexión con la base de datos
        db.execute("SELECT 1")
        db_status = "ONLINE"
    except Exception as e:
        db_status = f"OFFLINE: {str(e)}"
        
    return {
        "status": "OK",
        "timestamp": time.time(),
        "database": db_status,
        "app_env": settings.APP_ENV
    }

@app.get("/", tags=["Root"])
def root():
    return {
        "message": f"Welcome to {settings.APP_NAME} Core API",
        "docs_url": "/docs",
        "health_url": "/health"
    }
