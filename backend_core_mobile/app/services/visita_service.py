from sqlalchemy.orm import Session
from app.repositories.visita_repository import VisitaRepository
from app.repositories.cartera_repository import CarteraRepository
from app.models.visita_model import VisitaCliente
from app.schemas.visita_schema import VisitaCreate
from app.core.exceptions import ResourceNotFoundException
from datetime import datetime, timezone
import uuid

class VisitaService:
    @staticmethod
    def registrar_visita(db: Session, request: VisitaCreate) -> VisitaCliente:
        cartera = CarteraRepository.get_by_id(db, request.id_cartera)
        if not cartera:
            raise ResourceNotFoundException(detail="Item de cartera no encontrado")

        # 1. Crear registro de visita
        visita = VisitaCliente(
            id_visita=uuid.uuid4(),
            id_cartera=cartera.id_cartera,
            id_asesor=cartera.id_asesor,
            id_cliente=cartera.id_cliente,
            resultado=request.resultado,
            observacion=request.observacion,
            lat=request.lat,
            lng=request.lng,
            fecha_hora=datetime.utcnow()
        )
        VisitaRepository.create(db, visita)

        # 2. Actualizar cartera diaria
        cartera.estado_visita = "REALIZADA"
        cartera.resultado_visita = request.resultado
        cartera.observacion_visita = request.observacion
        cartera.lat_visita = request.lat
        cartera.lng_visita = request.lng
        cartera.timestamp_visita = datetime.utcnow()
        
        db.add(cartera)
        db.commit()
        db.refresh(visita)

        return visita
