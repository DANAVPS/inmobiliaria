<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    String emailUsuario = (String) session.getAttribute("usuario_email");
    
    if (usuarioId == null || !"INMOBILIARIA".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para estadísticas
    int totalPropiedades = 0;
    int propiedadesActivas = 0;
    int propiedadesDestacadas = 0;
    int totalCitas = 0;
    int citasPendientes = 0;
    int citasConfirmadas = 0;
    int citasHoy = 0;
    
    // Listas para datos
    List<Map<String, Object>> propiedadesRecientes = new ArrayList<>();
    List<Map<String, Object>> citasProximas = new ArrayList<>();
    List<Map<String, Object>> estadisticasTipos = new ArrayList<>();
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // =====================================================
        // 1. ESTADÍSTICAS DE PROPIEDADES
        // =====================================================
        
        // Total de propiedades del usuario
        String sqlTotalPropiedades = "SELECT COUNT(*) as total, " +
                                    "SUM(CASE WHEN disponible = 1 THEN 1 ELSE 0 END) as activas, " +
                                    "SUM(CASE WHEN destacada = 1 AND disponible = 1 THEN 1 ELSE 0 END) as destacadas " +
                                    "FROM propiedades WHERE id_propietario = ?";
        stmt = conn.prepareStatement(sqlTotalPropiedades);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            totalPropiedades = rs.getInt("total");
            propiedadesActivas = rs.getInt("activas");
            propiedadesDestacadas = rs.getInt("destacadas");
        }
        rs.close();
        stmt.close();
        
        // Estadísticas por tipo de propiedad
        String sqlTipos = "SELECT tp.nombre_tipo, COUNT(p.id_propiedad) as cantidad " +
                         "FROM tipos_propiedad tp " +
                         "LEFT JOIN propiedades p ON tp.id_tipo = p.id_tipo AND p.id_propietario = ? AND p.disponible = 1 " +
                         "GROUP BY tp.id_tipo, tp.nombre_tipo " +
                         "ORDER BY cantidad DESC";
        stmt = conn.prepareStatement(sqlTipos);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> tipo = new HashMap<>();
            tipo.put("nombre_tipo", rs.getString("nombre_tipo"));
            tipo.put("cantidad", rs.getInt("cantidad"));
            estadisticasTipos.add(tipo);
        }
        rs.close();
        stmt.close();
        
        // =====================================================
        // 2. ESTADÍSTICAS DE CITAS
        // =====================================================
        
        String sqlCitas = "SELECT COUNT(*) as total, " +
                         "SUM(CASE WHEN estado = 'PENDIENTE' THEN 1 ELSE 0 END) as pendientes, " +
                         "SUM(CASE WHEN estado = 'CONFIRMADA' THEN 1 ELSE 0 END) as confirmadas, " +
                         "SUM(CASE WHEN DATE(fecha_cita) = CURDATE() AND estado IN ('PENDIENTE', 'CONFIRMADA') THEN 1 ELSE 0 END) as hoy " +
                         "FROM citas c " +
                         "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                         "WHERE p.id_propietario = ?";
        stmt = conn.prepareStatement(sqlCitas);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            totalCitas = rs.getInt("total");
            citasPendientes = rs.getInt("pendientes");
            citasConfirmadas = rs.getInt("confirmadas");
            citasHoy = rs.getInt("hoy");
        }
        rs.close();
        stmt.close();
        
        // =====================================================
        // 3. PROPIEDADES RECIENTES (últimas 5)
        // =====================================================
        
        String sqlPropiedadesRecientes = "SELECT p.*, tp.nombre_tipo " +
                                        "FROM propiedades p " +
                                        "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                                        "WHERE p.id_propietario = ? " +
                                        "ORDER BY p.fecha_publicacion DESC " +
                                        "LIMIT 5";
        stmt = conn.prepareStatement(sqlPropiedadesRecientes);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id_propiedad", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("disponible", rs.getBoolean("disponible"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("fecha_publicacion", rs.getTimestamp("fecha_publicacion"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedadesRecientes.add(propiedad);
        }
        rs.close();
        stmt.close();
        
        // =====================================================
        // 4. CITAS PRÓXIMAS (próximas 5)
        // =====================================================
        
        String sqlCitasProximas = "SELECT c.*, p.titulo as propiedad_titulo, p.direccion, p.ciudad, " +
                                 "u.nombre as cliente_nombre, u.apellido as cliente_apellido, " +
                                 "u.email as cliente_email, u.telefono as cliente_telefono " +
                                 "FROM citas c " +
                                 "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                 "INNER JOIN usuarios u ON c.id_cliente = u.id_usuario " +
                                 "WHERE p.id_propietario = ? AND c.estado IN ('PENDIENTE', 'CONFIRMADA') " +
                                 "AND c.fecha_cita >= NOW() " +
                                 "ORDER BY c.fecha_cita ASC " +
                                 "LIMIT 5";
        stmt = conn.prepareStatement(sqlCitasProximas);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> cita = new HashMap<>();
            cita.put("id_cita", rs.getInt("id_cita"));
            cita.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            cita.put("estado", rs.getString("estado"));
            cita.put("notas", rs.getString("notas"));
            cita.put("telefono_contacto", rs.getString("telefono_contacto"));
            cita.put("propiedad_titulo", rs.getString("propiedad_titulo"));
            cita.put("direccion", rs.getString("direccion"));
            cita.put("ciudad", rs.getString("ciudad"));
            cita.put("cliente_nombre", rs.getString("cliente_nombre"));
            cita.put("cliente_apellido", rs.getString("cliente_apellido"));
            cita.put("cliente_email", rs.getString("cliente_email"));
            cita.put("cliente_telefono", rs.getString("cliente_telefono"));
            citasProximas.add(cita);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar información: " + e.getMessage();
        tipoMensaje = "error";
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Dashboard Inmobiliaria" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="dashboard" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado de bienvenida -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h2 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-building mr-2"></i>Bienvenido, <%= nombreUsuario %> <%= apellidoUsuario %>
                                    </h2>
                                    <p class="text-muted mb-0">
                                        Panel de control para gestionar tus propiedades y citas
                                    </p>
                                    <small class="text-muted">
                                        <i class="fas fa-clock mr-1"></i>Última conexión: <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new java.util.Date()) %>
                                    </small>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="../properties/nuevaPropiedad.jsp" class="btn text-white mr-2" style="background-color: var(--vino);">
                                        <i class="fas fa-plus mr-1"></i>Nueva Propiedad
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
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
            
            <!-- Estadísticas principales -->
            <div class="row mb-4">
                <div class="col-lg-3 col-md-6">
                    <div class="card text-white bg-primary shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Total Propiedades</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= totalPropiedades %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-home fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6">
                    <div class="card text-white bg-success shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Activas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= propiedadesActivas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-check-circle fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6">
                    <div class="card text-white bg-warning shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Destacadas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= propiedadesDestacadas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-star fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6">
                    <div class="card text-white bg-info shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Total Citas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= totalCitas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-calendar-alt fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Estadísticas de citas -->
            <div class="row mb-4">
                <div class="col-lg-4">
                    <div class="card border-left-warning shadow">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-warning text-uppercase mb-1">Citas Pendientes</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800"><%= citasPendientes %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-clock fa-2x text-warning"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-4">
                    <div class="card border-left-success shadow">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-success text-uppercase mb-1">Confirmadas</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800"><%= citasConfirmadas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-check-circle fa-2x text-success"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-4">
                    <div class="card border-left-danger shadow">
                        <div class="card-body">
                            <div class="row no-gutters align-items-center">
                                <div class="col mr-2">
                                    <div class="text-xs font-weight-bold text-danger text-uppercase mb-1">Citas Hoy</div>
                                    <div class="h5 mb-0 font-weight-bold text-gray-800"><%= citasHoy %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-calendar-day fa-2x text-danger"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Contenido principal en dos columnas -->
            <div class="row">
                
                <!-- Columna izquierda -->
                <div class="col-lg-8">
                    
                    <!-- Propiedades recientes -->
                    <div class="card shadow mb-4">
                        <div class="card-header py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                    <i class="fas fa-home mr-2"></i>Propiedades Recientes
                                </h6>
                                <a href="../inmobiliaria/misPropiedades.jsp" class="btn btn-sm btn-primary">
                                    Ver todas
                                </a>
                            </div>
                        </div>
                        <div class="card-body">
                            <% if (propiedadesRecientes.isEmpty()) { %>
                                <div class="text-center py-3">
                                    <i class="fas fa-home fa-3x text-muted mb-3"></i>
                                    <h5 class="text-muted">No tienes propiedades registradas</h5>
                                    <p class="text-muted">Comienza agregando tu primera propiedad</p>
                                    <a href="../properties/nuevaPropiedad.jsp" class="btn btn-primary">
                                        <i class="fas fa-plus mr-1"></i>Agregar Propiedad
                                    </a>
                                </div>
                            <% } else { %>
                                <div class="table-responsive">
                                    <table class="table table-sm">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>Propiedad</th>
                                                <th>Precio</th>
                                                <th>Estado</th>
                                                <th>Publicada</th>
                                                <th>Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> prop : propiedadesRecientes) { %>
                                                <tr>
                                                    <td>
                                                        <div>
                                                            <strong><%= prop.get("titulo") %></strong><br>
                                                            <small class="text-muted">
                                                                <i class="fas fa-map-marker-alt mr-1"></i>
                                                                <%= prop.get("direccion") %>, <%= prop.get("ciudad") %>
                                                            </small><br>
                                                            <span class="badge badge-info badge-sm"><%= prop.get("nombre_tipo") %></span>
                                                            <span class="badge badge-secondary badge-sm">
                                                                <%= ((String)prop.get("tipo_operacion")).replace("_", "/") %>
                                                            </span>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <strong class="text-success">
                                                            $<%= String.format("%,d", (Long)prop.get("precio")) %>
                                                        </strong>
                                                    </td>
                                                    <td>
                                                        <% if ((Boolean)prop.get("disponible")) { %>
                                                            <span class="badge badge-success">Activa</span>
                                                        <% } else { %>
                                                            <span class="badge badge-secondary">Inactiva</span>
                                                        <% } %>
                                                        
                                                        <% if ((Boolean)prop.get("destacada")) { %>
                                                            <br><span class="badge badge-warning badge-sm mt-1">
                                                                <i class="fas fa-star mr-1"></i>Destacada
                                                            </span>
                                                        <% } %>
                                                    </td>
                                                    <td>
                                                        <small>
                                                            <%= new SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)prop.get("fecha_publicacion")) %>
                                                        </small>
                                                    </td>
                                                    <td>
                                                        <div class="btn-group btn-group-sm">
                                                            <a href="../properties/verPropiedad.jsp?id=<%= prop.get("id_propiedad") %>" 
                                                               class="btn btn-outline-info">
                                                                <i class="fas fa-eye"></i>
                                                            </a>
                                                            <a href="../properties/editarPropiedad.jsp?id=<%= prop.get("id_propiedad") %>" 
                                                               class="btn btn-outline-primary">
                                                                <i class="fas fa-edit"></i>
                                                            </a>
                                                        </div>
                                                    </td>
                                                </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            <% } %>
                        </div>
                    </div>
                    
                </div>
                
                <!-- Columna derecha -->
                <div class="col-lg-4">
                    
                    <!-- Estadísticas por tipo -->
                    <div class="card shadow mb-4">
                        <div class="card-header py-3">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-chart-pie mr-2"></i>Propiedades por Tipo
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (estadisticasTipos.isEmpty() || propiedadesActivas == 0) { %>
                                <div class="text-center py-3">
                                    <i class="fas fa-chart-pie fa-2x text-muted mb-2"></i>
                                    <p class="text-muted">No hay datos disponibles</p>
                                </div>
                            <% } else { %>
                                <% for (Map<String, Object> tipo : estadisticasTipos) { 
                                    int cantidad = (Integer)tipo.get("cantidad");
                                    if (cantidad > 0) {
                                        double porcentaje = (cantidad * 100.0) / propiedadesActivas;
                                %>
                                    <div class="mb-3">
                                        <div class="d-flex justify-content-between">
                                            <span><%= tipo.get("nombre_tipo") %></span>
                                            <span><%= cantidad %> (<%= String.format("%.1f", porcentaje) %>%)</span>
                                        </div>
                                        <div class="progress" style="height: 8px;">
                                            <div class="progress-bar" role="progressbar" 
                                                style="<%= "width:" + porcentaje + "%; background-color: var(--vino);" %>"></div>
                                        </div>
                                    </div>
                                <% } } %>
                            <% } %>
                        </div>
                    </div>
                    
                    <!-- Citas próximas -->
                    <div class="card shadow">
                        <div class="card-header py-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                    <i class="fas fa-calendar-alt mr-2"></i>Próximas Citas
                                </h6>
                                <a href="../citas/citas.jsp" class="btn btn-sm btn-primary">
                                    Ver todas
                                </a>
                            </div>
                        </div>
                        <div class="card-body">
                            <% if (citasProximas.isEmpty()) { %>
                                <div class="text-center py-3">
                                    <i class="fas fa-calendar-times fa-2x text-muted mb-2"></i>
                                    <p class="text-muted">No hay citas próximas</p>
                                </div>
                            <% } else { %>
                                <% for (Map<String, Object> cita : citasProximas) { %>
                                    <div class="border-left-primary shadow-sm p-3 mb-3" style="border-left: 4px solid var(--vino) !important;">
                                        <div class="d-flex justify-content-between align-items-start">
                                            <div class="flex-grow-1">
                                                <h6 class="mb-1"><%= cita.get("propiedad_titulo") %></h6>
                                                <div class="small text-muted mb-2">
                                                    <i class="fas fa-map-marker-alt mr-1"></i>
                                                    <%= cita.get("direccion") %>, <%= cita.get("ciudad") %>
                                                </div>
                                                <div class="small mb-2">
                                                    <strong>Cliente:</strong> <%= cita.get("cliente_nombre") %> <%= cita.get("cliente_apellido") %><br>
                                                    <i class="fas fa-envelope mr-1"></i><%= cita.get("cliente_email") %>
                                                    <% if (cita.get("cliente_telefono") != null) { %>
                                                        <br><i class="fas fa-phone mr-1"></i><%= cita.get("cliente_telefono") %>
                                                    <% } %>
                                                </div>
                                                <div class="small">
                                                    <i class="fas fa-clock mr-1"></i>
                                                    <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format((java.util.Date)cita.get("fecha_cita")) %>
                                                    <span class="badge badge-<%= "PENDIENTE".equals(cita.get("estado")) ? "warning" : "success" %> badge-sm ml-2">
                                                        <%= cita.get("estado") %>
                                                    </span>
                                                </div>
                                            </div>
                                        </div>
                                        
                                        <% if ("PENDIENTE".equals(cita.get("estado"))) { %>
                                            <div class="mt-2">
                                                <form method="POST" action="../citas/citas.jsp" style="display: inline;">
                                                    <input type="hidden" name="accion" value="confirmar">
                                                    <input type="hidden" name="cita_id" value="<%= cita.get("id_cita") %>">
                                                    <button type="submit" class="btn btn-success btn-sm" 
                                                            onclick="return confirm('¿Confirmar esta cita?')">
                                                        <i class="fas fa-check mr-1"></i>Confirmar
                                                    </button>
                                                </form>
                                            </div>
                                        <% } %>
                                    </div>
                                <% } %>
                            <% } %>
                        </div>
                    </div>
                    
                </div>
            </div>
            
            <!-- Acciones rápidas -->
            <div class="row mt-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-rocket mr-2"></i>Acciones Rápidas
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-lg-3 col-md-6 mb-3">
                                    <a href="../properties/nuevaPropiedad.jsp" class="btn btn-outline-primary btn-block">
                                        <i class="fas fa-plus-circle mb-2 d-block fa-2x"></i>
                                        <strong>Nueva Propiedad</strong><br>
                                        <small>Agregar propiedad al catálogo</small>
                                    </a>
                                </div>
                                <div class="col-lg-3 col-md-6 mb-3">
                                    <a href="../inmobiliaria/misPropiedades.jsp" class="btn btn-outline-success btn-block">
                                        <i class="fas fa-home mb-2 d-block fa-2x"></i>
                                        <strong>Mis Propiedades</strong><br>
                                        <small>Gestionar mi inventario</small>
                                    </a>
                                </div>
                                <div class="col-lg-3 col-md-6 mb-3">
                                    <a href="../citas/citas.jsp" class="btn btn-outline-warning btn-block">
                                        <i class="fas fa-calendar-alt mb-2 d-block fa-2x"></i>
                                        <strong>Ver Citas</strong><br>
                                        <small>Administrar citas recibidas</small>
                                    </a>
                                </div>
                                <div class="col-lg-3 col-md-6 mb-3">
                                    <a href="../inmobiliaria/perfil.jsp" class="btn btn-outline-info btn-block">
                                        <i class="fas fa-user-cog mb-2 d-block fa-2x"></i>
                                        <strong>Mi Perfil</strong><br>
                                        <small>Actualizar información</small>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Alertas importantes -->
            <% if (citasPendientes > 0) { %>
                <div class="row mt-4">
                    <div class="col-12">
                        <div class="alert alert-warning alert-dismissible fade show" role="alert">
                            <i class="fas fa-exclamation-triangle mr-2"></i>
                            <strong>¡Atención!</strong> Tienes <%= citasPendientes %> cita<%= citasPendientes > 1 ? "s" : "" %> pendiente<%= citasPendientes > 1 ? "s" : "" %> de confirmar.
                            <a href="../citas/citas.jsp?estado=PENDIENTE" class="alert-link">Ver citas pendientes</a>
                            <button type="button" class="close" data-dismiss="alert">
                                <span>&times;</span>
                            </button>
                        </div>
                    </div>
                </div>
            <% } %>
            
            <% if (citasHoy > 0) { %>
                <div class="row mt-2">
                    <div class="col-12">
                        <div class="alert alert-info alert-dismissible fade show" role="alert">
                            <i class="fas fa-calendar-day mr-2"></i>
                            <strong>Hoy:</strong> Tienes <%= citasHoy %> cita<%= citasHoy > 1 ? "s" : "" %> programada<%= citasHoy > 1 ? "s" : "" %> para hoy.
                            <a href="../citas/citas.jsp" class="alert-link">Ver agenda del día</a>
                            <button type="button" class="close" data-dismiss="alert">
                                <span>&times;</span>
                            </button>
                        </div>
                    </div>
                </div>
            <% } %>
            
            <!-- Tips y consejos -->
            <div class="row mt-4 mb-4">
                <div class="col-12">
                    <div class="card border-left-success shadow">
                        <div class="card-header bg-light">
                            <h6 class="m-0 font-weight-bold text-success">
                                <i class="fas fa-lightbulb mr-2"></i>Consejos para Maximizar tus Ventas
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <div class="mb-3">
                                        <i class="fas fa-camera text-primary mr-2"></i>
                                        <strong>Fotos de Calidad</strong><br>
                                        <small class="text-muted">Sube fotos profesionales y bien iluminadas de tus propiedades</small>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="mb-3">
                                        <i class="fas fa-star text-warning mr-2"></i>
                                        <strong>Destaca Propiedades</strong><br>
                                        <small class="text-muted">Marca como destacadas tus mejores propiedades para mayor visibilidad</small>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="mb-3">
                                        <i class="fas fa-clock text-info mr-2"></i>
                                        <strong>Responde Rápido</strong><br>
                                        <small class="text-muted">Confirma las citas rápidamente para no perder clientes potenciales</small>
                                    </div>
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
    transition: transform 0.2s;
}

