<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Obtener información del usuario (si está logueado)
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    boolean isLoggedIn = (usuarioId != null);
    
    // Parámetros de búsqueda y filtros
    String busqueda = request.getParameter("busqueda");
    String ciudadFiltro = request.getParameter("ciudad");
    String tipoFiltro = request.getParameter("tipo");
    String operacionFiltro = request.getParameter("operacion");
    String precioMinStr = request.getParameter("precio_min");
    String precioMaxStr = request.getParameter("precio_max");
    String habitacionesFiltro = request.getParameter("habitaciones");
    String banosFiltro = request.getParameter("banos");
    String ordenar = request.getParameter("ordenar");
    
    // Variables para paginación
    int paginaActual = 1;
    int propiedadesPorPagina = 12;
    
    try {
        paginaActual = Integer.parseInt(request.getParameter("page") != null ? request.getParameter("page") : "1");
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * propiedadesPorPagina;
    
    // Variables para almacenar datos
    List<Map<String, Object>> propiedades = new ArrayList<>();
    List<Map<String, Object>> tiposPropiedad = new ArrayList<>();
    List<String> ciudades = new ArrayList<>();
    int totalPropiedades = 0;
    int totalDestacadas = 0;
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Construir consulta SQL con filtros
        StringBuilder sqlBase = new StringBuilder();
        sqlBase.append("SELECT p.id_propiedad, p.titulo, p.descripcion, p.precio, p.ciudad, p.departamento, ");
        sqlBase.append("p.tipo_operacion, p.disponible, p.destacada, p.imagen_principal, p.habitaciones, p.banos, ");
        sqlBase.append("p.garajes, p.area_construida, p.direccion, p.fecha_publicacion, tp.nombre_tipo, ");
        sqlBase.append("u.nombre as propietario_nombre, u.telefono as propietario_telefono ");
        sqlBase.append("FROM propiedades p ");
        sqlBase.append("INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo ");
        sqlBase.append("INNER JOIN usuarios u ON p.id_propietario = u.id_usuario ");
        sqlBase.append("WHERE p.disponible = 1 ");
        
        List<Object> parametros = new ArrayList<>();
        
        // Aplicar filtros
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            sqlBase.append("AND (p.titulo LIKE ? OR p.descripcion LIKE ? OR p.ciudad LIKE ? OR p.direccion LIKE ?) ");
            String searchPattern = "%" + busqueda.trim() + "%";
            parametros.add(searchPattern);
            parametros.add(searchPattern);
            parametros.add(searchPattern);
            parametros.add(searchPattern);
        }
        
        if (ciudadFiltro != null && !ciudadFiltro.trim().isEmpty()) {
            sqlBase.append("AND p.ciudad = ? ");
            parametros.add(ciudadFiltro);
        }
        
        if (tipoFiltro != null && !tipoFiltro.trim().isEmpty()) {
            sqlBase.append("AND p.id_tipo = ? ");
            parametros.add(Integer.parseInt(tipoFiltro));
        }
        
        if (operacionFiltro != null && !operacionFiltro.trim().isEmpty()) {
            sqlBase.append("AND p.tipo_operacion = ? ");
            parametros.add(operacionFiltro);
        }
        
        if (precioMinStr != null && !precioMinStr.trim().isEmpty()) {
            sqlBase.append("AND p.precio >= ? ");
            parametros.add(Long.parseLong(precioMinStr));
        }
        
        if (precioMaxStr != null && !precioMaxStr.trim().isEmpty()) {
            sqlBase.append("AND p.precio <= ? ");
            parametros.add(Long.parseLong(precioMaxStr));
        }
        
        if (habitacionesFiltro != null && !habitacionesFiltro.trim().isEmpty()) {
            sqlBase.append("AND p.habitaciones >= ? ");
            parametros.add(Integer.parseInt(habitacionesFiltro));
        }
        
        if (banosFiltro != null && !banosFiltro.trim().isEmpty()) {
            sqlBase.append("AND p.banos >= ? ");
            parametros.add(Integer.parseInt(banosFiltro));
        }
        
        // Aplicar ordenamiento
        if ("precio_asc".equals(ordenar)) {
            sqlBase.append("ORDER BY p.precio ASC ");
        } else if ("precio_desc".equals(ordenar)) {
            sqlBase.append("ORDER BY p.precio DESC ");
        } else if ("fecha_asc".equals(ordenar)) {
            sqlBase.append("ORDER BY p.fecha_publicacion ASC ");
        } else if ("titulo".equals(ordenar)) {
            sqlBase.append("ORDER BY p.titulo ASC ");
        } else {
            // Por defecto: destacadas primero, luego por fecha descendente
            sqlBase.append("ORDER BY p.destacada DESC, p.fecha_publicacion DESC ");
        }
        
        // Contar total de resultados
        String sqlCount = sqlBase.toString().replace("SELECT p.id_propiedad, p.titulo, p.descripcion, p.precio, p.ciudad, p.departamento, p.tipo_operacion, p.disponible, p.destacada, p.imagen_principal, p.habitaciones, p.banos, p.garajes, p.area_construida, p.direccion, p.fecha_publicacion, tp.nombre_tipo, u.nombre as propietario_nombre, u.telefono as propietario_telefono FROM", "SELECT COUNT(*) FROM");
        sqlCount = sqlCount.substring(0, sqlCount.indexOf("ORDER BY"));
        
        stmt = conn.prepareStatement(sqlCount);
        for (int i = 0; i < parametros.size(); i++) {
            stmt.setObject(i + 1, parametros.get(i));
        }
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            totalPropiedades = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        // Obtener propiedades con paginación
        sqlBase.append("LIMIT ? OFFSET ?");
        parametros.add(propiedadesPorPagina);
        parametros.add(offset);
        
        stmt = conn.prepareStatement(sqlBase.toString());
        for (int i = 0; i < parametros.size(); i++) {
            stmt.setObject(i + 1, parametros.get(i));
        }
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("descripcion", rs.getString("descripcion"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("departamento", rs.getString("departamento"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("garajes", rs.getInt("garajes"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("propietario_nombre", rs.getString("propietario_nombre"));
            propiedad.put("propietario_telefono", rs.getString("propietario_telefono"));
            propiedad.put("fecha_publicacion", rs.getTimestamp("fecha_publicacion"));
            
            propiedades.add(propiedad);
            
            if (rs.getBoolean("destacada")) {
                totalDestacadas++;
            }
        }
        rs.close();
        stmt.close();
        
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
        
        // Cargar ciudades disponibles para filtros
        String sqlCiudades = "SELECT DISTINCT ciudad FROM propiedades WHERE disponible = 1 ORDER BY ciudad";
        stmt = conn.prepareStatement(sqlCiudades);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            ciudades.add(rs.getString("ciudad"));
        }
        rs.close();
        stmt.close();
        
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
    <jsp:param name="title" value="Propiedades Disponibles" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar con filtros -->
        <div class="col-md-3 col-lg-2">
            <div class="card shadow-sm sticky-top" style="top: 1rem;">
                <div class="card-header text-white" style="background-color: var(--vino);">
                    <h6 class="mb-0">
                        <i class="fas fa-filter mr-2"></i>Filtros de Búsqueda
                    </h6>
                </div>
                <div class="card-body p-3">
                    <form method="GET" action="" id="filtrosForm">
                        <!-- Búsqueda general -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Búsqueda General</label>
                            <input type="text" class="form-control form-control-sm" name="busqueda" 
                                   value="<%= busqueda != null ? busqueda : "" %>" 
                                   placeholder="Título, ciudad, dirección...">
                        </div>
                        
                        <!-- Ciudad -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Ciudad</label>
                            <select class="form-control form-control-sm" name="ciudad">
                                <option value="">Todas las ciudades</option>
                                <% for (String ciudad : ciudades) { %>
                                    <option value="<%= ciudad %>" <%= ciudad.equals(ciudadFiltro) ? "selected" : "" %>>
                                        <%= ciudad %>
                                    </option>
                                <% } %>
                            </select>
                        </div>
                        
                        <!-- Tipo de propiedad -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Tipo de Propiedad</label>
                            <select class="form-control form-control-sm" name="tipo">
                                <option value="">Todos los tipos</option>
                                <% for (Map<String, Object> tipo : tiposPropiedad) { %>
                                    <option value="<%= tipo.get("id") %>" 
                                            <%= tipo.get("id").toString().equals(tipoFiltro) ? "selected" : "" %>>
                                        <%= tipo.get("nombre") %>
                                    </option>
                                <% } %>
                            </select>
                        </div>
                        
                        <!-- Operación -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Operación</label>
                            <select class="form-control form-control-sm" name="operacion">
                                <option value="">Todas</option>
                                <option value="VENTA" <%= "VENTA".equals(operacionFiltro) ? "selected" : "" %>>Venta</option>
                                <option value="ARRIENDO" <%= "ARRIENDO".equals(operacionFiltro) ? "selected" : "" %>>Arriendo</option>
                                <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(operacionFiltro) ? "selected" : "" %>>Venta/Arriendo</option>
                            </select>
                        </div>
                        
                        <!-- Rango de precios -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Rango de Precio</label>
                            <div class="row">
                                <div class="col-6">
                                    <input type="number" class="form-control form-control-sm" name="precio_min" 
                                           value="<%= precioMinStr != null ? precioMinStr : "" %>" 
                                           placeholder="Mín">
                                </div>
                                <div class="col-6">
                                    <input type="number" class="form-control form-control-sm" name="precio_max" 
                                           value="<%= precioMaxStr != null ? precioMaxStr : "" %>" 
                                           placeholder="Máx">
                                </div>
                            </div>
                        </div>
                        
                        <!-- Habitaciones -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Mín. Habitaciones</label>
                            <select class="form-control form-control-sm" name="habitaciones">
                                <option value="">Cualquier cantidad</option>
                                <option value="1" <%= "1".equals(habitacionesFiltro) ? "selected" : "" %>>1+</option>
                                <option value="2" <%= "2".equals(habitacionesFiltro) ? "selected" : "" %>>2+</option>
                                <option value="3" <%= "3".equals(habitacionesFiltro) ? "selected" : "" %>>3+</option>
                                <option value="4" <%= "4".equals(habitacionesFiltro) ? "selected" : "" %>>4+</option>
                                <option value="5" <%= "5".equals(habitacionesFiltro) ? "selected" : "" %>>5+</option>
                            </select>
                        </div>
                        
                        <!-- Baños -->
                        <div class="mb-3">
                            <label class="font-weight-bold small">Mín. Baños</label>
                            <select class="form-control form-control-sm" name="banos">
                                <option value="">Cualquier cantidad</option>
                                <option value="1" <%= "1".equals(banosFiltro) ? "selected" : "" %>>1+</option>
                                <option value="2" <%= "2".equals(banosFiltro) ? "selected" : "" %>>2+</option>
                                <option value="3" <%= "3".equals(banosFiltro) ? "selected" : "" %>>3+</option>
                                <option value="4" <%= "4".equals(banosFiltro) ? "selected" : "" %>>4+</option>
                            </select>
                        </div>
                        
                        <!-- Botones -->
                        <div class="d-grid gap-2">
                            <button type="submit" class="btn btn-sm text-white" style="background-color: var(--vino);">
                                <i class="fas fa-search mr-1"></i>Buscar
                            </button>
                            <a href="list-properties.jsp" class="btn btn-sm btn-outline-secondary">
                                <i class="fas fa-times mr-1"></i>Limpiar
                            </a>
                        </div>
                    </form>
                </div>
            </div>
            
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Header y ordenamiento -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 class="font-weight-bold" style="color: var(--vino);">
                        <i class="fas fa-home mr-2"></i>Propiedades Disponibles
                        <% if (totalDestacadas > 0) { %>
                            <span class="badge badge-warning ml-2">
                                <i class="fas fa-star mr-1"></i><%= totalDestacadas %> Destacadas
                            </span>
                        <% } %>
                    </h3>
                    <p class="text-muted mb-0">
                        <%= totalPropiedades %> propiedades encontradas
                        <% if (busqueda != null && !busqueda.trim().isEmpty()) { %>
                            para "<strong><%= busqueda %></strong>"
                        <% } %>
                    </p>
                </div>
                
                <!-- Ordenamiento -->
                <div class="d-flex align-items-center">
                    <label class="mr-2 mb-0 small font-weight-bold">Ordenar por:</label>
                    <select class="form-control form-control-sm" id="ordenarSelect" onchange="cambiarOrden()">
                        <option value="" <%= ordenar == null || ordenar.isEmpty() ? "selected" : "" %>>Relevancia</option>
                        <option value="precio_asc" <%= "precio_asc".equals(ordenar) ? "selected" : "" %>>Precio: Menor a Mayor</option>
                        <option value="precio_desc" <%= "precio_desc".equals(ordenar) ? "selected" : "" %>>Precio: Mayor a Menor</option>
                        <option value="fecha_desc" <%= "fecha_desc".equals(ordenar) ? "selected" : "" %>>Más Recientes</option>
                        <option value="fecha_asc" <%= "fecha_asc".equals(ordenar) ? "selected" : "" %>>Más Antiguos</option>
                        <option value="titulo" <%= "titulo".equals(ordenar) ? "selected" : "" %>>Título A-Z</option>
                    </select>
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
            
            <!-- Grid de propiedades -->
            <% if (!propiedades.isEmpty()) { %>
                <div class="row">
                    <% for (Map<String, Object> propiedad : propiedades) { 
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
                    <div class="col-md-6 col-lg-4 mb-4">
                        <div class="card h-100 shadow-sm property-card <%= destacada ? "border-warning" : "" %>">
                            <% if (destacada) { %>
                            <div class="card-img-overlay p-2" style="z-index: 1; pointer-events: none;">
                                <span class="badge badge-warning float-right" style="pointer-events: auto;">
                                    <i class="fas fa-star mr-1"></i>Destacada
                                </span>
                            </div>
                        <% } %>
                            
                            <!-- Imagen -->
                            <div class="property-image">
                                <% if (propiedad.get("imagen_principal") != null && !((String)propiedad.get("imagen_principal")).isEmpty()) { %>
                                    <img src="<%= propiedad.get("imagen_principal") %>" 
                                         alt="<%= propiedad.get("titulo") %>" 
                                         class="card-img-top"
                                         onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                <% } else { %>
                                    <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                         alt="Sin imagen" class="card-img-top">
                                <% } %>
                                
                                <!-- Overlay con tipo de operación -->
                                <div class="property-overlay">
                                    <span class="badge <%= badgeOperacion %> operation-badge">
                                        <%= operacion.replace("_", "/") %>
                                    </span>
                                </div>
                            </div>
                            
                            <div class="card-body d-flex flex-column">
                                <!-- Título y precio -->
                                <div class="mb-2">
                                    <h6 class="card-title font-weight-bold mb-1" style="color: var(--vino);">
                                        <%= propiedad.get("titulo") %>
                                    </h6>
                                    <h5 class="text-success font-weight-bold mb-0">
                                        $<%= String.format("%,d", (Long)propiedad.get("precio")) %>
                                    </h5>
                                </div>
                                
                                <!-- Ubicación -->
                                <p class="text-muted small mb-2">
                                    <i class="fas fa-map-marker-alt mr-1"></i>
                                    <%= propiedad.get("ciudad") %>, <%= propiedad.get("departamento") %>
                                </p>
                                
                                <!-- Características -->
                                <div class="property-features mb-3">
                                    <small class="text-muted">
                                        <% if ((Integer)propiedad.get("habitaciones") > 0) { %>
                                            <i class="fas fa-bed mr-1"></i><%= propiedad.get("habitaciones") %> hab
                                        <% } %>
                                        <% if ((Integer)propiedad.get("banos") > 0) { %>
                                            <i class="fas fa-bath ml-2 mr-1"></i><%= propiedad.get("banos") %> baños
                                        <% } %>
                                        <% if ((Integer)propiedad.get("garajes") > 0) { %>
                                            <i class="fas fa-car ml-2 mr-1"></i><%= propiedad.get("garajes") %> garajes
                                        <% } %>
                                        <% if ((Double)propiedad.get("area_construida") > 0) { %>
                                            <br><i class="fas fa-ruler-combined mr-1"></i><%= String.format("%.0f", (Double)propiedad.get("area_construida")) %>m²
                                        <% } %>
                                    </small>
                                </div>
                                
                                <!-- Descripción -->
                                <% if (propiedad.get("descripcion") != null) { %>
                                    <p class="card-text small text-muted flex-grow-1">
                                        <%= ((String)propiedad.get("descripcion")).length() > 100 ? 
                                            ((String)propiedad.get("descripcion")).substring(0, 100) + "..." : 
                                            propiedad.get("descripcion") %>
                                    </p>
                                <% } %>
                                
                                <!-- Botones de acción -->
                                <div class="mt-auto">
                                    <div class="d-flex justify-content-between align-items-center">
                                        <small class="text-muted">
                                            <i class="fas fa-user mr-1"></i><%= propiedad.get("propietario_nombre") %>
                                        </small>
                                        <div>
                                            <% if (propiedad.get("propietario_telefono") != null) { %>
                                                <a href="tel:<%= propiedad.get("propietario_telefono") %>" 
                                                   class="btn btn-sm btn-outline-success mr-1" title="Llamar">
                                                    <i class="fas fa-phone"></i>
                                                </a>
                                            <% } %>
                                            <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>" 
                                               class="btn btn-sm text-white" style="background-color: var(--vino);">
                                                Ver Detalles
                                            </a>
                                        </div>
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
                                <a class="page-link" href="<%= construirUrlPaginacion(request, paginaActual - 1) %>">
                                    <i class="fas fa-chevron-left"></i>
                                </a>
                            </li>
                            
                            <% 
                                int inicio = Math.max(1, paginaActual - 2);
                                int fin = Math.min(totalPaginas, paginaActual + 2);
                                
                                for (int i = inicio; i <= fin; i++) {
                            %>
                                <li class="page-item <%= i == paginaActual ? "active" : "" %>">
                                    <a class="page-link" href="<%= construirUrlPaginacion(request, i) %>"><%= i %></a>
                                </li>
                            <% } %>
                            
                            <li class="page-item <%= paginaActual == totalPaginas ? "disabled" : "" %>">
                                <a class="page-link" href="<%= construirUrlPaginacion(request, paginaActual + 1) %>">
                                    <i class="fas fa-chevron-right"></i>
                                </a>
                            </li>
                        </ul>
                    </nav>
                </div>
                <% } %>
                
            <% } else { %>
                <!-- Estado vacío -->
                <div class="text-center py-5">
                    <i class="fas fa-search fa-3x text-muted mb-3"></i>
                    <h5 class="text-muted">No se encontraron propiedades</h5>
                    <p class="text-muted">
                        Intenta ajustar los filtros de búsqueda o 
                        <a href="list-properties.jsp">ver todas las propiedades</a>
                    </p>
                </div>
            <% } %>
            
        </div>
    </div>
</div>

<%!
    // Función auxiliar para construir URLs de paginación
    private String construirUrlPaginacion(HttpServletRequest request, int pagina) {
        StringBuilder url = new StringBuilder("list-properties.jsp?page=" + pagina);
        
        if (request.getParameter("busqueda") != null && !request.getParameter("busqueda").isEmpty()) {
            url.append("&busqueda=").append(request.getParameter("busqueda"));
        }
        if (request.getParameter("ciudad") != null && !request.getParameter("ciudad").isEmpty()) {
            url.append("&ciudad=").append(request.getParameter("ciudad"));
        }
        if (request.getParameter("tipo") != null && !request.getParameter("tipo").isEmpty()) {
            url.append("&tipo=").append(request.getParameter("tipo"));
        }
        if (request.getParameter("operacion") != null && !request.getParameter("operacion").isEmpty()) {
            url.append("&operacion=").append(request.getParameter("operacion"));
        }
        if (request.getParameter("precio_min") != null && !request.getParameter("precio_min").isEmpty()) {
            url.append("&precio_min=").append(request.getParameter("precio_min"));
        }
        if (request.getParameter("precio_max") != null && !request.getParameter("precio_max").isEmpty()) {
            url.append("&precio_max=").append(request.getParameter("precio_max"));
        }
        if (request.getParameter("habitaciones") != null && !request.getParameter("habitaciones").isEmpty()) {
            url.append("&habitaciones=").append(request.getParameter("habitaciones"));
        }
        if (request.getParameter("banos") != null && !request.getParameter("banos").isEmpty()) {
            url.append("&banos=").append(request.getParameter("banos"));
        }
        if (request.getParameter("ordenar") != null && !request.getParameter("ordenar").isEmpty()) {
            url.append("&ordenar=").append(request.getParameter("ordenar"));
        }
        
        return url.toString();
    }
%>

<!-- Estilos adicionales -->
<style>
:root {
    --vino: #722f37;
    --rojo: #d32f2f;
    --naranja: #ff9800;
    --amarillo: #ffc107;
}

.property-card {
    transition: transform 0.3s ease, box-shadow 0.3s ease;
    border-radius: 10px;
    overflow: hidden;
}

.property-card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15);
}

.property-card.border-warning {
    border-color: var(--amarillo) !important;
    border-width: 2px !important;
}

.property-image {
    position: relative;
    height: 200px;
    overflow: hidden;
}

.property-image img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s ease;
}

.property-card:hover .property-image img {
    transform: scale(1.05);
}

.property-overlay {
    position: absolute;
    bottom: 10px;
    left: 10px;
    z-index: 2;
}

.operation-badge {
    font-size: 0.75rem;
    padding: 0.375rem 0.75rem;
}

.property-features i {
    color: var(--vino);
}

.card-title {
    font-size: 1rem;
    line-height: 1.3;
    max-height: 2.6rem;
    overflow: hidden;
    display: -webkit-box;
    /* -webkit-line-clamp: 2; */
    -webkit-box-orient: vertical;
}

.card-text {
    font-size: 0.85rem;
    line-height: 1.4;
}

.sticky-top {
    position: -webkit-sticky;
    position: sticky;
}

.pagination .page-link {
    color: var(--vino);
    border-color: #dee2e6;
}

.pagination .page-item.active .page-link {
    background-color: var(--vino);
    border-color: var(--vino);
}

.pagination .page-link:hover {
    color: var(--vino);
    background-color: #f8f9fa;
}

.form-control:focus {
    border-color: var(--vino);
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

.btn:focus, .btn.focus {
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

@media (max-width: 768px) {
    .property-image {
        height: 150px;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .sticky-top {
        position: relative !important;
        top: auto !important;
    }
}

@media (max-width: 576px) {
    .d-flex.justify-content-between {
        flex-direction: column;
        align-items: flex-start !important;
    }
    
    .d-flex.justify-content-between > div:last-child {
        margin-top: 1rem;
        align-self: stretch;
    }
}
</style>

<!-- JavaScript para funcionalidades interactivas -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Auto-submit del formulario cuando cambian los filtros
    const filtrosForm = document.getElementById('filtrosForm');
    const selectores = filtrosForm.querySelectorAll('select, input[type="number"]');
    
    selectores.forEach(selector => {
        selector.addEventListener('change', function() {
            // Pequeño delay para mejor UX
            setTimeout(() => {
                filtrosForm.submit();
            }, 100);
        });
    });
    
    // Submit manual para el campo de búsqueda (solo al presionar Enter)
    const busquedaInput = filtrosForm.querySelector('input[name="busqueda"]');
    if (busquedaInput) {
        busquedaInput.addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                filtrosForm.submit();
            }
        });
    }
    
    // Lazy loading para imágenes
    const imagenes = document.querySelectorAll('.property-image img');
    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.classList.add('fade-in');
                observer.unobserve(img);
            }
        });
    });
    
    imagenes.forEach(img => imageObserver.observe(img));
    
    // Smooth scroll para la paginación
    const paginationLinks = document.querySelectorAll('.pagination .page-link');
    paginationLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            // Scroll suave hacia arriba
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        });
    });
});

// Función para cambiar orden
function cambiarOrden() {
    const selectOrden = document.getElementById('ordenarSelect');
    const url = new URL(window.location);
    
    if (selectOrden.value) {
        url.searchParams.set('ordenar', selectOrden.value);
    } else {
        url.searchParams.delete('ordenar');
    }
    
    url.searchParams.set('page', '1'); // Resetear a primera página
    window.location.href = url.toString();
}

// Función para limpiar filtros
function limpiarFiltros() {
    window.location.href = 'list-properties.jsp';
}

// Funciones para favoritos (si el usuario está logueado)
if (isLoggedIn) { 
function toggleFavorito(propiedadId) {
    // Implementar funcionalidad de favoritos
    fetch('<%= request.getContextPath() %>/api/favoritos', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            propiedad_id: propiedadId,
            action: 'toggle'
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            const btn = document.querySelector(`[data-property-id="${propiedadId}"] .btn-favorito`);
            if (btn) {
                btn.innerHTML = data.is_favorite ? 
                    '<i class="fas fa-heart"></i>' : 
                    '<i class="far fa-heart"></i>';
                btn.title = data.is_favorite ? 'Quitar de favoritos' : 'Agregar a favoritos';
            }
        }
    })
    .catch(error => console.error('Error:', error));
} }
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />