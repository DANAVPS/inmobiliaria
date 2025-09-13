<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Verificar que el usuario esté logueado y sea administrador o inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || (!"ADMINISTRADOR".equals(usuarioRol) && !"INMOBILIARIA".equals(usuarioRol))) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID de la propiedad a editar
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("propiedades.jsp");
        return;
    }
    
    // Variables para almacenar datos
    Map<String, Object> propiedad = null;
    List<Map<String, Object>> tiposPropiedad = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar formulario si se envió
        if ("POST".equals(request.getMethod())) {
            String imagenPrincipalUrl = request.getParameter("imagen_principal_url");
            String titulo = request.getParameter("titulo");
            String descripcion = request.getParameter("descripcion");
            String precioStr = request.getParameter("precio");
            String areaConstrStr = request.getParameter("area_construida");
            String areaTotalStr = request.getParameter("area_total");
            String habitacionesStr = request.getParameter("habitaciones");
            String banosStr = request.getParameter("banos");
            String garajesStr = request.getParameter("garajes");
            String pisoStr = request.getParameter("piso");
            String direccion = request.getParameter("direccion");
            String ciudad = request.getParameter("ciudad");
            String departamento = request.getParameter("departamento");
            String codigoPostal = request.getParameter("codigo_postal");
            String latitudStr = request.getParameter("latitud");
            String longitudStr = request.getParameter("longitud");
            String tipoStr = request.getParameter("id_tipo");
            String disponibleStr = request.getParameter("disponible");
            String destacadaStr = request.getParameter("destacada");
            String tipoOperacion = request.getParameter("tipo_operacion");
            String videoUrl = request.getParameter("video_url");
            String tourVirtualUrl = request.getParameter("tour_virtual_url");
            
            // Validaciones básicas
            if (titulo == null || titulo.trim().isEmpty()) {
                mensaje = "El título es obligatorio.";
                tipoMensaje = "error";
            } else if (precioStr == null || precioStr.trim().isEmpty()) {
                mensaje = "El precio es obligatorio.";
                tipoMensaje = "error";
            } else if (direccion == null || direccion.trim().isEmpty()) {
                mensaje = "La dirección es obligatoria.";
                tipoMensaje = "error";
            } else if (ciudad == null || ciudad.trim().isEmpty()) {
                mensaje = "La ciudad es obligatoria.";
                tipoMensaje = "error";
            } else if (departamento == null || departamento.trim().isEmpty()) {
                mensaje = "El departamento es obligatorio.";
                tipoMensaje = "error";
            } else {
                try {
                    // Convertir valores numéricos
                    long precio = Long.parseLong(precioStr);
                    double areaConstr = areaConstrStr != null && !areaConstrStr.trim().isEmpty() ? Double.parseDouble(areaConstrStr) : 0;
                    double areaTotal = areaTotalStr != null && !areaTotalStr.trim().isEmpty() ? Double.parseDouble(areaTotalStr) : 0;
                    int habitaciones = habitacionesStr != null && !habitacionesStr.trim().isEmpty() ? Integer.parseInt(habitacionesStr) : 0;
                    int banos = banosStr != null && !banosStr.trim().isEmpty() ? Integer.parseInt(banosStr) : 0;
                    int garajes = garajesStr != null && !garajesStr.trim().isEmpty() ? Integer.parseInt(garajesStr) : 0;
                    int piso = pisoStr != null && !pisoStr.trim().isEmpty() ? Integer.parseInt(pisoStr) : 0;
                    double latitud = latitudStr != null && !latitudStr.trim().isEmpty() ? Double.parseDouble(latitudStr) : 0;
                    double longitud = longitudStr != null && !longitudStr.trim().isEmpty() ? Double.parseDouble(longitudStr) : 0;
                    int idTipo = Integer.parseInt(tipoStr);
                    boolean disponible = "1".equals(disponibleStr);
                    boolean destacada = "1".equals(destacadaStr);
                    
                    // Verificar que la propiedad pertenezca al usuario si es inmobiliaria
                    if ("INMOBILIARIA".equals(usuarioRol)) {
                        String sqlVerificar = "SELECT id_propietario FROM propiedades WHERE id_propiedad = ?";
                        stmt = conn.prepareStatement(sqlVerificar);
                        stmt.setInt(1, Integer.parseInt(idParam));
                        rs = stmt.executeQuery();
                        
                        if (rs.next()) {
                            int propietarioId = rs.getInt("id_propietario");
                            if (propietarioId != usuarioId) {
                                mensaje = "No tienes permisos para editar esta propiedad.";
                                tipoMensaje = "error";
                                rs.close();
                                stmt.close();
                                throw new Exception("Sin permisos");
                            }
                        } else {
                            mensaje = "Propiedad no encontrada.";
                            tipoMensaje = "error";
                            rs.close();
                            stmt.close();
                            throw new Exception("Propiedad no encontrada");
                        }
                        rs.close();
                        stmt.close();
                    }
                    
                    // Actualizar propiedad
                    String sqlUpdate = "UPDATE propiedades SET titulo=?, descripcion=?, precio=?, area_construida=?, " +
                                     "area_total=?, habitaciones=?, banos=?, garajes=?, piso=?, direccion=?, ciudad=?, " +
                                     "departamento=?, codigo_postal=?, latitud=?, longitud=?, id_tipo=?, disponible=?, " +
                                     "destacada=?, tipo_operacion=?, video_url=?, tour_virtual_url=?, imagen_principal=?, " +
                                     "fecha_actualizacion=CURRENT_TIMESTAMP WHERE id_propiedad=?";
                    
                    stmt = conn.prepareStatement(sqlUpdate);
                    stmt.setString(1, titulo.trim());
                    stmt.setString(2, descripcion != null ? descripcion.trim() : null);
                    stmt.setLong(3, precio);
                    stmt.setDouble(4, areaConstr);
                    stmt.setDouble(5, areaTotal);
                    stmt.setInt(6, habitaciones);
                    stmt.setInt(7, banos);
                    stmt.setInt(8, garajes);
                    stmt.setInt(9, piso);
                    stmt.setString(10, direccion.trim());
                    stmt.setString(11, ciudad.trim());
                    stmt.setString(12, departamento.trim());
                    stmt.setString(13, codigoPostal != null && !codigoPostal.trim().isEmpty() ? codigoPostal.trim() : null);
                    stmt.setDouble(14, latitud);
                    stmt.setDouble(15, longitud);
                    stmt.setInt(16, idTipo);
                    stmt.setBoolean(17, disponible);
                    stmt.setBoolean(18, destacada);
                    stmt.setString(19, tipoOperacion);
                    stmt.setString(20, videoUrl != null && !videoUrl.trim().isEmpty() ? videoUrl.trim() : null);
                    stmt.setString(21, tourVirtualUrl != null && !tourVirtualUrl.trim().isEmpty() ? tourVirtualUrl.trim() : null);
                    stmt.setString(22, imagenPrincipalUrl != null && !imagenPrincipalUrl.trim().isEmpty() ? imagenPrincipalUrl.trim() : null); // <- AGREGAR ESTA LÍNEA
                    stmt.setInt(23, Integer.parseInt(idParam));
                    
                    int rowsUpdated = stmt.executeUpdate();
                    
                    if (rowsUpdated > 0) {
                        mensaje = "Propiedad actualizada exitosamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "No se pudo actualizar la propiedad.";
                        tipoMensaje = "error";
                    }
                    
                    stmt.close();
                    
                } catch (NumberFormatException e) {
                    mensaje = "Error en los datos numéricos. Verifica que todos los campos numéricos sean válidos.";
                    tipoMensaje = "error";
                } catch (Exception e) {
                    if (!"Sin permisos".equals(e.getMessage()) && !"Propiedad no encontrada".equals(e.getMessage())) {
                        mensaje = "Error al actualizar la propiedad: " + e.getMessage();
                        tipoMensaje = "error";
                    }
                }
            }
        }
        
        // Cargar tipos de propiedad
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
        
        // Cargar datos de la propiedad
        String sqlPropiedad = "SELECT p.*, tp.nombre_tipo FROM propiedades p " +
                             "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                             "WHERE p.id_propiedad = ?";
        
        stmt = conn.prepareStatement(sqlPropiedad);
        stmt.setInt(1, Integer.parseInt(idParam));
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            // Verificar permisos para inmobiliaria
            if ("INMOBILIARIA".equals(usuarioRol) && rs.getInt("id_propietario") != usuarioId) {
                response.sendRedirect("misPropiedades.jsp");
                return;
            }
            
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
            propiedad.put("id_tipo", rs.getInt("id_tipo"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedad.put("disponible", rs.getBoolean("disponible"));
            propiedad.put("destacada", rs.getBoolean("destacada"));
            propiedad.put("tipo_operacion", rs.getString("tipo_operacion"));
            propiedad.put("video_url", rs.getString("video_url"));
            propiedad.put("tour_virtual_url", rs.getString("tour_virtual_url"));
        } else {
            mensaje = "Propiedad no encontrada.";
            tipoMensaje = "error";
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
    
    // Si no se encontró la propiedad, redirigir
    if (propiedad == null && mensaje.isEmpty()) {
        if ("ADMINISTRADOR".equals(usuarioRol)) {
            response.sendRedirect("propiedades.jsp");
        } else {
            response.sendRedirect("misPropiedades.jsp");
        }
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Editar Propiedad" />
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
                        <li class="breadcrumb-item"><a href="../admin/index.jsp">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="propiedades.jsp">Propiedades</a></li>
                    <% } else { %>
                        <li class="breadcrumb-item"><a href="../inmobiliaria/index.jsp">Dashboard</a></li>
                        <li class="breadcrumb-item"><a href="../inmobiliaria/misPropiedades.jsp">Mis Propiedades</a></li>
                    <% } %>
                    <li class="breadcrumb-item active">Editar Propiedad</li>
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
            
            <% if (propiedad != null) { %>
            
            <!-- Header -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-edit mr-2"></i>Editar Propiedad
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Modificar información de la propiedad: <strong><%= propiedad.get("titulo") %></strong>
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                        <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>" class="btn btn-info mr-2">
                                            <i class="fas fa-eye mr-1"></i>Ver Detalles
                                        </a>
                                        <a href="propiedades.jsp" class="btn btn-secondary">
                                            <i class="fas fa-arrow-left mr-1"></i>Volver
                                        </a>
                                    <% } else { %>
                                        <a href="../inmobiliaria/misPropiedades.jsp" class="btn btn-secondary">
                                            <i class="fas fa-arrow-left mr-1"></i>Volver
                                        </a>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Formulario de edición -->
            <form method="POST" action="">
                <div class="row">
                    
                    <!-- Información básica -->
                    <div class="col-lg-8 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--vino);">
                                <h6 class="mb-0">
                                    <i class="fas fa-info-circle mr-2"></i>Información Básica
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-8 mb-3">
                                        <label for="titulo" class="form-label font-weight-bold">Título de la Propiedad *</label>
                                        <input type="text" class="form-control" id="titulo" name="titulo" 
                                               value="<%= propiedad.get("titulo") != null ? propiedad.get("titulo") : "" %>" 
                                               required maxlength="200">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="id_tipo" class="form-label font-weight-bold">Tipo de Propiedad *</label>
                                        <select class="form-control" id="id_tipo" name="id_tipo" required>
                                            <option value="">Seleccionar tipo</option>
                                            <% for (Map<String, Object> tipo : tiposPropiedad) { %>
                                                <option value="<%= tipo.get("id") %>" 
                                                        <%= tipo.get("id").equals(propiedad.get("id_tipo")) ? "selected" : "" %>>
                                                    <%= tipo.get("nombre") %>
                                                </option>
                                            <% } %>
                                        </select>
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="descripcion" class="form-label font-weight-bold">Descripción</label>
                                    <textarea class="form-control" id="descripcion" name="descripcion" rows="4" 
                                              maxlength="1000"><%= propiedad.get("descripcion") != null ? propiedad.get("descripcion") : "" %></textarea>
                                    <small class="form-text text-muted">Máximo 1000 caracteres</small>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <label for="precio" class="form-label font-weight-bold">Precio *</label>
                                        <div class="input-group">
                                            <div class="input-group-prepend">
                                                <span class="input-group-text">$</span>
                                            </div>
                                            <input type="number" class="form-control" id="precio" name="precio" 
                                                   value="<%= propiedad.get("precio") %>" 
                                                   required min="1" max="999999999999">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="tipo_operacion" class="form-label font-weight-bold">Tipo de Operación *</label>
                                        <select class="form-control" id="tipo_operacion" name="tipo_operacion" required>
                                            <option value="VENTA" <%= "VENTA".equals(propiedad.get("tipo_operacion")) ? "selected" : "" %>>Venta</option>
                                            <option value="ARRIENDO" <%= "ARRIENDO".equals(propiedad.get("tipo_operacion")) ? "selected" : "" %>>Arriendo</option>
                                            <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(propiedad.get("tipo_operacion")) ? "selected" : "" %>>Venta/Arriendo</option>
                                        </select>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label class="form-label font-weight-bold">Estado</label>
                                        <div class="form-check">
                                            <input type="checkbox" class="form-check-input" id="disponible" name="disponible" value="1"
                                                   <%= (Boolean)propiedad.get("disponible") ? "checked" : "" %>>
                                            <label class="form-check-label" for="disponible">
                                                Disponible
                                            </label>
                                        </div>
                                        <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                        <div class="form-check">
                                            <input type="checkbox" class="form-check-input" id="destacada" name="destacada" value="1"
                                                   <%= (Boolean)propiedad.get("destacada") ? "checked" : "" %>>
                                            <label class="form-check-label" for="destacada">
                                                Destacada
                                            </label>
                                        </div>
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Características -->
                    <div class="col-lg-4 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--naranja);">
                                <h6 class="mb-0">
                                    <i class="fas fa-list-ul mr-2"></i>Características
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="area_construida" class="form-label font-weight-bold">Área Construida (m²)</label>
                                    <input type="number" class="form-control" id="area_construida" name="area_construida" 
                                           value="<%= (Double)propiedad.get("area_construida") > 0 ? propiedad.get("area_construida") : "" %>" 
                                           step="0.01" min="0" max="99999.99">
                                </div>
                                
                                <div class="mb-3">
                                    <label for="area_total" class="form-label font-weight-bold">Área Total (m²)</label>
                                    <input type="number" class="form-control" id="area_total" name="area_total" 
                                           value="<%= (Double)propiedad.get("area_total") > 0 ? propiedad.get("area_total") : "" %>" 
                                           step="0.01" min="0" max="99999.99">
                                </div>
                                
                                <div class="row">
                                    <div class="col-6 mb-3">
                                        <label for="habitaciones" class="form-label font-weight-bold">Habitaciones</label>
                                        <input type="number" class="form-control" id="habitaciones" name="habitaciones" 
                                               value="<%= (Integer)propiedad.get("habitaciones") > 0 ? propiedad.get("habitaciones") : "" %>" 
                                               min="0" max="50">
                                    </div>
                                    <div class="col-6 mb-3">
                                        <label for="banos" class="form-label font-weight-bold">Baños</label>
                                        <input type="number" class="form-control" id="banos" name="banos" 
                                               value="<%= (Integer)propiedad.get("banos") > 0 ? propiedad.get("banos") : "" %>" 
                                               min="0" max="50">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-6 mb-3">
                                        <label for="garajes" class="form-label font-weight-bold">Garajes</label>
                                        <input type="number" class="form-control" id="garajes" name="garajes" 
                                               value="<%= (Integer)propiedad.get("garajes") > 0 ? propiedad.get("garajes") : "" %>" 
                                               min="0" max="20">
                                    </div>
                                    <div class="col-6 mb-3">
                                        <label for="piso" class="form-label font-weight-bold">Piso</label>
                                        <input type="number" class="form-control" id="piso" name="piso" 
                                               value="<%= (Integer)propiedad.get("piso") > 0 ? propiedad.get("piso") : "" %>" 
                                               min="0" max="100">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <div class="row">
                    
                    <!-- Ubicación -->
                    <div class="col-lg-8 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--rojo);">
                                <h6 class="mb-0">
                                    <i class="fas fa-map-marker-alt mr-2"></i>Ubicación
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="direccion" class="form-label font-weight-bold">Dirección *</label>
                                    <input type="text" class="form-control" id="direccion" name="direccion" 
                                           value="<%= propiedad.get("direccion") != null ? propiedad.get("direccion") : "" %>" 
                                           required maxlength="300">
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="ciudad" class="form-label font-weight-bold">Ciudad *</label>
                                        <input type="text" class="form-control" id="ciudad" name="ciudad" 
                                               value="<%= propiedad.get("ciudad") != null ? propiedad.get("ciudad") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="departamento" class="form-label font-weight-bold">Departamento *</label>
                                        <input type="text" class="form-control" id="departamento" name="departamento" 
                                               value="<%= propiedad.get("departamento") != null ? propiedad.get("departamento") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <label for="codigo_postal" class="form-label font-weight-bold">Código Postal</label>
                                        <input type="text" class="form-control" id="codigo_postal" name="codigo_postal" 
                                               value="<%= propiedad.get("codigo_postal") != null ? propiedad.get("codigo_postal") : "" %>" 
                                               maxlength="20">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="latitud" class="form-label font-weight-bold">Latitud</label>
                                        <input type="number" class="form-control" id="latitud" name="latitud" 
                                               value="<%= (Double)propiedad.get("latitud") != 0 ? propiedad.get("latitud") : "" %>" 
                                               step="0.000001" min="-90" max="90">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="longitud" class="form-label font-weight-bold">Longitud</label>
                                        <input type="number" class="form-control" id="longitud" name="longitud" 
                                               value="<%= (Double)propiedad.get("longitud") != 0 ? propiedad.get("longitud") : "" %>" 
                                               step="0.000001" min="-180" max="180">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Multimedia -->
                    <div class="col-lg-4 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--amarillo); color: #000 !important;">
                                <h6 class="mb-0">
                                    <i class="fas fa-photo-video mr-2"></i>Multimedia
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="video_url" class="form-label font-weight-bold">URL del Video</label>
                                    <input type="url" class="form-control" id="video_url" name="video_url" 
                                           value="<%= propiedad.get("video_url") != null ? propiedad.get("video_url") : "" %>" 
                                           maxlength="255">
                                    <small class="form-text text-muted">YouTube, Vimeo, etc.</small>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="tour_virtual_url" class="form-label font-weight-bold">URL del Tour Virtual</label>
                                    <input type="url" class="form-control" id="tour_virtual_url" name="tour_virtual_url" 
                                        value="<%= propiedad.get("tour_virtual_url") != null ? propiedad.get("tour_virtual_url") : "" %>" 
                                        maxlength="255">
                                    <small class="form-text text-muted">Matterport, 360°, etc.</small>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="imagen_principal_url" class="form-label font-weight-bold">URL de Imagen Principal</label>
                                    <input type="url" class="form-control" id="imagen_principal_url" name="imagen_principal_url"
                                        value="<%= propiedad.get("imagen_principal") != null ? propiedad.get("imagen_principal") : "" %>"
                                        maxlength="500">
                                    <small class="form-text text-muted">URL directa a la imagen principal de la propiedad</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Botones de acción -->
                <div class="row">
                    <div class="col-12">
                        <div class="card shadow">
                            <div class="card-body text-center">
                                <button type="submit" class="btn btn-lg text-white mr-3" style="background-color: var(--vino);">
                                    <i class="fas fa-save mr-2"></i>Guardar Cambios
                                </button>
                                <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                    <a href="verPropiedad.jsp?id=<%= propiedad.get("id") %>" class="btn btn-lg btn-info mr-3">
                                        <i class="fas fa-eye mr-2"></i>Ver Propiedad
                                    </a>
                                    <a href="propiedades.jsp" class="btn btn-lg btn-secondary">
                                        <i class="fas fa-times mr-2"></i>Cancelar
                                    </a>
                                <% } else { %>
                                    <a href="../inmobiliaria/misPropiedades.jsp" class="btn btn-lg btn-secondary">
                                        <i class="fas fa-times mr-2"></i>Cancelar
                                    </a>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            
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
}

.form-control:focus {
    border-color: var(--vino);
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

.btn:focus, .btn.focus {
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

.form-check-input:checked {
    background-color: var(--vino);
    border-color: var(--vino);
}

.form-check-input:focus {
    border-color: var(--vino);
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .btn-lg {
        padding: 0.5rem 1rem;
        font-size: 1rem;
    }
}

/* Validación de formularios */
.was-validated .form-control:invalid {
    border-color: var(--rojo);
}

.was-validated .form-control:valid {
    border-color: #28a745;
}
</style>

<!-- JavaScript para validación y mejoras -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Validación del formulario
    const form = document.querySelector('form');
    const inputs = form.querySelectorAll('input[required], select[required]');
    
    form.addEventListener('submit', function(event) {
        let isValid = true;
        
        inputs.forEach(input => {
            if (!input.value.trim()) {
                input.classList.add('is-invalid');
                isValid = false;
            } else {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
            }
        });
        
        if (!isValid) {
            event.preventDefault();
            alert('Por favor completa todos los campos obligatorios.');
            return false;
        }
        
        // Confirmar antes de guardar
        if (!confirm('¿Estás seguro de que deseas guardar los cambios en esta propiedad?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Validación en tiempo real
    inputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (this.hasAttribute('required')) {
                if (!this.value.trim()) {
                    this.classList.add('is-invalid');
                    this.classList.remove('is-valid');
                } else {
                    this.classList.remove('is-invalid');
                    this.classList.add('is-valid');
                }
            }
        });
    });
    
    // Formatear precio mientras se escribe
    const precioInput = document.getElementById('precio');
    if (precioInput) {
        precioInput.addEventListener('input', function() {
            // Remover caracteres no numéricos excepto punto
            this.value = this.value.replace(/[^0-9]/g, '');
        });
    }
    
    // Validar URLs
    const urlInputs = document.querySelectorAll('input[type="url"]');
    urlInputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (this.value && !isValidUrl(this.value)) {
                this.setCustomValidity('Por favor ingresa una URL válida');
                this.classList.add('is-invalid');
            } else {
                this.setCustomValidity('');
                this.classList.remove('is-invalid');
            }
        });
    });
    
    function isValidUrl(string) {
        try {
            new URL(string);
            return true;
        } catch (_) {
            return false;
        }
    }
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />