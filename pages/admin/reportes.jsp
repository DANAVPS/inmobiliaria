<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>
<%@ page import="java.util.Map, java.util.Collections, java.text.DateFormatSymbols" %>


<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para estadísticas
    int totalUsuarios = 0;
    int usuariosActivos = 0;
    int usuariosInactivos = 0;
    int totalPropiedades = 0;
    int propiedadesDisponibles = 0;
    int propiedadesDestacadas = 0;
    int totalCitas = 0;
    int citasPendientes = 0;
    int citasConfirmadas = 0;
    int citasRealizadas = 0;
    
    // Listas para gráficos
    List<Map<String, Object>> usuariosPorRol = new ArrayList<>();
    List<Map<String, Object>> propiedadesPorTipo = new ArrayList<>();
    List<Map<String, Object>> propiedadesPorCiudad = new ArrayList<>();
    List<Map<String, Object>> citasPorEstado = new ArrayList<>();
    List<Map<String, Object>> registrosMensuales = new ArrayList<>();
    List<Map<String, Object>> propiedadesPorOperacion = new ArrayList<>();
    
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // ===============================================
        // ESTADÍSTICAS DE USUARIOS
        // ===============================================
        
        // Total de usuarios
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM usuarios");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalUsuarios = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Usuarios activos e inactivos
        stmt = conn.prepareStatement("SELECT activo, COUNT(*) as cantidad FROM usuarios GROUP BY activo");
        rs = stmt.executeQuery();
        while (rs.next()) {
            if (rs.getBoolean("activo")) {
                usuariosActivos = rs.getInt("cantidad");
            } else {
                usuariosInactivos = rs.getInt("cantidad");
            }
        }
        rs.close();
        stmt.close();
        
        // Usuarios por rol
        stmt = conn.prepareStatement(
            "SELECT r.nombre_rol, COUNT(*) as cantidad " +
            "FROM usuarios u " +
            "INNER JOIN roles r ON u.id_rol = r.id_rol " +
            "GROUP BY r.nombre_rol " +
            "ORDER BY cantidad DESC"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("rol", rs.getString("nombre_rol"));
            item.put("cantidad", rs.getInt("cantidad"));
            usuariosPorRol.add(item);
        }
        rs.close();
        stmt.close();
        
        // ===============================================
        // ESTADÍSTICAS DE PROPIEDADES
        // ===============================================
        
        // Total de propiedades
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalPropiedades = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Propiedades disponibles
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE disponible = 1");
        rs = stmt.executeQuery();
        if (rs.next()) {
            propiedadesDisponibles = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Propiedades destacadas
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE destacada = 1");
        rs = stmt.executeQuery();
        if (rs.next()) {
            propiedadesDestacadas = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Propiedades por tipo
        stmt = conn.prepareStatement(
            "SELECT tp.nombre_tipo, COUNT(*) as cantidad " +
            "FROM propiedades p " +
            "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
            "GROUP BY tp.nombre_tipo " +
            "ORDER BY cantidad DESC"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("tipo", rs.getString("nombre_tipo"));
            item.put("cantidad", rs.getInt("cantidad"));
            propiedadesPorTipo.add(item);
        }
        rs.close();
        stmt.close();
        
        // Propiedades por ciudad (top 10)
        stmt = conn.prepareStatement(
            "SELECT ciudad, COUNT(*) as cantidad " +
            "FROM propiedades " +
            "GROUP BY ciudad " +
            "ORDER BY cantidad DESC " +
            "LIMIT 10"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("ciudad", rs.getString("ciudad"));
            item.put("cantidad", rs.getInt("cantidad"));
            propiedadesPorCiudad.add(item);
        }
        rs.close();
        stmt.close();
        
        // Propiedades por tipo de operación
        stmt = conn.prepareStatement(
            "SELECT tipo_operacion, COUNT(*) as cantidad " +
            "FROM propiedades " +
            "GROUP BY tipo_operacion " +
            "ORDER BY cantidad DESC"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("operacion", rs.getString("tipo_operacion"));
            item.put("cantidad", rs.getInt("cantidad"));
            propiedadesPorOperacion.add(item);
        }
        rs.close();
        stmt.close();
        
        // ===============================================
        // ESTADÍSTICAS DE CITAS
        // ===============================================
        
        // Total de citas
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM citas");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalCitas = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Citas por estado
        stmt = conn.prepareStatement("SELECT estado, COUNT(*) as cantidad FROM citas GROUP BY estado");
        rs = stmt.executeQuery();
        while (rs.next()) {
            String estado = rs.getString("estado");
            int cantidad = rs.getInt("cantidad");
            
            Map<String, Object> item = new HashMap<>();
            item.put("estado", estado);
            item.put("cantidad", cantidad);
            citasPorEstado.add(item);
            
            switch (estado) {
                case "PENDIENTE":
                    citasPendientes = cantidad;
                    break;
                case "CONFIRMADA":
                    citasConfirmadas = cantidad;
                    break;
                case "REALIZADA":
                    citasRealizadas = cantidad;
                    break;
            }
        }
        rs.close();
        stmt.close();
        
        // ===============================================
        // REGISTROS MENSUALES (últimos 6 meses)
        // ===============================================
        
        stmt = conn.prepareStatement(
            "SELECT " +
            "DATE_FORMAT(fecha_registro, '%Y-%m') as mes, " +
            "COUNT(*) as usuarios_nuevos " +
            "FROM usuarios " +
            "WHERE fecha_registro >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH) " +
            "GROUP BY DATE_FORMAT(fecha_registro, '%Y-%m') " +
            "ORDER BY mes DESC " +
            "LIMIT 6"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> item = new HashMap<>();
            item.put("mes", rs.getString("mes"));
            item.put("usuarios", rs.getInt("usuarios_nuevos"));
            registrosMensuales.add(item);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar estadísticas: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Reportes y Estadísticas - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="reportes" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 style="color: var(--vino);" class="font-weight-bold">
                        <i class="fas fa-chart-line mr-2"></i>Reportes y Estadísticas
                    </h3>
                    <p class="text-muted mb-0">Análisis detallado del sistema inmobiliario</p>
                </div>
                <div>
                    <button class="btn btn-outline-primary mr-2" onclick="window.print()">
                        <i class="fas fa-print mr-1"></i>Imprimir
                    </button>
                </div>
            </div>
            
            <!-- Mensajes -->
            <% if (!mensaje.isEmpty()) { %>
                <div class="alert alert-<%= "success".equals(tipoMensaje) ? "success" : "danger" %> alert-dismissible fade show" role="alert">
                    <i class="fas fa-<%= "success".equals(tipoMensaje) ? "check-circle" : "exclamation-triangle" %> mr-2"></i>
                    <%= mensaje %>
                    <button type="button" class="close" data-dismiss="alert">
                        <span>&times;</span>
                    </button>
                </div>
            <% } %>
            
            <!-- Resumen general -->
            <div class="row mb-4">
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--vino), #8e3a4a);">
                        <div class="card-body text-center">
                            <i class="fas fa-users fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= totalUsuarios %></h4>
                            <p class="mb-0">Total Usuarios</p>
                            <small class="opacity-75"><%= usuariosActivos %> activos</small>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--rojo), #e74c3c);">
                        <div class="card-body text-center">
                            <i class="fas fa-building fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= totalPropiedades %></h4>
                            <p class="mb-0">Total Propiedades</p>
                            <small class="opacity-75"><%= propiedadesDisponibles %> disponibles</small>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--naranja), #f39c12);">
                        <div class="card-body text-center">
                            <i class="fas fa-calendar-alt fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= totalCitas %></h4>
                            <p class="mb-0">Total Citas</p>
                            <small class="opacity-75"><%= citasPendientes %> pendientes</small>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--amarillo), #f1c40f);">
                        <div class="card-body text-center">
                            <i class="fas fa-star fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= propiedadesDestacadas %></h4>
                            <p class="mb-0">Propiedades Destacadas</p>
                            <small class="opacity-75"><%= totalPropiedades > 0 ? String.format("%.1f", (double)propiedadesDestacadas/totalPropiedades*100) : "0" %>% del total</small>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Gráficos de usuarios -->
            <div class="row mb-4">
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--vino); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-user-friends mr-2"></i>Usuarios por Rol
                            </h6>
                        </div>
                        <div class="card-body">
                            <canvas id="chartUsuariosRol" width="400" height="200"></canvas>
                            <div class="mt-3">
                                <% for (Map<String, Object> item : usuariosPorRol) { %>
                                    <div class="d-flex justify-content-between border-bottom py-1">
                                        <span><%= item.get("rol") %></span>
                                        <strong><%= item.get("cantidad") %></strong>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--rojo); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-home mr-2"></i>Propiedades por Tipo
                            </h6>
                        </div>
                        <div class="card-body">
                            <canvas id="chartPropiedadesTipo" width="400" height="200"></canvas>
                            <div class="mt-3">
                                <% for (Map<String, Object> item : propiedadesPorTipo) { %>
                                    <div class="d-flex justify-content-between border-bottom py-1">
                                        <span><%= item.get("tipo") %></span>
                                        <strong><%= item.get("cantidad") %></strong>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Gráficos de ubicación y operaciones -->
            <div class="row mb-4">
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--naranja); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-map-marker-alt mr-2"></i>Top 10 Ciudades
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-sm">
                                    <thead>
                                        <tr>
                                            <th>#</th>
                                            <th>Ciudad</th>
                                            <th>Propiedades</th>
                                            <th>%</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% 
                                        int ranking = 1;
                                        for (Map<String, Object> item : propiedadesPorCiudad) { 
                                            int cantidad = (Integer) item.get("cantidad");
                                            double porcentaje = totalPropiedades > 0 ? (double) cantidad / totalPropiedades * 100 : 0;
                                        %>
                                        <tr>
                                            <td><strong><%= ranking++ %></strong></td>
                                            <td><%= item.get("ciudad") %></td>
                                            <td><%= cantidad %></td>
                                            <td>
                                                <div class="d-flex align-items-center">
                                                    <div class="progress flex-grow-1 mr-2" style="height: 6px;">
                                                        <div class="progress-bar" style="width: <%= porcentaje %>%; background-color: var(--naranja);"></div>
                                                    </div>
                                                    <small><%= String.format("%.1f%%", porcentaje) %></small>
                                                </div>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--amarillo); color: #000;">
                            <h6 class="mb-0">
                                <i class="fas fa-handshake mr-2"></i>Tipo de Operaciones
                            </h6>
                        </div>
                        <div class="card-body">
                            <canvas id="chartOperaciones" width="400" height="200"></canvas>
                            <div class="mt-3">
                                <% for (Map<String, Object> item : propiedadesPorOperacion) { %>
                                    <div class="d-flex justify-content-between border-bottom py-2">
                                        <span class="font-weight-bold">
                                            <%= ((String)item.get("operacion")).replace("_", "/") %>
                                        </span>
                                        <div class="text-right">
                                            <strong><%= item.get("cantidad") %></strong><br>
                                            <small class="text-muted">
                                                <%= totalPropiedades > 0 ? String.format("%.1f%%", (double)(Integer)item.get("cantidad")/totalPropiedades*100) : "0%" %>
                                            </small>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Estado de citas -->
            <div class="row mb-">
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-info text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-calendar-check mr-2"></i>Estado de las Citas
                            </h6>
                        </div>
                        <div class="card-body">
                            <canvas id="chartCitas" width="400" height="150"></canvas>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-success text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-chart-pie mr-2"></i>Resumen de Citas
                            </h6>
                        </div>
                        <div class="card-body">
                            <% for (Map<String, Object> item : citasPorEstado) { 
                                String estado = (String) item.get("estado");
                                String badgeClass = "";
                                String icono = "";
                                
                                switch (estado) {
                                    case "PENDIENTE":
                                        badgeClass = "badge-warning";
                                        icono = "fas fa-clock";
                                        break;
                                    case "CONFIRMADA":
                                        badgeClass = "badge-info";
                                        icono = "fas fa-check";
                                        break;
                                    case "REALIZADA":
                                        badgeClass = "badge-success";
                                        icono = "fas fa-check-double";
                                        break;
                                    case "CANCELADA":
                                        badgeClass = "badge-danger";
                                        icono = "fas fa-times";
                                        break;
                                    default:
                                        badgeClass = "badge-secondary";
                                        icono = "fas fa-question";
                                }
                            %>
                                <div class="d-flex justify-content-between align-items-center py-2 border-bottom">
                                    <div>
                                        <i class="<%= icono %> mr-2"></i>
                                        <%= estado %>
                                    </div>
                                    <span class="badge <%= badgeClass %> badge-pill">
                                        <%= item.get("cantidad") %>
                                    </span>
                                </div>
                            <% } %>
                            
                            <% if (citasPorEstado.isEmpty()) { %>
                                <div class="text-center py-4">
                                    <i class="fas fa-calendar-times fa-2x text-muted mb-2"></i>
                                    <p class="text-muted">No hay citas registradas</p>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Registros mensuales -->
            <% if (!registrosMensuales.isEmpty()) { %>
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header bg-dark text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-chart-line mr-2"></i>Nuevos Usuarios por Mes (Últimos 6 meses)
                            </h6>
                        </div>
                        <div class="card-body">
                            <canvas id="chartRegistros" width="400" height="100"></canvas>
                            <div class="row mt-3">
                                <% 
                                Collections.reverse(registrosMensuales); // Mostrar del más antiguo al más reciente
                                for (Map<String, Object> item : registrosMensuales) { 
                                    String mes = (String) item.get("mes");
                                    String[] partes = mes.split("-");
                                    String mesFormateado = new DateFormatSymbols().getMonths()[Integer.parseInt(partes[1]) - 1] + " " + partes[0];
                                %>
                                    <div class="col-md-2 col-sm-4 text-center mb-2">
                                        <div class="border rounded p-2">
                                            <h6 class="mb-1"><%= item.get("usuarios") %></h6>
                                            <small class="text-muted"><%= mesFormateado %></small>
                                        </div>
                                    </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Acciones rápidas -->
            <div class="row">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--vino); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-tools mr-2"></i>Acciones Rápidas
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 mb-3">
                                    <a href="usuarios.jsp" class="btn btn-outline-primary btn-block">
                                        <i class="fas fa-users mr-2"></i>
                                        Gestionar Usuarios
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="../properties/propiedades.jsp" class="btn btn-outline-success btn-block">
                                        <i class="fas fa-building mr-2"></i>
                                        Gestionar Propiedades
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="../citas/citas.jsp" class="btn btn-outline-info btn-block">
                                        <i class="fas fa-calendar-alt mr-2"></i>
                                        Ver Todas las Citas
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="configuracion.jsp" class="btn btn-outline-warning btn-block">
                                        <i class="fas fa-cog mr-2"></i>
                                        Configuración
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
        </div>
    </div>
</div>

<!-- Estilos adicionales -->
<style>
:root {
    --vino: #722f37;
    --rojo: #d32f2f;
    --naranja: #ff9800;
    --amarillo: #ffc107;
}

.card {
    border: none;
    border-radius: 10px;
}

.progress {
    border-radius: 10px;
}

.opacity-75 {
    opacity: 0.75;
}
/* Control de altura de gráficos */
#chartUsuariosRol, #chartPropiedadesTipo, #chartOperaciones {
    height: 300px !important;
}

#chartCitas {
    height: 300px !important;
}

#chartRegistros {
    height: 300px !important;
}

