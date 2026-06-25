from sqlalchemy.orm import Session
from app.repositories.cliente_repository import ClienteRepository
from app.schemas.cliente_schema import ClienteSchema, NegocioSchema, ClienteFichaResponse
from app.core.exceptions import ResourceNotFoundException

class ClienteService:
    @staticmethod
    def get_ficha_cliente(db: Session, id_cliente: str) -> ClienteFichaResponse:
        cliente = ClienteRepository.get_by_id(db, id_cliente)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")
        negocio = ClienteRepository.get_negocio_by_cliente_id(db, id_cliente)
        
        negocios_list = []
        if negocio:
            negocios_list.append(NegocioSchema.model_validate(negocio))
            
        return ClienteFichaResponse(
            cliente=ClienteSchema.model_validate(cliente),
            negocios=negocios_list
        )
