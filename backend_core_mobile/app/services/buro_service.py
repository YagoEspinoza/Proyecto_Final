from sqlalchemy.orm import Session
from app.repositories.solicitud_repository import SolicitudRepository
from app.repositories.cliente_repository import ClienteRepository
from app.models.solicitud_model import ConsultaBuro
from app.models.sync_model import ListaInhabilitados
from app.core.exceptions import ResourceNotFoundException
import uuid
from decimal import Decimal

class BuroService:
    @staticmethod
    def consultar_buro(db: Session, id_solicitud: str) -> dict:
        solicitud = SolicitudRepository.get_by_id(db, id_solicitud)
        if not solicitud:
            raise ResourceNotFoundException(detail="Solicitud no encontrada")

        cliente = ClienteRepository.get_by_id(db, solicitud.id_cliente)
        if not cliente:
            raise ResourceNotFoundException(detail="Cliente no encontrado")

        documento = cliente.documento
        
        # 1. Verificar si esta en la lista de inhabilitados
        inhabilitado = db.query(ListaInhabilitados).filter(
            ListaInhabilitados.documento == documento,
            ListaInhabilitados.estado == "ACTIVO"
        ).first()

        if inhabilitado:
            resultado_calificacion = "PERDIDA"
            esta_inhabilitado = True
            resultado_consulta = "RECHAZADO"
            
            # Bloquear solicitud
            solicitud.resultado_buro = "PERDIDA"
            solicitud.estado = "RECHAZADO"
            solicitud.motivo_rechazo = f"Cliente registrado en lista de inhabilitados: {inhabilitado.motivo}"
            db.add(solicitud)
        else:
            esta_inhabilitado = False
            # Determinar calificacion por el ultimo digito del DNI
            last_char = documento[-1] if len(documento) > 0 else '0'
            if last_char in ['0', '1', '2', '3']:
                resultado_calificacion = "NORMAL"
                resultado_consulta = "APROBADO"
            elif last_char in ['4', '5']:
                resultado_calificacion = "CPP"
                resultado_consulta = "ALERTA"
            elif last_char in ['6', '7']:
                resultado_calificacion = "DEFICIENTE"
                resultado_consulta = "ALERTA"
            elif last_char in ['8']:
                resultado_calificacion = "DUDOSO"
                resultado_consulta = "ALERTA"
            else:  # '9'
                resultado_calificacion = "PERDIDA"
                resultado_consulta = "RECHAZADO"
                solicitud.estado = "RECHAZADO"
                solicitud.motivo_rechazo = "Calificacion PERDIDA en buro de credito"
                db.add(solicitud)

            solicitud.resultado_buro = resultado_calificacion
            db.add(solicitud)

        # Generar simulacion de deudas
        entidades = 0 if resultado_calificacion == "NORMAL" else 2
        deuda = Decimal("0.00") if resultado_calificacion == "NORMAL" else Decimal("3500.00")
        mora_dias = 0
        if resultado_calificacion == "CPP":
            mora_dias = 15
        elif resultado_calificacion == "DEFICIENTE":
            mora_dias = 45
        elif resultado_calificacion == "DUDOSO":
            mora_dias = 95
        elif resultado_calificacion == "PERDIDA":
            mora_dias = 180

        # Registrar la consulta
        consulta = ConsultaBuro(
            id_consulta=uuid.uuid4(),
            id_solicitud=solicitud.id_solicitud,
            id_cliente=cliente.id_cliente,
            documento=documento,
            calificacion=resultado_calificacion,
            entidades_deuda=entidades,
            deuda_total=deuda,
            mayor_mora_dias=mora_dias,
            esta_inhabilitado=esta_inhabilitado,
            resultado=resultado_consulta
        )
        db.add(consulta)
        db.commit()

        return {
            "id_consulta": str(consulta.id_consulta),
            "id_solicitud": consulta.id_solicitud,
            "documento": documento,
            "calificacion": resultado_calificacion,
            "entidades_deuda": entidades,
            "deuda_total": deuda,
            "mayor_mora_dias": mora_dias,
            "esta_inhabilitado": esta_inhabilitado,
            "resultado": resultado_consulta,
            "solicitud_estado": solicitud.estado
        }
