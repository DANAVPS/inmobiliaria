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
    
    // Obtener ID de la cita
    String citaIdParam = request.getParameter("id");
    if (citaIdParam == null || citaIdParam.trim().isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/pages/citas/citas.jsp");
        return;
    }
    
    // Variables para datos
    Map<String, Object> cita = null;
    String mensaje = "";
    String tipoMensaje = "";
    boolean puedeVerCita = false;
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar acciones (actualizar estado de citas)
        String accion = request.getParameter("accion");
        
        if ("POST".equals(request.getMethod()) && accion != null) {
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
                    stmt.setInt(1, Integer.parseInt(citaIdParam));
                    stmt.setInt(2, usuarioId);
                    rs = stmt.executeQuery();
                    puedeActualizar = rs.next();
                    rs.close();
                    stmt.close();
                } else if ("CLIENTE".equals(usuarioRol) && "cancelar".equals(accion)) {
                    // Solo puede cancelar sus propias citas
                    String sqlVerificar = "SELECT id_cita FROM citas WHERE id_cita = ? AND id_cliente = ?";
                    stmt = conn.prepareStatement(sqlVerificar);
                    stmt.setInt(1, Integer.parseInt(citaIdParam));
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
                    stmt.setInt(2, Integer.parseInt(citaIdParam));
                    
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
        
        // Consultar la cita con toda la información
        String sqlCita = "";
        
        if ("ADMINISTRADOR".equals(usuarioRol)) {
            // Admin ve todas las citas con toda la información
            sqlCita = "SELECT c.*, p.id_propiedad, p.titulo as propiedad_titulo, p.descripcion as propiedad_descripcion, " +
                     "p.direccion, p.ciudad, p.departamento, p.precio, p.area_construida, p.habitaciones, " +
                     "p.banos, p.garajes, p.imagen_principal, p.tipo_operacion, tp.nombre_tipo, " +
                     "cliente.nombre as cliente_nombre, cliente.apellido as cliente_apellido, " +
                     "cliente.email as cliente_email, cliente.telefono as cliente_telefono, " +
                     "cliente.direccion as cliente_direccion, " +
                     "propietario.nombre as propietario_nombre, propietario.apellido as propietario_apellido, " +
                     "propietario.email as propietario_email, propietario.telefono as propietario_telefono " +
                     "FROM citas c " +
                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                     "INNER JOIN usuarios cliente ON c.id_cliente = cliente.id_usuario " +
                     "INNER JOIN usuarios propietario ON p.id_propietario = propietario.id_usuario " +
                     "WHERE c.id_cita = ?";
            stmt = conn.prepareStatement(sqlCita);
            stmt.setInt(1, Integer.parseInt(citaIdParam));
            
        } else if ("INMOBILIARIA".equals(usuarioRol)) {
            // Inmobiliaria ve citas de sus propiedades
            sqlCita = "SELECT c.*, p.id_propiedad, p.titulo as propiedad_titulo, p.descripcion as propiedad_descripcion, " +
                     "p.direccion, p.ciudad, p.departamento, p.precio, p.area_construida, p.habitaciones, " +
                     "p.banos, p.garajes, p.imagen_principal, p.tipo_operacion, tp.nombre_tipo, " +
                     "cliente.nombre as cliente_nombre, cliente.apellido as cliente_apellido, " +
                     "cliente.email as cliente_email, cliente.telefono as cliente_telefono, " +
                     "cliente.direccion as cliente_direccion " +
                     "FROM citas c " +
                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                     "INNER JOIN usuarios cliente ON c.id_cliente = cliente.id_usuario " +
                     "WHERE c.id_cita = ? AND p.id_propietario = ?";
            stmt = conn.prepareStatement(sqlCita);
            stmt.setInt(1, Integer.parseInt(citaIdParam));
            stmt.setInt(2, usuarioId);
            
        } else {
            // Cliente ve solo sus citas
            sqlCita = "SELECT c.*, p.id_propiedad, p.titulo as propiedad_titulo, p.descripcion as propiedad_descripcion, " +
                     "p.direccion, p.ciudad, p.departamento, p.precio, p.area_construida, p.habitaciones, " +
                     "p.banos, p.garajes, p.imagen_principal, p.tipo_operacion, tp.nombre_tipo, " +
                     "propietario.nombre as propietario_nombre, propietario.apellido as propietario_apellido, " +
                     "propietario.email as propietario_email, propietario.telefono as propietario_telefono " +
                     "FROM citas c " +
                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                     "INNER JOIN usuarios propietario ON p.id_propietario = propietario.id_usuario " +
                     "WHERE c.id_cita = ? AND c.id_cliente = ?";
            stmt = conn.prepareStatement(sqlCita);
            stmt.setInt(1, Integer.parseInt(citaIdParam));
            stmt.setInt(2, usuarioId);
        }
        
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            puedeVerCita = true;
            cita = new HashMap<>();
            
            // Datos de la cita
            cita.put("id_cita", rs.getInt("id_cita"));
            cita.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            cita.put("estado", rs.getString("estado"));
            cita.put("notas", rs.getString("notas"));
            cita.put("telefono_contacto", rs.getString("telefono_contacto"));
            cita.put("fecha_solicitud", rs.getTimestamp("fecha_solicitud"));
            
            // Datos de la propiedad
            cita.put("id_propiedad", rs.getInt("id_propiedad"));
            cita.put("propiedad_titulo", rs.getString("propiedad_titulo"));
            cita.put("propiedad_descripcion", rs.getString("propiedad_descripcion"));
            cita.put("direccion", rs.getString("direccion"));
            cita.put("ciudad", rs.getString("ciudad"));
            cita.put("departamento", rs.getString("departamento"));
            cita.put("precio", rs.getLong("precio"));
            cita.put("area_construida", rs.getBigDecimal("area_construida"));
            cita.put("habitaciones", rs.getInt("habitaciones"));
            cita.put("banos", rs.getInt("banos"));
            cita.put("garajes", rs.getInt("garajes"));
            cita.put("imagen_principal", rs.getString("imagen_principal"));
            cita.put("tipo_operacion", rs.getString("tipo_operacion"));
            cita.put("nombre_tipo", rs.getString("nombre_tipo"));
            
            // Datos según el rol
            if (!"CLIENTE".equals(usuarioRol)) {
                cita.put("cliente_nombre", rs.getString("cliente_nombre"));
                cita.put("cliente_apellido", rs.getString("cliente_apellido"));
                cita.put("cliente_email", rs.getString("cliente_email"));
                cita.put("cliente_telefono", rs.getString("cliente_telefono"));
                cita.put("cliente_direccion", rs.getString("cliente_direccion"));
            }
            
            if (!"INMOBILIARIA".equals(usuarioRol)) {
                cita.put("propietario_nombre", rs.getString("propietario_nombre"));
                cita.put("propietario_apellido", rs.getString("propietario_apellido"));
                cita.put("propietario_email", rs.getString("propietario_email"));
                cita.put("propietario_telefono", rs.getString("propietario_telefono"));
            }
        }
        
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar la información de la cita: " + e.getMessage();
        tipoMensaje = "error";
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    // Si no se encontró la cita o no tiene permisos
    if (!puedeVerCita) {
        response.sendRedirect(request.getContextPath() + "/pages/citas/citas.jsp");
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Detalles de la Cita" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar según el rol -->
        <div class="col-md-3 col-lg-2">
            <div class="card shadow-sm">
                <div class="card-header text-white" style="background-color: var(--vino);">
                    <h6 class="mb-0">
                        <i class="fas fa-user mr-2"></i>Panel <%= usuarioRol.charAt(0) + usuarioRol.toLowerCase().substring(1) %>
                    </h6>
                </div>
                <div class="list-group list-group-flush">
                    <% if ("CLIENTE".equals(usuarioRol)) { %>
                        <a href="../client/index.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
                        </a>
                        <a href="../properties/list-properties.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-search mr-2"></i>Buscar Propiedades
                        </a>
                        <a href="../client/favoritos.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-heart mr-2"></i>Mis Favoritos
                        </a>
                        <a href="../citas/citas.jsp" class="list-group-item list-group-item-action active">
                            <i class="fas fa-calendar-alt mr-2"></i>Mis Citas
                        </a>
                        <a href="../client/perfil.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                        </a>
                    <% } else if ("INMOBILIARIA".equals(usuarioRol)) { %>
                        <a href="../inmobiliaria/index.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
                        </a>
                        <a href="../inmobiliaria/misPropiedades.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-home mr-2"></i>Mis Propiedades
                        </a>
                        <a href="../citas/citas.jsp" class="list-group-item list-group-item-action active">
                            <i class="fas fa-calendar-alt mr-2"></i>Citas Recibidas
                        </a>
                        <a href="../inmobiliaria/solicitudes.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-inbox mr-2"></i>Solicitudes
                        </a>
                        <a href="../inmobiliaria/perfil.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                        </a>
                    <% } else { %>
                        <a href="../admin/index.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
                        </a>
                        <a href="../admin/usuarios.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-users mr-2"></i>Usuarios
                        </a>
                        <a href="../citas/citas.jsp" class="list-group-item list-group-item-action active">
                            <i class="fas fa-calendar-alt mr-2"></i>Todas las Citas
                        </a>
                        <a href="../admin/reportes.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-chart-bar mr-2"></i>Reportes
                        </a>
                        <a href="../admin/configuracion.jsp" class="list-group-item list-group-item-action">
                            <i class="fas fa-cog mr-2"></i>Configuración
                        </a>
                    <% } %>
                    <a href="../auth/logout.jsp" class="list-group-item list-group-item-action text-danger">
                        <i class="fas fa-sign-out-alt mr-2"></i>Cerrar Sesión
                    </a>
                </div>
            </div>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <% if ("CLIENTE".equals(usuarioRol)) { %>
                        <li class="breadcrumb-item"><a href="../client/index.jsp">Dashboard</a></li>
                    <% } else if ("INMOBILIARIA".equals(usuarioRol)) { %>
                        <li class="breadcrumb-item"><a href="../inmobiliaria/index.jsp">Dashboard</a></li>
                    <% } else { %>
                        <li class="breadcrumb-item"><a href="../admin/index.jsp">Dashboard</a></li>
                    <% } %>
                    <li class="breadcrumb-item"><a href="../citas/citas.jsp">Citas</a></li>
                    <li class="breadcrumb-item active">Detalles de Cita</li>
                </ol>
            </nav>
            
            <!-- Encabezado -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-calendar-alt mr-2"></i>Detalles de la Cita
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Información completa sobre la cita programada
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="../citas/citas.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-1"></i>Volver a Citas
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
            
            <!-- Estado de la cita -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body text-center">
                            <% 
                                String estado = (String)cita.get("estado");
                                String badgeClass = "";
                                String iconClass = "";
                                String descripcionEstado = "";
                                switch(estado) {
                                    case "PENDIENTE": 
                                        badgeClass = "badge-warning"; 
                                        iconClass = "fas fa-clock";
                                        descripcionEstado = "La cita está pendiente de confirmación por parte del propietario";
                                        break;
                                    case "CONFIRMADA": 
                                        badgeClass = "badge-success"; 
                                        iconClass = "fas fa-check-circle";
                                        descripcionEstado = "La cita ha sido confirmada y está programada";
                                        break;
                                    case "REALIZADA": 
                                        badgeClass = "badge-info"; 
                                        iconClass = "fas fa-handshake";
                                        descripcionEstado = "La cita se ha realizado exitosamente";
                                        break;
                                    case "CANCELADA": 
                                        badgeClass = "badge-danger"; 
                                        iconClass = "fas fa-times-circle";
                                        descripcionEstado = "La cita ha sido cancelada";
                                        break;
                                }
                            %>
                            <h4 class="mb-3">
                                <span class="badge <%= badgeClass %> p-3" style="font-size: 1.2rem;">
                                    <i class="<%= iconClass %> mr-2"></i><%= estado %>
                                </span>
                            </h4>
                            <p class="text-muted mb-0"><%= descripcionEstado %></p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información de la propiedad -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header text-white" style="background-color: var(--vino);">
                            <h6 class="mb-0">
                                <i class="fas fa-home mr-2"></i>Información de la Propiedad
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-4">
                                    <% if (cita.get("imagen_principal") != null) { %>
                                        <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= cita.get("imagen_principal") %>" 
                                             alt="<%= cita.get("propiedad_titulo") %>" 
                                             class="img-fluid rounded shadow"
                                             onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                    <% } else { %>
                                        <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                             alt="Sin imagen" class="img-fluid rounded shadow">
                                    <% } %>
                                    
                                    <div class="mt-3 text-center">
                                        <a href="../properties/verPropiedad.jsp?id=<%= cita.get("id_propiedad") %>" 
                                           class="btn btn-outline-primary btn-block">
                                            <i class="fas fa-eye mr-1"></i>Ver Propiedad Completa
                                        </a>
                                    </div>
                                </div>
                                <div class="col-md-8">
                                    <h4 class="mb-3"><%= cita.get("propiedad_titulo") %></h4>
                                    
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <p class="mb-2">
                                                <i class="fas fa-map-marker-alt text-danger mr-2"></i>
                                                <strong>Ubicación:</strong><br>
                                                <%= cita.get("direccion") %><br>
                                                <%= cita.get("ciudad") %>, <%= cita.get("departamento") %>
                                            </p>
                                        </div>
                                        <div class="col-md-6">
                                            <p class="mb-2">
                                                <i class="fas fa-tag text-success mr-2"></i>
                                                <strong>Precio:</strong><br>
                                                <span class="h5 text-success">$<%= String.format("%,d", (Long)cita.get("precio")) %></span>
                                            </p>
                                        </div>
                                    </div>
                                    
                                    <div class="row mb-3">
                                        <div class="col-md-6">
                                            <p class="mb-2">
                                                <i class="fas fa-building text-info mr-2"></i>
                                                <strong>Tipo:</strong> <%= cita.get("nombre_tipo") %>
                                            </p>
                                        </div>
                                        <div class="col-md-6">
                                            <p class="mb-2">
                                                <i class="fas fa-handshake text-warning mr-2"></i>
                                                <strong>Operación:</strong> <%= ((String)cita.get("tipo_operacion")).replace("_", "/") %>
                                            </p>
                                        </div>
                                    </div>
                                    
                                    <div class="row mb-3">
                                        <% if (cita.get("area_construida") != null && ((java.math.BigDecimal)cita.get("area_construida")).compareTo(java.math.BigDecimal.ZERO) > 0) { %>
                                            <div class="col-md-3">
                                                <p class="mb-1">
                                                    <i class="fas fa-ruler-combined text-secondary mr-1"></i>
                                                    <strong><%= cita.get("area_construida") %> m²</strong><br>
                                                    <small class="text-muted">Área construida</small>
                                                </p>
                                            </div>
                                        <% } %>
                                        <% if ((Integer)cita.get("habitaciones") > 0) { %>
                                            <div class="col-md-3">
                                                <p class="mb-1">
                                                    <i class="fas fa-bed text-primary mr-1"></i>
                                                    <strong><%= cita.get("habitaciones") %></strong><br>
                                                    <small class="text-muted">Habitaciones</small>
                                                </p>
                                            </div>
                                        <% } %>
                                        <% if ((Integer)cita.get("banos") > 0) { %>
                                            <div class="col-md-3">
                                                <p class="mb-1">
                                                    <i class="fas fa-bath text-info mr-1"></i>
                                                    <strong><%= cita.get("banos") %></strong><br>
                                                    <small class="text-muted">Baños</small>
                                                </p>
                                            </div>
                                        <% } %>
                                        <% if ((Integer)cita.get("garajes") > 0) { %>
                                            <div class="col-md-3">
                                                <p class="mb-1">
                                                    <i class="fas fa-car text-dark mr-1"></i>
                                                    <strong><%= cita.get("garajes") %></strong><br>
                                                    <small class="text-muted">Garajes</small>
                                                </p>
                                            </div>
                                        <% } %>
                                    </div>
                                    
                                    <% if (cita.get("propiedad_descripcion") != null && !((String)cita.get("propiedad_descripcion")).trim().isEmpty()) { %>
                                        <div class="alert alert-light">
                                            <strong>Descripción:</strong><br>
                                            <%= ((String)cita.get("propiedad_descripcion")).replace("\n", "<br>") %>
                                        </div>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información de la cita -->
            <div class="row mb-4">
                <div class="col-md-6">
                    <div class="card shadow h-100">
                        <div class="card-header bg-primary text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-calendar-check mr-2"></i>Detalles de la Cita
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="mb-3">
                                <strong>Fecha y Hora Programada:</strong><br>
                                <span class="h6 text-primary">
                                    <i class="fas fa-calendar mr-1"></i>
                                    <%= new SimpleDateFormat("EEEE, dd 'de' MMMM 'de' yyyy", new Locale("es", "ES")).format((java.util.Date)cita.get("fecha_cita")) %>
                                </span><br>
                                <span class="h6 text-primary">
                                    <i class="fas fa-clock mr-1"></i>
                                    <%= new SimpleDateFormat("HH:mm").format((java.util.Date)cita.get("fecha_cita")) %>
                                </span>
                            </div>
                            
                            <div class="mb-3">
                                <strong>Fecha de Solicitud:</strong><br>
                                <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format((java.util.Date)cita.get("fecha_solicitud")) %>
                            </div>
                            
                            <% if (cita.get("telefono_contacto") != null && !((String)cita.get("telefono_contacto")).trim().isEmpty()) { %>
                                <div class="mb-3">
                                    <strong>Teléfono de Contacto:</strong><br>
                                    <a href="tel:<%= cita.get("telefono_contacto") %>" class="text-decoration-none">
                                        <i class="fas fa-phone mr-1"></i><%= cita.get("telefono_contacto") %>
                                    </a>
                                </div>
                            <% } %>
                            
                            <% if (cita.get("notas") != null && !((String)cita.get("notas")).trim().isEmpty()) { %>
                                <div class="mb-0">
                                    <strong>Notas Adicionales:</strong><br>
                                    <div class="alert alert-light mt-2 mb-0">
                                        <%= ((String)cita.get("notas")).replace("\n", "<br>") %>
                                    </div>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
                <!-- Información de contacto -->
                <div class="col-md-6">
                    <div class="card shadow h-100">
                        <div class="card-header bg-info text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-users mr-2"></i>Información de Contacto
                            </h6>
                        </div>
                        <div class="card-body">
                            
                            <!-- Información del cliente -->
                            <% if (!"CLIENTE".equals(usuarioRol)) { %>
                                <div class="mb-4">
                                    <h6 class="text-primary">
                                        <i class="fas fa-user mr-2"></i>Cliente
                                    </h6>
                                    <p class="mb-1">
                                        <strong><%= cita.get("cliente_nombre") %> <%= cita.get("cliente_apellido") %></strong>
                                    </p>
                                    <p class="mb-1">
                                        <i class="fas fa-envelope mr-1"></i>
                                        <a href="mailto:<%= cita.get("cliente_email") %>" class="text-decoration-none">
                                            <%= cita.get("cliente_email") %>
                                        </a>
                                    </p>
                                    <% if (cita.get("cliente_telefono") != null && !((String)cita.get("cliente_telefono")).trim().isEmpty()) { %>
                                        <p class="mb-1">
                                            <i class="fas fa-phone mr-1"></i>
                                            <a href="tel:<%= cita.get("cliente_telefono") %>" class="text-decoration-none">
                                                <%= cita.get("cliente_telefono") %>
                                            </a>
                                        </p>
                                    <% } %>
                                    <% if (cita.get("cliente_direccion") != null && !((String)cita.get("cliente_direccion")).trim().isEmpty()) { %>
                                        <p class="mb-0">
                                            <i class="fas fa-map-marker-alt mr-1"></i>
                                            <%= cita.get("cliente_direccion") %>
                                        </p>
                                    <% } %>
                                </div>
                            <% } %>
                            
                            <!-- Información del propietario -->
                            <% if (!"INMOBILIARIA".equals(usuarioRol)) { %>
                                <div class="mb-0">
                                    <h6 class="text-success">
                                        <i class="fas fa-building mr-2"></i>Propietario/Inmobiliaria
                                    </h6>
                                    <p class="mb-1">
                                        <strong><%= cita.get("propietario_nombre") %> <%= cita.get("propietario_apellido") %></strong>
                                    </p>
                                    <p class="mb-1">
                                        <i class="fas fa-envelope mr-1"></i>
                                        <a href="mailto:<%= cita.get("propietario_email") %>" class="text-decoration-none">
                                            <%= cita.get("propietario_email") %>
                                        </a>
                                    </p>
                                    <% if (cita.get("propietario_telefono") != null && !((String)cita.get("propietario_telefono")).trim().isEmpty()) { %>
                                        <p class="mb-0">
                                            <i class="fas fa-phone mr-1"></i>
                                            <a href="tel:<%= cita.get("propietario_telefono") %>" class="text-decoration-none">
                                                <%= cita.get("propietario_telefono") %>
                                            </a>
                                        </p>
                                    <% } %>
                                </div>
                            <% } %>
                            
                            <!-- Mensaje si es el único contacto -->
                            <% if ("CLIENTE".equals(usuarioRol) && ("INMOBILIARIA".equals(usuarioRol))) { %>
                                <div class="alert alert-info">
                                    <i class="fas fa-info-circle mr-2"></i>
                                    Esta es tu cita programada. El propietario te contactará para confirmar los detalles.
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Acciones disponibles -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header bg-secondary text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-cogs mr-2"></i>Acciones Disponibles
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-12">
                                    
                                    <!-- Botones según el rol y estado -->
                                    <% if ("INMOBILIARIA".equals(usuarioRol) || "ADMINISTRADOR".equals(usuarioRol)) { %>
                                        
                                        <% if ("PENDIENTE".equals(estado)) { %>
                                            <form method="POST" style="display: inline;" onsubmit="return confirm('¿Confirmar esta cita? El cliente será notificado.')">
                                                <input type="hidden" name="accion" value="confirmar">
                                                <button type="submit" class="btn btn-success mr-2 mb-2">
                                                    <i class="fas fa-check mr-1"></i>Confirmar Cita
                                                </button>
                                            </form>
                                        <% } %>
                                        
                                        <% if ("CONFIRMADA".equals(estado)) { %>
                                            <form method="POST" style="display: inline;" onsubmit="return confirm('¿Marcar como realizada? Esta acción no se puede deshacer.')">
                                                <input type="hidden" name="accion" value="realizar">
                                                <button type="submit" class="btn btn-info mr-2 mb-2">
                                                    <i class="fas fa-handshake mr-1"></i>Marcar como Realizada
                                                </button>
                                            </form>
                                        <% } %>
                                        
                                        <% if (!"CANCELADA".equals(estado) && !"REALIZADA".equals(estado)) { %>
                                            <form method="POST" style="display: inline;" onsubmit="return confirm('¿Cancelar esta cita? Esta acción no se puede deshacer.')">
                                                <input type="hidden" name="accion" value="cancelar">
                                                <button type="submit" class="btn btn-danger mr-2 mb-2">
                                                    <i class="fas fa-times mr-1"></i>Cancelar Cita
                                                </button>
                                            </form>
                                        <% } %>
                                        
                                    <% } %>
                                    
                                    <!-- Cliente solo puede cancelar -->
                                    <% if ("CLIENTE".equals(usuarioRol)) { %>
                                        <% if ("PENDIENTE".equals(estado) || "CONFIRMADA".equals(estado)) { %>
                                            <form method="POST" style="display: inline;" onsubmit="return confirm('¿Cancelar esta cita? Podrás reprogramar otra más tarde.')">
                                                <input type="hidden" name="accion" value="cancelar">
                                                <button type="submit" class="btn btn-danger mr-2 mb-2">
                                                    <i class="fas fa-times mr-1"></i>Cancelar Cita
                                                </button>
                                            </form>
                                        <% } %>
                                        
                                        <% if ("CANCELADA".equals(estado)) { %>
                                            <a href="../citas/crearCita.jsp?propiedad=<%= cita.get("id_propiedad") %>" 
                                               class="btn text-white mr-2 mb-2" style="background-color: var(--vino);">
                                                <i class="fas fa-redo mr-1"></i>Reprogramar Cita
                                            </a>
                                        <% } %>
                                        
                                        <!-- Siempre mostrar opción de crear nueva cita -->
                                        <a href="../citas/crearCita.jsp" class="btn btn-outline-primary mr-2 mb-2">
                                            <i class="fas fa-plus mr-1"></i>Nueva Cita
                                        </a>
                                    <% } %>
                                    
                                    <!-- Botones comunes -->
                                    <a href="../properties/verPropiedad.jsp?id=<%= cita.get("id_propiedad") %>" 
                                       class="btn btn-outline-info mr-2 mb-2">
                                        <i class="fas fa-eye mr-1"></i>Ver Propiedad Completa
                                    </a>
                                    
                                    <a href="../citas/citas.jsp" class="btn btn-secondary mr-2 mb-2">
                                        <i class="fas fa-list mr-1"></i>Ver Todas las Citas
                                    </a>
                                    
                                    <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                        <a href="../admin/reportes.jsp" class="btn btn-outline-secondary mr-2 mb-2">
                                            <i class="fas fa-chart-bar mr-1"></i>Ver Reportes
                                        </a>
                                    <% } %>
                                </div>
                            </div>
                            
                            <!-- Información adicional según el estado -->
                            <div class="mt-3">
                                <% if ("PENDIENTE".equals(estado)) { %>
                                    <div class="alert alert-warning">
                                        <i class="fas fa-clock mr-2"></i>
                                        <strong>Cita Pendiente:</strong> 
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Tu cita está pendiente de confirmación. El propietario será notificado y te contactará pronto.
                                        <% } else { %>
                                            Esta cita requiere tu confirmación. Una vez confirmada, el cliente será notificado.
                                        <% } %>
                                    </div>
                                <% } else if ("CONFIRMADA".equals(estado)) { %>
                                    <div class="alert alert-success">
                                        <i class="fas fa-check-circle mr-2"></i>
                                        <strong>Cita Confirmada:</strong> 
                                        La cita está confirmada para el <%= new SimpleDateFormat("dd/MM/yyyy 'a las' HH:mm").format((java.util.Date)cita.get("fecha_cita")) %>.
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Te esperamos en la dirección de la propiedad.
                                        <% } else { %>
                                            Recuerda estar disponible para recibir al cliente.
                                        <% } %>
                                    </div>
                                <% } else if ("REALIZADA".equals(estado)) { %>
                                    <div class="alert alert-info">
                                        <i class="fas fa-handshake mr-2"></i>
                                        <strong>Cita Realizada:</strong> 
                                        Esta cita se completó exitosamente. 
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Esperamos que la visita haya sido de tu agrado.
                                        <% } else { %>
                                            La visita se realizó según lo programado.
                                        <% } %>
                                    </div>
                                <% } else if ("CANCELADA".equals(estado)) { %>
                                    <div class="alert alert-danger">
                                        <i class="fas fa-times-circle mr-2"></i>
                                        <strong>Cita Cancelada:</strong> 
                                        Esta cita fue cancelada. 
                                        <% if ("CLIENTE".equals(usuarioRol)) { %>
                                            Puedes reprogramar una nueva cita cuando gustes.
                                        <% } else { %>
                                            El cliente puede solicitar una nueva cita en el futuro.
                                        <% } %>
                                    </div>
                                <% } %>
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

.badge {
    font-size: 1rem;
}

.alert {
    border-radius: 8px;
}

.btn {
    border-radius: 6px;
}

.h-100 {
    height: 100% !important;
}

@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .btn {
        margin-bottom: 5px;
        font-size: 0.9rem;
    }
    
    .badge {
        font-size: 0.9rem;
        padding: 0.5rem 1rem;
    }
}

/* Mejoras visuales */
.card-header {
    border-bottom: none;
    font-weight: 600;
}

.text-decoration-none:hover {
    text-decoration: underline !important;
}

.alert-light {
    background-color: #f8f9fa;
    border-color: #dee2e6;
    color: #495057;
}
</style>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp"></jsp:include>