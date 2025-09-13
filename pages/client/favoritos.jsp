<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea cliente
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    
    if (usuarioId == null || !"CLIENTE".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para paginación y filtros
    int paginaActual = 1;
    int propiedadesPorPagina = 12;
    String filtroTipo = request.getParameter("tipo");
    String filtroOperacion = request.getParameter("operacion");
    String filtroOrden = request.getParameter("orden");
    
    try {
        paginaActual = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * propiedadesPorPagina;
    
    // Variables para datos
    List<Map<String, Object>> propiedadesFavoritas = new ArrayList<>();
    List<Map<String, Object>> tiposPropiedad = new ArrayList<>();
    int totalFavoritos = 0;
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Manejar acciones (eliminar favorito)
        String action = request.getParameter("action");
        String propiedadId = request.getParameter("propiedadId");
        
        if ("remove".equals(action) && propiedadId != null) {
            try {
                String sqlRemove = "DELETE FROM favoritos WHERE id_usuario = ? AND id_propiedad = ?";
                stmt = conn.prepareStatement(sqlRemove);
                stmt.setInt(1, usuarioId);
                stmt.setInt(2, Integer.parseInt(propiedadId));
                
                int rowsDeleted = stmt.executeUpdate();
                if (rowsDeleted > 0) {
                    mensaje = "Propiedad eliminada de favoritos exitosamente.";
                    tipoMensaje = "success";
                } else {
                    mensaje = "No se pudo eliminar la propiedad de favoritos.";
                    tipoMensaje = "error";
                }
                stmt.close();
                
            } catch (Exception e) {
                mensaje = "Error al eliminar favorito: " + e.getMessage();
                tipoMensaje = "error";
            }
        }
        
        // Cargar tipos de propiedad para filtros
        String sqlTipos = "SELECT id_tipo, nombre_tipo FROM tipos_propiedad WHERE activo = 1 ORDER BY nombre_tipo";
        stmt = conn.prepareStatement(sqlTipos);
        rs = stmt.executeQuery();
        while (rs.next()) {
            Map<String, Object> tipo = new HashMap<>();
            tipo.put("id", rs.getInt("id_tipo"));
            tipo.put("nombre", rs.getString("nombre_tipo"));
            tiposPropiedad.add(tipo);
        }
        rs.close();
        stmt.close();
        
        // Construir query con filtros
        StringBuilder sqlBase = new StringBuilder(
            "SELECT p.*, tp.nombre_tipo, f.fecha_agregado " +
            "FROM favoritos f " +
            "INNER JOIN propiedades p ON f.id_propiedad = p.id_propiedad " +
            "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
            "WHERE f.id_usuario = ? AND p.disponible = 1"
        );
        
        List<Object> params = new ArrayList<>();
        params.add(usuarioId);
        
        // Agregar filtros
        if (filtroTipo != null && !filtroTipo.isEmpty() && !"all".equals(filtroTipo)) {
            sqlBase.append(" AND p.id_tipo = ?");
            params.add(Integer.parseInt(filtroTipo));
        }
        
        if (filtroOperacion != null && !filtroOperacion.isEmpty() && !"all".equals(filtroOperacion)) {
            sqlBase.append(" AND p.tipo_operacion = ?");
            params.add(filtroOperacion);
        }
        
        // Agregar ordenamiento
        if ("price_asc".equals(filtroOrden)) {
            sqlBase.append(" ORDER BY p.precio ASC");
        } else if ("price_desc".equals(filtroOrden)) {
            sqlBase.append(" ORDER BY p.precio DESC");
        } else if ("newest".equals(filtroOrden)) {
            sqlBase.append(" ORDER BY f.fecha_agregado DESC");
        } else {
            sqlBase.append(" ORDER BY f.fecha_agregado DESC");
        }
        
        // Contar total de favoritos con filtros
        String sqlCount = sqlBase.toString().replace(
            "SELECT p.*, tp.nombre_tipo, f.fecha_agregado", 
            "SELECT COUNT(*)"
        );
        
        stmt = conn.prepareStatement(sqlCount);
        for (int i = 0; i < params.size(); i++) {
            stmt.setObject(i + 1, params.get(i));
        }
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalFavoritos = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Obtener favoritos con paginación
        sqlBase.append(" LIMIT ? OFFSET ?");
        params.add(propiedadesPorPagina);
        params.add(offset);
        
        stmt = conn.prepareStatement(sqlBase.toString());
        for (int i = 0; i < params.size(); i++) {
            stmt.setObject(i + 1, params.get(i));
        }
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("descripcion", rs.getString("descripcion"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("departamento", rs.getString("departamento"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("garajes", rs.getInt("garajes"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("area_total", rs.getDouble("area_total"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("fecha_agregado", rs.getTimestamp("fecha_agregado"));
            propiedadesFavoritas.add(propiedad);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar favoritos: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    int totalPaginas = (int) Math.ceil((double) totalFavoritos / propiedadesPorPagina);
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Mis Favoritos - Cliente" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
         <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="favoritos" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 style="color: var(--vino);" class="font-weight-bold">
                        <i class="fas fa-heart mr-2"></i>Mis Propiedades Favoritas
                    </h3>
                    <p class="text-muted mb-0">
                        Gestiona las propiedades que has guardado como favoritas
                        <span class="badge badge-info ml-2"><%= totalFavoritos %> propiedades</span>
                    </p>
                </div>
                <div>
                    <a href="../properties/list-properties.jsp" class="btn btn-primary">
                        <i class="fas fa-search mr-1"></i>Buscar Más Propiedades
                    </a>
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
            
            <!-- Filtros -->
            <div class="card shadow mb-4">
                <div class="card-header" style="background-color: var(--naranja); color: white;">
                    <h6 class="mb-0">
                        <i class="fas fa-filter mr-2"></i>Filtros de Búsqueda
                    </h6>
                </div>
                <div class="card-body">
                    <form method="GET" action="" id="formFiltros">
                        <div class="row">
                            <div class="col-md-3 mb-3">
                                <label for="tipo" class="form-label font-weight-bold">Tipo de Propiedad</label>
                                <select class="form-control" id="tipo" name="tipo" onchange="document.getElementById('formFiltros').submit()">
                                    <option value="all">Todos los tipos</option>
                                    <% for (Map<String, Object> tipo : tiposPropiedad) { %>
                                        <option value="<%= tipo.get("id") %>" 
                                                <%= String.valueOf(tipo.get("id")).equals(filtroTipo) ? "selected" : "" %>>
                                            <%= tipo.get("nombre") %>
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="col-md-3 mb-3">
                                <label for="operacion" class="form-label font-weight-bold">Tipo de Operación</label>
                                <select class="form-control" id="operacion" name="operacion" onchange="document.getElementById('formFiltros').submit()">
                                    <option value="all">Todas las operaciones</option>
                                    <option value="VENTA" <%= "VENTA".equals(filtroOperacion) ? "selected" : "" %>>Venta</option>
                                    <option value="ARRIENDO" <%= "ARRIENDO".equals(filtroOperacion) ? "selected" : "" %>>Arriendo</option>
                                    <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(filtroOperacion) ? "selected" : "" %>>Venta/Arriendo</option>
                                </select>
                            </div>
                            <div class="col-md-3 mb-3">
                                <label for="orden" class="form-label font-weight-bold">Ordenar por</label>
                                <select class="form-control" id="orden" name="orden" onchange="document.getElementById('formFiltros').submit()">
                                    <option value="newest" <%= "newest".equals(filtroOrden) || filtroOrden == null ? "selected" : "" %>>Más recientes</option>
                                    <option value="price_asc" <%= "price_asc".equals(filtroOrden) ? "selected" : "" %>>Precio menor a mayor</option>
                                    <option value="price_desc" <%= "price_desc".equals(filtroOrden) ? "selected" : "" %>>Precio mayor a menor</option>
                                </select>
                            </div>
                            <div class="col-md-3 mb-3 d-flex align-items-end">
                                <button type="button" class="btn btn-secondary btn-block" onclick="limpiarFiltros()">
                                    <i class="fas fa-times mr-1"></i>Limpiar Filtros
                                </button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Lista de favoritos -->
            <% if (propiedadesFavoritas.isEmpty()) { %>
                <div class="card shadow">
                    <div class="card-body text-center py-5">
                        <i class="fas fa-heart-broken fa-4x text-muted mb-4"></i>
                        <h4 class="text-muted">No tienes propiedades favoritas</h4>
                        <p class="text-muted mb-4">Explora nuestro catálogo y guarda las propiedades que más te interesen</p>
                        <a href="../properties/list-properties.jsp" class="btn btn-primary btn-lg">
                            <i class="fas fa-search mr-2"></i>Buscar Propiedades
                        </a>
                    </div>
                </div>
            <% } else { %>
                <div class="row">
                    <% for (Map<String, Object> propiedad : propiedadesFavoritas) { %>
                    <div class="col-lg-4 col-md-6 mb-4">
                        <div class="card h-100 property-card">
                            <!-- Badge destacada -->
                            <% if ((Boolean)propiedad.get("destacada")) { %>
                                <div class="position-absolute" style="top: 10px; left: 10px; z-index: 10;">
                                    <span class="badge badge-warning">
                                        <i class="fas fa-star mr-1"></i>Destacada
                                    </span>
                                </div>
                            <% } %>
                            
                            <!-- Botón eliminar favorito -->
                            <div class="position-absolute" style="top: 10px; right: 10px; z-index: 10;">
                                <button class="btn btn-danger btn-sm" onclick="eliminarFavorito(<%= propiedad.get("id") %>)" 
                                        title="Eliminar de favoritos">
                                    <i class="fas fa-heart"></i>
                                </button>
                            </div>
                            
                            <!-- Imagen -->
                            <% if (propiedad.get("imagen_principal") != null) { %>
                                <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= propiedad.get("imagen_principal") %>" 
                                     class="card-img-top" alt="<%= propiedad.get("titulo") %>" style="height: 250px; object-fit: cover;"
                                     onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                            <% } else { %>
                                <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                     class="card-img-top" alt="Sin imagen" style="height: 250px; object-fit: cover;">
                            <% } %>
                            
                            <div class="card-body">
                                <h6 class="card-title font-weight-bold"><%= propiedad.get("titulo") %></h6>
                                
                                <p class="text-muted mb-2">
                                    <i class="fas fa-map-marker-alt mr-1"></i>
                                    <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %>
                                </p>
                                
                                <p class="text-success font-weight-bold h5 mb-3">
                                    $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                </p>
                                
                                <div class="mb-3">
                                    <span class="badge badge-info mr-1"><%= propiedad.get("nombre_tipo") %></span>
                                    <span class="badge badge-primary">
                                        <%= ((String)propiedad.get("tipo_operacion")).replace("_", "/") %>
                                    </span>
                                </div>
                                
                                <!-- Características -->
                                <div class="row text-center mb-3">
                                    <% if ((Integer)propiedad.get("habitaciones") > 0) { %>
                                        <div class="col-4">
                                            <div class="text-muted">
                                                <i class="fas fa-bed"></i><br>
                                                <small><%= propiedad.get("habitaciones") %> hab</small>
                                            </div>
                                        </div>
                                    <% } %>
                                    <% if ((Integer)propiedad.get("banos") > 0) { %>
                                        <div class="col-4">
                                            <div class="text-muted">
                                                <i class="fas fa-bath"></i><br>
                                                <small><%= propiedad.get("banos") %> baños</small>
                                            </div>
                                        </div>
                                    <% } %>
                                    <% if ((Double)propiedad.get("area_construida") > 0) { %>
                                        <div class="col-4">
                                            <div class="text-muted">
                                                <i class="fas fa-home"></i><br>
                                                <small><%= String.format("%.0f", (Double)propiedad.get("area_construida")) %>m²</small>
                                            </div>
                                        </div>
                                    <% } %>
                                </div>
                                
                                <small class="text-muted">
                                    <i class="fas fa-clock mr-1"></i>
                                    Agregado el <%= new SimpleDateFormat("dd/MM/yyyy").format(propiedad.get("fecha_agregado")) %>
                                </small>
                            </div>
                            
                            <div class="card-footer bg-transparent">
                                <div class="row">
                                    <div class="col-6">
                                        <a href="../properties/verPropiedad.jsp?id=<%= propiedad.get("id") %>" 
                                           class="btn btn-primary btn-block">
                                            <i class="fas fa-eye mr-1"></i>Ver Detalles
                                        </a>
                                    </div>
                                    <div class="col-6">
                                        <a href="solicitarCita.jsp?propiedad=<%= propiedad.get("id") %>" 
                                           class="btn btn-success btn-block">
                                            <i class="fas fa-calendar-plus mr-1"></i>Solicitar Cita
                                        </a>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <% } %>
                </div>
                
                <!-- Paginación -->
                <% if (totalPaginas > 1) { %>
                <div class="d-flex justify-content-center mt-4">
                    <nav>
                        <ul class="pagination">
                            <li class="page-item <%= paginaActual == 1 ? "disabled" : "" %>">
                                <a class="page-link" href="?page=<%= paginaActual - 1 %><%= request.getQueryString() != null && !request.getQueryString().contains("page=") ? "&" + request.getQueryString().replaceAll("page=\\d+", "") : "" %>">
                                    <i class="fas fa-chevron-left"></i>
                                </a>
                            </li>
                            
                            <% 
                            int startPage = Math.max(1, paginaActual - 2);
                            int endPage = Math.min(totalPaginas, paginaActual + 2);
                            
                            for (int i = startPage; i <= endPage; i++) { 
                            %>
                                <li class="page-item <%= i == paginaActual ? "active" : "" %>">
                                    <a class="page-link" href="?page=<%= i %><%= request.getQueryString() != null && !request.getQueryString().contains("page=") ? "&" + request.getQueryString().replaceAll("page=\\d+", "") : "" %>">
                                        <%= i %>
                                    </a>
                                </li>
                            <% } %>
                            
                            <li class="page-item <%= paginaActual == totalPaginas ? "disabled" : "" %>">
                                <a class="page-link" href="?page=<%= paginaActual + 1 %><%= request.getQueryString() != null && !request.getQueryString().contains("page=") ? "&" + request.getQueryString().replaceAll("page=\\d+", "") : "" %>">
                                    <i class="fas fa-chevron-right"></i>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </div>
                
                <div class="text-center text-muted">
                    Mostrando <%= Math.min((paginaActual - 1) * propiedadesPorPagina + 1, totalFavoritos) %> - 
                    <%= Math.min(paginaActual * propiedadesPorPagina, totalFavoritos) %> de <%= totalFavoritos %> favoritos
                </div>
                <% } %>
            <% } %>
            
        </div>
    </div>
</div>

<!-- Modal de confirmación -->
<div class="modal fade" id="modalEliminar" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--rojo); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-heart-broken mr-2"></i>Eliminar de Favoritos
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p>¿Estás seguro de que deseas eliminar esta propiedad de tus favoritos?</p>
                <p class="text-muted">Podrás agregarla nuevamente cuando quieras desde la página de la propiedad.</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancelar</button>
                <a href="#" id="btnConfirmarEliminar" class="btn btn-danger">
                    <i class="fas fa-heart-broken mr-1"></i>Eliminar de Favoritos
                </a>
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

.property-card {
    position: relative;
    transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
}

.property-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

.btn-danger {
    background-color: var(--rojo);
    border-color: var(--rojo);
}

.btn-danger:hover {
    background-color: #b71c1c;
    border-color: #b71c1c;
}

.badge-info {
    background-color: #17a2b8;
}

.badge-primary {
    background-color: var(--vino);
}

@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .property-card:hover {
        transform: none;
    }
}
</style>

<!-- JavaScript -->
<script>
function eliminarFavorito(propiedadId) {
    const btnConfirmar = document.getElementById('btnConfirmarEliminar');
    btnConfirmar.href = 'favoritos.jsp?action=remove&propiedadId=' + propiedadId;
    $('#modalEliminar').modal('show');
}

function limpiarFiltros() {
    window.location.href = 'favoritos.jsp';
}

// Confirmación adicional para eliminar
document.addEventListener('DOMContentLoaded', function() {
    const botonesEliminar = document.querySelectorAll('.btn-danger[onclick*="eliminarFavorito"]');
    
    botonesEliminar.forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />