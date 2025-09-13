<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null || !"INMOBILIARIA".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Parámetros de filtro y paginación
    String filtroEstado = request.getParameter("estado");
    String filtroPropiedad = request.getParameter("propiedad");
    String filtroFecha = request.getParameter("fecha");
    String busqueda = request.getParameter("busqueda");
    
    int paginaActual = 1;
    int solicitudesPorPagina = 10;
    
    try {
        if (request.getParameter("pagina") != null) {
            paginaActual = Integer.parseInt(request.getParameter("pagina"));
        }
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * solicitudesPorPagina;
    
    // Variables para datos
    List<Map<String, Object>> solicitudes = new ArrayList<>();
    List<Map<String, Object>> propiedadesUsuario = new ArrayList<>();
    int totalSolicitudes = 0;
    int totalPaginas = 0;
    int pendientes = 0;
    int confirmadas = 0;
    int realizadas = 0;
    int canceladas = 0;
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones
    String accion = request.getParameter("accion");
    if (accion != null) {
        Connection connAccion = null;
        PreparedStatement stmtAccion = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            connAccion = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("actualizar_estado".equals(accion)) {
                int citaId = Integer.parseInt(request.getParameter("cita_id"));
                String nuevoEstado = request.getParameter("nuevo_estado");
                String notas = request.getParameter("notas");
                
                // Verificar que la cita pertenece a una propiedad del usuario
                String sqlVerificar = "SELECT c.id_cita FROM citas c " +
                                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                     "WHERE c.id_cita = ? AND p.id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, citaId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    String sqlActualizar = "UPDATE citas SET estado = ?, notas = ? WHERE id_cita = ?";
                    stmtAccion = connAccion.prepareStatement(sqlActualizar);
                    stmtAccion.setString(1, nuevoEstado);
                    stmtAccion.setString(2, notas != null && !notas.trim().isEmpty() ? notas.trim() : null);
                    stmtAccion.setInt(3, citaId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        String estadoTexto = "";
                        switch(nuevoEstado) {
                            case "CONFIRMADA": estadoTexto = "confirmada"; break;
                            case "REALIZADA": estadoTexto = "marcada como realizada"; break;
                            case "CANCELADA": estadoTexto = "cancelada"; break;
                            default: estadoTexto = "actualizada"; break;
                        }
                        mensaje = "Cita " + estadoTexto + " correctamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al actualizar el estado de la cita.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para modificar esta cita.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
                
            } else if ("eliminar_cita".equals(accion)) {
                int citaId = Integer.parseInt(request.getParameter("cita_id"));
                
                // Verificar que la cita pertenece a una propiedad del usuario
                String sqlVerificar = "SELECT c.id_cita FROM citas c " +
                                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                     "WHERE c.id_cita = ? AND p.id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, citaId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    String sqlEliminar = "DELETE FROM citas WHERE id_cita = ?";
                    stmtAccion = connAccion.prepareStatement(sqlEliminar);
                    stmtAccion.setInt(1, citaId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Cita eliminada correctamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al eliminar la cita.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para eliminar esta cita.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
            }
            
        } catch (Exception e) {
            mensaje = "Error al procesar la acción: " + e.getMessage();
            tipoMensaje = "error";
        } finally {
            if (stmtAccion != null) try { stmtAccion.close(); } catch (SQLException e) {}
            if (connAccion != null) try { connAccion.close(); } catch (SQLException e) {}
        }
    }
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Cargar propiedades del usuario para filtros
        String sqlPropiedades = "SELECT id_propiedad, titulo FROM propiedades WHERE id_propietario = ? ORDER BY titulo";
        stmt = conn.prepareStatement(sqlPropiedades);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id_propiedad", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedadesUsuario.add(propiedad);
        }
        rs.close();
        stmt.close();
        
        // Estadísticas generales
        String sqlEstadisticas = "SELECT " +
                                "COUNT(*) as total, " +
                                "SUM(CASE WHEN estado = 'PENDIENTE' THEN 1 ELSE 0 END) as pendientes, " +
                                "SUM(CASE WHEN estado = 'CONFIRMADA' THEN 1 ELSE 0 END) as confirmadas, " +
                                "SUM(CASE WHEN estado = 'REALIZADA' THEN 1 ELSE 0 END) as realizadas, " +
                                "SUM(CASE WHEN estado = 'CANCELADA' THEN 1 ELSE 0 END) as canceladas " +
                                "FROM citas c " +
                                "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                "WHERE p.id_propietario = ?";
        stmt = conn.prepareStatement(sqlEstadisticas);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            totalSolicitudes = rs.getInt("total");
            pendientes = rs.getInt("pendientes");
            confirmadas = rs.getInt("confirmadas");
            realizadas = rs.getInt("realizadas");
            canceladas = rs.getInt("canceladas");
        }
        rs.close();
        stmt.close();
        
        // Construir consulta con filtros
        StringBuilder sqlBase = new StringBuilder();
        sqlBase.append("FROM citas c ");
        sqlBase.append("INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad ");
        sqlBase.append("INNER JOIN usuarios u ON c.id_cliente = u.id_usuario ");
        sqlBase.append("WHERE p.id_propietario = ? ");
        
        List<Object> parametros = new ArrayList<>();
        parametros.add(usuarioId);
        
        // Aplicar filtros
        if (filtroEstado != null && !filtroEstado.trim().isEmpty()) {
            sqlBase.append("AND c.estado = ? ");
            parametros.add(filtroEstado);
        }
        
        if (filtroPropiedad != null && !filtroPropiedad.trim().isEmpty()) {
            sqlBase.append("AND c.id_propiedad = ? ");
            parametros.add(Integer.parseInt(filtroPropiedad));
        }
        
        if (filtroFecha != null && !filtroFecha.trim().isEmpty()) {
            switch(filtroFecha) {
                case "hoy":
                    sqlBase.append("AND DATE(c.fecha_cita) = CURDATE() ");
                    break;
                case "semana":
                    sqlBase.append("AND c.fecha_cita BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY) ");
                    break;
                case "mes":
                    sqlBase.append("AND c.fecha_cita BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY) ");
                    break;
                case "pasadas":
                    sqlBase.append("AND c.fecha_cita < NOW() ");
                    break;
            }
        }
        
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            sqlBase.append("AND (u.nombre LIKE ? OR u.apellido LIKE ? OR u.email LIKE ? OR p.titulo LIKE ?) ");
            parametros.add("%" + busqueda + "%");
            parametros.add("%" + busqueda + "%");
            parametros.add("%" + busqueda + "%");
            parametros.add("%" + busqueda + "%");
        }
        
        // Contar total con filtros
        String sqlCount = "SELECT COUNT(*) " + sqlBase.toString();
        stmt = conn.prepareStatement(sqlCount);
        for (int i = 0; i < parametros.size(); i++) {
            stmt.setObject(i + 1, parametros.get(i));
        }
        
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalSolicitudes = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        totalPaginas = (int) Math.ceil((double) totalSolicitudes / solicitudesPorPagina);
        
        // Obtener solicitudes con paginación
        StringBuilder sqlSolicitudes = new StringBuilder();
        sqlSolicitudes.append("SELECT c.*, p.titulo as propiedad_titulo, p.direccion, p.ciudad, ");
        sqlSolicitudes.append("u.nombre as cliente_nombre, u.apellido as cliente_apellido, ");
        sqlSolicitudes.append("u.email as cliente_email, u.telefono as cliente_telefono ");
        sqlSolicitudes.append(sqlBase.toString());
        sqlSolicitudes.append("ORDER BY c.fecha_solicitud DESC ");
        sqlSolicitudes.append("LIMIT ? OFFSET ?");
        
        stmt = conn.prepareStatement(sqlSolicitudes.toString());
        
        int paramIndex = 1;
        for (Object param : parametros) {
            stmt.setObject(paramIndex++, param);
        }
        stmt.setInt(paramIndex++, solicitudesPorPagina);
        stmt.setInt(paramIndex, offset);
        
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> solicitud = new HashMap<>();
            solicitud.put("id_cita", rs.getInt("id_cita"));
            solicitud.put("id_propiedad", rs.getInt("id_propiedad"));
            solicitud.put("id_cliente", rs.getInt("id_cliente"));
            solicitud.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            solicitud.put("estado", rs.getString("estado"));
            solicitud.put("notas", rs.getString("notas"));
            solicitud.put("telefono_contacto", rs.getString("telefono_contacto"));
            solicitud.put("fecha_solicitud", rs.getTimestamp("fecha_solicitud"));
            solicitud.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
            solicitud.put("propiedad_titulo", rs.getString("propiedad_titulo"));
            solicitud.put("direccion", rs.getString("direccion"));
            solicitud.put("ciudad", rs.getString("ciudad"));
            solicitud.put("cliente_nombre", rs.getString("cliente_nombre"));
            solicitud.put("cliente_apellido", rs.getString("cliente_apellido"));
            solicitud.put("cliente_email", rs.getString("cliente_email"));
            solicitud.put("cliente_telefono", rs.getString("cliente_telefono"));
            solicitudes.add(solicitud);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        if (mensaje.isEmpty()) {
            mensaje = "Error al cargar las solicitudes: " + e.getMessage();
            tipoMensaje = "error";
        }
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Solicitudes - Inmobiliaria" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="solicitudes" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h2 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-inbox mr-2"></i>Solicitudes de Citas
                                    </h2>
                                    <p class="text-muted mb-0">
                                        Gestiona las solicitudes de visitas a tus propiedades
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <span class="text-muted mr-3">
                                        Total: <strong><%= totalSolicitudes %></strong> solicitudes
                                    </span>
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
            
            <!-- Estadísticas -->
            <div class="row mb-4">
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white bg-warning shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Pendientes</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= pendientes %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-clock fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white bg-success shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Confirmadas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= confirmadas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-check-circle fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white bg-info shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Realizadas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= realizadas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-handshake fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white bg-secondary shadow">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <div class="text-xs font-weight-bold text-uppercase mb-1">Canceladas</div>
                                    <div class="h3 mb-0 font-weight-bold"><%= canceladas %></div>
                                </div>
                                <div class="col-auto">
                                    <i class="fas fa-times-circle fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filtros -->
            <div class="card shadow mb-4">
                <div class="card-header">
                    <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                        <i class="fas fa-filter mr-2"></i>Filtros y Búsqueda
                    </h6>
                </div>
                <div class="card-body">
                    <form method="GET" action="solicitudes.jsp">
                        <div class="row">
                            <div class="col-md-3">
                                <label for="busqueda" class="form-label">Buscar</label>
                                <input type="text" class="form-control form-control-sm" id="busqueda" name="busqueda" 
                                       value="<%= busqueda != null ? busqueda : "" %>" 
                                       placeholder="Cliente, email, propiedad...">
                            </div>
                            
                            <div class="col-md-2">
                                <label for="estado" class="form-label">Estado</label>
                                <select class="form-control form-control-sm" id="estado" name="estado">
                                    <option value="">Todos</option>
                                    <option value="PENDIENTE" <%= "PENDIENTE".equals(filtroEstado) ? "selected" : "" %>>Pendiente</option>
                                    <option value="CONFIRMADA" <%= "CONFIRMADA".equals(filtroEstado) ? "selected" : "" %>>Confirmada</option>
                                    <option value="REALIZADA" <%= "REALIZADA".equals(filtroEstado) ? "selected" : "" %>>Realizada</option>
                                    <option value="CANCELADA" <%= "CANCELADA".equals(filtroEstado) ? "selected" : "" %>>Cancelada</option>
                                </select>
                            </div>
                            
                            <div class="col-md-3">
                                <label for="propiedad" class="form-label">Propiedad</label>
                                <select class="form-control form-control-sm" id="propiedad" name="propiedad">
                                    <option value="">Todas</option>
                                    <% for (Map<String, Object> prop : propiedadesUsuario) { %>
                                        <option value="<%= prop.get("id_propiedad") %>" 
                                                <%= String.valueOf(prop.get("id_propiedad")).equals(filtroPropiedad) ? "selected" : "" %>>
                                            <%= prop.get("titulo") %>
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div class="col-md-2">
                                <label for="fecha" class="form-label">Período</label>
                                <select class="form-control form-control-sm" id="fecha" name="fecha">
                                    <option value="">Todas</option>
                                    <option value="hoy" <%= "hoy".equals(filtroFecha) ? "selected" : "" %>>Hoy</option>
                                    <option value="semana" <%= "semana".equals(filtroFecha) ? "selected" : "" %>>Esta semana</option>
                                    <option value="mes" <%= "mes".equals(filtroFecha) ? "selected" : "" %>>Este mes</option>
                                    <option value="pasadas" <%= "pasadas".equals(filtroFecha) ? "selected" : "" %>>Pasadas</option>
                                </select>
                            </div>
                            
                            <div class="col-md-2">
                                <label class="form-label">&nbsp;</label>
                                <div>
                                    <button type="submit" class="btn btn-primary btn-sm">
                                        <i class="fas fa-search"></i> Buscar
                                    </button>
                                    <a href="solicitudes.jsp" class="btn btn-secondary btn-sm ml-1">
                                        <i class="fas fa-times"></i>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Lista de solicitudes -->
            <div class="row">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-list mr-2"></i>Solicitudes de Citas
                                <% if (totalSolicitudes > 0) { %>
                                    <span class="badge badge-secondary ml-2"><%= totalSolicitudes %></span>
                                <% } %>
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (solicitudes.isEmpty()) { %>
                                <div class="text-center py-5">
                                    <i class="fas fa-inbox fa-4x text-muted mb-4"></i>
                                    <h4 class="text-muted">No hay solicitudes</h4>
                                    <p class="text-muted mb-4">
                                        <% if (busqueda != null || filtroEstado != null || filtroPropiedad != null || filtroFecha != null) { %>
                                            No se encontraron solicitudes con los filtros aplicados.
                                        <% } else { %>
                                            Aún no has recibido solicitudes de citas para tus propiedades.
                                        <% } %>
                                    </p>
                                    <% if (busqueda != null || filtroEstado != null || filtroPropiedad != null || filtroFecha != null) { %>
                                        <a href="solicitudes.jsp" class="btn btn-primary">
                                            <i class="fas fa-times mr-1"></i>Limpiar Filtros
                                        </a>
                                    <% } %>
                                </div>
                            <% } else { %>
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>Cliente</th>
                                                <th>Propiedad</th>
                                                <th>Fecha/Hora Cita</th>
                                                <th>Estado</th>
                                                <th>Solicitud</th>
                                                <th>Acciones</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> solicitud : solicitudes) { %>
                                                <tr>
                                                    <td>
                                                        <div>
                                                            <strong><%= solicitud.get("cliente_nombre") %> <%= solicitud.get("cliente_apellido") %></strong><br>
                                                            <small class="text-muted">
                                                                <i class="fas fa-envelope mr-1"></i><%= solicitud.get("cliente_email") %>
                                                                <% if (solicitud.get("cliente_telefono") != null) { %>
                                                                    <br><i class="fas fa-phone mr-1"></i><%= solicitud.get("cliente_telefono") %>
                                                                <% } %>
                                                            </small>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <div>
                                                            <strong><%= solicitud.get("propiedad_titulo") %></strong><br>
                                                            <small class="text-muted">
                                                                <i class="fas fa-map-marker-alt mr-1"></i>
                                                                <%= solicitud.get("direccion") %>, <%= solicitud.get("ciudad") %>
                                                            </small>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <div>
                                                            <strong>
                                                                <%= new SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)solicitud.get("fecha_cita")) %>
                                                            </strong><br>
                                                            <small class="text-muted">
                                                                <%= new SimpleDateFormat("HH:mm").format((java.util.Date)solicitud.get("fecha_cita")) %>
                                                            </small>
                                                        </div>
                                                    </td>
                                                    <td>
                                                        <% 
                                                            String estado = (String)solicitud.get("estado");
                                                            String badgeClass = "";
                                                            String icono = "";
                                                            switch(estado) {
                                                                case "PENDIENTE":
                                                                    badgeClass = "badge-warning";
                                                                    icono = "clock";
                                                                    break;
                                                                case "CONFIRMADA":
                                                                    badgeClass = "badge-success";
                                                                    icono = "check-circle";
                                                                    break;
                                                                case "REALIZADA":
                                                                    badgeClass = "badge-info";
                                                                    icono = "handshake";
                                                                    break;
                                                                case "CANCELADA":
                                                                    badgeClass = "badge-secondary";
                                                                    icono = "times-circle";
                                                                    break;
                                                                default:
                                                                    badgeClass = "badge-light";
                                                                    icono = "question";
                                                            }
                                                        %>
                                                        <span class="badge <%= badgeClass %>">
                                                            <i class="fas fa-<%= icono %> mr-1"></i><%= estado %>
                                                        </span>
                                                    </td>
                                                    <td>
                                                        <small class="text-muted">
                                                            <%= new SimpleDateFormat("dd/MM/yy HH:mm").format((java.util.Date)solicitud.get("fecha_solicitud")) %>
                                                        </small>
                                                    </td>
                                                    <td>
                                                        <div class="btn-group-vertical btn-group-sm" role="group">
                                                            <a href="verSolicitud.jsp?id=<%= solicitud.get("id_cita") %>"
                                                                class="btn btn-outline-info btn-sm mb-1">
                                                                <i class="fas fa-eye"></i> Ver
                                                            </a>
                                                            
                                                            <% if ("PENDIENTE".equals(estado)) { %>
                                                                <form method="POST" action="solicitudes.jsp" style="display: inline;">
                                                                    <input type="hidden" name="accion" value="actualizar_estado">
                                                                    <input type="hidden" name="cita_id" value="<%= solicitud.get("id_cita") %>">
                                                                    <input type="hidden" name="nuevo_estado" value="CONFIRMADA">
                                                                    <button type="submit" class="btn btn-success btn-sm mb-1" 
                                                                            onclick="return confirm('¿Confirmar esta cita?')">
                                                                        <i class="fas fa-check"></i> Confirmar
                                                                    </button>
                                                                </form>
                                                                
                                                                <form method="POST" action="solicitudes.jsp" style="display: inline;">
                                                                    <input type="hidden" name="accion" value="actualizar_estado">
                                                                    <input type="hidden" name="cita_id" value="<%= solicitud.get("id_cita") %>">
                                                                    <input type="hidden" name="nuevo_estado" value="CANCELADA">
                                                                    <button type="submit" class="btn btn-outline-danger btn-sm mb-1" 
                                                                            onclick="return confirm('¿Cancelar esta cita?')">
                                                                        <i class="fas fa-times"></i> Cancelar
                                                                    </button>
                                                                </form>
                                                            <% } else if ("CONFIRMADA".equals(estado)) { %>
                                                                <form method="POST" action="solicitudes.jsp" style="display: inline;">
                                                                    <input type="hidden" name="accion" value="actualizar_estado">
                                                                    <input type="hidden" name="cita_id" value="<%= solicitud.get("id_cita") %>">
                                                                    <input type="hidden" name="nuevo_estado" value="REALIZADA">
                                                                    <button type="submit" class="btn btn-info btn-sm mb-1" 
                                                                            onclick="return confirm('¿Marcar como realizada?')">
                                                                        <i class="fas fa-handshake"></i> Realizada
                                                                    </button>
                                                                </form>
                                                            <% } %>
                                                        </div>
                                                    </td>
                                                </tr>
                                                
                                                <!-- Modal de detalles -->
                                                <div class="modal fade" id="modalDetalle<%= solicitud.get("id_cita") %>" tabindex="-1" role="dialog">
                                                    <div class="modal-dialog modal-lg" role="document">
                                                        <div class="modal-content">
                                                            <div class="modal-header">
                                                                <h5 class="modal-title">
                                                                    <i class="fas fa-info-circle mr-2"></i>Detalles de la Solicitud
                                                                </h5>
                                                                <button type="button" class="close" data-dismiss="modal">
                                                                    <span>&times;</span>
                                                                </button>
                                                            </div>
                                                            <div class="modal-body">
                                                                <div class="row">
                                                                    <div class="col-md-6">
                                                                        <h6 class="text-primary">Información del Cliente</h6>
                                                                        <p><strong>Nombre:</strong> <%= solicitud.get("cliente_nombre") %> <%= solicitud.get("cliente_apellido") %></p>
                                                                        <p><strong>Email:</strong> <%= solicitud.get("cliente_email") %></p>
                                                                        <% if (solicitud.get("cliente_telefono") != null) { %>
                                                                            <p><strong>Teléfono:</strong> <%= solicitud.get("cliente_telefono") %></p>
                                                                        <% } %>
                                                                    </div>
                                                                    <div class="col-md-6">
                                                                        <h6 class="text-success">Información de la Cita</h6>
                                                                        <p><strong>Propiedad:</strong> <%= solicitud.get("propiedad_titulo") %></p>
                                                                        <p><strong>Dirección:</strong> <%= solicitud.get("direccion") %>, <%= solicitud.get("ciudad") %></p>
                                                                        <p><strong>Fecha:</strong> <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format((java.util.Date)solicitud.get("fecha_cita")) %></p>
                                                                        <p><strong>Estado:</strong> 
                                                                            <span class="badge <%= badgeClass %>">
                                                                                <i class="fas fa-<%= icono %> mr-1"></i><%= estado %>
                                                                            </span>
                                                                        </p>
                                                                    </div>
                                                                </div>
                                                            </div>
                                                            <div class="modal-footer">
                                                                <a href="mailto:<%= solicitud.get("cliente_email") %>?subject=Cita para <%= solicitud.get("propiedad_titulo") %>" 
                                                                   class="btn btn-outline-primary">
                                                                    <i class="fas fa-envelope mr-1"></i>Enviar Email
                                                                </a>
                                                                <% if (solicitud.get("cliente_telefono") != null) { %>
                                                                    <a href="tel:<%= solicitud.get("cliente_telefono") %>" class="btn btn-outline-success">
                                                                        <i class="fas fa-phone mr-1"></i>Llamar
                                                                    </a>
                                                                <% } %>
                                                                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            <% } %>
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

