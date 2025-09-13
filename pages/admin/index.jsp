<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String usuarioNombre = (String) session.getAttribute("usuario_nombre");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        // Si no es admin, redirigir al login
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener estadísticas de la base de datos
    int totalUsuarios = 0;
    int totalPropiedades = 0;
    int totalCitas = 0;
    int propiedadesDestacadas = 0;
    List<Map<String, Object>> ultimosUsuarios = new ArrayList<>();
    List<Map<String, Object>> ultimasPropiedades = new ArrayList<>();
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Contar usuarios
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM usuarios WHERE activo = 1");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalUsuarios = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Contar propiedades
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE disponible = 1");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalPropiedades = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Contar citas
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM citas");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalCitas = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Contar propiedades destacadas
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades WHERE destacada = 1 AND disponible = 1");
        rs = stmt.executeQuery();
        if (rs.next()) {
            propiedadesDestacadas = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Últimos usuarios registrados
        stmt = conn.prepareStatement(
            "SELECT u.nombre, u.apellido, u.email, r.nombre_rol, u.fecha_registro " +
            "FROM usuarios u INNER JOIN roles r ON u.id_rol = r.id_rol " +
            "WHERE u.activo = 1 ORDER BY u.fecha_registro DESC LIMIT 5"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> usuario = new HashMap<>();
            usuario.put("nombre", rs.getString("nombre") + " " + rs.getString("apellido"));
            usuario.put("email", rs.getString("email"));
            usuario.put("rol", rs.getString("nombre_rol"));
            usuario.put("fecha", rs.getTimestamp("fecha_registro"));
            ultimosUsuarios.add(usuario);
        }
        rs.close();
        stmt.close();
        
        // Últimas propiedades agregadas
        stmt = conn.prepareStatement(
            "SELECT p.titulo, p.precio, tp.nombre_tipo, u.nombre as propietario, p.fecha_publicacion " +
            "FROM propiedades p " +
            "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
            "INNER JOIN usuarios u ON p.id_propietario = u.id_usuario " +
            "WHERE p.disponible = 1 ORDER BY p.fecha_publicacion DESC LIMIT 5"
        );
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("tipo", rs.getString("nombre_tipo"));
            propiedad.put("propietario", rs.getString("propietario"));
            propiedad.put("fecha", rs.getTimestamp("fecha_publicacion"));
            ultimasPropiedades.add(propiedad);
        }
        
    } catch (Exception e) {
        out.println("<!-- Error al obtener estadísticas: " + e.getMessage() + " -->");
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard Administrador - Inmobiliaria J de la Espriella</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="../../assets/css/admin.css">
    <style>
        .card-stat {
            border: none;
            border-radius: 15px;
            transition: transform 0.3s ease;
            overflow: hidden;
        }
        .card-stat:hover {
            transform: translateY(-5px);
        }
        .card-stat .card-body {
            padding: 2rem;
        }
        .stat-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-bottom: 1rem;
        }
        .bg-gradient-primary { background: linear-gradient(45deg, #007bff, #0056b3); }
        .bg-gradient-success { background: linear-gradient(45deg, #28a745, #1e7e34); }
        .bg-gradient-warning { background: linear-gradient(45deg, #ffc107, #d39e00); }
        .bg-gradient-info { background: linear-gradient(45deg, #17a2b8, #117a8b); }
        
        .table-responsive {
            border-radius: 10px;
            overflow: hidden;
        }
        .table thead th {
            border: none;
            background-color: #f8f9fa;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.85rem;
            letter-spacing: 0.5px;
        }
    </style>
</head>
<body>
    
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Dashboard Administrador" />
</jsp:include>

<div class="container-fluid">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="usuarios" />
            </jsp:include>
        </div>
        
        <!-- Main Content -->
        <div class="col-md-9 col-lg-10 p-0">
            
            <!-- Header -->
            <nav class="navbar navbar-expand-lg navbar-light bg-white border-bottom px-4">
                <h4 class="mb-0">Panel de Administración</h4>
                <div class="ml-auto">
                    <span class="navbar-text">
                        <i class="fas fa-user-circle mr-2"></i>Bienvenido, <strong><%= usuarioNombre %></strong>
                    </span>
                </div>
            </nav>
            
            <!-- Content -->
            <div class="p-4">
                
                <!-- Mensaje de bienvenida -->
                <%
                    String mensajeBienvenida = (String) session.getAttribute("mensaje_bienvenida");
                    if (mensajeBienvenida != null) {
                        session.removeAttribute("mensaje_bienvenida");
                %>
                    <div class="alert alert-success alert-dismissible fade show" role="alert">
                        <i class="fas fa-check-circle mr-2"></i><%= mensajeBienvenida %>
                        <button type="button" class="close" data-dismiss="alert">
                            <span>&times;</span>
                        </button>
                    </div>
                <% } %>
                
                <!-- Estadísticas principales -->
                <div class="row mb-4">
                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card card-stat shadow">
                            <div class="card-body">
                                <div class="stat-icon bg-gradient-primary text-white mx-auto">
                                    <i class="fas fa-users fa-lg"></i>
                                </div>
                                <h3 class="font-weight-bold text-center"><%= totalUsuarios %></h3>
                                <p class="text-muted text-center mb-0">Usuarios Activos</p>
                                <div class="text-center mt-2">
                                    <a href="usuarios.jsp" class="btn btn-sm btn-outline-primary">
                                        <i class="fas fa-eye mr-1"></i>Ver Todos
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card card-stat shadow">
                            <div class="card-body">
                                <div class="stat-icon bg-gradient-success text-white mx-auto">
                                    <i class="fas fa-building fa-lg"></i>
                                </div>
                                <h3 class="font-weight-bold text-center"><%= totalPropiedades %></h3>
                                <p class="text-muted text-center mb-0">Propiedades Disponibles</p>
                                <div class="text-center mt-2">
                                    <a href="../properties/propiedades.jsp" class="btn btn-sm btn-outline-success">
                                        <i class="fas fa-eye mr-1"></i>Gestionar
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card card-stat shadow">
                            <div class="card-body">
                                <div class="stat-icon bg-gradient-warning text-white mx-auto">
                                    <i class="fas fa-calendar-alt fa-lg"></i>
                                </div>
                                <h3 class="font-weight-bold text-center"><%= totalCitas %></h3>
                                <p class="text-muted text-center mb-0">Citas Programadas</p>
                                <div class="text-center mt-2">
                                    <a href="../citas/citas.jsp" class="btn btn-sm btn-outline-warning">
                                        <i class="fas fa-eye mr-1"></i>Ver Citas
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-xl-3 col-md-6 mb-4">
                        <div class="card card-stat shadow">
                            <div class="card-body">
                                <div class="stat-icon bg-gradient-info text-white mx-auto">
                                    <i class="fas fa-star fa-lg"></i>
                                </div>
                                <h3 class="font-weight-bold text-center"><%= propiedadesDestacadas %></h3>
                                <p class="text-muted text-center mb-0">Propiedades Destacadas</p>
                                <div class="text-center mt-2">
                                    <a href="../properties/propiedades.jsp?destacadas=1" class="btn btn-sm btn-outline-info">
                                        <i class="fas fa-eye mr-1"></i>Ver Destacadas
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Tablas de datos recientes -->
                <div class="row">
                    
                    <!-- Últimos usuarios -->
                    <div class="col-lg-6 mb-4">
                        <div class="card shadow">
                            <div class="card-header bg-primary text-white">
                                <h6 class="mb-0">
                                    <i class="fas fa-user-plus mr-2"></i>Usuarios Recientes
                                </h6>
                            </div>
                            <div class="card-body p-0">
                                <div class="table-responsive">
                                    <table class="table table-hover mb-0">
                                        <thead>
                                            <tr>
                                                <th>Usuario</th>
                                                <th>Rol</th>
                                                <th>Fecha</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> usuario : ultimosUsuarios) { %>
                                            <tr>
                                                <td>
                                                    <div>
                                                        <strong><%= usuario.get("nombre") %></strong><br>
                                                        <small class="text-muted"><%= usuario.get("email") %></small>
                                                    </div>
                                                </td>
                                                <td>
                                                    <span class="badge badge-secondary"><%= usuario.get("rol") %></span>
                                                </td>
                                                <td>
                                                    <small><%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha")) %></small>
                                                </td>
                                            </tr>
                                            <% } %>
                                            <% if (ultimosUsuarios.isEmpty()) { %>
                                            <tr>
                                                <td colspan="3" class="text-center text-muted py-4">
                                                    <i class="fas fa-inbox fa-2x mb-2"></i><br>
                                                    No hay usuarios registrados
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <div class="card-footer text-center">
                                    <a href="usuarios.jsp" class="btn btn-primary btn-sm">
                                        <i class="fas fa-eye mr-1"></i>Ver Todos los Usuarios
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Últimas propiedades -->
                    <div class="col-lg-6 mb-4">
                        <div class="card shadow">
                            <div class="card-header bg-success text-white">
                                <h6 class="mb-0">
                                    <i class="fas fa-building mr-2"></i>Propiedades Recientes
                                </h6>
                            </div>
                            <div class="card-body p-0">
                                <div class="table-responsive">
                                    <table class="table table-hover mb-0">
                                        <thead>
                                            <tr>
                                                <th>Propiedad</th>
                                                <th>Precio</th>
                                                <th>Fecha</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            <% for (Map<String, Object> propiedad : ultimasPropiedades) { %>
                                            <tr>
                                                <td>
                                                    <div>
                                                        <strong><%= propiedad.get("titulo") %></strong><br>
                                                        <small class="text-muted">
                                                            <%= propiedad.get("tipo") %> - <%= propiedad.get("propietario") %>
                                                        </small>
                                                    </div>
                                                </td>
                                                <td>
                                                    <strong class="text-success">
                                                        $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                                    </strong>
                                                </td>
                                                <td>
                                                    <small><%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(propiedad.get("fecha")) %></small>
                                                </td>
                                            </tr>
                                            <% } %>
                                            <% if (ultimasPropiedades.isEmpty()) { %>
                                            <tr>
                                                <td colspan="3" class="text-center text-muted py-4">
                                                    <i class="fas fa-home fa-2x mb-2"></i><br>
                                                    No hay propiedades publicadas
                                                </td>
                                            </tr>
                                            <% } %>
                                        </tbody>
                                    </table>
                                </div>
                                <div class="card-footer text-center">
                                    <a href="../properties/propiedades.jsp" class="btn btn-success btn-sm">
                                        <i class="fas fa-eye mr-1"></i>Ver Todas las Propiedades
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Acciones rápidas -->
                <div class="row">
                    <div class="col-12">
                        <div class="card shadow">
                            <div class="card-header bg-info text-white">
                                <h6 class="mb-0">
                                    <i class="fas fa-bolt mr-2"></i>Acciones Rápidas
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-3 mb-3">
                                        <a href="../auth/register.jsp?action=new" class="btn btn-outline-primary btn-block">
                                            <i class="fas fa-user-plus mb-2"></i><br>
                                            Crear Usuario
                                        </a>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <a href="../properties/nuevaPropiedad.jsp?action=new" class="btn btn-outline-success btn-block">
                                            <i class="fas fa-plus-circle mb-2"></i><br>
                                            Nueva Propiedad
                                        </a>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <a href="reportes.jsp" class="btn btn-outline-warning btn-block">
                                            <i class="fas fa-chart-line mb-2"></i><br>
                                            Ver Reportes
                                        </a>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <a href="configuracion.jsp" class="btn btn-outline-info btn-block">
                                            <i class="fas fa-tools mb-2"></i><br>
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
</div>

<!-- Scripts -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.slim.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.min.js"></script>

<script>
// Auto-actualizar estadísticas cada 30 segundos
setTimeout(function() {
    location.reload();
}, 30000);

// Tooltips para botones
$(function () {
    $('[data-toggle="tooltip"]').tooltip();
});
</script>

</body>
</html> 