.card:hover {
    transform: translateY(-2px);
}

.border-left-primary {
    border-left: 4px solid var(--vino) !important;
}

.border-left-success {
    border-left: 4px solid #28a745 !important;
}

.border-left-warning {
    border-left: 4px solid #ffc107 !important;
}

.border-left-danger {
    border-left: 4px solid #dc3545 !important;
}

.text-xs {
    font-size: 0.75rem;
}

.progress-bar {
    background-color: var(--vino) !important;
}

.btn-outline-primary:hover,
.btn-outline-success:hover,
.btn-outline-warning:hover,
.btn-outline-info:hover {
    transform: scale(1.02);
    transition: transform 0.2s;
}

.alert {
    border-radius: 10px;
}

@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .h3 {
        font-size: 1.5rem;
    }
    
    .fa-2x {
        font-size: 1.5em !important;
    }
    
    .table-responsive {
        font-size: 0.875rem;
    }
}

/* Animaciones sutiles */
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translate3d(0, 40px, 0);
    }
    to {
        opacity: 1;
        transform: translate3d(0, 0, 0);
    }
}

.card {
    animation: fadeInUp 0.5s ease-out;
}

/* Efectos hover para las estadísticas */
.bg-primary:hover,
.bg-success:hover,
.bg-warning:hover,
.bg-info:hover {
    opacity: 0.9;
    transform: translateY(-1px);
    transition: all 0.2s;
}
</style>

<!-- JavaScript opcional para mejorar la experiencia -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Auto-ocultar alertas después de 8 segundos
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(alert => {
        setTimeout(() => {
            if (alert.parentNode) {
                alert.style.transition = 'opacity 0.5s';
                alert.style.opacity = '0';
                setTimeout(() => {
                    if (alert.parentNode) {
                        alert.remove();
                    }
                }, 500);
            }
        }, 8000);
    });
    
    // Efectos de hover para las tarjetas de estadísticas
    const statCards = document.querySelectorAll('.bg-primary, .bg-success, .bg-warning, .bg-info');
    statCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.cursor = 'pointer';
        });
    });
    
    // Tooltip para información adicional
    $('[data-toggle="tooltip"]').tooltip();
});

// Función para actualizar la hora actual
function actualizarHora() {
    const ahora = new Date();
    const horaFormateada = ahora.toLocaleString('es-CO', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
    
    const elementoHora = document.querySelector('.ultima-conexion');
    if (elementoHora) {
        elementoHora.textContent = 'Última conexión: ' + horaFormateada;
    }
}

// Actualizar la hora cada minuto
setInterval(actualizarHora, 60000);
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />