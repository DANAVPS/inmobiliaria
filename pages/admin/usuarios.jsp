<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones (activar/desactivar/eliminar usuarios)
    String action = request.getParameter("action");
    String userIdParam = request.getParameter("userId");
    
    if (action != null && userIdParam != null) {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("toggle".equals(action)) {
                // Obtener estado actual del usuario
                stmt = conn.prepareStatement("SELECT activo FROM usuarios WHERE id_usuario = ?");
                stmt.setInt(1, Integer.parseInt(userIdParam));
                ResultSet rs = stmt.executeQuery();
                
                if (rs.next()) {
                    boolean estadoActual = rs.getBoolean("activo");
                    boolean nuevoEstado = !estadoActual;
                    
                    // Actualizar estado
                    stmt.close();
                    stmt = conn.prepareStatement("UPDATE usuarios SET activo = ? WHERE id_usuario = ?");
                    stmt.setBoolean(1, nuevoEstado);
                    stmt.setInt(2, Integer.parseInt(userIdParam));
                    
                    int resultado = stmt.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Usuario " + (nuevoEstado ? "activado" : "desactivado") + " exitosamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al cambiar el estado del usuario.";
                        tipoMensaje = "error";
                    }
                }
                rs.close();
                
            } else if ("delete".equals(action)) {
                // Verificar que no sea el mismo usuario administrador
                if (Integer.parseInt(userIdParam) == usuarioId) {
                    mensaje = "No puedes eliminar tu propia cuenta.";
                    tipoMensaje = "error";
                } else {
                    // Verificar si el usuario tiene propiedades asociadas
                    stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE id_propietario = ?");
                    stmt.setInt(1, Integer.parseInt(userIdParam));
                    ResultSet rs = stmt.executeQuery();
                    
                    int propiedadesCount = 0;
                    if (rs.next()) {
                        propiedadesCount = rs.getInt(1);
                    }
                    rs.close();
                    stmt.close();
                    
                    if (propiedadesCount > 0) {
                        mensaje = "No se puede eliminar el usuario porque tiene " + propiedadesCount + " propiedades asociadas. Primero debes reasignar o eliminar sus propiedades.";
                        tipoMensaje = "error";
                    } else {
                        // Verificar si tiene citas asociadas
                        stmt = conn.prepareStatement("SELECT COUNT(*) FROM citas WHERE id_cliente = ?");
                        stmt.setInt(1, Integer.parseInt(userIdParam));
                        rs = stmt.executeQuery();
                        
                        int citasCount = 0;
                        if (rs.next()) {
                            citasCount = rs.getInt(1);
                        }
                        rs.close();
                        stmt.close();
                        
                        if (citasCount > 0) {
                            // Eliminar citas primero
                            stmt = conn.prepareStatement("DELETE FROM citas WHERE id_cliente = ?");
                            stmt.setInt(1, Integer.parseInt(userIdParam));
                            stmt.executeUpdate();
                            stmt.close();
                        }
                        
                        // Eliminar favoritos si existen
                        stmt = conn.prepareStatement("DELETE FROM favoritos WHERE id_usuario = ?");
                        stmt.setInt(1, Integer.parseInt(userIdParam));
                        stmt.executeUpdate();
                        stmt.close();
                        
                        // Eliminar usuario
                        stmt = conn.prepareStatement("DELETE FROM usuarios WHERE id_usuario = ?");
                        stmt.setInt(1, Integer.parseInt(userIdParam));
                        
                        int resultado = stmt.executeUpdate();
                        if (resultado > 0) {
                            mensaje = "Usuario eliminado exitosamente.";
                            tipoMensaje = "success";
                        } else {
                            mensaje = "Error al eliminar el usuario.";
                            tipoMensaje = "error";
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            mensaje = "Error: " + e.getMessage();
            tipoMensaje = "error";
        } finally {
            if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }
    
    // Obtener lista de usuarios con paginación
    List<Map<String, Object>> usuarios = new ArrayList<>();
    int totalUsuarios = 0;
    int usuariosActivos = 0;
    int usuariosInactivos = 0;
    int paginaActual = 1;
    int usuariosPorPagina = 10;
    
    try {
        paginaActual = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * usuariosPorPagina;
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Contar total de usuarios
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM usuarios");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalUsuarios = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Obtener usuarios con paginación
        String sql = "SELECT u.id_usuario, u.nombre, u.apellido, u.email, u.telefono, " +
                    "u.activo, u.fecha_registro, r.nombre_rol " +
                    "FROM usuarios u " +
                    "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                    "ORDER BY u.fecha_registro DESC " +
                    "LIMIT ? OFFSET ?";
        
        stmt = conn.prepareStatement(sql);
        stmt.setInt(1, usuariosPorPagina);
        stmt.setInt(2, offset);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> usuario = new HashMap<>();
            usuario.put("id", rs.getInt("id_usuario"));
            usuario.put("nombre", rs.getString("nombre"));
            usuario.put("apellido", rs.getString("apellido"));
            usuario.put("email", rs.getString("email"));
            usuario.put("telefono", rs.getString("telefono"));
    
            boolean activo = rs.getBoolean("activo");
            usuario.put("activo", activo);
    
            usuario.put("fecha_registro", rs.getTimestamp("fecha_registro"));
            usuario.put("rol", rs.getString("nombre_rol"));
            usuarios.add(usuario);
    
            // Contar activos/inactivos
            if (activo) {
                usuariosActivos++;
            } else {
                usuariosInactivos++;
            }
        }   
        
    } catch (Exception e) {
        mensaje = "Error al cargar usuarios: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    int totalPaginas = (int) Math.ceil((double) totalUsuarios / usuariosPorPagina);
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Gestion de Usuarios - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- En cualquier archivo JSP -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="usuarios" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 class="font-weight-bold" style="color: var(--vino);">
                        <i class="fas fa-users mr-2"></i>Gestión de Usuarios
                    </h3>
                    <p class="text-muted mb-0">Administra todos los usuarios del sistema</p>
                </div>
                <a href="../auth/register.jsp" class="btn text-white" style="background-color: var(--vino);">
                    <i class="fas fa-user-plus mr-2"></i>Agregar Usuario
                </a>
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
                <div class="col-md-3">
                    <div class="card text-white" style="background-color: var(--vino);">
                        <div class="card-body text-center">
                            <h4><%= totalUsuarios %></h4>
                            <small>Total Usuarios</small>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center">
                            <h4><%= usuariosActivos %></h4>
                            <small>Activos</small>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white" style="background-color: var(--rojo);">
                        <div class="card-body text-center">
                            <h4><%= usuariosInactivos %></h4>
                            <small>Inactivos</small>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white" style="background-color: var(--naranja);">
                        <div class="card-body text-center">
                            <h4><%= totalPaginas %></h4>
                            <small>Páginas</small>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Tabla de usuarios -->
            <div class="card shadow">
                <div class="card-header bg-light">
                    <div class="row align-items-center">
                        <div class="col">
                            <h6 class="mb-0 font-weight-bold">Lista de Usuarios</h6>
                        </div>
                        <div class="col-auto">
                            <span class="badge badge-secondary">
                                Página <%= paginaActual %> de <%= totalPaginas %>
                            </span>
                        </div>
                    </div>
                </div>
                <div class="card-body p-0">
                    <div class="table-responsive">
                        <table class="table table-hover mb-0">
                            <thead class="thead-light">
                                <tr>
                                    <th>ID</th>
                                    <th>Usuario</th>
                                    <th>Email</th>
                                    <th>Teléfono</th>
                                    <th>Rol</th>
                                    <th>Estado</th>
                                    <th>Fecha Registro</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Map<String, Object> usuario : usuarios) { 
                                    Boolean activo = (Boolean) usuario.get("activo");
                                    String badgeClass = activo ? "badge-success" : "badge-danger";
                                    String estadoTexto = activo ? "Activo" : "Inactivo";
                                    boolean esAdminActual = usuario.get("id").equals(usuarioId);
                                %>
                                <tr class="<%= activo ? "" : "table-light" %>">
                                    <td><strong>#<%= usuario.get("id") %></strong></td>
                                    <td>
                                        <div>
                                            <strong><%= usuario.get("nombre") %> <%= usuario.get("apellido") %></strong>
                                            <% if (esAdminActual) { %>
                                                <span class="badge badge-info ml-1">Tú</span>
                                            <% } %>
                                            <% if (!activo) { %>
                                                <br><small class="text-muted"><i class="fas fa-ban mr-1"></i>Usuario desactivado</small>
                                            <% } %>
                                        </div>
                                    </td>
                                    <td>
                                        <a href="mailto:<%= usuario.get("email") %>" class="text-decoration-none">
                                            <%= usuario.get("email") %>
                                        </a>
                                    </td>
                                    <td>
                                        <% if (usuario.get("telefono") != null) { %>
                                            <a href="tel:<%= usuario.get("telefono") %>" class="text-decoration-none">
                                                <%= usuario.get("telefono") %>
                                            </a>
                                        <% } else { %>
                                            <span class="text-muted">No registrado</span>
                                        <% } %>
                                    </td>
                                    <td>
                                        <span class="badge" style="background-color: var(--vino); color: white;"><%= usuario.get("rol") %></span>
                                    </td>
                                    <td>
                                        <span class="badge <%= badgeClass %>"><%= estadoTexto %></span>
                                    </td>
                                    <td>
                                        <small><%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(usuario.get("fecha_registro")) %></small>
                                    </td>
                                    <td>
                                        <div class="btn-group-vertical btn-group-sm" role="group">
                                            <!-- Ver detalles -->
                                            <a href="ver-usuario.jsp?id=<%= usuario.get("id") %>"
                                                class="btn btn-outline-info btn-sm mb-1"
                                                title="Ver detalles">
                                                <i class="fas fa-eye mr-1"></i>Ver
                                            </a>
                                            
                                            <!-- Editar -->
                                            <a href="editarUsuario.jsp?id=<%= usuario.get("id") %>"
                                                class="btn btn-outline-primary btn-sm mb-1"
                                                title="Editar usuario">
                                                <i class="fas fa-edit mr-1"></i>Editar
                                            </a>
                                            
                                            <!-- Activar/Desactivar -->
                                            <% if (activo) { %>
                                                <a href="usuarios.jsp?action=toggle&userId=<%= usuario.get("id") %>" 
                                                   class="btn btn-outline-warning btn-sm mb-1" 
                                                   title="Desactivar usuario"
                                                   onclick="return confirm('¿Está seguro de desactivar este usuario?')">
                                                    <i class="fas fa-ban mr-1"></i>Desactivar
                                                </a>
                                            <% } else { %>
                                                <a href="usuarios.jsp?action=toggle&userId=<%= usuario.get("id") %>" 
                                                   class="btn btn-outline-success btn-sm mb-1" 
                                                   title="Activar usuario"
                                                   onclick="return confirm('¿Está seguro de activar este usuario?')">
                                                    <i class="fas fa-check mr-1"></i>Activar
                                                </a>
                                            <% } %>
                                            
                                            <!-- Eliminar (solo si no es el admin actual) -->
                                            <% if (!esAdminActual) { %>
                                                <a href="usuarios.jsp?action=delete&userId=<%= usuario.get("id") %>" 
                                                   class="btn btn-outline-danger btn-sm" 
                                                   title="Eliminar usuario"
                                                   onclick="return confirmarEliminacion('<%= usuario.get("nombre") %>', '<%= usuario.get("apellido") %>')">
                                                    <i class="fas fa-trash mr-1"></i>Eliminar
                                                </a>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                                
                                <% if (usuarios.isEmpty()) { %>
                                <tr>
                                    <td colspan="8" class="text-center py-5">
                                        <i class="fas fa-users fa-3x text-muted mb-3"></i>
                                        <h5 class="text-muted">No hay usuarios registrados</h5>
                                        <a href="../auth/register.jsp" class="btn text-white" style="background-color: var(--vino);">
                                            <i class="fas fa-user-plus mr-2"></i>Crear Primer Usuario
                                        </a>
                                    </td>
                                </tr>
                                <% } %>
                            </tbody>
                        </table>
                    </div>
                </div>
                
                <!-- Paginación -->
                <% if (totalPaginas > 1) { %>
                <div class="card-footer">
                    <nav>
                        <ul class="pagination pagination-sm justify-content-center mb-0">
                            <li class="page-item <%= paginaActual == 1 ? "disabled" : "" %>">
                                <a class="page-link" href="usuarios.jsp?page=<%= paginaActual - 1 %>">
                                    <i class="fas fa-chevron-left"></i>
                                </a>
                            </li>
                            
                            <% for (int i = 1; i <= totalPaginas; i++) { %>
                                <li class="page-item <%= i == paginaActual ? "active" : "" %>">
                                    <a class="page-link" href="usuarios.jsp?page=<%= i %>"><%= i %></a>
                                </li>
                            <% } %>
                            
                            <li class="page-item <%= paginaActual == totalPaginas ? "disabled" : "" %>">
                                <a class="page-link" href="usuarios.jsp?page=<%= paginaActual + 1 %>">
                                    <i class="fas fa-chevron-right"></i>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </div>
                <% } %>
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

.table th {
    border-top: none;
    font-weight: 600;
    text-transform: uppercase;
    font-size: 0.85rem;
    letter-spacing: 0.5px;
}

.btn-group-vertical .btn {
    margin-bottom: 2px;
}

.card {
    border: none;
    border-radius: 10px;
}

.badge {
    font-size: 0.75rem;
    padding: 0.375rem 0.75rem;
}

.table-responsive {
    border-radius: 10px;
}

@media (max-width: 768px) {
    .btn-group-vertical {
        width: 100%;
    }
    
    .btn-group-vertical .btn {
        margin-bottom: 3px;
        font-size: 0.75rem;
    }
    
    .table-responsive {
        font-size: 0.85rem;
    }
}
</style>

<!-- Scripts -->
<script>
function confirmarEliminacion(nombre, apellido) {
    return confirm(
        '¿Está ABSOLUTAMENTE seguro de eliminar al usuario "' + nombre + ' ' + apellido + '"?\n\n' +
        'Esta acción eliminará:\n' +
        '• Toda la información del usuario\n' +
        '• Sus citas programadas\n' +
        '• Sus favoritos\n\n' +
        'ADVERTENCIA: Esta acción NO SE PUEDE DESHACER.\n\n' +
        'Si el usuario tiene propiedades asociadas, primero debe reasignarlas.\n\n' +
        'Escriba "ELIMINAR" para confirmar:'
    ) && prompt('Para confirmar la eliminación, escriba: ELIMINAR') === 'ELIMINAR';
}

// Confirmar acciones
document.addEventListener('DOMContentLoaded', function() {
    // Auto-ocultar alertas después de 5 segundos
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        if (alert.classList.contains('alert-success')) {
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