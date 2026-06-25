from sqlalchemy.orm import Session
from app.models.sync_model import SyncOutbox, SyncLog
from app.repositories.sync_repository import SyncRepository
from datetime import datetime, timezone
from typing import List
import uuid

class SyncService:
    @staticmethod
    def get_pending_events(db: Session) -> List[SyncOutbox]:
        return SyncRepository.get_outbox_pendientes(db)

    @staticmethod
    def get_logs(db: Session) -> List[SyncLog]:
        return db.query(SyncLog).order_by(SyncLog.created_at.desc()).all()

    @staticmethod
    def procesar_outbox(db: Session) -> dict:
        pending = SyncRepository.get_outbox_pendientes(db)
        procesados = 0
        errores = 0

        for event in pending:
            try:
                event.intentos += 1
                # Simular sincronizacion exitosa con el nucleo financiero
                event.estado = "PROCESADO"
                event.procesado_at = datetime.now(timezone.utc)
                db.add(event)

                # Registrar log
                log = SyncLog(
                    id_log=uuid.uuid4(),
                    id_evento=event.id_evento,
                    accion=f"SYNC_{event.tipo_evento}",
                    resultado="EXITOSO",
                    detalle=f"Sincronizado {event.entidad} ID {event.entidad_id} exitosamente."
                )
                db.add(log)
                procesados += 1
            except Exception as e:
                event.estado = "ERROR"
                event.error = str(e)
                db.add(event)

                log = SyncLog(
                    id_log=uuid.uuid4(),
                    id_evento=event.id_evento,
                    accion=f"SYNC_{event.tipo_evento}",
                    resultado="ERROR",
                    detalle=f"Error al sincronizar: {str(e)}"
                )
                db.add(log)
                errores += 1

        db.commit()
        return {
            "procesados": procesados,
            "errores": errores,
            "total_pendientes_iniciales": len(pending)
        }
