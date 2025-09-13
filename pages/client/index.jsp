<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea cliente
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null || !"CLIENTE".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para estadísticas del cliente
    int totalFavoritos = 0;
    int citasPendientes = 0;
    int citasRealizadas = 0;
    int totalCitas = 0;
    List<Map<String, Object>> citasRecientes = new ArrayList<>();
    List<Map<String, Object>> propiedadesRecomendadas = new ArrayList<>();
    List<Map<String, Object>> propiedadesFavoritas = new ArrayList<>();
    
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Obtener total de favoritos
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM favoritos WHERE id_usuario = ?");
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalFavoritos = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Obtener estadísticas de citas
        stmt = conn.prepareStatement("SELECT estado, COUNT(*) as cantidad FROM citas WHERE id_cliente = ? GROUP BY estado");
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        while (rs.next()) {
            String estado = rs.getString("estado");
            int cantidad = rs.getInt("cantidad");
            totalCitas += cantidad;
            
            if ("PENDIENTE".equals(estado) || "CONFIRMADA".equals(estado)) {
                citasPendientes += cantidad;
            } else if ("REALIZADA".equals(estado)) {
                citasRealizadas = cantidad;
            }
        }
        rs.close();
        stmt.close();
        
        // Obtener citas recientes (últimas 5)
        stmt = conn.prepareStatement(
            "SELECT c.*, p.titulo, p.direccion, p.ciudad, p.precio, p.imagen_principal " +
            "FROM citas c " +
            "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
            "WHERE c.id_cliente = ? " +
            "ORDER BY c.fecha_solicitud DESC " +
            "LIMIT 5"
        );
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> cita = new HashMap<>();
            cita.put("id", rs.getInt("id_cita"));
            cita.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            cita.put("estado", rs.getString("estado"));
            cita.put("notas", rs.getString("notas"));
            cita.put("propiedad_titulo", rs.getString("titulo"));
            cita.put("propiedad_direccion", rs.getString("direccion"));
            cita.put("propiedad_ciudad", rs.getString("ciudad"));
            cita.put("propiedad_precio", rs.getLong("precio"));
            cita.put("propiedad_imagen", rs.getString("imagen_principal"));
            cita.put("propiedad_id", rs.getInt("id_propiedad"));
            citasRecientes.add(cita);
        }
        rs.close();
        stmt.close();
        
        // Obtener propiedades favoritas (últimas 6)
        stmt = conn.prepareStatement(
            "SELECT p.*, tp.nombre_tipo " +
            "FROM favoritos f " +
            "INNER JOIN propiedades p ON f.id_propiedad = p.id_propiedad " +
            "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
            "WHERE f.id_usuario = ? AND p.disponible = 1 " +
            "ORDER BY f.fecha_agregado DESC " +
            "LIMIT 6"
        );
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedadesFavoritas.add(propiedad);
        }
        rs.close();
        stmt.close();
        
        // Obtener propiedades recomendadas (últimas 6 disponibles)
        stmt = conn.prepareStatement(
            "SELECT p.*, tp.nombre_tipo " +
            "FROM propiedades p " +
            "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
            "WHERE p.disponible = 1 " +
            "ORDER BY p.destacada DESC, p.fecha_publicacion DESC " +
            "LIMIT 6"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedadesRecomendadas.add(propiedad);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar información: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Dashboard Cliente" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        <!-- sidebar-->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="dashboard" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Bienvenida -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="jumbotron jumbotron-fluid" style="background: linear-gradient(135deg, var(--vino), var(--rojo)); color: white;">
                        <div class="container">
                            <h1 class="display-5">¡Bienvenido, <%= nombreUsuario %>!</h1>
                            <p class="lead">Encuentra la propiedad perfecta para ti. Explora, guarda tus favoritos y programa citas para visitarlas.</p>
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
            
            <!-- Estadísticas rápidas -->
            <div class="row mb-4">
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--vino), #8e3a4a);">
                        <div class="card-body text-center">
                            <i class="fas fa-heart fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= totalFavoritos %></h4>
                            <p class="mb-0">Propiedades Favoritas</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--naranja), #f39c12);">
                        <div class="card-body text-center">
                            <i class="fas fa-calendar-alt fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= citasPendientes %></h4>
                            <p class="mb-0">Citas Pendientes</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--amarillo), #f1c40f);">
                        <div class="card-body text-center">
                            <i class="fas fa-check-circle fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= citasRealizadas %></h4>
                            <p class="mb-0">Visitas Realizadas</p>
                        </div>
                    </div>
                </div>
                <div class="col-lg-3 col-md-6 mb-3">
                    <div class="card text-white h-100" style="background: linear-gradient(135deg, var(--rojo), #e74c3c);">
                        <div class="card-body text-center">
                            <i class="fas fa-clipboard-list fa-2x mb-2"></i>
                            <h4 class="font-weight-bold"><%= totalCitas %></h4>
                            <p class="mb-0">Total de Citas</p>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Acciones rápidas -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--vino); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-bolt mr-2"></i>Acciones Rápidas
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-3 mb-3">
                                    <a href="../properties/list-properties.jsp" class="btn btn-primary btn-block btn-lg">
                                        <i class="fas fa-search mr-2"></i>
                                        Buscar Propiedades
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="favoritos.jsp" class="btn btn-danger btn-block btn-lg">
                                        <i class="fas fa-heart mr-2"></i>
                                        Ver Favoritos
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="../citas/crearCita.jsp" class="btn btn-warning btn-block btn-lg">
                                        <i class="fas fa-calendar-plus mr-2"></i>
                                        Programar Cita
                                    </a>
                                </div>
                                <div class="col-md-3 mb-3">
                                    <a href="perfil.jsp" class="btn btn-info btn-block btn-lg">
                                        <i class="fas fa-user-edit mr-2"></i>
                                        Editar Perfil
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Citas recientes -->
            <% if (!citasRecientes.isEmpty()) { %>
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--naranja); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-clock mr-2"></i>Mis Citas Recientes
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead class="thead-light">
                                        <tr>
                                            <th>Propiedad</th>
                                            <th>Fecha y Hora</th>
                                            <th>Estado</th>
                                            <th>Acciones</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <% for (Map<String, Object> cita : citasRecientes) { 
                                            String estado = (String) cita.get("estado");
                                            String badgeClass = "";
                                            switch (estado) {
                                                case "PENDIENTE": badgeClass = "badge-warning"; break;
                                                case "CONFIRMADA": badgeClass = "badge-info"; break;
                                                case "REALIZADA": badgeClass = "badge-success"; break;
                                                case "CANCELADA": badgeClass = "badge-danger"; break;
                                                default: badgeClass = "badge-secondary";
                                            }
                                        %>
                                        <tr>
                                            <td>
                                                <div class="d-flex align-items-center">
                                                    <% if (cita.get("propiedad_imagen") != null) { %>
                                                        <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= cita.get("propiedad_imagen") %>" 
                                                             alt="Propiedad" class="rounded mr-3" style="width: 50px; height: 50px; object-fit: cover;"
                                                             onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                                    <% } else { %>
                                                        <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                                             alt="Sin imagen" class="rounded mr-3" style="width: 50px; height: 50px; object-fit: cover;">
                                                    <% } %>
                                                    <div>
                                                        <strong><%= cita.get("propiedad_titulo") %></strong><br>
                                                        <small class="text-muted"><%= cita.get("propiedad_direccion") %>, <%= cita.get("propiedad_ciudad") %></small><br>
                                                        <small class="text-success font-weight-bold">$<%= String.format("%,d", (Long)cita.get("propiedad_precio")) %></small>
                                                    </div>
                                                </div>
                                            </td>
                                            <td>
                                                <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format(cita.get("fecha_cita")) %>
                                            </td>
                                            <td>
                                                <span class="badge <%= badgeClass %>"><%= estado %></span>
                                            </td>
                                            <td>
                                                <a href="../properties/verPropiedad.jsp?id=<%= cita.get("propiedad_id") %>" 
                                                   class="btn btn-sm btn-outline-primary" title="Ver propiedad">
                                                    <i class="fas fa-eye"></i>
                                                </a>
                                                <% if ("PENDIENTE".equals(estado)) { %>
                                                <a href="citas.jsp#cita-<%= cita.get("id") %>" 
                                                   class="btn btn-sm btn-outline-warning" title="Gestionar cita">
                                                    <i class="fas fa-edit"></i>
                                                </a>
                                                <% } %>
                                            </td>
                                        </tr>
                                        <% } %>
                                    </tbody>
                                </table>
                            </div>
                            <div class="text-center mt-3">
                                <a href="citas.jsp" class="btn btn-outline-primary">
                                    <i class="fas fa-calendar-alt mr-2"></i>Ver Todas las Citas
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Propiedades favoritas -->
            <% if (!propiedadesFavoritas.isEmpty()) { %>
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--rojo); color: white;">
                            <h6 class="mb-0">
                                <i class="fas fa-heart mr-2"></i>Mis Propiedades Favoritas
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <% for (Map<String, Object> propiedad : propiedadesFavoritas) { %>
                                <div class="col-lg-4 col-md-6 mb-4">
                                    <div class="card h-100 property-card">
                                        <% if (propiedad.get("imagen_principal") != null) { %>
                                            <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= propiedad.get("imagen_principal") %>" 
                                                 class="card-img-top" alt="<%= propiedad.get("titulo") %>" style="height: 200px; object-fit: cover;"
                                                 onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                        <% } else { %>
                                            <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                                 class="card-img-top" alt="Sin imagen" style="height: 200px; object-fit: cover;">
                                        <% } %>
                                        
                                        <div class="card-body">
                                            <h6 class="card-title"><%= propiedad.get("titulo") %></h6>
                                            <p class="text-muted mb-2">
                                                <i class="fas fa-map-marker-alt mr-1"></i>
                                                <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %>
                                            </p>
                                            <p class="text-success font-weight-bold mb-2">
                                                $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                            </p>
                                            <p class="mb-2">
                                                <span class="badge badge-info"><%= propiedad.get("nombre_tipo") %></span>
                                                <span class="badge badge-primary">
                                                    <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                                </span>
                                            </p>
                                            <div class="d-flex justify-content-between text-muted mb-3">
                                                <% if ((Integer)propiedad.get("habitaciones") > 0) { %>
                                                    <small><i class="fas fa-bed mr-1"></i><%= propiedad.get("habitaciones") %></small>
                                                <% } %>
                                                <% if ((Integer)propiedad.get("banos") > 0) { %>
                                                    <small><i class="fas fa-bath mr-1"></i><%= propiedad.get("banos") %></small>
                                                <% } %>
                                                <% if ((Double)propiedad.get("area_construida") > 0) { %>
                                                    <small><i class="fas fa-home mr-1"></i><%= String.format("%.0f", (Double)propiedad.get("area_construida")) %>m²</small>
                                                <% } %>
                                            </div>
                                        </div>
                                        <div class="card-footer bg-transparent">
                                            <div class="row">
                                                <div class="col-6">
                                                    <a href="../properties/verPropiedad.jsp?id=<%= propiedad.get("id") %>" 
                                                       class="btn btn-primary btn-sm btn-block">
                                                        <i class="fas fa-eye mr-1"></i>Ver
                                                    </a>
                                                </div>
                                                <div class="col-6">
                                                    <a href="solicitarCita.jsp?propiedad=<%= propiedad.get("id") %>" 
                                                       class="btn btn-success btn-sm btn-block">
                                                        <i class="fas fa-calendar-plus mr-1"></i>Cita
                                                    </a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                            <div class="text-center">
                                <a href="favoritos.jsp" class="btn btn-outline-danger">
                                    <i class="fas fa-heart mr-2"></i>Ver Todos los Favoritos
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Propiedades recomendadas -->
            <div class="row">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header" style="background-color: var(--amarillo); color: #000;">
                            <h6 class="mb-0">
                                <i class="fas fa-star mr-2"></i>Propiedades Recomendadas Para Ti
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (!propiedadesRecomendadas.isEmpty()) { %>
                            <div class="row">
                                <% for (Map<String, Object> propiedad : propiedadesRecomendadas) { %>
                                <div class="col-lg-4 col-md-6 mb-4">
                                    <div class="card h-100 property-card">
                                        <% if ((Boolean)propiedad.get("destacada")) { %>
                                            <div class="position-absolute" style="top: 10px; left: 10px; z-index: 10;">
                                                <span class="badge badge-warning">
                                                    <i class="fas fa-star mr-1"></i>Destacada
                                                </span>
                                            </div>
                                        <% } %>
                                        
                                        <% if (propiedad.get("imagen_principal") != null) { %>
                                            <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= propiedad.get("imagen_principal") %>" 
                                                 class="card-img-top" alt="<%= propiedad.get("titulo") %>" style="height: 200px; object-fit: cover;"
                                                 onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                        <% } else { %>
                                            <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                                 class="card-img-top" alt="Sin imagen" style="height: 200px; object-fit: cover;">
                                        <% } %>
                                        
                                        <div class="card-body">
                                            <h6 class="card-title"><%= propiedad.get("titulo") %></h6>
                                            <p class="text-muted mb-2">
                                                <i class="fas fa-map-marker-alt mr-1"></i>
                                                <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %>
                                            </p>
                                            <p class="text-success font-weight-bold mb-2">
                                                $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                            </p>
                                            <p class="mb-2">
                                                <span class="badge badge-info"><%= propiedad.get("nombre_tipo") %></span>
                                                <span class="badge badge-primary">
                                                    <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                                </span>
                                            </p>
                                            <div class="d-flex justify-content-between text-muted mb-3">
                                                <% if ((Integer)propiedad.get("habitaciones") > 0) { %>
                                                    <small><i class="fas fa-bed mr-1"></i><%= propiedad.get("habitaciones") %></small>
                                                <% } %>
                                                <% if ((Integer)propiedad.get("banos") > 0) { %>
                                                    <small><i class="fas fa-bath mr-1"></i><%= propiedad.get("banos") %></small>
                                                <% } %>
                                                <% if ((Double)propiedad.get("area_construida") > 0) { %>
                                                    <small><i class="fas fa-home mr-1"></i><%= String.format("%.0f", (Double)propiedad.get("area_construida")) %>m²</small>
                                                <% } %>
                                            </div>
                                        </div>
                                        <div class="card-footer bg-transparent">
                                            <div class="row">
                                                <div class="col-6">
                                                    <a href="../properties/verPropiedad.jsp?id=<%= propiedad.get(" id") %>"
                                                        class="btn btn-primary btn-sm btn-block">
                                                        <i class="fas fa-eye mr-1"></i>Ver
                                                    </a>
                                                </div>
                                                <div class="col-6">
                                                    <a href="solicitarCita.jsp?propiedad=<%= propiedad.get("id") %>" 
                                                       class="btn btn-success btn-sm btn-block">
                                                        <i class="fas fa-calendar-plus mr-1"></i>Cita
                                                    </a>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <% } %>
                            </div>
                            <% } else { %>
                            <div class="text-center py-5">
                                <i class="fas fa-home fa-3x text-muted mb-3"></i>
                                <h5 class="text-muted">No hay propiedades disponibles</h5>
                                <p class="text-muted">Las propiedades aparecerán aquí cuando estén disponibles.</p>
                                <a href="../properties/list-properties.jsp" class="btn btn-primary">
                                    <i class="fas fa-search mr-2"></i>Buscar Propiedades
                                </a>
                            </div>
                            <% } %>
                            
                            <div class="text-center mt-3">
                                <a href="../properties/list-properties.jsp" class="btn btn-outline-primary">
                                    <i class="fas fa-search mr-2"></i>Ver Todas las Propiedades
                                </a>
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

.jumbotron {
    border-radius: 15px;
    margin-bottom: 2rem;
}

.property-card {
    transition: transform 0.2s, box-shadow 0.2s;
    border: 1px solid #e0e0e0;
}

.property-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

.opacity-75 {
    opacity: 0.75;
}

.badge-pill {
    font-size: 0.7rem;
}

@media (max-width: 768px) {
    .jumbotron {
        padding: 2rem 1rem;
    }
    
    .jumbotron .display-5 {
        font-size: 1.8rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .btn-lg {
        padding: 0.5rem 1rem;
        font-size: 1rem;
    }
}

.table th {
    border-top: none;
    font-weight: 600;
    color: var(--vino);
}

.list-group-item.active {
    background-color: var(--vino);
    border-color: var(--vino);
}

.list-group-item:hover {
    background-color: #f8f9fa;
}
</style>

<!-- JavaScript para interactividad -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Animar las tarjetas de estadísticas al cargar
    const cards = document.querySelectorAll('.card');
    cards.forEach((card, index) => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        
        setTimeout(() => {
            card.style.transition = 'all 0.5s ease';
            card.style.opacity = '1';
            card.style.transform = 'translateY(0)';
        }, index * 100);
    });
    
    // Agregar efecto de hover a las tarjetas de propiedades
    const propertyCards = document.querySelectorAll('.property-card');
    propertyCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
        });
    });
    
    // Auto-dismiss de alertas después de 5 segundos
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            if (alert.querySelector('.close')) {
                alert.querySelector('.close').click();
            }
        }, 5000);
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />