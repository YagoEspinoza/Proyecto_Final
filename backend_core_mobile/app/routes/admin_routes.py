from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import require_roles
from app.models.usuario_model import Usuario
from app.models.cliente_model import Cliente
from app.models.asesor_model import Asesor
from app.models.credito_model import ProductoCredito
from app.core.security import get_password_hash
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from typing import List, Optional
from decimal import Decimal
from pydantic import BaseModel
import uuid

router = APIRouter(prefix="/admin", tags=["Administración (Admin)"])

class UserCreateRequest(BaseModel):
    documento: str
    codigo_empleado: Optional[str] = None
    correo: Optional[str] = None
    password: str
    rol: str
    estado: Optional[str] = "ACTIVO"

class UserUpdateRequest(BaseModel):
    codigo_empleado: Optional[str] = None
    correo: Optional[str] = None
    password: Optional[str] = None
    rol: Optional[str] = None
    estado: Optional[str] = None

class UserAdminResponse(BaseModel):
    id_usuario: str
    documento: str
    codigo_empleado: Optional[str] = None
    correo: Optional[str] = None
    rol: str
    estado: str

class ProductoCreditoCreateRequest(BaseModel):
    codigo: str
    nombre: str
    tipo: Optional[str] = "Consumo"
    tea_con_seguro: Decimal
    tea_sin_seguro: Decimal
    monto_minimo: Decimal
    monto_maximo: Decimal
    plazo_minimo: int
    plazo_maximo: int
    moneda: Optional[str] = "PEN"
    estado: Optional[str] = "ACTIVO"

class ProductoCreditoUpdateRequest(BaseModel):
    nombre: Optional[str] = None
    tipo: Optional[str] = None
    tea_con_seguro: Optional[Decimal] = None
    tea_sin_seguro: Optional[Decimal] = None
    monto_minimo: Optional[Decimal] = None
    monto_maximo: Optional[Decimal] = None
    plazo_minimo: Optional[int] = None
    plazo_maximo: Optional[int] = None
    moneda: Optional[str] = None
    estado: Optional[str] = None

