<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null ) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID de la propiedad a ver
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("propiedades.jsp");
        return;
    }
    
    // Variables para almacenar datos de la propiedad
    Map<String, Object> propiedad = null;
    List<Map<String, Object> > imagenes = new ArrayList<>();
    List<Map<String, Object>> citasPropiedad = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar acciones de aprobación/rechazo
        String action = request.getParameter("action");
        if (action != null) {
            if ("aprobar".equals(action)) {
                // Marcar como disponible y destacada (aprobada)
                stmt = conn.prepareStatement("UPDATE propiedades SET disponible = 1, destacada = 1 WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(idParam));
                int resultado = stmt.executeUpdate();
                
                if (resultado > 0) {
                    mensaje = "Propiedad aprobada exitosamente. Ahora está disponible y destacada.";
                    tipoMensaje = "success";
                } else {
                    mensaje = "Error al aprobar la propiedad.";
                    tipoMensaje = "error";
                }
                stmt.close();
                
            } else if ("rechazar".equals(action)) {
                // Marcar como no disponible y quitar de destacadas (rechazada)
                stmt = conn.prepareStatement("UPDATE propiedades SET disponible = 0, destacada = 0 WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(idParam));
                int resultado = stmt.executeUpdate();
                
                if (resultado > 0) {
                    mensaje = "Propiedad rechazada. Ha sido marcada como no disponible.";
                    tipoMensaje = "warning";
                } else {
                    mensaje = "Error al rechazar la propiedad.";
                    tipoMensaje = "error";
                }
                stmt.close();
                
            } else if ("suspender".equals(action)) {
                // Suspender temporalmente (no disponible pero mantener otros datos)
                stmt = conn.prepareStatement("UPDATE propiedades SET disponible = 0 WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(idParam));
                int resultado = stmt.executeUpdate();
                
                if (resultado > 0) {
                    mensaje = "Propiedad suspendida temporalmente.";
                    tipoMensaje = "warning";
                } else {
                    mensaje = "Error al suspender la propiedad.";
                    tipoMensaje = "error";
                }
                stmt.close();
            }
        }
        
        // Obtener información completa de la propiedad
        String sqlPropiedad = "SELECT p.*, tp.nombre_tipo, u.nombre as propietario_nombre, " +
                             "u.apellido as propietario_apellido, u.email as propietario_email, u.telefono as propietario_telefono " +
                             "FROM propiedades p " +
                             "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                             "INNER JOIN usuarios u ON p.id_propietario = u.id_usuario " +
                             "WHERE p.id_propiedad = ?";
        
        stmt = conn.prepareStatement(sqlPropiedad);
        stmt.setInt(1, Integer.parseInt(idParam));
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("descripcion", rs.getString("descripcion"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("area_total", rs.getDouble("area_total"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("garajes", rs.getInt("garajes"));
            propiedad.put("piso", rs.getInt("piso"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("departamento", rs.getString("departamento"));
            propiedad.put("codigo_postal", rs.getString("codigo_postal"));
            propiedad.put("latitud", rs.getDouble("latitud"));
            propiedad.put("longitud", rs.getDouble("longitud"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("disponible", rs.getBoolean("disponible"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("video_url", rs.getString("video_url"));
            propiedad.put("tour_virtual_url", rs.getString("tour_virtual_url"));
            propiedad.put("fecha_publicacion", rs.getTimestamp("fecha_publicacion"));
            propiedad.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
            propiedad.put("propietario_nombre", rs.getString("propietario_nombre"));
            propiedad.put("propietario_apellido", rs.getString("propietario_apellido"));
            propiedad.put("propietario_email", rs.getString("propietario_email"));
            propiedad.put("propietario_telefono", rs.getString("propietario_telefono"));
        } else {
            mensaje = "Propiedad no encontrada.";
            tipoMensaje = "error";
        }
        rs.close();
        stmt.close();
        
        // Si la propiedad existe, obtener imágenes adicionales
        if (propiedad != null) {
            String sqlImagenes = "SELECT * FROM imagenes_propiedades WHERE id_propiedad = ? ORDER BY orden_imagen, fecha_subida";
            
            stmt = conn.prepareStatement(sqlImagenes);
            stmt.setInt(1, Integer.parseInt(idParam));
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> imagen = new HashMap<>();
                imagen.put("id", rs.getInt("id_imagen"));
                imagen.put("nombre_archivo", rs.getString("nombre_archivo"));
                imagen.put("ruta_archivo", rs.getString("ruta_archivo"));
                imagen.put("es_principal", rs.getBoolean("es_principal"));
                imagen.put("orden_imagen", rs.getInt("orden_imagen"));
                imagenes.add(imagen);
            }
            rs.close();
            stmt.close();
            
            // Obtener citas para esta propiedad
            String sqlCitas = "SELECT c.*, u.nombre as cliente_nombre, u.apellido as cliente_apellido, " +
                             "u.email as cliente_email, u.telefono as cliente_telefono " +
                             "FROM citas c " +
                             "INNER JOIN usuarios u ON c.id_cliente = u.id_usuario " +
                             "WHERE c.id_propiedad = ? " +
                             "ORDER BY c.fecha_cita DESC";
            
            stmt = conn.prepareStatement(sqlCitas);
            stmt.setInt(1, Integer.parseInt(idParam));
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> cita = new HashMap<>();
                cita.put("id", rs.getInt("id_cita"));
                cita.put("fecha_cita", rs.getTimestamp("fecha_cita"));
                cita.put("estado", rs.getString("estado"));
                cita.put("notas", rs.getString("notas"));
                cita.put("telefono_contacto", rs.getString("telefono_contacto"));
                cita.put("fecha_solicitud", rs.getTimestamp("fecha_solicitud"));
                cita.put("cliente_nombre", rs.getString("cliente_nombre"));
                cita.put("cliente_apellido", rs.getString("cliente_apellido"));
                cita.put("cliente_email", rs.getString("cliente_email"));
                cita.put("cliente_telefono", rs.getString("cliente_telefono"));
                citasPropiedad.add(cita);
            }
            rs.close();
            stmt.close();
        }
        
    } catch (Exception e) {
        mensaje = "Error al cargar información de la propiedad: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    // Si no se encontró la propiedad, redirigir
    if (propiedad == null && mensaje.isEmpty()) {
        response.sendRedirect("propiedades.jsp");
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Detalles de Propiedad - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="propiedades" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                        <li class="breadcrumb-item"><a href="index.jsp">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="propiedades.jsp">Propiedades</a></li>
                        <% } else if ("CLIENTE".equals(usuarioRol)) { %>
                            <li class="breadcrumb-item"><a href="../client/index.jsp">Dashboard</a></li>
                            <li class="breadcrumb-item"><a href="../properties/list-properties.jsp">Propiedades</a></li>
                            <% } else { %>
                                <li class="breadcrumb-item"><a href="../../index.jsp">Inicio</a></li>
                                <% } %>
                                    <li class="breadcrumb-item active">Detalles de Propiedad</li>
                </ol>
            </nav>
            
            <!-- Mensajes -->
            <% if (!mensaje.isEmpty()) { %>
                <div class="alert alert-<%= "success".equals(tipoMensaje) ? "success" : ("warning".equals(tipoMensaje) ? "warning" : "danger") %> alert-dismissible fade show" role="alert">
                    <i class="fas fa-<%= "success".equals(tipoMensaje) ? "check-circle" : ("warning".equals(tipoMensaje) ? "exclamation-triangle" : "exclamation-triangle") %> mr-2"></i>
                    <%= mensaje %>
                    <button type="button" class="close" data-dismiss="alert">
                        <span>&times;</span>
                    </button>
                </div>
            <% } %>
            
            <% if (propiedad != null) { %>
            
            <!-- Header de la propiedad -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-6">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-building mr-2"></i>
                                        <%= propiedad.get("titulo") %>
                                    </h3>
                                    <p class="text-muted mb-2">
                                        <i class="fas fa-map-marker-alt mr-1"></i>
                                        <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %>, <%= propiedad.get("departamento") %>
                                    </p>
                                    <div>
                                        <span class="badge <%= (Boolean)propiedad.get("disponible") ? "badge-success" : "badge-danger" %> mr-2">
                                            <%= (Boolean)propiedad.get("disponible") ? "Disponible" : "No Disponible" %>
                                        </span>
                                        <% if ((Boolean)propiedad.get("destacada")) { %>
                                            <span class="badge badge-warning mr-2">Destacada</span>
                                        <% } %>
                                        <span class="badge badge-info">
                                            <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                        </span>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <h4 class="text-success font-weight-bold mb-2 text-center">
                                        $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                    </h4>
                                </div>
                                <div class="col-md-3 text-right">
    <div class="btn-group-vertical" role="group">
        <!-- Botón volver - adaptado por rol -->
        <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
            <a href="propiedades.jsp" class="btn btn-secondary btn-sm mb-1">
                <i class="fas fa-arrow-left mr-1"></i>Volver a Lista
            </a>
            <a href="editarPropiedad.jsp?id=<%= propiedad.get("id") %>" class="btn btn-primary btn-sm">
                <i class="fas fa-edit mr-1"></i>Editar
            </a>
        <% } else if ("CLIENTE".equals(usuarioRol)) { %>
            <a href="../client/favoritos.jsp" class="btn btn-secondary btn-sm mb-1">
                <i class="fas fa-arrow-left mr-1"></i>Volver
            </a>
            <a href="../properties/list-properties.jsp" class="btn btn-info btn-sm">
                <i class="fas fa-search mr-1"></i>Buscar Más
            </a>
        <% } %>
    </div>
</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Panel de acciones administrativas - SOLO PARA ADMINISTRADORES -->
<% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
<div class="row mb-4">
    <div class="col-12">
        <div class="card shadow border-left-primary">
            <div class="card-header text-white" style="background-color: var(--vino);">
                <h6 class="mb-0">
                    <i class="fas fa-tools mr-2"></i>Acciones Administrativas
                </h6>
            </div>
            <div class="card-body">
                <div class="row">
                    <div class="col-md-8">
                        <h6 class="text-muted mb-3">Gestionar el estado de aprobación de esta propiedad:</h6>
                        <% 
                            boolean disponible = (Boolean)propiedad.get("disponible");
                            boolean destacada = (Boolean)propiedad.get("destacada");
                            String estadoActual = "";
                            String colorEstado = "";
                            
                            if (disponible && destacada) {
                                estadoActual = "APROBADA Y DESTACADA";
                                colorEstado = "text-success";
                            } else if (disponible && !destacada) {
                                estadoActual = "APROBADA";
                                colorEstado = "text-info";
                            } else if (!disponible) {
                                estadoActual = "RECHAZADA/SUSPENDIDA";
                                colorEstado = "text-danger";
                            }
                        %>
                        <p class="mb-3">
                            <strong>Estado actual:</strong> 
                            <span class="<%= colorEstado %> font-weight-bold"><%= estadoActual %></span>
                        </p>
                    </div>
                    <div class="col-md-4">
                        <div class="btn-group-vertical w-100" role="group">
                            <% if (!disponible || !destacada) { %>
                                <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>&action=aprobar" 
                                   class="btn btn-success btn-sm mb-2"
                                   onclick="return confirm('¿Está seguro de aprobar esta propiedad? Será marcada como disponible y destacada.')">
                                    <i class="fas fa-check-circle mr-2"></i>Aprobar Propiedad
                                </a>
                            <% } %>
                            
                            <% if (disponible) { %>
                                <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>&action=suspender" 
                                   class="btn btn-warning btn-sm mb-2"
                                   onclick="return confirm('¿Está seguro de suspender temporalmente esta propiedad?')">
                                    <i class="fas fa-pause-circle mr-2"></i>Suspender
                                </a>
                                
                                <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>&action=rechazar" 
                                   class="btn btn-danger btn-sm"
                                   onclick="return confirm('¿Está seguro de rechazar esta propiedad? Será marcada como no disponible.')">
                                    <i class="fas fa-times-circle mr-2"></i>Rechazar
                                </a>
                            <% } else { %>
                                <small class="text-muted">La propiedad está actualmente rechazada o suspendida.</small>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<% } %>

<!-- Panel de acciones para CLIENTES -->
<% if ("CLIENTE".equals(usuarioRol)) { %>
<div class="row mb-4">
    <div class="col-12">
        <div class="card shadow border-left-success">
            <div class="card-header bg-success text-white">
                <h6 class="mb-0">
                    <i class="fas fa-heart mr-2"></i>Acciones de Cliente
                </h6>
            </div>
            <div class="card-body">
                <div class="row align-items-center">
                    <div class="col-md-8">
                        <h6 class="mb-2">¿Te interesa esta propiedad?</h6>
                        <p class="text-muted mb-0">Puedes agregarla a favoritos o programar una cita para visitarla.</p>
                    </div>
                    <div class="col-md-4">
                        <div class="btn-group w-100" role="group">
                            <button class="btn btn-outline-danger" 
                                    onclick="toggleFavorito(<%= propiedad.get("id") %>)" 
                                    id="btnFavorito"
                                    title="Gestionar favoritos">
                                <i class="far fa-heart mr-1"></i>Cargando...
                            </button>
                            <a href="../client/solicitarCita.jsp?propiedad=<%= propiedad.get("id") %>" 
                               class="btn btn-success">
                                <i class="fas fa-calendar-plus mr-1"></i>Solicitar Cita
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
<% } %>
            
            <!-- Imagen principal -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body text-center">
                            <% if (propiedad.get("imagen_principal") != null && !((String)propiedad.get("imagen_principal")).isEmpty()) { %>
                                <img src="<%= propiedad.get("imagen_principal") %>" 
                                     alt="<%= propiedad.get("titulo") %>" 
                                     class="img-fluid rounded shadow"
                                     style="max-height: 400px; width: auto;"
                                     onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                            <% } else { %>
                                <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                     alt="Sin imagen" 
                                     class="img-fluid rounded shadow"
                                     style="max-height: 400px; width: auto;">
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información detallada -->
            <div class="row">
                
                <!-- Información básica -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header text-white" style="background-color: var(--naranja);">
                            <h6 class="mb-0">
                                <i class="fas fa-info-circle mr-2"></i>Información Básica
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (propiedad.get("descripcion") != null) { %>
                                <p class="mb-3"><%= propiedad.get("descripcion") %></p>
                                <hr>
                            <% } %>
                            
                            <table class="table table-borderless">
                                <tr>
                                    <td class="font-weight-bold">ID:</td>
                                    <td>#<%= propiedad.get("id") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Tipo:</td>
                                    <td><%= propiedad.get("nombre_tipo") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Operación:</td>
                                    <td>
                                        <span class="badge badge-primary">
                                            <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Precio:</td>
                                    <td class="text-success font-weight-bold">
                                        $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                    </td>
                                </tr>
                                <% if (propiedad.get("codigo_postal") != null) { %>
                                <tr>
                                    <td class="font-weight-bold">Código Postal:</td>
                                    <td><%= propiedad.get("codigo_postal") %></td>
                                </tr>
                                <% } %>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Características -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header bg-success text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-list-ul mr-2"></i>Características
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <% if ((Double)propiedad.get("area_construida") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-home fa-2x text-primary mb-2"></i>
                                        <h5><%= String.format("%.0f", (Double)propiedad.get("area_construida")) %>m²</h5>
                                        <small class="text-muted">Área Construida</small>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if ((Double)propiedad.get("area_total") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-expand-arrows-alt fa-2x text-primary mb-2"></i>
                                        <h5><%= String.format("%.0f", (Double)propiedad.get("area_total")) %>m²</h5>
                                        <small class="text-muted">Área Total</small>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if ((Integer)propiedad.get("habitaciones") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-bed fa-2x text-primary mb-2"></i>
                                        <h5><%= propiedad.get("habitaciones") %></h5>
                                        <small class="text-muted">Habitaciones</small>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if ((Integer)propiedad.get("banos") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-bath fa-2x text-primary mb-2"></i>
                                        <h5><%= propiedad.get("banos") %></h5>
                                        <small class="text-muted">Baños</small>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if ((Integer)propiedad.get("garajes") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-car fa-2x text-primary mb-2"></i>
                                        <h5><%= propiedad.get("garajes") %></h5>
                                        <small class="text-muted">Garajes</small>
                                    </div>
                                </div>
                                <% } %>
                                
                                <% if ((Integer)propiedad.get("piso") > 0) { %>
                                <div class="col-6 mb-3">
                                    <div class="text-center">
                                        <i class="fas fa-layer-group fa-2x text-primary mb-2"></i>
                                        <h5><%= propiedad.get("piso") %></h5>
                                        <small class="text-muted">Piso</small>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información del propietario -->
            <div class="row">
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header text-white" style="background-color: var(--amarillo); color: #000 !important;">
                            <h6 class="mb-0">
                                <i class="fas fa-user mr-2"></i>Información del Propietario
                            </h6>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless">
                                <tr>
                                    <td class="font-weight-bold">Nombre:</td>
                                    <td><%= propiedad.get("propietario_nombre") %> <%= propiedad.get("propietario_apellido") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Email:</td>
                                    <td>
                                        <a href="mailto:<%= propiedad.get("propietario_email") %>">
                                            <%= propiedad.get("propietario_email") %>
                                        </a>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Teléfono:</td>
                                    <td>
                                        <% if (propiedad.get("propietario_telefono") != null) { %>
                                            <a href="tel:<%= propiedad.get("propietario_telefono") %>">
                                                <%= propiedad.get("propietario_telefono") %>
                                            </a>
                                        <% } else { %>
                                            <span class="text-muted">No registrado</span>
                                        <% } %>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Multimedia y fechas -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow">
                        <div class="card-header text-white" style="background-color: var(--rojo);">
                            <h6 class="mb-0">
                                <i class="fas fa-photo-video mr-2"></i>Multimedia y Fechas
                            </h6>
                        </div>
                        <div class="card-body">
                            <!-- Multimedia -->
                            <% if (propiedad.get("video_url") != null || propiedad.get("tour_virtual_url") != null) { %>
                                <div class="mb-3">
                                    <h6>Multimedia:</h6>
                                    <% if (propiedad.get("video_url") != null) { %>
                                        <a href="<%= propiedad.get("video_url") %>" target="_blank" class="btn btn-sm btn-danger mr-2">
                                            <i class="fab fa-youtube mr-1"></i>Ver Video
                                        </a>
                                    <% } %>
                                    <% if (propiedad.get("tour_virtual_url") != null) { %>
                                        <a href="<%= propiedad.get("tour_virtual_url") %>" target="_blank" class="btn btn-sm btn-info">
                                            <i class="fas fa-vr-cardboard mr-1"></i>Tour Virtual
                                        </a>
                                    <% } %>
                                </div>
                                <hr>
                            <% } %>
                            
                            <!-- Fechas -->
                            <table class="table table-borderless">
                                <tr>
                                    <td class="font-weight-bold">Publicada:</td>
                                    <td>
                                        <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(propiedad.get("fecha_publicacion")) %>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Actualizada:</td>
                                    <td>
                                        <% if (propiedad.get("fecha_actualizacion") != null) { %>
                                            <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(propiedad.get("fecha_actualizacion")) %>
                                        <% } else { %>
                                            <span class="text-muted">No actualizada</span>
                                        <% } %>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Citas para esta propiedad -->
            <% if (!citasPropiedad.isEmpty()) { %>
            <div class="row">
                <div class="col-12 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-primary text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-calendar-alt mr-2"></i>Citas Programadas 
                                <span class="badge badge-light ml-2"><%= citasPropiedad.size() %></span>
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>ID</th>
                                            <th>Cliente</th>
                                            <th>Fecha y Hora</th>
                                            <th>Estado</th>
                                            <th>Teléfono</th>
                                            <th>Notas</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (Map<String, Object> cita : citasPropiedad) { %>
                                        <tr>
                                            <td>#<%= cita.get("id") %></td>
                                            <td>
                                                <div>
                                                    <strong><%= cita.get("cliente_nombre") %> <%= cita.get("cliente_apellido") %></strong><br>
                                                    <small class="text-muted">
                                                        <a href="mailto:<%= cita.get("cliente_email") %>">
                                                            <%= cita.get("cliente_email") %>
                                                        </a>
                                                    </small>
                                                </div>
                                            </td>
                                            <td>
                                                <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(cita.get("fecha_cita")) %>
                                            </td>
                                            <td>
                                                <% 
                                                    String estado = (String) cita.get("estado");
                                                    String badgeClass = "badge-secondary";
                                                    if ("PENDIENTE".equals(estado)) badgeClass = "badge-warning";
                                                    else if ("CONFIRMADA".equals(estado)) badgeClass = "badge-info";
                                                    else if ("REALIZADA".equals(estado)) badgeClass = "badge-success";
                                                    else if ("CANCELADA".equals(estado)) badgeClass = "badge-danger";
                                                %>
                                                <span class="badge <%= badgeClass %>"><%= estado %></span>
                                            </td>
                                            <td>
                                                <% if (cita.get("telefono_contacto") != null) { %>
                                                    <a href="tel:<%= cita.get("telefono_contacto") %>">
                                                        <%= cita.get("telefono_contacto") %>
                                                    </a>
                                                <% } else if (cita.get("cliente_telefono") != null) { %>
                                                    <a href="tel:<%= cita.get("cliente_telefono") %>">
                                                        <%= cita.get("cliente_telefono") %>
                                                    </a>
                                                <% } else { %>
                                                    <span class="text-muted">No registrado</span>
                                                <% } %>
                                            </td>
                                            <td>
                                                <% if (cita.get("notas") != null) { %>
                                                    <%= cita.get("notas") %>
                                                <% } else { %>
                                                    <span class="text-muted">Sin notas</span>
                                                <% } %>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Imágenes adicionales -->
            <% if (!imagenes.isEmpty()) { %>
            <div class="row">
                <div class="col-12 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-secondary text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-images mr-2"></i>Galería de Imágenes 
                                <span class="badge badge-light ml-2"><%= imagenes.size() %></span>
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <% for (Map<String, Object> imagen : imagenes) { %>
                                <div class="col-md-3 col-sm-6 mb-3">
                                    <div class="card">
                                        <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= imagen.get("ruta_archivo") %>" 
                                             alt="<%= imagen.get("nombre_archivo") %>" 
                                             class="card-img-top img-gallery"
                                             onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'"
                                             data-toggle="modal" 
                                             data-target="#modalImagen"
                                             data-src="<%= request.getContextPath() %>/assets/uploads/properties/<%= imagen.get("ruta_archivo") %>"
                                             style="cursor: pointer;">
                                        <div class="card-footer text-center">
                                            <small class="text-muted">
                                                <% if ((Boolean)imagen.get("es_principal")) { %>
                                                    <i class="fas fa-star text-warning mr-1"></i>Principal
                                                <% } else { %>
                                                    <i class="fas fa-image mr-1"></i>Orden: <%= imagen.get("orden_imagen") %>
                                                <% } %>
                                            </small>
                                        </div>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <% } %>
            
        </div>
    </div>
</div>

<!-- Modal para ver imagen ampliada -->
<div class="modal fade" id="modalImagen" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <i class="fas fa-image mr-2"></i>Imagen de la Propiedad
                </h5>
                <button type="button" class="close" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body text-center">
                <img id="imagenAmpliada" src="" alt="Imagen ampliada" class="img-fluid">
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

.table-borderless td {
    border: none;
    padding: 0.75rem 0.75rem;
}

.card {
    border: none;
    border-radius: 10px;
}

.border-left-primary {
    border-left: 0.25rem solid var(--vino) !important;
}

.img-gallery {
    height: 200px;
    object-fit: cover;
    transition: transform 0.2s;
}

.img-gallery:hover {
    transform: scale(1.05);
}

@media (max-width: 768px) {
    .table-responsive {
        font-size: 0.85rem;
    }
    
    .btn-group-vertical .btn {
        margin-bottom: 2px;
        font-size: 0.75rem;
    }
    
    .img-gallery {
        height: 150px;
    }
}
</style>

<!-- JavaScript para funcionalidades -->

<script>
// Variables globales para manejar favoritos
let esFavorito = false;
const propiedadId = <%= propiedad.get("id") %>;

// Verificar estado de favorito al cargar la página
document.addEventListener('DOMContentLoaded', function() {
    // Solo verificar si es cliente
    <% if ("CLIENTE".equals(usuarioRol)) { %>
        verificarFavorito();
    <% } %>
});

// Función para verificar si la propiedad está en favoritos
function verificarFavorito() {
    fetch('verificarFavorito.jsp?propiedadId=' + propiedadId, {
        method: 'GET',
        headers: {
            'Cache-Control': 'no-cache'
        }
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Error en la respuesta del servidor');
        }
        return response.json();
    })
    .then(data => {
        if (data.error) {
            console.error('Error al verificar favorito:', data.error);
            return;
        }
        esFavorito = data.esFavorito;
        actualizarBotonFavorito();
    })
    .catch(error => {
        console.error('Error al verificar favorito:', error);
    });
}

// Función principal para gestionar favoritos
function toggleFavorito(id) {
    const action = esFavorito ? 'remove' : 'add';
    const btn = document.getElementById('btnFavorito');
    
    // Deshabilitar botón durante la operación
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i>Procesando...';
    
    fetch('gestionarFavorito.jsp', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Cache-Control': 'no-cache'
        },
        body: 'action=' + encodeURIComponent(action) + '&propiedadId=' + encodeURIComponent(id)
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Error en la respuesta del servidor');
        }
        return response.json();
    })
    .then(data => {
        // Rehabilitar botón
        btn.disabled = false;
        
        if (data.success) {
            // Cambiar estado
            esFavorito = !esFavorito;
            actualizarBotonFavorito();
            
            // Mostrar notificación de éxito
            mostrarNotificacion(data.message, 'success');
        } else {
            // Mostrar error pero mantener estado actual
            actualizarBotonFavorito();
            mostrarNotificacion(data.message, 'error');
        }
    })
    .catch(error => {
        // Rehabilitar botón en caso de error
        btn.disabled = false;
        actualizarBotonFavorito();
        
        console.error('Error:', error);
        mostrarNotificacion('Error de conexión. Intenta nuevamente.', 'error');
    });
}

// Actualizar la apariencia del botón de favoritos
function actualizarBotonFavorito() {
    const btn = document.getElementById('btnFavorito');
    if (!btn) return;
    
    if (esFavorito) {
        btn.innerHTML = '<i class="fas fa-heart mr-1"></i>En Favoritos';
        btn.className = 'btn btn-danger';
        btn.title = 'Eliminar de favoritos';
    } else {
        btn.innerHTML = '<i class="far fa-heart mr-1"></i>Agregar a Favoritos';
        btn.className = 'btn btn-outline-danger';
        btn.title = 'Agregar a favoritos';
    }
}

// Mostrar notificaciones temporales
function mostrarNotificacion(mensaje, tipo) {
    // Remover notificaciones anteriores
    const notificacionesAnteriores = document.querySelectorAll('.notificacion-favorito');
    notificacionesAnteriores.forEach(notif => notif.remove());
    
    const alertClass = tipo === 'success' ? 'alert-success' : 'alert-danger';
    const iconClass = tipo === 'success' ? 'fa-check-circle' : 'fa-exclamation-triangle';
    
    const alert = document.createElement('div');
    alert.className = `alert ${alertClass} alert-dismissible fade show notificacion-favorito`;
    alert.style.position = 'fixed';
    alert.style.top = '20px';
    alert.style.right = '20px';
    alert.style.zIndex = '9999';
    alert.style.minWidth = '300px';
    alert.innerHTML = `
        <i class="fas ${iconClass} mr-2"></i>
        ${mensaje}
        <button type="button" class="close" onclick="this.parentElement.remove()">
            <span>&times;</span>
        </button>
    `;
    
    // Agregar al body
    document.body.appendChild(alert);
    
    // Auto-ocultar después de 4 segundos
    setTimeout(() => {
        if (alert.parentElement) {
            alert.style.transition = 'opacity 0.5s';
            alert.style.opacity = '0';
            setTimeout(() => {
                if (alert.parentElement) {
                    alert.remove();
                }
            }, 500);
        }
    }, 4000);
}
</script>
<script>
// Modal de imagen ampliada
$('#modalImagen').on('show.bs.modal', function (event) {
    var button = $(event.relatedTarget);
    var imageSrc = button.data('src');
    var modal = $(this);
    modal.find('#imagenAmpliada').attr('src', imageSrc);
});

// Auto-ocultar alertas después de 5 segundos
document.addEventListener('DOMContentLoaded', function() {
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        if (alert.classList.contains('alert-success') || alert.classList.contains('alert-warning')) {
            setTimeout(() => {
                alert.style.transition = 'opacity 0.5s';
                alert.style.opacity = '0';
                setTimeout(() => alert.remove(), 500);
            }, 5000);
        }
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />