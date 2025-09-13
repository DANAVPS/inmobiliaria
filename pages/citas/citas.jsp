<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para datos
    List<Map<String, Object>> listaCitas = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    int totalCitas = 0;
    int citasPendientes = 0;
    int citasConfirmadas = 0;
    int citasRealizadas = 0;
    int citasCanceladas = 0;
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar acciones (actualizar estado de citas)
        String accion = request.getParameter("accion");
        String citaId = request.getParameter("cita_id");
        
        if ("POST".equals(request.getMethod()) && accion != null && citaId != null) {
            if ("confirmar".equals(accion) || "cancelar".equals(accion) || "realizar".equals(accion)) {
                String nuevoEstado = "";
                switch(accion) {
                    case "confirmar": nuevoEstado = "CONFIRMADA"; break;
                    case "cancelar": nuevoEstado = "CANCELADA"; break;
                    case "realizar": nuevoEstado = "REALIZADA"; break;
                }
                
                // Verificar permisos antes de actualizar
                boolean puedeActualizar = false;
                if ("ADMINISTRADOR".equals(usuarioRol)) {
                    puedeActualizar = true;
                } else if ("INMOBILIARIA".equals(usuarioRol)) {
                    // Solo puede actualizar citas de sus propiedades
                    String sqlVerificar = "SELECT c.id_cita FROM citas c " +
                                         "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                         "WHERE c.id_cita = ? AND p.id_propietario = ?";
                    stmt = conn.prepareStatement(sqlVerificar);
                    stmt.setInt(1, Integer.parseInt(citaId));
                    stmt.setInt(2, usuarioId);
                    rs = stmt.executeQuery();
                    puedeActualizar = rs.next();
                    rs.close();
                    stmt.close();
                } else if ("CLIENTE".equals(usuarioRol) && "cancelar".equals(accion)) {
                    // Solo puede cancelar sus propias citas
                    String sqlVerificar = "SELECT id_cita FROM citas WHERE id_cita = ? AND id_cliente = ?";
                    stmt = conn.prepareStatement(sqlVerificar);
                    stmt.setInt(1, Integer.parseInt(citaId));
                    stmt.setInt(2, usuarioId);
                    rs = stmt.executeQuery();
                    puedeActualizar = rs.next();
                    rs.close();
                    stmt.close();
                }
                
                if (puedeActualizar) {
                    String sqlUpdate = "UPDATE citas SET estado = ?, fecha_actualizacion = CURRENT_TIMESTAMP WHERE id_cita = ?";
                    stmt = conn.prepareStatement(sqlUpdate);
                    stmt.setString(1, nuevoEstado);
                    stmt.setInt(2, Integer.parseInt(citaId));
                    
                    int rowsUpdated = stmt.executeUpdate();
                    if (rowsUpdated > 0) {
                        mensaje = "Estado de la cita actualizado exitosamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al actualizar el estado de la cita.";
                        tipoMensaje = "error";
                    }
                    stmt.close();
                } else {
                    mensaje = "No tienes permisos para realizar esta acción.";
                    tipoMensaje = "error";
                }
            }
        }
        
        // Consulta base según el rol
        String sqlBase = "";
        String whereClause = "";
        
        if ("ADMINISTRADOR".equals(usuarioRol)) {
    // Admin ve todas las citas
    sqlBase = "SELECT c.*, p.titulo as propiedad_titulo, p.direccion, p.ciudad, p.precio, " +
             "p.imagen_principal, tp.nombre_tipo, " +
             "cliente.nombre as cliente_nombre, cliente.apellido as cliente_apellido, " +
             "cliente.email as cliente_email, cliente.telefono as cliente_telefono, " +
             "propietario.nombre as propietario_nombre, propietario.apellido as propietario_apellido, " +
             "propietario.email as propietario_email, propietario.telefono as propietario_telefono " +  // ← AGREGADO
             "FROM citas c " +
             "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
             "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
             "INNER JOIN usuarios cliente ON c.id_cliente = cliente.id_usuario " +
             "INNER JOIN usuarios propietario ON p.id_propietario = propietario.id_usuario ";
        } else if ("INMOBILIARIA".equals(usuarioRol)) {
            // Inmobiliaria ve citas de sus propiedades
            sqlBase = "SELECT c.*, p.titulo as propiedad_titulo, p.direccion, p.ciudad, p.precio, " +
                     "p.imagen_principal, tp.nombre_tipo, " +
                     "cliente.nombre as cliente_nombre, cliente.apellido as cliente_apellido, " +
                     "cliente.email as cliente_email, cliente.telefono as cliente_telefono " +
                     "FROM citas c " +
                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                     "INNER JOIN usuarios cliente ON c.id_cliente = cliente.id_usuario " +
                     "WHERE p.id_propietario = ? ";
        } else {
            // Cliente ve solo sus citas
            sqlBase = "SELECT c.*, p.titulo as propiedad_titulo, p.direccion, p.ciudad, p.precio, " +
                     "p.imagen_principal, tp.nombre_tipo, " +
                     "propietario.nombre as propietario_nombre, propietario.apellido as propietario_apellido, " +
                     "propietario.email as propietario_email, propietario.telefono as propietario_telefono " +
                     "FROM citas c " +
                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                     "INNER JOIN usuarios propietario ON p.id_propietario = propietario.id_usuario " +
                     "WHERE c.id_cliente = ? ";
        }
        
        // Filtros opcionales
        String filtroEstado = request.getParameter("estado");
        String filtroFecha = request.getParameter("fecha");
        
        if (filtroEstado != null && !filtroEstado.trim().isEmpty()) {
            sqlBase += ("ADMINISTRADOR".equals(usuarioRol) ? "WHERE " : "AND ") + "c.estado = ? ";
        }
        if (filtroFecha != null && !filtroFecha.trim().isEmpty()) {
            sqlBase += (sqlBase.contains("WHERE") ? "AND " : "WHERE ") + "DATE(c.fecha_cita) = ? ";
        }
        
        sqlBase += "ORDER BY c.fecha_cita DESC";
        
        // Ejecutar consulta principal
        stmt = conn.prepareStatement(sqlBase);
        int paramIndex = 1;
        
        if (!"ADMINISTRADOR".equals(usuarioRol)) {
            stmt.setInt(paramIndex++, usuarioId);
        }
        if (filtroEstado != null && !filtroEstado.trim().isEmpty()) {
            stmt.setString(paramIndex++, filtroEstado);
        }
        if (filtroFecha != null && !filtroFecha.trim().isEmpty()) {
            stmt.setString(paramIndex++, filtroFecha);
        }
        
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> cita = new HashMap<>();
            cita.put("id_cita", rs.getInt("id_cita"));
            cita.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            cita.put("estado", rs.getString("estado"));
            cita.put("notas", rs.getString("notas"));
            cita.put("telefono_contacto", rs.getString("telefono_contacto"));
            cita.put("fecha_solicitud", rs.getTimestamp("fecha_solicitud"));
            
            // Datos de la propiedad
            cita.put("propiedad_titulo", rs.getString("propiedad_titulo"));
            cita.put("direccion", rs.getString("direccion"));
            cita.put("ciudad", rs.getString("ciudad"));
            cita.put("precio", rs.getLong("precio"));
            cita.put("imagen_principal", rs.getString("imagen_principal"));
            cita.put("nombre_tipo", rs.getString("nombre_tipo"));
            
            // Datos según el rol
            if (!"CLIENTE".equals(usuarioRol)) {
                cita.put("cliente_nombre", rs.getString("cliente_nombre"));
                cita.put("cliente_apellido", rs.getString("cliente_apellido"));
                cita.put("cliente_email", rs.getString("cliente_email"));
                cita.put("cliente_telefono", rs.getString("cliente_telefono"));
            }
            
            if (!"INMOBILIARIA".equals(usuarioRol)) {
                cita.put("propietario_nombre", rs.getString("propietario_nombre"));
                cita.put("propietario_apellido", rs.getString("propietario_apellido"));
                cita.put("propietario_email", rs.getString("propietario_email"));
                cita.put("propietario_telefono", rs.getString("propietario_telefono"));
            }
            
            listaCitas.add(cita);
        }
        rs.close();
        stmt.close();
        
        // Calcular estadísticas
        String sqlEstadisticas = "";
        if ("ADMINISTRADOR".equals(usuarioRol)) {
            sqlEstadisticas = "SELECT estado, COUNT(*) as cantidad FROM citas GROUP BY estado";
            stmt = conn.prepareStatement(sqlEstadisticas);
        } else if ("INMOBILIARIA".equals(usuarioRol)) {
            sqlEstadisticas = "SELECT estado, COUNT(*) as cantidad FROM citas c " +
                             "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                             "WHERE p.id_propietario = ? GROUP BY estado";
            stmt = conn.prepareStatement(sqlEstadisticas);
            stmt.setInt(1, usuarioId);
        } else {
            sqlEstadisticas = "SELECT estado, COUNT(*) as cantidad FROM citas WHERE id_cliente = ? GROUP BY estado";
            stmt = conn.prepareStatement(sqlEstadisticas);
            stmt.setInt(1, usuarioId);
        }
        
        rs = stmt.executeQuery();
        while (rs.next()) {
            String estado = rs.getString("estado");
            int cantidad = rs.getInt("cantidad");
            totalCitas += cantidad;
            
            switch(estado) {
                case "PENDIENTE": citasPendientes = cantidad; break;
                case "CONFIRMADA": citasConfirmadas = cantidad; break;
                case "REALIZADA": citasRealizadas = cantidad; break;
                case "CANCELADA": citasCanceladas = cantidad; break;
            }
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar las citas: " + e.getMessage();
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
    <jsp:param name="title" value="Mis Citas" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar según el rol -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="citas" />
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
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-calendar-alt mr-2"></i>
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Mis Citas Programadas
                                        <% } else if ("INMOBILIARIA".equals(usuarioRol)) { %>
                                            Citas Recibidas
                                        <% } else { %>
                                            Gestión de Citas
                                        <% } %>
                                    </h3>
                                    <p class="text-muted mb-0">
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Gestiona las citas que has solicitado para visitar propiedades
                                        <% } else if ("INMOBILIARIA".equals(usuarioRol)) { %>
                                            Administra las citas para visitar tus propiedades
                                        <% } else { %>
                                            Vista completa de todas las citas del sistema
                                        <% } %>
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <% if ("CLIENTE".equals(usuarioRol)) { %>
                                        <a href="../citas/crearCita.jsp" class="btn text-white" style="background-color: var(--vino);">
                                            <i class="fas fa-plus mr-1"></i>Nueva Cita
                                        </a>
                                    <% } %>
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
                <div class="col-md-3">
                    <div class="card text-white bg-primary">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h4 class="mb-0"><%= totalCitas %></h4>
                                    <small>Total Citas</small>
                                </div>
                                <div class="align-self-center">
                                    <i class="fas fa-calendar-alt fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white bg-warning">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h4 class="mb-0"><%= citasPendientes %></h4>
                                    <small>Pendientes</small>
                                </div>
                                <div class="align-self-center">
                                    <i class="fas fa-clock fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white bg-success">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h4 class="mb-0"><%= citasConfirmadas %></h4>
                                    <small>Confirmadas</small>
                                </div>
                                <div class="align-self-center">
                                    <i class="fas fa-check-circle fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white bg-info">
                        <div class="card-body">
                            <div class="d-flex justify-content-between">
                                <div>
                                    <h4 class="mb-0"><%= citasRealizadas %></h4>
                                    <small>Realizadas</small>
                                </div>
                                <div class="align-self-center">
                                    <i class="fas fa-handshake fa-2x"></i>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Filtros -->
            <div class="card shadow mb-4">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-filter mr-2"></i>Filtros
                    </h6>
                </div>
                <div class="card-body">
                    <form method="GET" action="">
                        <div class="row">
                            <div class="col-md-4">
                                <label for="estado" class="form-label">Estado</label>
                                <select class="form-control" id="estado" name="estado">
                                    <option value="">Todos los estados</option>
                                    <option value="PENDIENTE" <%= "PENDIENTE".equals(request.getParameter("estado")) ? "selected" : "" %>>Pendiente</option>
                                    <option value="CONFIRMADA" <%= "CONFIRMADA".equals(request.getParameter("estado")) ? "selected" : "" %>>Confirmada</option>
                                    <option value="REALIZADA" <%= "REALIZADA".equals(request.getParameter("estado")) ? "selected" : "" %>>Realizada</option>
                                    <option value="CANCELADA" <%= "CANCELADA".equals(request.getParameter("estado")) ? "selected" : "" %>>Cancelada</option>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="fecha" class="form-label">Fecha</label>
                                <input type="date" class="form-control" id="fecha" name="fecha" 
                                       value="<%= request.getParameter("fecha") != null ? request.getParameter("fecha") : "" %>">
                            </div>
                            <div class="col-md-4 d-flex align-items-end">
                                <button type="submit" class="btn btn-primary mr-2">
                                    <i class="fas fa-search mr-1"></i>Filtrar
                                </button>
                                <a href="citas.jsp" class="btn btn-secondary">
                                    <i class="fas fa-times mr-1"></i>Limpiar
                                </a>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Lista de citas -->
            <div class="card shadow">
                <div class="card-header">
                    <h6 class="mb-0">
                        <i class="fas fa-list mr-2"></i>Lista de Citas (<%= listaCitas.size() %> encontradas)
                    </h6>
                </div>
                <div class="card-body">
                    <% if (listaCitas.isEmpty()) { %>
                        <div class="text-center py-5">
                            <i class="fas fa-calendar-times fa-3x text-muted mb-3"></i>
                            <h5 class="text-muted">No hay citas disponibles</h5>
                            <p class="text-muted">
                                <% if ("CLIENTE".equals(usuarioRol)) { %>
                                    Aún no has programado ninguna cita. <a href="../citas/crearCita.jsp">Crear primera cita</a>
                                <% } else { %>
                                    No se encontraron citas con los filtros aplicados.
                                <% } %>
                            </p>
                        </div>
                    <% } else { %>
                        <div class="table-responsive">
                            <table class="table table-hover">
                                <thead class="thead-light">
                                    <tr>
                                        <th>Propiedad</th>
                                        <% if (!"CLIENTE".equals(usuarioRol)) { %>
                                            <th>Cliente</th>
                                        <% } %>
                                        <% if (!"INMOBILIARIA".equals(usuarioRol)) { %>
                                            <th>Propietario</th>
                                        <% } %>
                                        <th>Fecha/Hora</th>
                                        <th>Estado</th>
                                        <th>Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <% for (Map<String, Object> cita : listaCitas) { %>
                                        <tr>
                                            <td>
                                                <div class="d-flex align-items-center">
                                                    <div class="mr-3">
                                                        <% if (cita.get("imagen_principal") != null) { %>
                                                            <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= cita.get("imagen_principal") %>" 
                                                                 alt="<%= cita.get("propiedad_titulo") %>" 
                                                                 class="rounded" style="width: 60px; height: 45px; object-fit: cover;"
                                                                 onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                                        <% } else { %>
                                                            <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                                                 alt="Sin imagen" class="rounded" style="width: 60px; height: 45px; object-fit: cover;">
                                                        <% } %>
                                                    </div>
                                                    <div>
                                                        <h6 class="mb-1"><%= cita.get("propiedad_titulo") %></h6>
                                                        <small class="text-muted">
                                                            <i class="fas fa-map-marker-alt mr-1"></i>
                                                            <%= cita.get("direccion") %>, <%= cita.get("ciudad") %>
                                                        </small><br>
                                                        <small class="text-success font-weight-bold">
                                                            $<%= String.format("%,d", (Long)cita.get("precio")) %>
                                                        </small>
                                                        <span class="badge badge-info badge-sm ml-1"><%= cita.get("nombre_tipo") %></span>
                                                    </div>
                                                </div>
                                            </td>
                                            
                                            <% if (!"CLIENTE".equals(usuarioRol)) { %>
                                                <td>
                                                    <div>
                                                        <strong><%= cita.get("cliente_nombre") %> <%= cita.get("cliente_apellido") %></strong><br>
                                                        <small class="text-muted">
                                                            <i class="fas fa-envelope mr-1"></i><%= cita.get("cliente_email") %>
                                                        </small><br>
                                                        <% if (cita.get("cliente_telefono") != null) { %>
                                                            <small class="text-muted">
                                                                <i class="fas fa-phone mr-1"></i><%= cita.get("cliente_telefono") %>
                                                            </small>
                                                        <% } %>
                                                    </div>
                                                </td>
                                            <% } %>
                                            
                                            <% if (!"INMOBILIARIA".equals(usuarioRol)) { %>
                                                <td>
                                                    <div>
                                                        <strong><%= cita.get("propietario_nombre") %> <%= cita.get("propietario_apellido") %></strong><br>
                                                        <small class="text-muted">
                                                            <i class="fas fa-envelope mr-1"></i><%= cita.get("propietario_email") %>
                                                        </small><br>
                                                        <% if (cita.get("propietario_telefono") != null) { %>
                                                            <small class="text-muted">
                                                                <i class="fas fa-phone mr-1"></i><%= cita.get("propietario_telefono") %>
                                                            </small>
                                                        <% } %>
                                                    </div>
                                                </td>
                                            <% } %>
                                            
                                            <td>
                                                <div>
                                                    <strong>
                                                        <%= new SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)cita.get("fecha_cita")) %>
                                                    </strong><br>
                                                    <small class="text-muted">
                                                        <i class="fas fa-clock mr-1"></i>
                                                        <%= new SimpleDateFormat("HH:mm").format((java.util.Date)cita.get("fecha_cita")) %>
                                                    </small><br>
                                                    <small class="text-muted">
                                                        Solicitada: <%= new SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)cita.get("fecha_solicitud")) %>
                                                    </small>
                                                </div>
                                            </td>
                                            
                                            <td>
                                                <% 
                                                    String estado = (String)cita.get("estado");
                                                    String badgeClass = "";
                                                    String iconClass = "";
                                                    switch(estado) {
                                                        case "PENDIENTE": 
                                                            badgeClass = "badge-warning"; 
                                                            iconClass = "fas fa-clock";
                                                            break;
                                                        case "CONFIRMADA": 
                                                            badgeClass = "badge-success"; 
                                                            iconClass = "fas fa-check-circle";
                                                            break;
                                                        case "REALIZADA": 
                                                            badgeClass = "badge-info"; 
                                                            iconClass = "fas fa-handshake";
                                                            break;
                                                        case "CANCELADA": 
                                                            badgeClass = "badge-danger"; 
                                                            iconClass = "fas fa-times-circle";
                                                            break;
                                                    }
                                                %>
                                                <span class="badge <%= badgeClass %> p-2">
                                                    <i class="<%= iconClass %> mr-1"></i><%= estado %>
                                                </span>
                                                
                                                <% if (cita.get("notas") != null && !((String)cita.get("notas")).trim().isEmpty()) { %>
                                                    <br><small class="text-muted mt-1">
                                                        <i class="fas fa-sticky-note mr-1"></i>Con notas
                                                    </small>
                                                <% } %>
                                                
                                                <% if (cita.get("telefono_contacto") != null && !((String)cita.get("telefono_contacto")).trim().isEmpty()) { %>
                                                    <br><small class="text-muted">
                                                        <i class="fas fa-phone mr-1"></i><%= cita.get("telefono_contacto") %>
                                                    </small>
                                                <% } %>
                                            </td>
                                            
                                            <td>
                                                <div class="btn-group-vertical btn-group-sm" role="group">
                                                    
                                                    <!-- Botón Ver Detalles -->
                                                    <a href="../citas/verCita.jsp?id=<%= cita.get("id_cita") %>"
                                                        class="btn btn-outline-info btn-sm mb-1">
                                                        <i class="fas fa-eye mr-1"></i>Ver
                                                    </a>
                                                    
                                                    <!-- Acciones según el rol y estado -->
                                                    <% if ("INMOBILIARIA".equals(usuarioRol) || "ADMINISTRADOR".equals(usuarioRol)) { %>
                                                        <% if ("PENDIENTE".equals(estado)) { %>
                                                            <form method="POST" style="display: inline;">
                                                                <input type="hidden" name="accion" value="confirmar">
                                                                <input type="hidden" name="cita_id" value="<%= cita.get("id_cita") %>">
                                                                <button type="submit" class="btn btn-success btn-sm mb-1" 
                                                                        onclick="return confirm('¿Confirmar esta cita?')">
                                                                    <i class="fas fa-check mr-1"></i>Confirmar
                                                                </button>
                                                            </form>
                                                        <% } %>
                                                        
                                                        <% if ("CONFIRMADA".equals(estado)) { %>
                                                            <form method="POST" style="display: inline;">
                                                                <input type="hidden" name="accion" value="realizar">
                                                                <input type="hidden" name="cita_id" value="<%= cita.get("id_cita") %>">
                                                                <button type="submit" class="btn btn-info btn-sm mb-1" 
                                                                        onclick="return confirm('¿Marcar como realizada?')">
                                                                    <i class="fas fa-handshake mr-1"></i>Realizada
                                                                </button>
                                                            </form>
                                                        <% } %>
                                                        
                                                        <% if (!"CANCELADA".equals(estado) && !"REALIZADA".equals(estado)) { %>
                                                            <form method="POST" style="display: inline;">
                                                                <input type="hidden" name="accion" value="cancelar">
                                                                <input type="hidden" name="cita_id" value="<%= cita.get("id_cita") %>">
                                                                <button type="submit" class="btn btn-danger btn-sm mb-1" 
                                                                        onclick="return confirm('¿Cancelar esta cita?')">
                                                                    <i class="fas fa-times mr-1"></i>Cancelar
                                                                </button>
                                                            </form>
                                                        <% } %>
                                                    <% } %>
                                                    
                                                    <!-- Cliente solo puede cancelar -->
                                                    <% if ("CLIENTE".equals(usuarioRol)) { %>
                                                        <% if ("PENDIENTE".equals(estado) || "CONFIRMADA".equals(estado)) { %>
                                                            <form method="POST" style="display: inline;">
                                                                <input type="hidden" name="accion" value="cancelar">
                                                                <input type="hidden" name="cita_id" value="<%= cita.get("id_cita") %>">
                                                                <button type="submit" class="btn btn-danger btn-sm mb-1" 
                                                                        onclick="return confirm('¿Cancelar esta cita?')">
                                                                    <i class="fas fa-times mr-1"></i>Cancelar
                                                                </button>
                                                            </form>
                                                        <% } %>
                                                        
                                                        <!-- Opción de reprogramar (enlace a crear nueva cita) -->
                                                        <% if ("CANCELADA".equals(estado)) { %>
                                                            <a href="../citas/crearCita.jsp?propiedad=<%= cita.get("id_propiedad") %>" 
                                                               class="btn btn-outline-primary btn-sm mb-1">
                                                                <i class="fas fa-redo mr-1"></i>Reprogramar
                                                            </a>
                                                        <% } %>
                                                    <% } %>
                                                    
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
    </div>
</div>

<!-- Modal para ver detalles de la cita -->
<div class="modal fade" id="modalDetalles" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--vino); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-calendar-alt mr-2"></i>Detalles de la Cita
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body" id="contenidoDetalles">
                <!-- Se llenará dinámicamente con JavaScript -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
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

.badge {
    font-size: 0.75rem;
}

.btn-group-vertical .btn {
    border-radius: 0.25rem !important;
    margin-bottom: 2px;
}

.table td {
    vertical-align: middle;
}

@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .table-responsive {
        font-size: 0.875rem;
    }
    
    .btn-group-vertical .btn {
        padding: 0.25rem 0.5rem;
        font-size: 0.75rem;
    }
}
</style>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />