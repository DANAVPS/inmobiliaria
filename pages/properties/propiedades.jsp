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
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones (destacar/no destacar, disponible/no disponible, eliminar)
    String action = request.getParameter("action");
    String propIdParam = request.getParameter("propId");
    
    if (action != null && propIdParam != null) {
        Connection conn = null;
        PreparedStatement stmt = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("toggleDestacada".equals(action)) {
                // Obtener estado actual de destacada
                stmt = conn.prepareStatement("SELECT destacada FROM propiedades WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                ResultSet rs = stmt.executeQuery();
                
                if (rs.next()) {
                    boolean estadoActual = rs.getBoolean("destacada");
                    boolean nuevoEstado = !estadoActual;
                    
                    // Actualizar estado
                    stmt.close();
                    stmt = conn.prepareStatement("UPDATE propiedades SET destacada = ? WHERE id_propiedad = ?");
                    stmt.setBoolean(1, nuevoEstado);
                    stmt.setInt(2, Integer.parseInt(propIdParam));
                    
                    int resultado = stmt.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Propiedad " + (nuevoEstado ? "marcada como destacada" : "removida de destacadas") + " exitosamente.";
                        tipoMensaje = "success";
                    }
                }
                rs.close();
                
            } else if ("toggleDisponible".equals(action)) {
                // Obtener estado actual de disponible
                stmt = conn.prepareStatement("SELECT disponible FROM propiedades WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                ResultSet rs = stmt.executeQuery();
                
                if (rs.next()) {
                    boolean estadoActual = rs.getBoolean("disponible");
                    boolean nuevoEstado = !estadoActual;
                    
                    // Actualizar estado
                    stmt.close();
                    stmt = conn.prepareStatement("UPDATE propiedades SET disponible = ? WHERE id_propiedad = ?");
                    stmt.setBoolean(1, nuevoEstado);
                    stmt.setInt(2, Integer.parseInt(propIdParam));
                    
                    int resultado = stmt.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Propiedad " + (nuevoEstado ? "marcada como disponible" : "marcada como no disponible") + " exitosamente.";
                        tipoMensaje = "success";
                    }
                }
                rs.close();
                
            } else if ("delete".equals(action)) {
                // Verificar si la propiedad tiene citas asociadas
                stmt = conn.prepareStatement("SELECT COUNT(*) FROM citas WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                ResultSet rs = stmt.executeQuery();
                
                int citasCount = 0;
                if (rs.next()) {
                    citasCount = rs.getInt(1);
                }
                rs.close();
                stmt.close();
                
                if (citasCount > 0) {
                    // Eliminar citas primero
                    stmt = conn.prepareStatement("DELETE FROM citas WHERE id_propiedad = ?");
                    stmt.setInt(1, Integer.parseInt(propIdParam));
                    stmt.executeUpdate();
                    stmt.close();
                }
                
                // Eliminar favoritos si existen
                stmt = conn.prepareStatement("DELETE FROM favoritos WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                stmt.executeUpdate();
                stmt.close();
                
                // Eliminar imágenes de la propiedad
                stmt = conn.prepareStatement("DELETE FROM imagenes_propiedades WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                stmt.executeUpdate();
                stmt.close();
                
                // Eliminar la propiedad
                stmt = conn.prepareStatement("DELETE FROM propiedades WHERE id_propiedad = ?");
                stmt.setInt(1, Integer.parseInt(propIdParam));
                
                int resultado = stmt.executeUpdate();
                if (resultado > 0) {
                    mensaje = "Propiedad eliminada exitosamente junto con sus datos relacionados.";
                    tipoMensaje = "success";
                } else {
                    mensaje = "Error al eliminar la propiedad.";
                    tipoMensaje = "error";
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
    
    // Obtener lista de propiedades con paginación
    List<Map<String, Object>> propiedades = new ArrayList<>();
    int totalPropiedades = 0;
    int propiedadesDisponibles = 0;
    int propiedadesDestacadas = 0;
    int paginaActual = 1;
    int propiedadesPorPagina = 8;
    
    try {
        paginaActual = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * propiedadesPorPagina;
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Contar total de propiedades
        stmt = conn.prepareStatement("SELECT COUNT(*) FROM propiedades");
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalPropiedades = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Obtener propiedades con paginación
        String sql = "SELECT p.id_propiedad, p.titulo, p.precio, p.ciudad, p.departamento, " +
                    "p.tipo_operacion, p.disponible, p.destacada, p.imagen_principal, " +
                    "p.fecha_publicacion, tp.nombre_tipo, u.nombre as propietario " +
                    "FROM propiedades p " +
                    "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                    "INNER JOIN usuarios u ON p.id_propietario = u.id_usuario " +
                    "ORDER BY p.fecha_publicacion DESC " +
                    "LIMIT ? OFFSET ?";
        
        stmt = conn.prepareStatement(sql);
        stmt.setInt(1, propiedadesPorPagina);
        stmt.setInt(2, offset);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("departamento", rs.getString("departamento"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("propietario", rs.getString("propietario"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("fecha_publicacion", rs.getTimestamp("fecha_publicacion"));
            
            boolean disponible = rs.getBoolean("disponible");
            boolean destacada = rs.getBoolean("destacada");
            propiedad.put("disponible", disponible);
            propiedad.put("destacada", destacada);
            
            propiedades.add(propiedad);
            
            // Contar disponibles/destacadas
            if (disponible) {
                propiedadesDisponibles++;
            }
            if (destacada) {
                propiedadesDestacadas++;
            }
        }
        
    } catch (Exception e) {
        mensaje = "Error al cargar propiedades: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    int totalPaginas = (int) Math.ceil((double) totalPropiedades / propiedadesPorPagina);
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Gestión de Propiedades - Admin" />
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
            
            <!-- Encabezado -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 class="font-weight-bold" style="color: var(--vino);">
                        <i class="fas fa-building mr-2"></i>Gestión de Propiedades
                    </h3>
                    <p class="text-muted mb-0">Administra todas las propiedades del sistema</p>
                </div>
                <a href="../properties/nuevaPropiedad.jsp" class="btn text-white" style="background-color: var(--vino);">
                    <i class="fas fa-plus mr-2"></i>Agregar Propiedad
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
                            <h4><%= totalPropiedades %></h4>
                            <small>Total Propiedades</small>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card bg-success text-white">
                        <div class="card-body text-center">
                            <h4><%= propiedadesDisponibles %></h4>
                            <small>Disponibles</small>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card text-white" style="background-color: var(--amarillo); color: #000 !important;">
                        <div class="card-body text-center">
                            <h4><%= propiedadesDestacadas %></h4>
                            <small>Destacadas</small>
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
            
            <!-- Tabla de propiedades -->
            <div class="card shadow">
                <div class="card-header bg-light">
                    <div class="row align-items-center">
                        <div class="col">
                            <h6 class="mb-0 font-weight-bold">Lista de Propiedades</h6>
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
                                    <th>Imagen</th>
                                    <th>Propiedad</th>
                                    <th>Ubicación</th>
                                    <th>Precio</th>
                                    <th>Operación</th>
                                    <th>Estado</th>
                                    <th>Destacada</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <% for (Map<String, Object> propiedad : propiedades) { 
                                    Boolean disponible = (Boolean) propiedad.get("disponible");
                                    Boolean destacada = (Boolean) propiedad.get("destacada");
                                    String operacion = (String) propiedad.get("tipo_operacion");
                                    String badgeOperacion = "";
                                    
                                    if ("VENTA".equals(operacion)) {
                                        badgeOperacion = "badge-info";
                                    } else if ("ARRIENDO".equals(operacion)) {
                                        badgeOperacion = "badge-warning";
                                    } else {
                                        badgeOperacion = "badge-secondary";
                                    }
                                %>
                                <tr class="<%= disponible ? "" : "table-light" %>">
                                    <td><strong>#<%= propiedad.get("id") %></strong></td>
                                    <td>
                                        <% if (propiedad.get("imagen_principal") != null && !((String)propiedad.get("imagen_principal")).isEmpty()) { %>
                                            <img src="<%= propiedad.get("imagen_principal") %>" 
                                                 alt="<%= propiedad.get("titulo") %>" 
                                                 class="img-thumbnail img-mini"
                                                 onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                        <% } else { %>
                                            <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                                 alt="Sin imagen" class="img-thumbnail img-mini">
                                        <% } %>
                                    </td>
                                    <td>
                                        <div>
                                            <strong><%= propiedad.get("titulo") %></strong><br>
                                            <small class="text-muted">
                                                <i class="fas fa-tag mr-1"></i><%= propiedad.get("nombre_tipo") %>
                                                | <i class="fas fa-user mr-1"></i><%= propiedad.get("propietario") %>
                                            </small>
                                        </div>
                                    </td>
                                    <td>
                                        <i class="fas fa-map-marker-alt mr-1"></i>
                                        <%= propiedad.get("ciudad") %><br>
                                        <small class="text-muted"><%= propiedad.get("departamento") %></small>
                                    </td>
                                    <td>
                                        <strong class="text-success">
                                            $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                        </strong>
                                    </td>
                                    <td>
                                        <span class="badge <%= badgeOperacion %>">
                                            <%= operacion.replace("_", "/") %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%= disponible ? "badge-success" : "badge-danger" %>">
                                            <%= disponible ? "Disponible" : "No Disponible" %>
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge <%= destacada ? "badge-warning" : "badge-secondary" %>">
                                            <%= destacada ? "Sí" : "No" %>
                                        </span>
                                    </td>
                                    <td>
                                        <div class="btn-group-vertical btn-group-sm" role="group">
                                            <!-- Ver detalles -->
                                            <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>"
                                                class="btn btn-outline-info btn-sm mb-1"
                                                title="Ver detalles">
                                                <i class="fas fa-eye mr-1"></i>Ver
                                            </a>
                                            
                                            <!-- Editar -->
                                            <a href="editarPropiedad.jsp?id=<%= propiedad.get("id") %>"
                                                class="btn btn-outline-primary btn-sm mb-1"
                                                title="Editar propiedad">
                                                <i class="fas fa-edit mr-1"></i>Editar
                                            </a>
                                            
                                            <!-- Disponibilidad -->
                                            <a href="propiedades.jsp?action=toggleDisponible&propId=<%= propiedad.get("id") %>" 
                                               class="btn btn-outline-<%= disponible ? "warning" : "success" %> btn-sm mb-1" 
                                               title="<%= disponible ? "Marcar como no disponible" : "Marcar como disponible" %>"
                                               onclick="return confirm('¿Está seguro de cambiar el estado de disponibilidad?')">
                                                <i class="fas fa-<%= disponible ? "ban" : "check" %> mr-1"></i><%= disponible ? "Desactivar" : "Activar" %>
                                            </a>
                                            
                                            <!-- Destacar -->
                                            <a href="propiedades.jsp?action=toggleDestacada&propId=<%= propiedad.get("id") %>" 
                                               class="btn btn-outline-<%= destacada ? "secondary" : "warning" %> btn-sm mb-1" 
                                               title="<%= destacada ? "Quitar de destacadas" : "Marcar como destacada" %>"
                                               onclick="return confirm('¿Está seguro de cambiar el estado de destacada?')">
                                                <i class="fas fa-<%= destacada ? "star-half-alt" : "star" %> mr-1"></i><%= destacada ? "Quitar" : "Destacar" %>
                                            </a>
                                            
                                            <!-- Eliminar -->
                                            <a href="propiedades.jsp?action=delete&propId=<%= propiedad.get("id") %>" 
                                               class="btn btn-outline-danger btn-sm" 
                                               title="Eliminar propiedad"
                                               onclick="return confirmarEliminacionPropiedad('<%= propiedad.get("titulo") %>')">
                                                <i class="fas fa-trash mr-1"></i>Eliminar
                                            </a>
                                        </div>
                                    </td>
                                </tr>
                                <% } %>
                                
                                <% if (propiedades.isEmpty()) { %>
                                <tr>
                                    <td colspan="9" class="text-center py-5">
                                        <i class="fas fa-building fa-3x text-muted mb-3"></i>
                                        <h5 class="text-muted">No hay propiedades registradas</h5>
                                        <a href="../properties/nuevaPropiedad.jsp" class="btn text-white" style="background-color: var(--vino);">
                                            <i class="fas fa-plus mr-2"></i>Crear Primera Propiedad
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
                                <a class="page-link" href="propiedades.jsp?page=<%= paginaActual - 1 %>">
                                    <i class="fas fa-chevron-left"></i>
                                </a>
                            </li>
                            
                            <% for (int i = 1; i <= totalPaginas; i++) { %>
                                <li class="page-item <%= i == paginaActual ? "active" : "" %>">
                                    <a class="page-link" href="propiedades.jsp?page=<%= i %>"><%= i %></a>
                                </li>
                            <% } %>
                            
                            <li class="page-item <%= paginaActual == totalPaginas ? "disabled" : "" %>">
                                <a class="page-link" href="propiedades.jsp?page=<%= paginaActual + 1 %>">
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

.img-mini {
    width: 50px;
    height: 50px;
    object-fit: cover;
    border-radius: 8px;
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
    
    .img-mini {
        width: 40px;
        height: 40px;
    }
}
</style>

<!-- Scripts -->
<script>
function confirmarEliminacionPropiedad(titulo) {
    return confirm(
        '¿Está ABSOLUTAMENTE seguro de eliminar la propiedad "' + titulo + '"?\n\n' +
        'Esta acción eliminará:\n' +
        '• Toda la información de la propiedad\n' +
        '• Todas las imágenes asociadas\n' +
        '• Las citas programadas\n' +
        '• Los favoritos de usuarios\n\n' +
        'ADVERTENCIA: Esta acción NO SE PUEDE DESHACER.\n\n' +
        'Escriba "ELIMINAR" para confirmar:'
    ) && prompt('Para confirmar la eliminación, escriba: ELIMINAR') === 'ELIMINAR';
}

// Auto-ocultar alertas después de 5 segundos
document.addEventListener('DOMContentLoaded', function() {
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