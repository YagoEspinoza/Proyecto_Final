from sqlalchemy.orm import Session
from app.repositories.documento_repository import DocumentoRepository
from app.repositories.solicitud_repository import SolicitudRepository
from app.models.documento_model import SolicitudDocumento
from app.core.exceptions import ResourceNotFoundException
from typing import List
import uuid

class DocumentoService:
    @staticmethod
    def get_documentos_solicitud(db: Session, id_solicitud: str) -> List[SolicitudDocumento]:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")
        return DocumentoRepository.get_documentos_by_solicitud_id(db, id_solicitud)

    @staticmethod
    def crear_documento(
        db: Session, 
        id_solicitud: str, 
        tipo_documento: str, 
        nombre_archivo: str, 
        storage_path: str, 
        url_publica: str = None
    ) -> SolicitudDocumento:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        documento = SolicitudDocumento(
            id_documento=uuid.uuid4(),
            id_solicitud=solicitud.id_solicitud,
            tipo_documento=tipo_documento,
            nombre_archivo=nombre_archivo,
            storage_path=storage_path,
            url_publica=url_publica,
            estado_validacion="PENDIENTE"
        )
        return DocumentoRepository.create(db, documento)
