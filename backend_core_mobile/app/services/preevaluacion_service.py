from sqlalchemy.orm import Session
from app.repositories.solicitud_repository import SolicitudRepository
from app.repositories.cliente_repository import ClienteRepository
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from decimal import Decimal

class PreevaluacionService:
    @staticmethod
    def preevaluar_solicitud(db: Session, id_solicitud: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        negocio = ClienteRepository.get_negocio_by_cliente_id(db, solicitud.id_cliente)
        if not negocio:
            raise BusinessRuleException(detail="El cliente no tiene un negocio registrado")

        ingreso = Decimal(str(negocio.ingreso_mensual))
        gasto = Decimal(str(negocio.gasto_mensual))
        capacidad_pago = ingreso - gasto

        if capacidad_pago <= 0:
            resultado = "NO_APTO"
            puntaje = 30
        else:
            cuota = Decimal(str(solicitud.cuota_estimada))
            ratio_cuota = float(cuota / capacidad_pago)

            if ratio_cuota <= 0.40:
                resultado = "APTO"
                puntaje = 85
            elif ratio_cuota <= 0.60:
                resultado = "REVISAR"
                puntaje = 60
            else:
                resultado = "NO_APTO"
                puntaje = 30

        solicitud.resultado_preevaluacion = resultado
        solicitud.puntaje_preevaluacion = puntaje
        solicitud.estado = "EN_EVALUACION"
        db.add(solicitud)
        db.commit()

        return {
            "id_solicitud": str(solicitud.id_solicitud),
            "resultado_preevaluacion": resultado,
            "puntaje_preevaluacion": puntaje,
            "capacidad_pago": float(capacidad_pago),
            "ratio_cuota": float(ratio_cuota) if capacidad_pago > 0 else 999.0
        }