.btn:hover {
    transform: translateY(-1px);
    transition: transform 0.2s;
}

.modal-content {
    border-radius: 10px;
}

.text-xs {
    font-size: 0.75rem;
}

.badge {
    font-size: 0.8rem;
    padding: 0.4rem 0.6rem;
}

.table tbody tr:hover {
    background-color: rgba(0,0,0,.075);
}

/* Efectos hover para estadísticas */
.bg-warning:hover,
.bg-success:hover,
.bg-info:hover,
.bg-secondary:hover {
    opacity: 0.9;
    transform: translateY(-1px);
    transition: all 0.2s;
    cursor: pointer;
}

/* Responsividad */
@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .table-responsive {
        font-size: 0.875rem;
    }
    
    .btn-group-vertical .btn {
        font-size: 0.75rem;
        padding: 0.25rem 0.5rem;
    }
}

/* Animaciones */
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translate3d(0, 30px, 0);
    }
    to {
        opacity: 1;
        transform: translate3d(0, 0, 0);
    }
}

.card {
    animation: fadeInUp 0.5s ease-out;
}
</style>

<!-- JavaScript -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Auto-ocultar alertas después de 5 segundos
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
        }, 5000);
    });
    
    // Función para filtrado rápido desde las estadísticas
    const statCards = document.querySelectorAll('.bg-warning, .bg-success, .bg-info, .bg-secondary');
    statCards.forEach((card, index) => {
        card.addEventListener('click', function() {
            const estados = ['PENDIENTE', 'CONFIRMADA', 'REALIZADA', 'CANCELADA'];
            if (index < estados.length) {
                document.getElementById('estado').value = estados[index];
                document.querySelector('form').submit();
            }
        });
        
        card.style.cursor = 'pointer';
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />