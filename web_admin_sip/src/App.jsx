import React, { useState, useEffect } from 'react';
import { 
  Building2, 
  Users, 
  Briefcase, 
  FileText, 
  TrendingUp, 
  CheckCircle, 
  MapPin, 
  Search, 
  RefreshCw, 
  LogOut, 
  DollarSign, 
  FileCheck, 
  ShieldCheck, 
  Clock,
  ChevronRight,
  Plus
} from 'lucide-react';

const API_BASE = "http://localhost:8003";

export default function App() {
  const formatAmount = (val) => {
    if (val === undefined || val === null) return '0.00';
    const num = Number(val);
    return isNaN(num) ? '0.00' : num.toFixed(2);
  };

  const [token, setToken] = useState(localStorage.getItem('admin_token') || '');
  const [user, setUser] = useState(JSON.parse(localStorage.getItem('admin_user') || 'null'));
  
  // Auth Form State
  const [username, setUsername] = useState('SUP001');
  const [password, setPassword] = useState('123456');
  const [authError, setAuthError] = useState('');
  const [loading, setLoading] = useState(false);

  // App Navigation State
  const [activeTab, setActiveTab] = useState('inicio');

  // Business Data State
  const [solicitudes, setSolicitudes] = useState([]);
  const [cartera, setCartera] = useState([]);
  const [clientes, setClientes] = useState([]);
  const [asesores, setAsesores] = useState([]);
  const [carteraSubTab, setCarteraSubTab] = useState('clientes');
  const [cobranza, setCobranza] = useState([]);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);

  // Approve dialog state
  const [approveAmount, setApproveAmount] = useState('');

  // Auto-reload data when logged in
  useEffect(() => {
    if (token) {
      loadData();
    }
  }, [token]);

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setAuthError('');
    try {
      const response = await fetch(`${API_BASE}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ codigo_empleado: username, password })
      });
      if (response.ok) {
        const data = await response.json();
        if (data.usuario.rol === 'SUPERVISOR' || data.usuario.rol === 'ADMIN') {
          localStorage.setItem('admin_token', data.access_token);
          localStorage.setItem('admin_user', JSON.stringify(data.usuario));
          setToken(data.access_token);
          setUser(data.usuario);
        } else {
          setAuthError('Acceso denegado: Se requiere rol de Supervisor o Administrador.');
        }
      } else {
        const err = await response.json();
        setAuthError(err.detail || 'Credenciales inválidas.');
      }
    } catch (err) {
      // Offline/Local mock login for testing ease
      if (username === 'SUP001' && password === '123456') {
        const mockUser = { id_usuario: 'mock-sup', nombre: 'Carlos Ramirez', correo: 'supervisor@sip.com.pe', rol: 'SUPERVISOR' };
        localStorage.setItem('admin_token', 'mock-token');
        localStorage.setItem('admin_user', JSON.stringify(mockUser));
        setToken('mock-token');
        setUser(mockUser);
      } else {
        setAuthError('Error de red: No se pudo conectar al servidor backend (puerto 8003).');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    setToken('');
    setUser(null);
  };

  const loadData = async () => {
    setRefreshing(true);
    try {
      // 1. Fetch Solicitudes (Comité / Todos)
      let solList = [];
      try {
        const headers = { 'Authorization': `Bearer ${token}` };
        const res = await fetch(`${API_BASE}/comite/solicitudes`, { headers });
        if (res.ok) {
          solList = await res.json();
        }
      } catch(_) {}

      // Fallback/Simulated database content if empty or offline
      if (solList.length === 0) {
        solList = [
          {
            id_solicitud: "c90ac33a-9f98-4a2c-9fac-9bc3f5aca621",
            numero_expediente: "EXP-2026-845136",
            monto_solicitado: 1000.00,
            monto_aprobado: 1000.00,
            plazo_meses: 12,
            moneda: "PEN",
            estado: "APROBADO",
            destino_credito: "Capital de trabajo para bodega",
            created_at: "2026-06-24T15:20:00Z",
            cliente_nombre: "Daniel Espinoza",
            negocio_nombre: "Negocio Daniel",
            resultado_preevaluacion: "APTO",
            puntaje_preevaluacion: 85,
            resultado_buro: "NORMAL"
          },
          {
            id_solicitud: "sol-002",
            numero_expediente: "EXP-2026-254992",
            monto_solicitado: 3000.00,
            monto_aprobado: null,
            plazo_meses: 12,
            moneda: "PEN",
            estado: "EN_EVALUACION",
            destino_credito: "Compra de cocina industrial",
            created_at: "2026-06-24T16:10:00Z",
            cliente_nombre: "Eulalia Mamani",
            negocio_nombre: "Restaurante La Eulalia",
            resultado_preevaluacion: "APTO",
            puntaje_preevaluacion: 85,
            resultado_buro: "NORMAL"
          },
          {
            id_solicitud: "sol-003",
            numero_expediente: "EXP-2026-993855",
            monto_solicitado: 15000.00,
            monto_aprobado: 7000.00,
            plazo_meses: 18,
            moneda: "PEN",
            estado: "CONDICIONADO",
            destino_credito: "Ampliación de local nuevo",
            created_at: "2026-06-24T10:05:00Z",
            cliente_nombre: "Filoctetes Cruz",
            negocio_nombre: "Cevicheria Filoctetes",
            resultado_preevaluacion: "APTO",
            puntaje_preevaluacion: 85,
            resultado_buro: "CPP"
          }
        ];
      }

      setSolicitudes(solList);

      // 2. Fetch Clientes
      let clientsList = [];
      try {
        const headers = { 'Authorization': `Bearer ${token}` };
        const res = await fetch(`${API_BASE}/admin/clientes`, { headers });
        if (res.ok) {
          clientsList = await res.json();
        }
      } catch(_) {}
      if (clientsList.length === 0) {
        clientsList = [
          { id_cliente: "3d875793-836d-4929-b555-c761efeb43b1", nombres: "Anaximandro", apellidos: "Quispe", documento: "40118120", telefono: "964110201", correo: "anaximandro.quispe@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "6e64b00a-31b9-4496-817d-a5eb88b2cd84", nombres: "Eulalia", apellidos: "Mamani", documento: "41223341", telefono: "964110202", correo: "eulalia.mamani@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "146e8a8d-cd8c-42b5-ba5f-4439c5225132", nombres: "Teofilo", apellidos: "Huaman", documento: "42330336", telefono: "964110203", correo: "teofilo.huaman@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "0969e905-2f1d-4120-b895-ca1afb5ce43f", nombres: "Casandra", apellidos: "Flores", documento: "43440349", telefono: "964110204", correo: "casandra.flores@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "b49b73d5-b724-426d-ab6b-e0c3ce8546fb", nombres: "Demostenes", apellidos: "Rojas", documento: "40556071", telefono: "964110205", correo: "demostenes.rojas@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "c74eecbf-cbd5-4407-a507-522b08b29baa", nombres: "Hipatia", apellidos: "Condori", documento: "41669066", telefono: "964110206", correo: "hipatia.condori@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "65207b65-c4c5-437b-a833-14fde25ebfa3", nombres: "Anibal", apellidos: "Vargas", documento: "43773379", telefono: "964110207", correo: "anibal.vargas@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "22aac785-e6c4-42ab-a2d4-ab054d1f623e", nombres: "Penelope", apellidos: "Apaza", documento: "40886086", telefono: "964110208", correo: "penelope.apaza@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "5b6e0187-fa2b-44b1-bd33-1ef12e512f98", nombres: "Heraclito", apellidos: "Ccahua", documento: "41990091", telefono: "964110209", correo: "heraclito.ccahua@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" },
          { id_cliente: "34c76174-4029-4354-b5f1-484b617feaad", nombres: "Cleopatra", apellidos: "Soto", documento: "43003039", telefono: "964110210", correo: "cleopatra.soto@example.com", estado: "ACTIVO", tipo_cliente: "NUEVO" }
        ];
      }
      setClientes(clientsList);

      // 3. Fetch Asesores
      let advisorsList = [];
      try {
        const headers = { 'Authorization': `Bearer ${token}` };
        const res = await fetch(`${API_BASE}/admin/asesores`, { headers });
        if (res.ok) {
          advisorsList = await res.json();
        }
      } catch(_) {}
      if (advisorsList.length === 0) {
        advisorsList = [
          { id_asesor: "dde4e1ae-9d9f-4acd-b522-143f6f59f68e", nombres: "Jorge", apellidos: "Valdivia", codigo_empleado: "A001", telefono: "999111222", cargo: "Asesor Senior", estado: "ACTIVO" }
        ];
      }
      setAsesores(advisorsList);

      // 4. Fetch Cartera / Visitas
      let carteraList = [];
      try {
        const headers = { 'Authorization': `Bearer ${token}` };
        const res = await fetch(`${API_BASE}/admin/cartera`, { headers });
        if (res.ok) {
          carteraList = await res.json();
        }
      } catch(_) {}
      if (carteraList.length === 0) {
        carteraList = [
          { id_cartera: "c-01", cliente_nombre: "Daniel Espinoza", asesor_nombre: "Jorge Valdivia", tipo_gestion: "NUEVA_SOLICITUD", prioridad: "ALTA", estado_visita: "REALIZADA", resultado_visita: "VISITA_EFECTIVA" },
          { id_cartera: "c-02", cliente_nombre: "Eulalia Mamani", asesor_nombre: "Jorge Valdivia", tipo_gestion: "NUEVA_SOLICITUD", prioridad: "MEDIA", estado_visita: "REALIZADA", resultado_visita: "VISITA_EFECTIVA" },
          { id_cartera: "c-03", cliente_nombre: "Filoctetes Cruz", asesor_nombre: "Jorge Valdivia", tipo_gestion: "RENOVACION", prioridad: "MEDIA", estado_visita: "REALIZADA", resultado_visita: "VISITA_EFECTIVA" },
          { id_cartera: "c-04", cliente_nombre: "Juan Flores", asesor_nombre: "Jorge Valdivia", tipo_gestion: "SEGUIMIENTO", prioridad: "BAJA", estado_visita: "PENDIENTE", resultado_visita: "Pendiente de visita" }
        ];
      }
      setCartera(carteraList);

      // 5. Load Cobranza
      setCobranza([
        { id_cobranza: "cob-01", cliente: "Pedro Sanchez", dias_mora: 45, monto_vencido: 850.00, urgencia: "Naranja" },
        { id_cobranza: "cob-02", cliente: "Andrea Rios", dias_mora: 12, monto_vencido: 290.00, urgencia: "Amarillo" },
        { id_cobranza: "cob-03", cliente: "Felipe Vargas", dias_mora: 95, monto_vencido: 2450.00, urgencia: "Rojo" }
      ]);

    } catch (e) {
      console.error(e);
    } finally {
      setRefreshing(false);
    }
  };

  // State Transitions for Committee Action
  const runComiteAction = async (action, reqId, payload = {}) => {
    try {
      const headers = { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };
      const res = await fetch(`${API_BASE}/comite/solicitudes/${reqId}/${action}`, {
        method: 'POST',
        headers,
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        await loadData();
        setSelectedRequest(null);
        alert(`Operación ejecutada con éxito.`);
      } else {
        const err = await res.json();
        alert(`Error: ${err.detail || 'No se pudo completar la transacción.'}`);
      }
    } catch (e) {
      // Mock flow transitions in offline mode
      setSolicitudes(prev => prev.map(s => {
        if (s.id_solicitud === reqId) {
          let nextState = s.estado;
          let nextApproved = s.monto_aprobado;
          if (action === 'recibir') nextState = 'RECIBIDO_COMITE';
          if (action === 'evaluar') nextState = 'EN_EVALUACION';
          if (action === 'aprobar') {
            nextState = 'APROBADO';
            nextApproved = payload.monto_aprobado || s.monto_solicitado;
          }
          if (action === 'desembolsar') nextState = 'DESEMBOLSADO';
          
          const updated = { ...s, estado: nextState, monto_aprobado: nextApproved };
          if (selectedRequest && selectedRequest.id_solicitud === reqId) {
            setSelectedRequest(updated);
          }
          return updated;
        }
        return s;
      }));
      alert(`[Offline Mode] Simulación de transición '${action}' ejecutada con éxito.`);
    }
  };

  if (!token) {
    return (
      <div className="login-container">
        <form onSubmit={handleLogin} className="login-card">
          <div className="logo-icon login-logo">BN</div>
          <h1 className="login-title">Banco de la Nación</h1>
          <p className="login-sub">Panel Administrativo — El banco de todos</p>
          
          {authError && (
            <div className="badge error" style={{ width: '100%', padding: '12px', borderRadius: '8px', marginBottom: '20px', textAlign: 'center' }}>
              {authError}
            </div>
          )}

          <div className="form-group">
            <label className="form-label">Código de Colaborador</label>
            <input 
              type="text" 
              className="form-control" 
              value={username} 
              onChange={(e) => setUsername(e.target.value)} 
              required 
            />
          </div>

          <div className="form-group">
            <label className="form-label">Contraseña</label>
            <input 
              type="password" 
              className="form-control" 
              value={password} 
              onChange={(e) => setPassword(e.target.value)} 
              required 
            />
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', height: '48px', marginTop: '12px' }} disabled={loading}>
            {loading ? 'Ingresando...' : 'Iniciar Sesión'}
          </button>
        </form>
      </div>
    );
  }

  // Count requests by state
  const pendingCount = solicitudes.filter(s => s.estado === 'RECIBIDO_COMITE' || s.estado === 'EN_EVALUACION' || s.estado === 'ENVIADO').length;
  const approvedCount = solicitudes.filter(s => s.estado === 'APROBADO').length;
  const disbursedCount = solicitudes.filter(s => s.estado === 'DESEMBOLSADO').length;

  const pendingSum = solicitudes
    .filter(s => s.estado === 'RECIBIDO_COMITE' || s.estado === 'EN_EVALUACION' || s.estado === 'ENVIADO')
    .reduce((sum, s) => sum + (Number(s.monto_solicitado) || 0), 0);
  const approvedSum = solicitudes
    .filter(s => s.estado === 'APROBADO')
    .reduce((sum, s) => sum + (Number(s.monto_aprobado) || Number(s.monto_solicitado) || 0), 0);
  const disbursedSum = solicitudes
    .filter(s => s.estado === 'DESEMBOLSADO')
    .reduce((sum, s) => sum + (Number(s.monto_aprobado) || Number(s.monto_solicitado) || 0), 0);

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="logo-icon">BN</div>
          <div>
            <span className="brand-name">Banco de la Nación</span>
            <span className="brand-sub">El banco de todos</span>
          </div>
        </div>

        <nav className="sidebar-menu">
          <button className={`menu-item ${activeTab === 'inicio' ? 'active' : ''}`} onClick={() => { setActiveTab('inicio'); setSelectedRequest(null); }}>
            <Building2 size={18} />
            <span>Inicio</span>
          </button>
          <button className={`menu-item ${activeTab === 'cartera' ? 'active' : ''}`} onClick={() => { setActiveTab('cartera'); setSelectedRequest(null); }}>
            <Users size={18} />
            <span>Cartera</span>
          </button>
          <button className={`menu-item ${activeTab === 'solicitudes' ? 'active' : ''}`} onClick={() => { setActiveTab('solicitudes'); setSelectedRequest(null); }}>
            <FileText size={18} />
            <span>Solicitudes</span>
          </button>
          <button className={`menu-item ${activeTab === 'evaluacion' ? 'active' : ''}`} onClick={() => { setActiveTab('evaluacion'); setSelectedRequest(null); }}>
            <ShieldCheck size={18} />
            <span>Evaluación Comité</span>
            {pendingCount > 0 && <span className="badge error" style={{ marginLeft: 'auto', padding: '2px 8px' }}>{pendingCount}</span>}
          </button>
          <button className={`menu-item ${activeTab === 'cobranza' ? 'active' : ''}`} onClick={() => { setActiveTab('cobranza'); setSelectedRequest(null); }}>
            <TrendingUp size={18} />
            <span>Cobranza</span>
          </button>
        </nav>

        <div className="sidebar-footer">
          <div className="user-profile">
            <div className="avatar">CR</div>
            <div className="user-info">
              <span className="user-name">{user?.nombre || 'Carlos Ramirez'}</span>
              <span className="user-role">{user?.rol || 'Supervisor'}</span>
            </div>
          </div>
          <button onClick={handleLogout} className="btn btn-outline" style={{ width: '100%', justifyContent: 'center' }}>
            <LogOut size={16} />
            <span>Cerrar Sesión</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <header className="top-header">
          <div className="header-title-container">
            <h2 className="header-title">
              {activeTab === 'inicio' && 'Resumen Operativo'}
              {activeTab === 'cartera' && 'Cartera de Campo'}
              {activeTab === 'solicitudes' && 'Expedientes de Crédito'}
              {activeTab === 'evaluacion' && 'Bandeja de Comité y Desembolsos'}
              {activeTab === 'cobranza' && 'Seguimiento de Mora'}
            </h2>
            <span className="header-date">Banco de la Nación · El banco de todos · 2026</span>
          </div>

          <div className="header-actions">
            <button className="btn btn-secondary" onClick={loadData} disabled={refreshing}>
              <RefreshCw size={16} className={refreshing ? 'spin-animation' : ''} />
              <span>{refreshing ? 'Actualizando...' : 'Actualizar'}</span>
            </button>
          </div>
        </header>

        <div className="content-viewport">
          {activeTab === 'inicio' && (
            <div>
              {/* Stat Cards */}
              <div className="card-grid">
                <div className="stat-card">
                  <div className="stat-icon-wrapper primary">
                    <Clock size={24} />
                  </div>
                  <div className="stat-info">
                    <span className="stat-label">Pendientes Comité ({pendingCount})</span>
                    <span className="stat-value" style={{ fontSize: '18px', whiteSpace: 'nowrap' }}>
                      PEN {pendingSum.toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>

                <div className="stat-card">
                  <div className="stat-icon-wrapper success">
                    <FileCheck size={24} />
                  </div>
                  <div className="stat-info">
                    <span className="stat-label">Aprobadas ({approvedCount})</span>
                    <span className="stat-value" style={{ fontSize: '18px', whiteSpace: 'nowrap' }}>
                      PEN {approvedSum.toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>

                <div className="stat-card">
                  <div className="stat-icon-wrapper warning">
                    <DollarSign size={24} />
                  </div>
                  <div className="stat-info">
                    <span className="stat-label">Desembolsadas ({disbursedCount})</span>
                    <span className="stat-value" style={{ fontSize: '18px', whiteSpace: 'nowrap' }}>
                      PEN {disbursedSum.toLocaleString('es-PE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                    </span>
                  </div>
                </div>
              </div>

              {/* Quick Access */}
              <div className="content-card">
                <h3 className="card-title" style={{ marginBottom: '16px' }}>Accesos Rápidos Operativos</h3>
                <div className="card-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))' }}>
                  <button className="btn btn-outline" style={{ height: '80px', flexDirection: 'column', gap: '8px' }} onClick={() => setActiveTab('cartera')}>
                    <Users size={20} className="text-primary" />
                    <span>Cartera del día</span>
                  </button>
                  <button className="btn btn-outline" style={{ height: '80px', flexDirection: 'column', gap: '8px' }} onClick={() => setActiveTab('evaluacion')}>
                    <ShieldCheck size={20} className="text-primary" />
                    <span>Comité y Desembolso</span>
                  </button>
                  <button className="btn btn-outline" style={{ height: '80px', flexDirection: 'column', gap: '8px' }} onClick={() => setActiveTab('cobranza')}>
                    <TrendingUp size={20} className="text-primary" />
                    <span>Cobranza</span>
                  </button>
                </div>
              </div>

              {/* Recent solicitudes */}
              <div className="content-card">
                <h3 className="card-title" style={{ marginBottom: '16px' }}>Últimas Solicitudes Recibidas</h3>
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Expediente</th>
                        <th>Cliente</th>
                        <th>Monto Solicitado</th>
                        <th>Estado</th>
                        <th>Fecha</th>
                      </tr>
                    </thead>
                    <tbody>
                      {solicitudes.slice(0, 5).map((s) => (
                        <tr key={s.id_solicitud}>
                          <td><strong>{s.numero_expediente}</strong></td>
                          <td>{s.cliente_nombre || 'Daniel Espinoza'}</td>
                          <td>{s.moneda} {formatAmount(s.monto_solicitado)}</td>
                          <td>
                            <span className={`badge ${
                              s.estado === 'DESEMBOLSADO' ? 'success' : 
                              s.estado === 'APROBADO' ? 'primary' : 
                              s.estado === 'RECHAZADO' ? 'error' : 'warning'
                            }`}>{s.estado}</span>
                          </td>
                          <td>{new Date(s.created_at).toLocaleDateString()}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'cartera' && (
            <div className="content-card">
              <div className="card-header" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: '16px', marginBottom: '24px' }}>
                <h3 className="card-title">Cartera de Clientes, Asesores y Visitas</h3>
                
                {/* Sub-tabs Selector */}
                <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border)', width: '100%', paddingBottom: '12px' }}>
                  <button 
                    className={`btn ${carteraSubTab === 'clientes' ? 'btn-primary' : 'btn-outline'}`}
                    onClick={() => setCarteraSubTab('clientes')}
                    style={{ height: '36px', padding: '0 16px', fontSize: '13px', display: 'flex', alignItems: 'center' }}
                  >
                    Clientes Registrados ({clientes.length})
                  </button>
                  <button 
                    className={`btn ${carteraSubTab === 'asesores' ? 'btn-primary' : 'btn-outline'}`}
                    onClick={() => setCarteraSubTab('asesores')}
                    style={{ height: '36px', padding: '0 16px', fontSize: '13px', display: 'flex', alignItems: 'center' }}
                  >
                    Asesores de Ventas ({asesores.length})
                  </button>
                  <button 
                    className={`btn ${carteraSubTab === 'visitas' ? 'btn-primary' : 'btn-outline'}`}
                    onClick={() => setCarteraSubTab('visitas')}
                    style={{ height: '36px', padding: '0 16px', fontSize: '13px', display: 'flex', alignItems: 'center' }}
                  >
                    Visitas y Cartera Diaria ({cartera.length})
                  </button>
                </div>
              </div>

              {/* View Clientes */}
              {carteraSubTab === 'clientes' && (
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Nombres y Apellidos</th>
                        <th>Documento (DNI)</th>
                        <th>Teléfono</th>
                        <th>Correo Electrónico</th>
                        <th>Tipo</th>
                        <th>Estado</th>
                      </tr>
                    </thead>
                    <tbody>
                      {clientes.map((c) => (
                        <tr key={c.id_cliente}>
                          <td><strong>{c.nombres} {c.apellidos}</strong></td>
                          <td>{c.documento}</td>
                          <td>{c.telefono || 'No registrado'}</td>
                          <td>{c.correo || 'No registrado'}</td>
                          <td>
                            <span className="badge primary" style={{ textTransform: 'uppercase', fontSize: '11px' }}>
                              {c.tipo_cliente || 'NUEVO'}
                            </span>
                          </td>
                          <td>
                            <span className={`badge ${c.estado === 'ACTIVO' ? 'success' : 'error'}`}>
                              {c.estado}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* View Asesores */}
              {carteraSubTab === 'asesores' && (
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Código Empleado</th>
                        <th>Asesor de Ventas</th>
                        <th>Teléfono</th>
                        <th>Cargo</th>
                        <th>Estado</th>
                      </tr>
                    </thead>
                    <tbody>
                      {asesores.map((a) => (
                        <tr key={a.id_asesor}>
                          <td><strong>{a.codigo_empleado}</strong></td>
                          <td>{a.nombres} {a.apellidos}</td>
                          <td>{a.telefono || 'No registrado'}</td>
                          <td>{a.cargo || 'Asesor'}</td>
                          <td>
                            <span className={`badge ${a.estado === 'ACTIVO' ? 'success' : 'error'}`}>
                              {a.estado}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* View Visitas */}
              {carteraSubTab === 'visitas' && (
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Cliente</th>
                        <th>Asesor Asignado</th>
                        <th>Gestión</th>
                        <th>Prioridad</th>
                        <th>Visita</th>
                        <th>Resultado</th>
                      </tr>
                    </thead>
                    <tbody>
                      {cartera.map((item) => (
                        <tr key={item.id_cartera}>
                          <td><strong>{item.cliente_nombre || item.cliente}</strong></td>
                          <td>{item.asesor_nombre || 'Asesor Asignado'}</td>
                          <td>{item.tipo_gestion}</td>
                          <td>
                            <span className={`badge ${item.prioridad === 'ALTA' ? 'error' : 'warning'}`}>{item.prioridad}</span>
                          </td>
                          <td>
                            <span className={`badge ${item.estado_visita === 'REALIZADA' ? 'success' : 'primary'}`}>{item.estado_visita}</span>
                          </td>
                          <td>
                            {item.resultado_visita || item.resultado ? (
                              <span className="badge primary">{item.resultado_visita || item.resultado}</span>
                            ) : (
                              <span className="text-muted">Pendiente de visita en campo</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {activeTab === 'solicitudes' && (
            <div className="content-card">
              <div className="card-header">
                <h3 className="card-title">Expedientes Originados en Campo</h3>
              </div>
              <div className="table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Expediente</th>
                      <th>Cliente</th>
                      <th>Monto Solicitado</th>
                      <th>Preevaluación</th>
                      <th>Buró</th>
                      <th>Estado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {solicitudes.map((s) => (
                      <tr key={s.id_solicitud}>
                        <td><strong>{s.numero_expediente}</strong></td>
                        <td>{s.cliente_nombre || 'Daniel Espinoza'}</td>
                        <td>{s.moneda} {formatAmount(s.monto_solicitado)}</td>
                        <td>
                          <span className="badge success">{s.resultado_preevaluacion || 'APTO'} ({s.puntaje_preevaluacion} pts)</span>
                        </td>
                        <td>
                          <span className="badge primary">{s.resultado_buro || 'NORMAL'}</span>
                        </td>
                        <td>
                          <span className={`badge ${
                            s.estado === 'DESEMBOLSADO' ? 'success' : 
                            s.estado === 'APROBADO' ? 'primary' : 
                            s.estado === 'RECHAZADO' ? 'error' : 'warning'
                          }`}>{s.estado}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activeTab === 'evaluacion' && (
            <div style={{ display: 'flex', gap: '24px' }}>
              {/* Requests List */}
              <div className="content-card" style={{ flex: selectedRequest ? '1' : '2' }}>
                <h3 className="card-title" style={{ marginBottom: '16px' }}>Bandeja del Comité</h3>
                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Expediente</th>
                        <th>Cliente</th>
                        <th>Monto</th>
                        <th>Estado</th>
                        <th>Acción</th>
                      </tr>
                    </thead>
                    <tbody>
                      {solicitudes.map((s) => (
                        <tr key={s.id_solicitud}>
                          <td><strong>{s.numero_expediente}</strong></td>
                          <td>{s.cliente_nombre || 'Daniel Espinoza'}</td>
                          <td>{s.moneda} {formatAmount(s.monto_solicitado)}</td>
                          <td>
                            <span className={`badge ${
                              s.estado === 'DESEMBOLSADO' ? 'success' : 
                              s.estado === 'APROBADO' ? 'primary' : 
                              s.estado === 'RECHAZADO' ? 'error' : 'warning'
                            }`}>{s.estado}</span>
                          </td>
                          <td>
                            <button className="btn btn-outline" onClick={() => setSelectedRequest(s)}>
                              <span>Ver Comité</span>
                              <ChevronRight size={14} />
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>

              {/* Request Evaluation Panel */}
              {selectedRequest && (
                <div className="content-card" style={{ flex: '1' }}>
                  <div className="card-header">
                    <h3 className="card-title">Detalle del Comité</h3>
                    <button className="btn btn-outline" onClick={() => setSelectedRequest(null)}>Cerrar</button>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <div>
                      <span className="text-secondary" style={{ fontSize: '12px' }}>Expediente</span>
                      <p style={{ fontWeight: 'bold', fontSize: '18px' }}>{selectedRequest.numero_expediente}</p>
                    </div>

                    <div>
                      <span className="text-secondary" style={{ fontSize: '12px' }}>Cliente</span>
                      <p style={{ fontWeight: '600' }}>{selectedRequest.cliente_nombre || 'Daniel Espinoza'}</p>
                    </div>

                    <div>
                      <span className="text-secondary" style={{ fontSize: '12px' }}>Monto Solicitado</span>
                      <p style={{ fontWeight: '600', fontSize: '16px' }}>{selectedRequest.moneda} {formatAmount(selectedRequest.monto_solicitado)}</p>
                    </div>

                    {selectedRequest.monto_aprobado && (
                      <div>
                        <span className="text-secondary" style={{ fontSize: '12px' }}>Monto Aprobado</span>
                        <p style={{ fontWeight: '700', fontSize: '16px', color: 'var(--primary)' }}>{selectedRequest.moneda} {formatAmount(selectedRequest.monto_aprobado)}</p>
                      </div>
                    )}

                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '16px' }}>
                      <span className="text-secondary" style={{ fontSize: '12px', fontWeight: 'bold' }}>Acciones Disponibles</span>

                      {selectedRequest.estado === 'ENVIADO' && (
                        <button className="btn btn-primary" onClick={() => runComiteAction('recibir', selectedRequest.id_solicitud)}>
                          Recibir en Comité
                        </button>
                      )}

                      {selectedRequest.estado === 'RECIBIDO_COMITE' && (
                        <button className="btn btn-primary" onClick={() => runComiteAction('evaluar', selectedRequest.id_solicitud)}>
                          Iniciar Evaluación
                        </button>
                      )}

                      {selectedRequest.estado === 'EN_EVALUACION' && (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                          <input 
                            type="number" 
                            className="form-control" 
                            placeholder="Monto Aprobado" 
                            value={approveAmount}
                            onChange={(e) => setApproveAmount(e.target.value)}
                          />
                          <button className="btn btn-primary" onClick={() => {
                            const amt = parseFloat(approveAmount) || selectedRequest.monto_solicitado;
                            runComiteAction('aprobar', selectedRequest.id_solicitud, { monto_aprobado: amt });
                          }}>
                            Aprobar Solicitud
                          </button>
                        </div>
                      )}

                      {selectedRequest.estado === 'APROBADO' && (
                        <button className="btn btn-success" onClick={() => runComiteAction('desembolsar', selectedRequest.id_solicitud)}>
                          <DollarSign size={16} />
                          <span>Desembolsar Crédito</span>
                        </button>
                      )}

                      {selectedRequest.estado === 'DESEMBOLSADO' && (
                        <div className="badge success" style={{ padding: '12px', justifyContent: 'center' }}>
                          Crédito ya Desembolsado
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'cobranza' && (
            <div className="content-card">
              <div className="card-header">
                <h3 className="card-title">Clientes en Mora (Recuperación de Cartera)</h3>
              </div>
              <div className="table-container">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Cliente</th>
                      <th>Días de Mora</th>
                      <th>Monto Vencido</th>
                      <th>Urgencia</th>
                    </tr>
                  </thead>
                  <tbody>
                    {cobranza.map((item) => (
                      <tr key={item.id_cobranza}>
                        <td><strong>{item.cliente}</strong></td>
                        <td>{item.dias_mora} días</td>
                        <td>PEN {formatAmount(item.monto_vencido)}</td>
                        <td>
                          <span className={`badge ${
                            item.urgency === 'Rojo' ? 'error' : 
                            item.urgency === 'Naranja' ? 'warning' : 'primary'
                          }`}>{item.urgencia}</span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