@router.get("/usuarios", response_model=List[UserAdminResponse])
def get_usuarios(
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    users = db.query(Usuario).all()
    return [UserAdminResponse(
        id_usuario=str(u.id_usuario),
        documento=u.documento,
        codigo_empleado=u.codigo_empleado,
        correo=u.correo,
        rol=u.rol,
        estado=u.estado
    ) for u in users]

@router.post("/usuarios", response_model=UserAdminResponse, status_code=status.HTTP_201_CREATED)
def create_usuario(
    request: UserCreateRequest,
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    existing = db.query(Usuario).filter(Usuario.documento == request.documento).first()
    if existing:
        raise BusinessRuleException(detail="Ya existe un usuario con el documento ingresado")

    user = Usuario(
        id_usuario=uuid.uuid4(),
        documento=request.documento,
        codigo_empleado=request.codigo_empleado,
        correo=request.correo,
        password_hash=get_password_hash(request.password),
        rol=request.rol.upper(),
        estado=request.estado or "ACTIVO",
        intentos_fallidos=0
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return UserAdminResponse(
        id_usuario=str(user.id_usuario),
        documento=user.documento,
        codigo_empleado=user.codigo_empleado,
        correo=user.correo,
        rol=user.rol,
        estado=user.estado
    )

@router.put("/usuarios/{id_usuario}", response_model=UserAdminResponse)
def update_usuario(
    id_usuario: str,
    request: UserUpdateRequest,
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    user = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not user:
        raise ResourceNotFoundException(detail="Usuario no encontrado")

    if request.codigo_empleado is not None:
        user.codigo_empleado = request.codigo_empleado
    if request.correo is not None:
        user.correo = request.correo
    if request.rol is not None:
        user.rol = request.rol.upper()
    if request.estado is not None:
        user.estado = request.estado
    if request.password is not None:
        user.password_hash = get_password_hash(request.password)

    db.add(user)
    db.commit()
    db.refresh(user)

    return UserAdminResponse(
        id_usuario=str(user.id_usuario),
        documento=user.documento,
        codigo_empleado=user.codigo_empleado,
        correo=user.correo,
        rol=user.rol,
        estado=user.estado
    )

@router.delete("/usuarios/{id_usuario}")
def delete_usuario(
    id_usuario: str,
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    user = db.query(Usuario).filter(Usuario.id_usuario == id_usuario).first()
    if not user:
        raise ResourceNotFoundException(detail="Usuario no encontrado")
        
    db.delete(user)
    db.commit()
    return {"message": "Usuario eliminado correctamente"}

@router.get("/clientes")
def get_clientes(
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    clientes = db.query(Cliente).all()
    return [{
        "id_cliente": str(c.id_cliente),
        "id_usuario": str(c.id_usuario),
        "id_agencia": str(c.id_agencia) if c.id_agencia else None,
        "documento": c.documento,
        "nombres": c.nombres,
        "apellidos": c.apellidos,
        "correo": c.correo,
        "telefono": c.telefono,
        "estado": c.estado
    } for c in clientes]

@router.get("/asesores")
def get_asesores(
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    asesores = db.query(Asesor).all()
    return [{
        "id_asesor": str(a.id_asesor),
        "id_usuario": str(a.id_usuario),
        "id_agencia": str(a.id_agencia) if a.id_agencia else None,
        "codigo_empleado": a.codigo_empleado,
        "nombres": a.nombres,
        "apellidos": a.apellidos,
        "cargo": a.cargo,
        "estado": a.estado
    } for a in asesores]

@router.get("/productos-creditos")
def get_productos(
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    productos = db.query(ProductoCredito).all()
    return [{
        "id_producto_credito": str(p.id_producto_credito),
        "codigo": p.codigo,
        "nombre": p.nombre,
        "tipo": p.tipo,
        "tea_con_seguro": float(p.tea_con_seguro),
        "tea_sin_seguro": float(p.tea_sin_seguro),
        "monto_minimo": float(p.monto_minimo),
        "monto_maximo": float(p.monto_maximo),
        "plazo_minimo": p.plazo_minimo,
        "plazo_maximo": p.plazo_maximo,
        "moneda": p.moneda,
        "estado": p.estado
    } for p in productos]

@router.post("/productos-creditos", status_code=status.HTTP_201_CREATED)
def create_producto(
    request: ProductoCreditoCreateRequest,
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    producto = ProductoCredito(
        id_producto_credito=uuid.uuid4(),
        codigo=request.codigo,
        nombre=request.nombre,
        tipo=request.tipo,
        tea_con_seguro=request.tea_con_seguro,
        tea_sin_seguro=request.tea_sin_seguro,
        monto_minimo=request.monto_minimo,
        monto_maximo=request.monto_maximo,
        plazo_minimo=request.plazo_minimo,
        plazo_maximo=request.plazo_maximo,
        moneda=request.moneda or "PEN",
        estado=request.estado or "ACTIVO"
    )
    db.add(producto)
    db.commit()
    db.refresh(producto)
    return {
        "id_producto_credito": str(producto.id_producto_credito),
        "codigo": producto.codigo,
        "nombre": producto.nombre
    }

@router.put("/productos-creditos/{id_producto}")
def update_producto(
    id_producto: str,
    request: ProductoCreditoUpdateRequest,
    current_user: Usuario = require_roles(["ADMIN"]),
    db: Session = Depends(get_db)
):
    producto = db.query(ProductoCredito).filter(ProductoCredito.id_producto_credito == id_producto).first()
    if not producto:
        raise ResourceNotFoundException(detail="Producto de credito no encontrado")

    if request.nombre is not None:
        producto.nombre = request.nombre
    if request.tipo is not None:
        producto.tipo = request.tipo
    if request.tea_con_seguro is not None:
        producto.tea_con_seguro = request.tea_con_seguro
    if request.tea_sin_seguro is not None:
        producto.tea_sin_seguro = request.tea_sin_seguro
    if request.monto_minimo is not None:
        producto.monto_minimo = request.monto_minimo
    if request.monto_maximo is not None:
        producto.monto_maximo = request.monto_maximo
    if request.plazo_minimo is not None:
        producto.plazo_minimo = request.plazo_minimo
    if request.plazo_maximo is not None:
        producto.plazo_maximo = request.plazo_maximo
    if request.moneda is not None:
        producto.moneda = request.moneda
    if request.estado is not None:
        producto.estado = request.estado

    db.add(producto)
    db.commit()
    db.refresh(producto)
    return {"message": "Producto de credito actualizado correctamente"}

@router.get("/cartera")
def get_all_cartera(
    current_user: Usuario = require_roles(["SUPERVISOR", "ADMIN"]),
    db: Session = Depends(get_db)
):
    from app.models.cartera_model import CarteraDiaria
    from app.models.cliente_model import Cliente
    from app.models.asesor_model import Asesor

    items = db.query(
        CarteraDiaria,
        Cliente.nombres.label("cliente_nombres"),
        Cliente.apellidos.label("cliente_apellidos"),
        Asesor.nombres.label("asesor_nombres"),
        Asesor.apellidos.label("asesor_apellidos")
    ).join(Cliente, CarteraDiaria.id_cliente == Cliente.id_cliente)\
     .join(Asesor, CarteraDiaria.id_asesor == Asesor.id_asesor).all()

    return [{
        "id_cartera": str(x[0].id_cartera),
        "id_asesor": str(x[0].id_asesor),
        "asesor_nombre": f"{x.asesor_nombres} {x.asesor_apellidos}",
        "id_cliente": str(x[0].id_cliente),
        "cliente_nombre": f"{x.cliente_nombres} {x.cliente_apellidos}",
        "tipo_gestion": x[0].tipo_gestion,
        "prioridad": x[0].prioridad,
        "estado_visita": x[0].estado_visita,
        "resultado_visita": x[0].resultado_visita or "Pendiente de visita",
        "fecha_asignacion": str(x[0].fecha_asignacion)
    } for x in items]