.card-body canvas {
    max-height: 300px;
}

@media print {
    .btn, .sidebar, .breadcrumb {
        display: none !important;
    }
    
    .container-fluid {
        margin: 0;
        padding: 0;
    }
    
    .card {
        break-inside: avoid;
        margin-bottom: 1rem;
    }
}

@media (max-width: 768px) {
    .card-body {
        padding: 1rem;
    }
    
    canvas {
        max-height: 300px;
    }
}
</style>

<!-- Chart.js CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<!-- JavaScript para gráficos -->
<script>
    document.addEventListener('DOMContentLoaded', function() {
    
    // Configuración común de colores
    const colors = {
        vino: '#722f37',
        rojo: '#d32f2f',
        naranja: '#ff9800',
        amarillo: '#ffc107',
        azul: '#2196f3',
        verde: '#4caf50',
        morado: '#9c27b0'
    };
    
    // Datos para usuarios por rol
    const usuariosRolLabels = [];
    const usuariosRolData = [];
    <% for (Map<String, Object> item : usuariosPorRol) { %>
        usuariosRolLabels.push('<%= item.get("rol") %>');
        usuariosRolData.push(<%= item.get("cantidad") %>);
    <% } %>
    
    // Datos para propiedades por tipo
    const propiedadesTipoLabels = [];
    const propiedadesTipoData = [];
    <% for (Map<String, Object> item : propiedadesPorTipo) { %>
        propiedadesTipoLabels.push('<%= item.get("tipo") %>');
        propiedadesTipoData.push(<%= item.get("cantidad") %>);
    <% } %>
    
    // Datos para operaciones
    const operacionesLabels = [];
    const operacionesData = [];
    <% for (Map<String, Object> item : propiedadesPorOperacion) { %>
        operacionesLabels.push('<%= ((String)item.get("operacion")).replace("_", "/") %>');
        operacionesData.push(<%= item.get("cantidad") %>);
    <% } %>
    
    // Datos para citas
    const citasLabels = [];
    const citasData = [];
    <% for (Map<String, Object> item : citasPorEstado) { %>
        citasLabels.push('<%= item.get("estado") %>');
        citasData.push(<%= item.get("cantidad") %>);
    <% } %>
    
    // Datos para registros mensuales
    const registrosLabels = [];
    const registrosData = [];
    <% 
    Collections.reverse(registrosMensuales);
    for (Map<String, Object> item : registrosMensuales) { 
        String mes = (String) item.get("mes");
        String[] partes = mes.split("-");
        String mesCorto = new DateFormatSymbols().getShortMonths()[Integer.parseInt(partes[1]) - 1];
    %>
        registrosLabels.push('<%= mesCorto + " " + partes[0] %>');
        registrosData.push(<%= item.get("usuarios") %>);
    <% } %>
    
    // Gráfico de usuarios por rol
    if (usuariosRolLabels.length > 0) {
        const ctxUsuarios = document.getElementById('chartUsuariosRol').getContext('2d');
        new Chart(ctxUsuarios, {
            type: 'doughnut',
            data: {
                labels: usuariosRolLabels,
                datasets: [{
                    data: usuariosRolData,
                    backgroundColor: [colors.vino, colors.rojo, colors.naranja, colors.amarillo],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }
    
    // Gráfico de propiedades por tipo
    if (propiedadesTipoLabels.length > 0) {
        const ctxPropiedades = document.getElementById('chartPropiedadesTipo').getContext('2d');
        new Chart(ctxPropiedades, {
            type: 'bar',
            data: {
                labels: propiedadesTipoLabels,
                datasets: [{
                    label: 'Propiedades',
                    data: propiedadesTipoData,
                    backgroundColor: colors.rojo,
                    borderColor: colors.vino,
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }
    
    // Gráfico de operaciones
    if (operacionesLabels.length > 0) {
        const ctxOperaciones = document.getElementById('chartOperaciones').getContext('2d');
        new Chart(ctxOperaciones, {
            type: 'pie',
            data: {
                labels: operacionesLabels,
                datasets: [{
                    data: operacionesData,
                    backgroundColor: [colors.amarillo, colors.naranja, colors.verde]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }
    
    // Gráfico de citas
    if (citasLabels.length > 0) {
        const ctxCitas = document.getElementById('chartCitas').getContext('2d');
        new Chart(ctxCitas, {
            type: 'bar',
            data: {
                labels: citasLabels,
                datasets: [{
                    label: 'Citas',
                    data: citasData,
                    backgroundColor: [colors.amarillo, colors.azul, colors.verde, colors.rojo],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }
    
    // Gráfico de registros mensuales
    if (registrosLabels.length > 0) {
        const ctxRegistros = document.getElementById('chartRegistros').getContext('2d');
        new Chart(ctxRegistros, {
            type: 'line',
            data: {
                labels: registrosLabels,
                datasets: [{
                    label: 'Nuevos Usuarios',
                    data: registrosData,
                    borderColor: colors.vino,
                    backgroundColor: colors.vino + '20',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
});
</script>


<!-- JavaScript para gráficos -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    
    // Configuración común de colores
    const colors = {
        vino: '#722f37',
        rojo: '#d32f2f',
        naranja: '#ff9800',
        amarillo: '#ffc107',
        azul: '#2196f3',
        verde: '#4caf50',
        morado: '#9c27b0'
    };
    
    // Gráfico de usuarios por rol
    if (datosGraficos.usuariosPorRol.labels.length > 0) {
        const ctxUsuarios = document.getElementById('chartUsuariosRol').getContext('2d');
        new Chart(ctxUsuarios, {
            type: 'doughnut',
            data: {
                labels: datosGraficos.usuariosPorRol.labels,
                datasets: [{
                    data: datosGraficos.usuariosPorRol.data,
                    backgroundColor: [colors.vino, colors.rojo, colors.naranja, colors.amarillo],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }
    
    // Gráfico de propiedades por tipo
    if (datosGraficos.propiedadesPorTipo.labels.length > 0) {
        const ctxPropiedades = document.getElementById('chartPropiedadesTipo').getContext('2d');
        new Chart(ctxPropiedades, {
            type: 'bar',
            data: {
                labels: datosGraficos.propiedadesPorTipo.labels,
                datasets: [{
                    label: 'Propiedades',
                    data: datosGraficos.propiedadesPorTipo.data,
                    backgroundColor: colors.rojo,
                    borderColor: colors.vino,
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }
    
    // Gráfico de operaciones
    if (datosGraficos.propiedadesPorOperacion.labels.length > 0) {
        const ctxOperaciones = document.getElementById('chartOperaciones').getContext('2d');
        new Chart(ctxOperaciones, {
            type: 'pie',
            data: {
                labels: datosGraficos.propiedadesPorOperacion.labels,
                datasets: [{
                    data: datosGraficos.propiedadesPorOperacion.data,
                    backgroundColor: [colors.amarillo, colors.naranja, colors.verde]
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    }
                }
            }
        });
    }
    
    // Gráfico de citas
    if (datosGraficos.citasPorEstado.labels.length > 0) {
        const ctxCitas = document.getElementById('chartCitas').getContext('2d');
        new Chart(ctxCitas, {
            type: 'bar',
            data: {
                labels: datosGraficos.citasPorEstado.labels,
                datasets: [{
                    label: 'Citas',
                    data: datosGraficos.citasPorEstado.data,
                    backgroundColor: [colors.amarillo, colors.azul, colors.verde, colors.rojo],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }
    
    // Gráfico de registros mensuales
    if (datosGraficos.registrosMensuales.labels.length > 0) {
        const ctxRegistros = document.getElementById('chartRegistros').getContext('2d');
        new Chart(ctxRegistros, {
            type: 'line',
            data: {
                labels: datosGraficos.registrosMensuales.labels,
                datasets: [{
                    label: 'Nuevos Usuarios',
                    data: datosGraficos.registrosMensuales.data,
                    borderColor: colors.vino,
                    backgroundColor: colors.vino + '20',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }
});


<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />