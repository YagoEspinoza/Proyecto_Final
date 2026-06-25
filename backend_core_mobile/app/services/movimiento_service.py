from sqlalchemy.orm import Session
from app.repositories.movimiento_repository import MovimientoRepository
from app.repositories.cliente_repository import ClienteRepository
from app.models.movimiento_model import Movimiento
from app.core.exceptions import ResourceNotFoundException
from typing import List

class MovimientoService:
    @staticmethod
    def get_movimientos_cliente(db: Session, id_usuario: str) -> List[Movimiento]:
        cliente = ClienteRepository.get_by_usuario_id(db, id_usuario)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        return MovimientoRepository.get_movimientos_by_cliente_id(db, cliente.id_cliente)
