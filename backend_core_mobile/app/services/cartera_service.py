from sqlalchemy.orm import Session
from app.repositories.cartera_repository import CarteraRepository
from app.repositories.asesor_repository import AsesorRepository
from app.models.cartera_model import CarteraDiaria
from app.core.exceptions import ResourceNotFoundException
from typing import List

class CarteraService:
    @staticmethod
    def get_cartera_hoy(db: Session, id_usuario: str) -> List[CarteraDiaria]:
        asesor = AsesorRepository.get_by_usuario_id(db, id_usuario)
        if not asesor:
            raise ResourceNotFoundException(detail="Asesor no encontrado")
        return CarteraRepository.get_cartera_hoy(db, asesor.id_asesor)

    @staticmethod
    def get_cartera_item(db: Session, id_cartera: str) -> CarteraDiaria:
        item = CarteraRepository.get_by_id(db, id_cartera)
        if not item:
            raise ResourceNotFoundException(detail="Item de cartera no encontrado")
        return item
