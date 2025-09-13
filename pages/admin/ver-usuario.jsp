<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID del usuario a ver
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("usuarios.jsp");
        return;
    }
    
    // Variables para almacenar datos del usuario
    Map<String, Object> usuario = null;
    List<Map<String, Object>> propiedadesUsuario = new ArrayList<>();
    List<Map<String, Object>> citasUsuario = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Obtener información completa del usuario
        String sqlUsuario = "SELECT u.*, r.nombre_rol, r.descripcion as rol_descripcion " +
                           "FROM usuarios u " +
                           "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                           "WHERE u.id_usuario = ?";
        
        stmt = conn.prepareStatement(sqlUsuario);
        stmt.setInt(1, Integer.parseInt(idParam));
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            usuario = new HashMap<>();
            usuario.put("id", rs.getInt("id_usuario"));
            usuario.put("nombre", rs.getString("nombre"));
            usuario.put("apellido", rs.getString("apellido"));
            usuario.put("email", rs.getString("email"));
            usuario.put("telefono", rs.getString("telefono"));
            usuario.put("direccion", rs.getString("direccion"));
            usuario.put("fecha_nacimiento", rs.getDate("fecha_nacimiento"));
            usuario.put("id_rol", rs.getInt("id_rol"));
            usuario.put("nombre_rol", rs.getString("nombre_rol"));
            usuario.put("rol_descripcion", rs.getString("rol_descripcion"));
            usuario.put("activo", rs.getBoolean("activo"));
            usuario.put("fecha_registro", rs.getTimestamp("fecha_registro"));
            usuario.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
        } else {
            mensaje = "Usuario no encontrado.";
            tipoMensaje = "error";
        }
        rs.close();
        stmt.close();
        
        // Si el usuario existe, obtener sus propiedades (si es inmobiliaria)
        if (usuario != null && (Integer)usuario.get("id_rol") == 4) {
            String sqlPropiedades = "SELECT p.id_propiedad, p.titulo, p.precio, p.ciudad, " +
                                   "p.tipo_operacion, p.disponible, p.destacada, tp.nombre_tipo " +
                                   "FROM propiedades p " +
                                   "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                                   "WHERE p.id_propietario = ? " +
                                   "ORDER BY p.fecha_publicacion DESC";
            
            stmt = conn.prepareStatement(sqlPropiedades);
            stmt.setInt(1, Integer.parseInt(idParam));
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> propiedad = new HashMap<>();
                propiedad.put("id", rs.getInt("id_propiedad"));
                propiedad.put("titulo", rs.getString("titulo"));
                propiedad.put("precio", rs.getLong("precio"));
                propiedad.put("ciudad", rs.getString("ciudad"));
                propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
                propiedad.put("disponible", rs.getBoolean("disponible"));
                propiedad.put("destacada", rs.getBoolean("destacada"));
                propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
                propiedadesUsuario.add(propiedad);
            }
            rs.close();
            stmt.close();
        }
        
        // Obtener citas del usuario (si es cliente)
        if (usuario != null && (Integer)usuario.get("id_rol") == 3) {
            String sqlCitas = "SELECT c.id_cita, c.fecha_cita, c.estado, c.notas, " +
                             "p.titulo as propiedad_titulo, p.ciudad " +
                             "FROM citas c " +
                             "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                             "WHERE c.id_cliente = ? " +
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
                cita.put("propiedad_titulo", rs.getString("propiedad_titulo"));
                cita.put("ciudad", rs.getString("ciudad"));
                citasUsuario.add(cita);
            }
            rs.close();
            stmt.close();
        }
        
    } catch (Exception e) {
        mensaje = "Error al cargar información del usuario: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    // Si no se encontró el usuario, redirigir
    if (usuario == null && mensaje.isEmpty()) {
        response.sendRedirect("usuarios.jsp");
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Detalles de Usuario - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="usuarios" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="index.jsp">Dashboard</a></li>
                    <li class="breadcrumb-item"><a href="usuarios.jsp">Usuarios</a></li>
                    <li class="breadcrumb-item active">Detalles de Usuario</li>
                </ol>
            </nav>
            
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
            
            <% if (usuario != null) { %>
            
            <!-- Header del usuario -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1">
                                        <i class="fas fa-user-circle text-primary mr-2"></i>
                                        <%= usuario.get("nombre") %> <%= usuario.get("apellido") %>
                                        <% if (!(Boolean)usuario.get("activo")) { %>
                                            <span class="badge badge-danger ml-2">Inactivo</span>
                                        <% } else { %>
                                            <span class="badge badge-success ml-2">Activo</span>
                                        <% } %>
                                    </h3>
                                    <p class="text-muted mb-0">
                                        <i class="fas fa-envelope mr-1"></i><%= usuario.get("email") %>
                                        <span class="mx-2">|</span>
                                        <i class="fas fa-user-tag mr-1"></i><%= usuario.get("nombre_rol") %>
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="usuarios.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-1"></i>Volver a Lista
                                    </a>
                                    <a href="usuarios.jsp?action=toggle&userId=<%= usuario.get("id") %>" 
                                       class="btn <%= (Boolean)usuario.get("activo") ? "btn-warning" : "btn-success" %>"
                                       onclick="return confirm('¿Está seguro de cambiar el estado del usuario?')">
                                        <i class="fas fa-<%= (Boolean)usuario.get("activo") ? "ban" : "check" %> mr-1"></i>
                                        <%= (Boolean)usuario.get("activo") ? "Desactivar" : "Activar" %>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información detallada -->
            <div class="row">
                
                <!-- Información personal -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header bg-info text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-user mr-2"></i>Información Personal
                            </h6>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless">
                                <tr>
                                    <td class="font-weight-bold">ID:</td>
                                    <td>#<%= usuario.get("id") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Nombre Completo:</td>
                                    <td><%= usuario.get("nombre") %> <%= usuario.get("apellido") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Email:</td>
                                    <td>
                                        <a href="mailto:<%= usuario.get("email") %>">
                                            <%= usuario.get("email") %>
                                        </a>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Teléfono:</td>
                                    <td>
                                        <% if (usuario.get("telefono") != null) { %>
                                            <a href="tel:<%= usuario.get("telefono") %>">
                                                <%= usuario.get("telefono") %>
                                            </a>
                                        <% } else { %>
                                            <span class="text-muted">No registrado</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Dirección:</td>
                                    <td>
                                        <% if (usuario.get("direccion") != null) { %>
                                            <%= usuario.get("direccion") %>
                                        <% } else { %>
                                            <span class="text-muted">No registrada</span>
                                        <% } %>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Fecha de Nacimiento:</td>
                                    <td>
                                        <% if (usuario.get("fecha_nacimiento") != null) { %>
                                            <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_nacimiento")) %>
                                            <% 
                                                java.util.Date fechaNac = (java.util.Date) usuario.get("fecha_nacimiento");
                                                java.util.Date fechaActual = new java.util.Date();
                                                long diferencia = fechaActual.getTime() - fechaNac.getTime();
                                                int edad = (int) (diferencia / (365.25 * 24 * 60 * 60 * 1000));
                                            %>
                                            <small class="text-muted">(<%= edad %> años)</small>
                                        <% } else { %>
                                            <span class="text-muted">No registrada</span>
                                        <% } %>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
                
                <!-- Información del sistema -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header bg-secondary text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-cog mr-2"></i>Información del Sistema
                            </h6>
                        </div>
                        <div class="card-body">
                            <table class="table table-borderless">
                                <tr>
                                    <td class="font-weight-bold">Rol:</td>
                                    <td>
                                        <span class="badge badge-primary badge-lg">
                                            <%= usuario.get("nombre_rol") %>
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Descripción del Rol:</td>
                                    <td><%= usuario.get("rol_descripcion") %></td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Estado:</td>
                                    <td>
                                        <span class="badge <%= (Boolean)usuario.get("activo") ? "badge-success" : "badge-danger" %> badge-lg">
                                            <%= (Boolean)usuario.get("activo") ? "Activo" : "Inactivo" %>
                                        </span>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Fecha de Registro:</td>
                                    <td>
                                        <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(usuario.get("fecha_registro")) %>
                                    </td>
                                </tr>
                                <tr>
                                    <td class="font-weight-bold">Última Actualización:</td>
                                    <td>
                                        <% if (usuario.get("fecha_actualizacion") != null) { %>
                                            <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(usuario.get("fecha_actualizacion")) %>
                                        <% } else { %>
                                            <span class="text-muted">No actualizado</span>
                                        <% } %>
                                    </td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Propiedades (solo para inmobiliarias) -->
            <% if ((Integer)usuario.get("id_rol") == 4) { %>
            <div class="row">
                <div class="col-12 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-success text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-building mr-2"></i>Propiedades Publicadas 
                                <span class="badge badge-light ml-2"><%= propiedadesUsuario.size() %></span>
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (!propiedadesUsuario.isEmpty()) { %>
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>ID</th>
                                                <th>Título</th>
                                                <th>Tipo</th>
                                                <th>Ciudad</th>
                                                <th>Precio</th>
                                                <th>Operación</th>
                                                <th>Estado</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> propiedad : propiedadesUsuario) { %>
                                            <tr>
                                                <td>#<%= propiedad.get("id") %></td>
                                                <td><%= propiedad.get("titulo") %></td>
                                                <td><%= propiedad.get("nombre_tipo") %></td>
                                                <td><%= propiedad.get("ciudad") %></td>
                                                <td class="text-success font-weight-bold">
                                                    $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                                </td>
                                                <td>
                                                    <span class="badge badge-info">
                                                        <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                                    </span>
                                                </td>
                                                <td>
                                                    <span class="badge <%= (Boolean)propiedad.get("disponible") ? "badge-success" : "badge-secondary" %>">
                                                        <%= (Boolean)propiedad.get("disponible") ? "Disponible" : "No Disponible" %>
                                                    </span>
                                                    <% if ((Boolean)propiedad.get("destacada")) { %>
                                                        <span class="badge badge-warning ml-1">Destacada</span>
                                                    <% } %>
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                            <% } else { %>
                                <div class="text-center py-4">
                                    <i class="fas fa-building fa-3x text-muted mb-3"></i>
                                    <h5 class="text-muted">No ha publicado propiedades</h5>
                                    <p class="text-muted">Este usuario no tiene propiedades registradas en el sistema.</p>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Citas (solo para clientes) -->
            <% if ((Integer)usuario.get("id_rol") == 3) { %>
            <div class="row">
                <div class="col-12 mb-4">
                    <div class="card shadow">
                        <div class="card-header bg-warning text-dark">
                            <h6 class="mb-0">
                                <i class="fas fa-calendar-alt mr-2"></i>Citas Programadas 
                                <span class="badge badge-dark ml-2"><%= citasUsuario.size() %></span>
                            </h6>
                        </div>
                        <div class="card-body">
                            <% if (!citasUsuario.isEmpty()) { %>
                                <div class="table-responsive">
                                    <table class="table table-hover">
                                        <thead class="thead-light">
                                            <tr>
                                                <th>ID</th>
                                                <th>Fecha y Hora</th>
                                                <th>Propiedad</th>
                                                <th>Ciudad</th>
                                                <th>Estado</th>
                                                <th>Notas</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> cita : citasUsuario) { %>
                                            <tr>
                                                <td>#<%= cita.get("id") %></td>
                                                <td>
                                                    <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(cita.get("fecha_cita")) %>
                                                </td>
                                                <td><%= cita.get("propiedad_titulo") %></td>
                                                <td><%= cita.get("ciudad") %></td>
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
                            <% } else { %>
                                <div class="text-center py-4">
                                    <i class="fas fa-calendar-times fa-3x text-muted mb-3"></i>
                                    <h5 class="text-muted">No tiene citas programadas</h5>
                                    <p class="text-muted">Este cliente no ha solicitado citas para ver propiedades.</p>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <% } %>
            
        </div>
    </div>
</div>

<!-- Estilos adicionales -->
<style>
.badge-lg {
    padding: 0.5rem 0.75rem;
    font-size: 0.875rem;
}

.table-borderless td {
    border: none;
    padding: 0.75rem 0.75rem;
}

.card {
    border: none;
    border-radius: 10px;
}

@media (max-width: 768px) {
    .table-responsive {
        font-size: 0.85rem;
    }
}
</style>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />