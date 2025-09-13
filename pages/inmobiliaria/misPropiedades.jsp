<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null || !"INMOBILIARIA".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Parámetros de filtro y paginación
    String filtroTipo = request.getParameter("tipo");
    String filtroEstado = request.getParameter("estado");
    String filtroOperacion = request.getParameter("operacion");
    String filtroCiudad = request.getParameter("ciudad");
    String filtroOrden = request.getParameter("orden");
    String busqueda = request.getParameter("busqueda");
    
    int paginaActual = 1;
    int propiedadesPorPagina = 12;
    
    try {
        if (request.getParameter("pagina") != null) {
            paginaActual = Integer.parseInt(request.getParameter("pagina"));
        }
    } catch (NumberFormatException e) {
        paginaActual = 1;
    }
    
    int offset = (paginaActual - 1) * propiedadesPorPagina;
    
    // Variables para datos
    List<Map<String, Object>> propiedades = new ArrayList<>();
    List<Map<String, Object>> tiposPropiedad = new ArrayList<>();
    List<String> ciudadesDisponibles = new ArrayList<>();
    int totalPropiedades = 0;
    int totalPaginas = 0;
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones
    String accion = request.getParameter("accion");
    if (accion != null) {
        Connection connAccion = null;
        PreparedStatement stmtAccion = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            connAccion = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("cambiar_estado".equals(accion)) {
                int propiedadId = Integer.parseInt(request.getParameter("propiedad_id"));
                boolean nuevoEstado = Boolean.parseBoolean(request.getParameter("nuevo_estado"));
                
                // Verificar que la propiedad pertenece al usuario
                String sqlVerificar = "SELECT id_propiedad FROM propiedades WHERE id_propiedad = ? AND id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, propiedadId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    String sqlCambiarEstado = "UPDATE propiedades SET disponible = ? WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlCambiarEstado);
                    stmtAccion.setBoolean(1, nuevoEstado);
                    stmtAccion.setInt(2, propiedadId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Estado de la propiedad actualizado correctamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al actualizar el estado de la propiedad.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para modificar esta propiedad.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
                
            } else if ("cambiar_destacada".equals(accion)) {
                int propiedadId = Integer.parseInt(request.getParameter("propiedad_id"));
                boolean nuevaDestacada = Boolean.parseBoolean(request.getParameter("nueva_destacada"));
                
                // Verificar que la propiedad pertenece al usuario
                String sqlVerificar = "SELECT id_propiedad FROM propiedades WHERE id_propiedad = ? AND id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, propiedadId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    String sqlCambiarDestacada = "UPDATE propiedades SET destacada = ? WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlCambiarDestacada);
                    stmtAccion.setBoolean(1, nuevaDestacada);
                    stmtAccion.setInt(2, propiedadId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        mensaje = nuevaDestacada ? "Propiedad marcada como destacada." : "Propiedad desmarcada como destacada.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al actualizar la propiedad.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para modificar esta propiedad.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
                
            } else if ("eliminar".equals(accion)) {
                int propiedadId = Integer.parseInt(request.getParameter("propiedad_id"));
                
                // Verificar que la propiedad pertenece al usuario
                String sqlVerificar = "SELECT id_propiedad FROM propiedades WHERE id_propiedad = ? AND id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, propiedadId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    // Primero eliminar las imágenes asociadas
                    String sqlEliminarImagenes = "DELETE FROM imagenes_propiedades WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlEliminarImagenes);
                    stmtAccion.setInt(1, propiedadId);
                    stmtAccion.executeUpdate();
                    stmtAccion.close();
                    
                    // Luego eliminar las citas asociadas
                    String sqlEliminarCitas = "DELETE FROM citas WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlEliminarCitas);
                    stmtAccion.setInt(1, propiedadId);
                    stmtAccion.executeUpdate();
                    stmtAccion.close();
                    
                    // Eliminar favoritos
                    String sqlEliminarFavoritos = "DELETE FROM favoritos WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlEliminarFavoritos);
                    stmtAccion.setInt(1, propiedadId);
                    stmtAccion.executeUpdate();
                    stmtAccion.close();
                    
                    // Finalmente eliminar la propiedad
                    String sqlEliminarPropiedad = "DELETE FROM propiedades WHERE id_propiedad = ?";
                    stmtAccion = connAccion.prepareStatement(sqlEliminarPropiedad);
                    stmtAccion.setInt(1, propiedadId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        mensaje = "Propiedad eliminada correctamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al eliminar la propiedad.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para eliminar esta propiedad.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
            }
            
        } catch (Exception e) {
            mensaje = "Error al procesar la acción: " + e.getMessage();
            tipoMensaje = "error";
        } finally {
            if (stmtAccion != null) try { stmtAccion.close(); } catch (SQLException e) {}
            if (connAccion != null) try { connAccion.close(); } catch (SQLException e) {}
        }
    }
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // =====================================================
        // 1. CARGAR DATOS PARA FILTROS
        // =====================================================
        
        // Tipos de propiedad
        String sqlTipos = "SELECT * FROM tipos_propiedad WHERE activo = 1 ORDER BY nombre_tipo";
        stmt = conn.prepareStatement(sqlTipos);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> tipo = new HashMap<>();
            tipo.put("id_tipo", rs.getInt("id_tipo"));
            tipo.put("nombre_tipo", rs.getString("nombre_tipo"));
            tiposPropiedad.add(tipo);
        }
        rs.close();
        stmt.close();
        
        // Ciudades disponibles
        String sqlCiudades = "SELECT DISTINCT ciudad FROM propiedades WHERE id_propietario = ? ORDER BY ciudad";
        stmt = conn.prepareStatement(sqlCiudades);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            ciudadesDisponibles.add(rs.getString("ciudad"));
        }
        rs.close();
        stmt.close();
        
        // =====================================================
        // 2. CONTAR TOTAL DE PROPIEDADES CON FILTROS
        // =====================================================
        
        StringBuilder sqlCount = new StringBuilder("SELECT COUNT(*) FROM propiedades p ");
        sqlCount.append("INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo ");
        sqlCount.append("WHERE p.id_propietario = ? ");
        
        List<Object> parametros = new ArrayList<>();
        parametros.add(usuarioId);
        
        // Aplicar filtros
        if (filtroTipo != null && !filtroTipo.trim().isEmpty()) {
            sqlCount.append("AND p.id_tipo = ? ");
            parametros.add(Integer.parseInt(filtroTipo));
        }
        
        if (filtroEstado != null && !filtroEstado.trim().isEmpty()) {
            if ("activa".equals(filtroEstado)) {
                sqlCount.append("AND p.disponible = 1 ");
            } else if ("inactiva".equals(filtroEstado)) {
                sqlCount.append("AND p.disponible = 0 ");
            } else if ("destacada".equals(filtroEstado)) {
                sqlCount.append("AND p.destacada = 1 ");
            }
        }
        
        if (filtroOperacion != null && !filtroOperacion.trim().isEmpty()) {
            sqlCount.append("AND p.tipo_operacion = ? ");
            parametros.add(filtroOperacion);
        }
        
        if (filtroCiudad != null && !filtroCiudad.trim().isEmpty()) {
            sqlCount.append("AND p.ciudad = ? ");
            parametros.add(filtroCiudad);
        }
        
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            sqlCount.append("AND (p.titulo LIKE ? OR p.descripcion LIKE ? OR p.direccion LIKE ?) ");
            parametros.add("%" + busqueda + "%");
            parametros.add("%" + busqueda + "%");
            parametros.add("%" + busqueda + "%");
        }
        
        stmt = conn.prepareStatement(sqlCount.toString());
        for (int i = 0; i < parametros.size(); i++) {
            stmt.setObject(i + 1, parametros.get(i));
        }
        
        rs = stmt.executeQuery();
        if (rs.next()) {
            totalPropiedades = rs.getInt(1);
        }
        rs.close();
        stmt.close();
        
        totalPaginas = (int) Math.ceil((double) totalPropiedades / propiedadesPorPagina);
        
        // =====================================================
        // 3. OBTENER PROPIEDADES CON FILTROS Y PAGINACIÓN
        // =====================================================
        
        StringBuilder sqlPropiedades = new StringBuilder();
        sqlPropiedades.append("SELECT p.*, tp.nombre_tipo, ");
        sqlPropiedades.append("(SELECT COUNT(*) FROM citas c WHERE c.id_propiedad = p.id_propiedad) as total_citas, ");
        sqlPropiedades.append("(SELECT COUNT(*) FROM citas c WHERE c.id_propiedad = p.id_propiedad AND c.estado = 'PENDIENTE') as citas_pendientes, ");
        sqlPropiedades.append("(SELECT COUNT(*) FROM favoritos f WHERE f.id_propiedad = p.id_propiedad) as total_favoritos ");
        sqlPropiedades.append("FROM propiedades p ");
        sqlPropiedades.append("INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo ");
        sqlPropiedades.append("WHERE p.id_propietario = ? ");
        
        // Aplicar los mismos filtros
        if (filtroTipo != null && !filtroTipo.trim().isEmpty()) {
            sqlPropiedades.append("AND p.id_tipo = ? ");
        }
        
        if (filtroEstado != null && !filtroEstado.trim().isEmpty()) {
            if ("activa".equals(filtroEstado)) {
                sqlPropiedades.append("AND p.disponible = 1 ");
            } else if ("inactiva".equals(filtroEstado)) {
                sqlPropiedades.append("AND p.disponible = 0 ");
            } else if ("destacada".equals(filtroEstado)) {
                sqlPropiedades.append("AND p.destacada = 1 ");
            }
        }
        
        if (filtroOperacion != null && !filtroOperacion.trim().isEmpty()) {
            sqlPropiedades.append("AND p.tipo_operacion = ? ");
        }
        
        if (filtroCiudad != null && !filtroCiudad.trim().isEmpty()) {
            sqlPropiedades.append("AND p.ciudad = ? ");
        }
        
        if (busqueda != null && !busqueda.trim().isEmpty()) {
            sqlPropiedades.append("AND (p.titulo LIKE ? OR p.descripcion LIKE ? OR p.direccion LIKE ?) ");
        }
        
        // Orden
        sqlPropiedades.append("ORDER BY ");
        if ("precio_asc".equals(filtroOrden)) {
            sqlPropiedades.append("p.precio ASC ");
        } else if ("precio_desc".equals(filtroOrden)) {
            sqlPropiedades.append("p.precio DESC ");
        } else if ("fecha_asc".equals(filtroOrden)) {
            sqlPropiedades.append("p.fecha_publicacion ASC ");
        } else if ("titulo".equals(filtroOrden)) {
            sqlPropiedades.append("p.titulo ASC ");
        } else {
            sqlPropiedades.append("p.fecha_publicacion DESC ");
        }
        
        sqlPropiedades.append("LIMIT ? OFFSET ?");
        
        stmt = conn.prepareStatement(sqlPropiedades.toString());
        
        int paramIndex = 1;
        for (Object param : parametros) {
            stmt.setObject(paramIndex++, param);
        }
        stmt.setInt(paramIndex++, propiedadesPorPagina);
        stmt.setInt(paramIndex, offset);
        
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id_propiedad", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("descripcion", rs.getString("descripcion"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("area_construida", rs.getDouble("area_construida"));
            propiedad.put("area_total", rs.getDouble("area_total"));
            propiedad.put("habitaciones", rs.getInt("habitaciones"));
            propiedad.put("banos", rs.getInt("banos"));
            propiedad.put("garajes", rs.getInt("garajes"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("departamento", rs.getString("departamento"));
            propiedad.put("disponible", rs.getBoolean("disponible"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("imagen_principal", rs.getString("imagen_principal"));
            propiedad.put("fecha_publicacion", rs.getTimestamp("fecha_publicacion"));
            propiedad.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("total_citas", rs.getInt("total_citas"));
            propiedad.put("citas_pendientes", rs.getInt("citas_pendientes"));
            propiedad.put("total_favoritos", rs.getInt("total_favoritos"));
            propiedades.add(propiedad);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        if (mensaje.isEmpty()) {
            mensaje = "Error al cargar las propiedades: " + e.getMessage();
            tipoMensaje = "error";
        }
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Mis Propiedades - Inmobiliaria" />
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
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-6">
                                    <h2 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-home mr-2"></i>Mis Propiedades
                                    </h2>
                                    <p class="text-muted mb-0">
                                        Gestiona tu inventario de propiedades
                                    </p>
                                </div>
                                <div class="col-md-6 text-md-right">
                                    <span class="text-muted mr-3">
                                        Total: <strong><%= totalPropiedades %></strong> propiedades
                                    </span>
                                    <a href="../properties/nuevaPropiedad.jsp" class="btn text-white" style="background-color: var(--vino);">
                                        <i class="fas fa-plus mr-1"></i>Nueva Propiedad
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
            
            <!-- Filtros -->
            <div class="card shadow mb-4">
                <div class="card-header">
                    <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                        <i class="fas fa-filter mr-2"></i>Filtros y Búsqueda
                    </h6>
                </div>
                <div class="card-body">
                    <form method="GET" action="misPropiedades.jsp">
                        <div class="row">
                            <div class="col-md-3">
                                <label for="busqueda" class="form-label">Buscar</label>
                                <input type="text" class="form-control form-control-sm" id="busqueda" name="busqueda" 
                                       value="<%= busqueda != null ? busqueda : "" %>" 
                                       placeholder="Título, descripción...">
                            </div>
                            
                            <div class="col-md-2">
                                <label for="tipo" class="form-label">Tipo</label>
                                <select class="form-control form-control-sm" id="tipo" name="tipo">
                                    <option value="">Todos</option>
                                    <% for (Map<String, Object> tipo : tiposPropiedad) { %>
                                        <option value="<%= tipo.get("id_tipo") %>" 
                                                <%= String.valueOf(tipo.get("id_tipo")).equals(filtroTipo) ? "selected" : "" %>>
                                            <%= tipo.get("nombre_tipo") %>
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div class="col-md-2">
                                <label for="estado" class="form-label">Estado</label>
                                <select class="form-control form-control-sm" id="estado" name="estado">
                                    <option value="">Todos</option>
                                    <option value="activa" <%= "activa".equals(filtroEstado) ? "selected" : "" %>>Activa</option>
                                    <option value="inactiva" <%= "inactiva".equals(filtroEstado) ? "selected" : "" %>>Inactiva</option>
                                    <option value="destacada" <%= "destacada".equals(filtroEstado) ? "selected" : "" %>>Destacada</option>
                                </select>
                            </div>
                            
                            <div class="col-md-2">
                                <label for="operacion" class="form-label">Operación</label>
                                <select class="form-control form-control-sm" id="operacion" name="operacion">
                                    <option value="">Todas</option>
                                    <option value="VENTA" <%= "VENTA".equals(filtroOperacion) ? "selected" : "" %>>Venta</option>
                                    <option value="ARRIENDO" <%= "ARRIENDO".equals(filtroOperacion) ? "selected" : "" %>>Arriendo</option>
                                    <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(filtroOperacion) ? "selected" : "" %>>Venta/Arriendo</option>
                                </select>
                            </div>
                            
                            <div class="col-md-2">
                                <label for="ciudad" class="form-label">Ciudad</label>
                                <select class="form-control form-control-sm" id="ciudad" name="ciudad">
                                    <option value="">Todas</option>
                                    <% for (String ciudad : ciudadesDisponibles) { %>
                                        <option value="<%= ciudad %>" <%= ciudad.equals(filtroCiudad) ? "selected" : "" %>>
                                            <%= ciudad %>
                                        </option>
                                    <% } %>
                                </select>
                            </div>
                            
                            <div class="col-md-1">
                                <label class="form-label">&nbsp;</label>
                                <div>
                                    <button type="submit" class="btn btn-primary btn-sm">
                                        <i class="fas fa-search"></i>
                                    </button>
                                    <a href="misPropiedades.jsp" class="btn btn-secondary btn-sm ml-1">
                                        <i class="fas fa-times"></i>
                                    </a>
                                </div>
                            </div>
                        </div>
                        
                        <div class="row mt-3">
                            <div class="col-md-3">
                                <label for="orden" class="form-label">Ordenar por</label>
                                <select class="form-control form-control-sm" id="orden" name="orden" onchange="this.form.submit()">
                                    <option value="fecha_desc" <%= "fecha_desc".equals(filtroOrden) || filtroOrden == null ? "selected" : "" %>>Más recientes</option>
                                    <option value="fecha_asc" <%= "fecha_asc".equals(filtroOrden) ? "selected" : "" %>>Más antiguas</option>
                                    <option value="precio_desc" <%= "precio_desc".equals(filtroOrden) ? "selected" : "" %>>Precio mayor</option>
                                    <option value="precio_asc" <%= "precio_asc".equals(filtroOrden) ? "selected" : "" %>>Precio menor</option>
                                    <option value="titulo" <%= "titulo".equals(filtroOrden) ? "selected" : "" %>>Título A-Z</option>
                                </select>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            
            <!-- Lista de propiedades -->
            <div class="row">
                <% if (propiedades.isEmpty()) { %>
                    <div class="col-12">
                        <div class="card shadow">
                            <div class="card-body text-center py-5">
                                <i class="fas fa-home fa-4x text-muted mb-4"></i>
                                <h4 class="text-muted">No se encontraron propiedades</h4>
                                <p class="text-muted mb-4">
                                    <% if (busqueda != null || filtroTipo != null || filtroEstado != null || filtroOperacion != null || filtroCiudad != null) { %>
                                        Intenta modificar los filtros de búsqueda para encontrar más resultados.
                                    <% } else { %>
                                        Comienza agregando tu primera propiedad al catálogo.
                                    <% } %>
                                </p>
                                <a href="../properties/nuevaPropiedad.jsp" class="btn text-white" style="background-color: var(--vino);">
                                    <i class="fas fa-plus mr-1"></i>Agregar Primera Propiedad
                                </a>
                            </div>
                        </div>
                    </div>
                <% } else { %>
                    <% for (Map<String, Object> prop : propiedades) { %>
                        <div class="col-lg-4 col-md-6 mb-4">
                            <div class="card shadow h-100">
                                <!-- Imagen de la propiedad -->
                                <div class="position-relative">
                                    <% if (prop.get("imagen_principal") != null) { %>
                                        <img src="<%= prop.get("imagen_principal") %>" 
                                             class="card-img-top" alt="<%= prop.get("titulo") %>" 
                                             style="height: 200px; object-fit: cover;">
                                    <% } else { %>
                                        <div class="card-img-top d-flex align-items-center justify-content-center bg-light" 
                                             style="height: 200px;">
                                            <i class="fas fa-image fa-3x text-muted"></i>
                                        </div>
                                    <% } %>
                                    
                                    <!-- Badges de estado -->
                                    <div class="position-absolute" style="top: 10px; left: 10px;">
                                        <% if (!(Boolean)prop.get("disponible")) { %>
                                            <span class="badge badge-secondary">Inactiva</span>
                                        <% } %>
                                        <% if ((Boolean)prop.get("destacada")) { %>
                                            <span class="badge badge-warning">
                                                <i class="fas fa-star mr-1"></i>Destacada
                                            </span>
                                        <% } %>
                                    </div>
                                    
                                    <!-- Tipo de operación -->
                                    <div class="position-absolute" style="top: 10px; right: 10px;">
                                        <span class="badge badge-info">
                                            <%= ((String)prop.get("tipo_operacion")).replace("_", "/") %>
                                        </span>
                                    </div>
                                    
                                    <!-- Precio -->
                                    <div class="position-absolute bg-dark text-white px-2 py-1 rounded" 
                                         style="bottom: 10px; left: 10px;">
                                        <strong>$<%= String.format("%,d", (Long)prop.get("precio")) %></strong>
                                    </div>
                                </div>
                                
                                <div class="card-body d-flex flex-column">
                                    <!-- Título y tipo -->
                                    <h6 class="card-title mb-2" style="color: var(--vino);">
                                        <strong><%= prop.get("titulo") %></strong>
                                    </h6>
                                    <p class="text-muted mb-2">
                                        <span class="badge badge-outline-primary"><%= prop.get("nombre_tipo") %></span>
                                    </p>
                                    
                                    <!-- Ubicación -->
                                    <p class="text-muted mb-2">
                                        <i class="fas fa-map-marker-alt mr-1"></i>
                                        <%= prop.get("direccion") %><br>
                                        <%= prop.get("ciudad") %>, <%= prop.get("departamento") %>
                                    </p>
                                    
                                    <!-- Características -->
                                    <div class="row mb-3">
                                        <% if ((Integer)prop.get("habitaciones") > 0) { %>
                                            <div class="col-4 text-center">
                                                <i class="fas fa-bed text-muted"></i><br>
                                                <small><%= prop.get("habitaciones") %> hab</small>
                                            </div>
                                        <% } %>
                                        <% if ((Integer)prop.get("banos") > 0) { %>
                                            <div class="col-4 text-center">
                                                <i class="fas fa-bath text-muted"></i><br>
                                                <small><%= prop.get("banos") %> baños</small>
                                            </div>
                                        <% } %>
                                        <% if (prop.get("area_construida") != null && (Double)prop.get("area_construida") > 0) { %>
                                            <div class="col-4 text-center">
                                                <i class="fas fa-ruler-combined text-muted"></i><br>
                                                <small><%= String.format("%.0f", (Double)prop.get("area_construida")) %> m²</small>
                                            </div>
                                        <% } %>
                                    </div>
                                    
                                    <!-- Estadísticas -->
                                    <div class="mb-3">
                                        <div class="row text-center">
                                            <div class="col-4">
                                                <div class="text-primary">
                                                    <i class="fas fa-calendar-alt"></i>
                                                    <small class="d-block"><%= prop.get("total_citas") %> citas</small>
                                                </div>
                                            </div>
                                            <div class="col-4">
                                                <div class="text-warning">
                                                    <i class="fas fa-clock"></i>
                                                    <small class="d-block"><%= prop.get("citas_pendientes") %> pend.</small>
                                                </div>
                                            </div>
                                            <div class="col-4">
                                                <div class="text-danger">
                                                    <i class="fas fa-heart"></i>
                                                    <small class="d-block"><%= prop.get("total_favoritos") %> fav.</small>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <!-- Fecha de publicación -->
                                    <small class="text-muted mb-3">
                                        <i class="fas fa-clock mr-1"></i>
                                        Publicada: <%= new SimpleDateFormat("dd/MM/yyyy").format((java.util.Date)prop.get("fecha_publicacion")) %>
                                    </small>
                                    
                                    <!-- Botones de acción -->
                                    <div class="mt-auto">
                                        <div class="btn-group btn-group-sm d-flex" role="group">
                                            <a href="../properties/verPropiedad.jsp?id=<%= prop.get("id_propiedad") %>" 
                                               class="btn btn-outline-info flex-fill">
                                                <i class="fas fa-eye"></i><span class="d-none d-lg-inline ml-1">Ver</span>
                                            </a>
                                            <a href="../properties/editarPropiedad.jsp?id=<%= prop.get("id_propiedad") %>" 
                                               class="btn btn-outline-primary flex-fill">
                                                <i class="fas fa-edit"></i><span class="d-none d-lg-inline ml-1">Editar</span>
                                            </a>
                                            <div class="btn-group flex-fill">
                                                <button type="button" class="btn btn-outline-secondary dropdown-toggle" 
                                                        data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                                                    <i class="fas fa-cog"></i><span class="d-none d-lg-inline ml-1">Más</span>
                                                </button>
                                                <div class="dropdown-menu dropdown-menu-right">
                                                    <!-- Cambiar estado disponible -->
                                                    <form method="POST" action="misPropiedades.jsp" style="display: inline;">
                                                        <input type="hidden" name="accion" value="cambiar_estado">
                                                        <input type="hidden" name="propiedad_id" value="<%= prop.get("id_propiedad") %>">
                                                        <input type="hidden" name="nuevo_estado" value="<%= !(Boolean)prop.get("disponible") %>">
                                                        <button type="submit" class="dropdown-item" 
                                                                onclick="return confirm('<%= (Boolean)prop.get("disponible") ? "¿Desactivar" : "¿Activar" %> esta propiedad?')">
                                                            <i class="fas fa-<%= (Boolean)prop.get("disponible") ? "eye-slash" : "eye" %> mr-2"></i>
                                                            <%= (Boolean)prop.get("disponible") ? "Desactivar" : "Activar" %>
                                                        </button>
                                                    </form>
                                                    
                                                    <!-- Cambiar destacada -->
                                                    <form method="POST" action="misPropiedades.jsp" style="display: inline;">
                                                        <input type="hidden" name="accion" value="cambiar_destacada">
                                                        <input type="hidden" name="propiedad_id" value="<%= prop.get("id_propiedad") %>">
                                                        <input type="hidden" name="nueva_destacada" value="<%= !(Boolean)prop.get("destacada") %>">
                                                        <button type="submit" class="dropdown-item" 
                                                                onclick="return confirm('<%= (Boolean)prop.get("destacada") ? "¿Quitar" : "¿Marcar" %> como destacada?')">
                                                            <i class="fas fa-<%= (Boolean)prop.get("destacada") ? "star-half-alt" : "star" %> mr-2"></i>
                                                            <%= (Boolean)prop.get("destacada") ? "Quitar destacado" : "Marcar destacada" %>
                                                        </button>
                                                    </form>
                                                    
                                                    <div class="dropdown-divider"></div>
                                                    
                                                    <!-- Ver citas -->
                                                    <a class="dropdown-item" href="../citas/citas.jsp?propiedad=<%= prop.get("id_propiedad") %>">
                                                        <i class="fas fa-calendar-alt mr-2"></i>Ver citas
                                                    </a>
                                                    
                                                    <div class="dropdown-divider"></div>
                                                    
                                                    <!-- Eliminar -->
                                                    <form method="POST" action="misPropiedades.jsp" style="display: inline;">
                                                        <input type="hidden" name="accion" value="eliminar">
                                                        <input type="hidden" name="propiedad_id" value="<%= prop.get("id_propiedad") %>">
                                                        <button type="submit" class="dropdown-item text-danger" 
                                                                onclick="return confirm('¿Estás seguro de eliminar esta propiedad? Esta acción no se puede deshacer.')">
                                                            <i class="fas fa-trash mr-2"></i>Eliminar
                                                        </button>
                                                    </form>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    <% } %>
                <% } %>
            </div>
            
            <!-- Paginación -->
            <% if (totalPaginas > 1) { %>
                <div class="row mt-4">
                    <div class="col-12">
                        <div class="card shadow">
                            <div class="card-body">
                                <nav aria-label="Navegación de propiedades">
                                    <ul class="pagination justify-content-center mb-0">
                                        <!-- Página anterior -->
                                        <% if (paginaActual > 1) { %>
                                            <li class="page-item">
                                                <a class="page-link" href="?pagina=<%= paginaActual - 1 %><%= 
                                                    (busqueda != null ? "&busqueda=" + busqueda : "") +
                                                    (filtroTipo != null ? "&tipo=" + filtroTipo : "") +
                                                    (filtroEstado != null ? "&estado=" + filtroEstado : "") +
                                                    (filtroOperacion != null ? "&operacion=" + filtroOperacion : "") +
                                                    (filtroCiudad != null ? "&ciudad=" + filtroCiudad : "") +
                                                    (filtroOrden != null ? "&orden=" + filtroOrden : "")
                                                %>">
                                                    <i class="fas fa-chevron-left"></i> Anterior
                                                </a>
                                            </li>
                                        <% } %>
                                        
                                        <!-- Números de página -->
                                        <% 
                                        int inicioRango = Math.max(1, paginaActual - 2);
                                        int finRango = Math.min(totalPaginas, paginaActual + 2);
                                        
                                        if (inicioRango > 1) { %>
                                            <li class="page-item">
                                                <a class="page-link" href="?pagina=1<%= 
                                                    (busqueda != null ? "&busqueda=" + busqueda : "") +
                                                    (filtroTipo != null ? "&tipo=" + filtroTipo : "") +
                                                    (filtroEstado != null ? "&estado=" + filtroEstado : "") +
                                                    (filtroOperacion != null ? "&operacion=" + filtroOperacion : "") +
                                                    (filtroCiudad != null ? "&ciudad=" + filtroCiudad : "") +
                                                    (filtroOrden != null ? "&orden=" + filtroOrden : "")
                                                %>">1</a>
                                            </li>
                                            <% if (inicioRango > 2) { %>
                                                <li class="page-item disabled">
                                                    <span class="page-link">...</span>
                                                </li>
                                            <% } %>
                                        <% } %>
                                        
                                        <% for (int i = inicioRango; i <= finRango; i++) { %>
                                            <li class="page-item <%= i == paginaActual ? "active" : "" %>">
                                                <a class="page-link" href="?pagina=<%= i %><%= 
                                                    (busqueda != null ? "&busqueda=" + busqueda : "") +
                                                    (filtroTipo != null ? "&tipo=" + filtroTipo : "") +
                                                    (filtroEstado != null ? "&estado=" + filtroEstado : "") +
                                                    (filtroOperacion != null ? "&operacion=" + filtroOperacion : "") +
                                                    (filtroCiudad != null ? "&ciudad=" + filtroCiudad : "") +
                                                    (filtroOrden != null ? "&orden=" + filtroOrden : "")
                                                %>"><%= i %></a>
                                            </li>
                                        <% } %>
                                        
                                        <% if (finRango < totalPaginas) { 
                                            if (finRango < totalPaginas - 1) { %>
                                                <li class="page-item disabled">
                                                    <span class="page-link">...</span>
                                                </li>
                                            <% } %>
                                            <li class="page-item">
                                                <a class="page-link" href="?pagina=<%= totalPaginas %><%= 
                                                    (busqueda != null ? "&busqueda=" + busqueda : "") +
                                                    (filtroTipo != null ? "&tipo=" + filtroTipo : "") +
                                                    (filtroEstado != null ? "&estado=" + filtroEstado : "") +
                                                    (filtroOperacion != null ? "&operacion=" + filtroOperacion : "") +
                                                    (filtroCiudad != null ? "&ciudad=" + filtroCiudad : "") +
                                                    (filtroOrden != null ? "&orden=" + filtroOrden : "")
                                                %>"><%= totalPaginas %></a>
                                            </li>
                                        <% } %>
                                        
                                        <!-- Página siguiente -->
                                        <% if (paginaActual < totalPaginas) { %>
                                            <li class="page-item">
                                                <a class="page-link" href="?pagina=<%= paginaActual + 1 %><%= 
                                                    (busqueda != null ? "&busqueda=" + busqueda : "") +
                                                    (filtroTipo != null ? "&tipo=" + filtroTipo : "") +
                                                    (filtroEstado != null ? "&estado=" + filtroEstado : "") +
                                                    (filtroOperacion != null ? "&operacion=" + filtroOperacion : "") +
                                                    (filtroCiudad != null ? "&ciudad=" + filtroCiudad : "") +
                                                    (filtroOrden != null ? "&orden=" + filtroOrden : "")
                                                %>">
                                                    Siguiente <i class="fas fa-chevron-right"></i>
                                                </a>
                                            </li>
                                        <% } %>
                                    </ul>
                                </nav>
                                
                                <!-- Info de paginación -->
                                <div class="text-center mt-3">
                                    <small class="text-muted">
                                        Mostrando <%= Math.min(propiedadesPorPagina, propiedades.size()) %> de <%= totalPropiedades %> propiedades
                                        (Página <%= paginaActual %> de <%= totalPaginas %>)
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            <% } %>
            
            
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
    transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.15) !important;
}

.border-left-primary {
    border-left: 4px solid var(--vino) !important;
}

.badge-outline-primary {
    color: var(--vino);
    border: 1px solid var(--vino);
    background: transparent;
}

.btn-group-sm > .btn, .btn-sm {
    padding: .25rem .5rem;
    font-size: .875rem;
    border-radius: .2rem;
}

.position-absolute .badge {
    font-size: 0.7rem;
}

.card-img-top {
    border-top-left-radius: 10px;
    border-top-right-radius: 10px;
}

/* Efectos hover para botones */
.btn:hover {
    transform: translateY(-1px);
    transition: transform 0.2s;
}

/* Paginación personalizada */
.pagination .page-item.active .page-link {
    background-color: var(--vino);
    border-color: var(--vino);
}

.pagination .page-link {
    color: var(--vino);
}

.pagination .page-link:hover {
    color: white;
    background-color: var(--vino);
    border-color: var(--vino);
}

/* Mejorar los dropdowns para que aparezcan por encima */
.dropdown-menu {
    border-radius: 8px;
    border: none;
    box-shadow: 0 4px 20px rgba(0,0,0,0.15);
    z-index: 1050 !important;
    position: absolute !important;
}

.dropdown-item:hover {
    background-color: var(--vino);
    color: white;
}

.dropdown-item.text-danger:hover {
    background-color: #dc3545;
    color: white;
}

/* Asegurar que los dropdowns estén por encima */
.card .dropdown {
    position: relative;
    z-index: 10;
}

/* Responsividad */
@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .btn-group-sm .d-none {
        display: none !important;
    }
    
    .position-absolute .badge {
        font-size: 0.6rem;
    }
    
    .dropdown-menu {
        min-width: 150px;
    }
}

/* Animaciones */
@keyframes fadeInUp {
    from {
        opacity: 0;
        transform: translate3d(0, 30px, 0);
    }
    to {
        opacity: 1;
        transform: translate3d(0, 0, 0);
    }
}

.card {
    animation: fadeInUp 0.5s ease-out;
}

/* Estados de las propiedades */
.card.propiedad-inactiva {
    opacity: 0.7;
}

.card.propiedad-destacada {
    border: 2px solid var(--amarillo);
}

/* Mejorar estadísticas principales */
.bg-primary:hover,
.bg-success:hover,
.bg-warning:hover,
.bg-info:hover {
    opacity: 0.9;
    transform: translateY(-1px);
    transition: all 0.2s;
    cursor: pointer;
}

.text-xs {
    font-size: 0.75rem;
}
</style>

<!-- JavaScript adicional -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Auto-ocultar alertas después de 5 segundos
    const alerts = document.querySelectorAll('.alert-dismissible');
    alerts.forEach(alert => {
        setTimeout(() => {
            if (alert.parentNode) {
                alert.style.transition = 'opacity 0.5s';
                alert.style.opacity = '0';
                setTimeout(() => {
                    if (alert.parentNode) {
                        alert.remove();
                    }
                }, 500);
            }
        }, 5000);
    });
    
    // Aplicar clases especiales a las tarjetas
    const cards = document.querySelectorAll('.card');
    cards.forEach(card => {
        const isInactiva = card.querySelector('.badge-secondary');
        const isDestacada = card.querySelector('.badge-warning');
        
        if (isInactiva) {
            card.classList.add('propiedad-inactiva');
        }
        
        if (isDestacada) {
            card.classList.add('propiedad-destacada');
        }
    });
    
    // Mejorar los dropdowns para que funcionen correctamente
    $('.dropdown-toggle').dropdown();
    
    // Confirmación mejorada para eliminar
    const deleteButtons = document.querySelectorAll('button[onclick*="eliminar"]');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function(e) {
            e.preventDefault();
            const propiedadTitulo = this.closest('.card').querySelector('.card-title strong').textContent;
            
            if (confirm(`¿Estás seguro de eliminar "${propiedadTitulo}"?\n\nEsta acción eliminará también:\n- Todas las citas asociadas\n- Todas las imágenes\n- Los favoritos de usuarios\n\nEsta acción NO se puede deshacer.`)) {
                this.closest('form').submit();
            }
        });
    });
    
    // Mejorar la funcionalidad de los dropdowns
    document.addEventListener('click', function(event) {
        // Cerrar otros dropdowns al abrir uno nuevo
        const clickedDropdown = event.target.closest('.dropdown');
        const allDropdowns = document.querySelectorAll('.dropdown');
        
        allDropdowns.forEach(dropdown => {
            if (dropdown !== clickedDropdown) {
                const dropdownMenu = dropdown.querySelector('.dropdown-menu');
                if (dropdownMenu && dropdownMenu.classList.contains('show')) {
                    dropdown.querySelector('.dropdown-toggle').click();
                }
            }
        });
    });
    
    // Evitar que el dropdown se cierre al hacer clic en formularios dentro de él
    document.querySelectorAll('.dropdown-menu form').forEach(form => {
        form.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    });
    
    // Tooltip para botones
    if (typeof $ !== 'undefined' && $.fn.tooltip) {
        $('[data-toggle="tooltip"]').tooltip();
    }
});

// Función para filtrado rápido desde las tarjetas de estadísticas
function filtroRapido(tipo) {
    if (tipo === 'activas') {
        document.getElementById('estado').value = 'activa';
    } else if (tipo === 'destacadas') {
        document.getElementById('estado').value = 'destacada';
    }
    document.querySelector('form').submit();
}

// Agregar click a las tarjetas de estadísticas para filtrado rápido
document.addEventListener('DOMContentLoaded', function() {
    const statCards = document.querySelectorAll('.bg-success, .bg-warning');
    statCards.forEach((card, index) => {
        card.addEventListener('click', function() {
            if (index === 0) { // Tarjeta de activas (bg-success)
                filtroRapido('activas');
            } else if (index === 1) { // Tarjeta de destacadas (bg-warning)
                filtroRapido('destacadas');
            }
        });
        
        // Agregar cursor pointer
        card.style.cursor = 'pointer';
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />