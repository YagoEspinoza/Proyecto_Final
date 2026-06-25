from sqlalchemy.orm import Session
from app.repositories.asesor_repository import AsesorRepository
from app.models.asesor_model import Asesor

class AsesorService:
    @staticmethod
    def get_by_usuario_id(db: Session, id_usuario: str) -> Asesor:
        return AsesorRepository.get_by_usuario_id(db, id_usuario)
