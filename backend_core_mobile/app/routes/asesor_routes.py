from fastapi import APIRouter, Depends, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.core.dependencies import require_roles
from app.models.usuario_model import Usuario
from app.repositories.asesor_repository import AsesorRepository
from app.repositories.solicitud_repository import SolicitudRepository
from app.schemas.cartera_schema import CarteraDiariaSchema
from app.schemas.cliente_schema import ClienteFichaResponse
from app.schemas.visita_schema import VisitaCreate, VisitaClienteSchema
from app.schemas.solicitud_schema import SolicitudCreate, SolicitudUpdate, SolicitudCreditoSchema, PreevaluacionResponse, BuroResponse, SolicitudFirmaRequest
from app.schemas.documento_schema import SolicitudDocumentoSchema
from app.services.cartera_service import CarteraService
from app.services.cliente_service import ClienteService
from app.services.visita_service import VisitaService
from app.services.solicitud_service import SolicitudService
from app.services.preevaluacion_service import PreevaluacionService
from app.services.buro_service import BuroService
from app.services.documento_service import DocumentoService
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from typing import List, Optional
import os
import uuid

router = APIRouter(prefix="/fventas", tags=["Fuerza de Ventas (Asesor)"])

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.get("/cartera/hoy", response_model=List[CarteraDiariaSchema])
def get_cartera_hoy(
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    return CarteraService.get_cartera_hoy(db, current_user.id_usuario)

@router.get("/cartera/{id_cartera}", response_model=CarteraDiariaSchema)
def get_cartera_item(
    id_cartera: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not asesor:
        raise ResourceNotFoundException(detail="Asesor no encontrado")
    item = CarteraService.get_cartera_item(db, id_cartera)
    if item.id_asesor != asesor.id_asesor:
        raise ResourceNotFoundException(detail="Item de cartera no encontrado")
    return item

@router.get("/clientes/{id_cliente}/ficha", response_model=ClienteFichaResponse)
def get_ficha_cliente(
    id_cliente: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    return ClienteService.get_ficha_cliente(db, id_cliente)

@router.post("/visitas", response_model=VisitaClienteSchema, status_code=status.HTTP_201_CREATED)
def registrar_visita(
    request: VisitaCreate,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not asesor:
        raise ResourceNotFoundException(detail="Asesor no encontrado")
    cartera = CarteraService.get_cartera_item(db, request.id_cartera)
    if cartera.id_asesor != asesor.id_asesor:
        raise BusinessRuleException(detail="No está autorizado para registrar visita en este item de cartera")
    return VisitaService.registrar_visita(db, request)

@router.post("/solicitudes", response_model=SolicitudCreditoSchema, status_code=status.HTTP_201_CREATED)
def crear_solicitud(
    request: SolicitudCreate,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    return SolicitudService.crear_solicitud(db, current_user.id_usuario, request, canal_origen="ASESOR")

@router.put("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoSchema)
def actualizar_solicitud(
    id_solicitud: str,
    request: SolicitudUpdate,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
    
    asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not asesor or solicitud.id_asesor != asesor.id_asesor:
        raise BusinessRuleException(detail="No está autorizado para modificar esta solicitud")

    update_data = request.model_dump(exclude_unset=True)
    return SolicitudRepository.update(db, solicitud, update_data)

@router.post("/solicitudes/{id_solicitud}/preevaluar", response_model=PreevaluacionResponse)
def preevaluar(
    id_solicitud: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    return PreevaluacionService.preevaluar_solicitud(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/buro", response_model=BuroResponse)
def consultar_buro(
    id_solicitud: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    return BuroService.consultar_buro(db, id_solicitud)

@router.post("/solicitudes/{id_solicitud}/documentos", response_model=SolicitudDocumentoSchema, status_code=status.HTTP_201_CREATED)
def subir_documento(
    id_solicitud: str,
    tipo_documento: str = Form(...),
    file: UploadFile = File(...),
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    file_ext = os.path.splitext(file.filename)[1]
    filename = f"{id_solicitud}_{tipo_documento}_{uuid.uuid4().hex}{file_ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    
    with open(filepath, "wb") as buffer:
        buffer.write(file.file.read())
        
    url_publica = f"/static/{filename}"
    return DocumentoService.crear_documento(
        db, 
        id_solicitud=id_solicitud, 
        tipo_documento=tipo_documento, 
        nombre_archivo=file.filename, 
        storage_path=filepath, 
        url_publica=url_publica
    )

@router.post("/solicitudes/{id_solicitud}/firma", response_model=SolicitudCreditoSchema)
def guardar_firma(
    id_solicitud: str,
    request: SolicitudFirmaRequest,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
        
    solicitud.firma_cliente_base64 = request.firma_base64
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)
    return solicitud

@router.post("/solicitudes/{id_solicitud}/enviar-comite", response_model=SolicitudCreditoSchema)
def enviar_comite(
    id_solicitud: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
        
    if not solicitud.firma_cliente_base64:
        raise BusinessRuleException(detail="Debe registrar la firma del cliente antes de enviar al comite")

    solicitud.estado = "ENVIADO"
    db.add(solicitud)
    db.commit()
    db.refresh(solicitud)
    return solicitud

@router.get("/solicitudes", response_model=List[SolicitudCreditoSchema])
def get_solicitudes(
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not asesor:
        raise ResourceNotFoundException(detail="Asesor no encontrado")
    return SolicitudRepository.get_solicitudes_by_asesor_id(db, asesor.id_asesor)

@router.get("/solicitudes/{id_solicitud}", response_model=SolicitudCreditoSchema)
def get_solicitud(
    id_solicitud: str,
    current_user: Usuario = require_roles(["ASESOR"]),
    db: Session = Depends(get_db)
):
    solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
    if not solicitud:
        raise ResourceNotFoundException(detail="Solicitud no encontrada")
        
    asesor = AsesorRepository.get_by_usuario_id(db, current_user.id_usuario)
    if not asesor or solicitud.id_asesor != asesor.id_asesor:
        raise BusinessRuleException(detail="No está autorizado para ver esta solicitud")
        
    return solicitud
