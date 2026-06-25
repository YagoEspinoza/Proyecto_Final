from sqlalchemy.orm import Session
from app.repositories.solicitud_repository import SolicitudRepository
from app.core.exceptions import ResourceNotFoundException, BusinessRuleException
from decimal import Decimal

class ComiteService:
    @staticmethod
    def recibir_solicitud(db: Session, id_solicitud: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")
        
        if solicitud.estado not in ["ENVIADO", "BORRADOR"]:
            raise BusinessRuleException(detail=f"No se puede recibir una solicitud en estado {solicitud.estado}")

        solicitud.estado = "RECIBIDO_COMITE"
        db.add(solicitud)
        db.commit()
        return {"id_solicitud": str(solicitud.id_solicitud), "estado": solicitud.estado}

    @staticmethod
    def evaluar_solicitud(db: Session, id_solicitud: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        if solicitud.estado not in ["RECIBIDO_COMITE", "ENVIADO"]:
            raise BusinessRuleException(detail=f"No se puede evaluar una solicitud en estado {solicitud.estado}")

        solicitud.estado = "EN_EVALUACION"
        db.add(solicitud)
        db.commit()
        return {"id_solicitud": str(solicitud.id_solicitud), "estado": solicitud.estado}

    @staticmethod
    def aprobar_solicitud(db: Session, id_solicitud: str, monto_aprobado: Decimal = None) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        if solicitud.estado not in ["RECIBIDO_COMITE", "EN_EVALUACION"]:
            raise BusinessRuleException(detail=f"No se puede aprobar una solicitud en estado {solicitud.estado}")

        if not monto_aprobado:
            monto_aprobado = solicitud.monto_solicitado

        solicitud.estado = "APROBADO"
        solicitud.monto_aprobado = monto_aprobado
        db.add(solicitud)
        db.commit()
        return {"id_solicitud": str(solicitud.id_solicitud), "estado": solicitud.estado, "monto_aprobado": float(monto_aprobado)}

    @staticmethod
    def condicionar_solicitud(db: Session, id_solicitud: str, condicion_adicional: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        if solicitud.estado not in ["RECIBIDO_COMITE", "EN_EVALUACION"]:
            raise BusinessRuleException(detail=f"No se puede condicionar una solicitud en estado {solicitud.estado}")

        if not condicion_adicional:
            raise BusinessRuleException(detail="Debe ingresar la condicion adicional")

        solicitud.estado = "CONDICIONADO"
        solicitud.condicion_adicional = condicion_adicional
        db.add(solicitud)
        db.commit()
        return {"id_solicitud": str(solicitud.id_solicitud), "estado": solicitud.estado, "condicion_adicional": condicion_adicional}

    @staticmethod
    def rechazar_solicitud(db: Session, id_solicitud: str, motivo_rechazo: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        if solicitud.estado in ["DESEMBOLSADO", "RECHAZADO"]:
            raise BusinessRuleException(detail=f"No se puede rechazar una solicitud en estado {solicitud.estado}")

        if not motivo_rechazo:
            raise BusinessRuleException(detail="Debe ingresar el motivo de rechazo")

        solicitud.estado = "RECHAZADO"
        solicitud.motivo_rechazo = motivo_rechazo
        db.add(solicitud)
        db.commit()
        return {"id_solicitud": str(solicitud.id_solicitud), "estado": solicitud.estado, "motivo_rechazo": motivo_rechazo}
