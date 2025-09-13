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
    
    // Variables para almacenar datos
    List<Map<String, Object>> tiposPropiedad = new ArrayList<>();
    List<Map<String, Object>> usuarios = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar formulario si se envió
        if ("POST".equals(request.getMethod())) {
            String imagenPrincipalUrl = request.getParameter("imagen_principal");
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
            String propietarioStr = request.getParameter("id_propietario");
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
            } else if (tipoStr == null || tipoStr.trim().isEmpty()) {
                mensaje = "El tipo de propiedad es obligatorio.";
                tipoMensaje = "error";
            } else if (tipoOperacion == null || tipoOperacion.trim().isEmpty()) {
                mensaje = "El tipo de operación es obligatorio.";
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
                    
                    // Determinar propietario
                    int idPropietario;
                    if ("ADMINISTRADOR".equals(usuarioRol) && propietarioStr != null && !propietarioStr.trim().isEmpty()) {
                        idPropietario = Integer.parseInt(propietarioStr);
                    } else {
                        // Si es inmobiliaria o admin sin seleccionar, usar su propio ID
                        idPropietario = usuarioId;
                    }
                    
                    boolean disponible = "1".equals(disponibleStr);
                    boolean destacada = "1".equals(destacadaStr);
                    
                    // Solo admin puede marcar como destacada
                    if (!"ADMINISTRADOR".equals(usuarioRol)) {
                        destacada = false;
                    }
                    
                    // Insertar nueva propiedad
                    String sqlInsert = "INSERT INTO propiedades (titulo, descripcion, precio, area_construida, area_total, " +
                                    "habitaciones, banos, garajes, piso, direccion, ciudad, departamento, codigo_postal, " +
                                    "latitud, longitud, id_tipo, id_propietario, disponible, destacada, tipo_operacion, " +
                                    "video_url, tour_virtual_url, imagen_principal, fecha_publicacion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)";
                    
                    stmt = conn.prepareStatement(sqlInsert);
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
                    stmt.setInt(17, idPropietario);
                    stmt.setBoolean(18, disponible);
                    stmt.setBoolean(19, destacada);
                    stmt.setString(20, tipoOperacion);
                    stmt.setString(21, videoUrl != null && !videoUrl.trim().isEmpty() ? videoUrl.trim() : null);
                    stmt.setString(22, tourVirtualUrl != null && !tourVirtualUrl.trim().isEmpty() ? tourVirtualUrl.trim() : null);
                    stmt.setString(23, imagenPrincipalUrl != null && !imagenPrincipalUrl.trim().isEmpty() ? imagenPrincipalUrl.trim() : null);
                    System.out.println("=== DEBUG ===");
System.out.println("Título: " + titulo);
System.out.println("Imagen URL: " + imagenPrincipalUrl);
System.out.println("SQL: " + sqlInsert);
System.out.println("=============");
                    int rowsInserted = stmt.executeUpdate();
                    
                    if (rowsInserted > 0) {
                        mensaje = "Propiedad creada exitosamente.";
                        tipoMensaje = "success";
                        
                        // Limpiar formulario redirigiendo a la misma página
                        response.sendRedirect("nuevaPropiedad.jsp?success=1");
                        return;
                    } else {
                        mensaje = "Error al crear la propiedad.";
                        tipoMensaje = "error";
                    }
                    
                    stmt.close();
                    
                } catch (NumberFormatException e) {
                    mensaje = "Error en los datos numéricos. Verifica que todos los campos numéricos sean válidos.";
                    tipoMensaje = "error";
                } catch (Exception e) {
                    mensaje = "Error al crear la propiedad: " + e.getMessage();
tipoMensaje = "error";
e.printStackTrace(); // Agregar esta línea
System.out.println("ERROR COMPLETO: " + e.toString());
                }
            }
        }
        
        // Mostrar mensaje de éxito si viene de redirección
        if ("1".equals(request.getParameter("success"))) {
            mensaje = "Propiedad creada exitosamente.";
            tipoMensaje = "success";
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
        
        // Cargar usuarios inmobiliaria (solo si es admin)
        if ("ADMINISTRADOR".equals(usuarioRol)) {
            String sqlUsuarios = "SELECT u.id_usuario, u.nombre, u.apellido, u.email " +
                               "FROM usuarios u INNER JOIN roles r ON u.id_rol = r.id_rol " +
                               "WHERE r.nombre_rol = 'INMOBILIARIA' AND u.activo = 1 " +
                               "ORDER BY u.nombre, u.apellido";
            stmt = conn.prepareStatement(sqlUsuarios);
            rs = stmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> usuario = new HashMap<>();
                usuario.put("id", rs.getInt("id_usuario"));
                usuario.put("nombre", rs.getString("nombre"));
                usuario.put("apellido", rs.getString("apellido"));
                usuario.put("email", rs.getString("email"));
                usuarios.add(usuario);
            }
            rs.close();
            stmt.close();
        }
        
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
    <jsp:param name="title" value="Crear Propiedad" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value='<%= "ADMINISTRADOR".equals(usuarioRol) ? "propiedades" : "nueva-propiedad" %>' />
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
                    <li class="breadcrumb-item active">Crear Propiedad</li>
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
            
            <!-- Header -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-plus-circle mr-2"></i>Crear Nueva Propiedad
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Registra una nueva propiedad en el sistema
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                        <a href="propiedades.jsp" class="btn btn-secondary">
                                            <i class="fas fa-arrow-left mr-1"></i>Volver a Lista
                                        </a>
                                    <% } else { %>
                                        <a href="../inmobiliaria/misPropiedades.jsp" class="btn btn-secondary">
                                            <i class="fas fa-arrow-left mr-1"></i>Mis Propiedades
                                        </a>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Formulario de creación -->
            <form method="POST" action="" id="formCrearPropiedad">
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
                                               required maxlength="200" placeholder="Ej: Casa Moderna en El Poblado">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="id_tipo" class="form-label font-weight-bold">Tipo de Propiedad *</label>
                                        <select class="form-control" id="id_tipo" name="id_tipo" required>
                                            <option value="">Seleccionar tipo</option>
                                            <% for (Map<String, Object> tipo : tiposPropiedad) { %>
                                                <option value="<%= tipo.get("id") %>">
                                                    <%= tipo.get("nombre") %>
                                                </option>
                                            <% } %>
                                        </select>
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="descripcion" class="form-label font-weight-bold">Descripción</label>
                                    <textarea class="form-control" id="descripcion" name="descripcion" rows="4" 
                                              maxlength="1000" placeholder="Describe las características principales de la propiedad..."></textarea>
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
                                                   required min="1" max="999999999999" placeholder="Ej: 850000000">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="tipo_operacion" class="form-label font-weight-bold">Tipo de Operación *</label>
                                        <select class="form-control" id="tipo_operacion" name="tipo_operacion" required>
                                            <option value="">Seleccionar operación</option>
                                            <option value="VENTA">Venta</option>
                                            <option value="ARRIENDO">Arriendo</option>
                                            <option value="VENTA_ARRIENDO">Venta/Arriendo</option>
                                        </select>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label class="form-label font-weight-bold">Estado</label>
                                        <div class="form-check">
                                            <input type="checkbox" class="form-check-input" id="disponible" name="disponible" value="1" checked>
                                            <label class="form-check-label" for="disponible">
                                                Disponible
                                            </label>
                                        </div>
                                        <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
                                        <div class="form-check">
                                            <input type="checkbox" class="form-check-input" id="destacada" name="destacada" value="1">
                                            <label class="form-check-label" for="destacada">
                                                Destacada
                                            </label>
                                        </div>
                                        <% } %>
                                    </div>
                                </div>
                                
                                <!-- Propietario (solo para admin) -->
                                <% if ("ADMINISTRADOR".equals(usuarioRol) && !usuarios.isEmpty()) { %>
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="id_propietario" class="form-label font-weight-bold">Asignar a Inmobiliaria</label>
                                        <select class="form-control" id="id_propietario" name="id_propietario">
                                            <option value="">Usar mi cuenta como propietario</option>
                                            <% for (Map<String, Object> usuario : usuarios) { %>
                                                <option value="<%= usuario.get("id") %>">
                                                    <%= usuario.get("nombre") %> <%= usuario.get("apellido") %> - <%= usuario.get("email") %>
                                                </option>
                                            <% } %>
                                        </select>
                                        <small class="form-text text-muted">Opcional: Asignar la propiedad a una inmobiliaria específica</small>
                                    </div>
                                </div>
                                <% } %>
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
                                           step="0.01" min="0" max="99999.99" placeholder="Ej: 250.50">
                                </div>
                                
                                <div class="mb-3">
                                    <label for="area_total" class="form-label font-weight-bold">Área Total (m²)</label>
                                    <input type="number" class="form-control" id="area_total" name="area_total" 
                                           step="0.01" min="0" max="99999.99" placeholder="Ej: 300.00">
                                </div>
                                
                                <div class="row">
                                    <div class="col-6 mb-3">
                                        <label for="habitaciones" class="form-label font-weight-bold">Habitaciones</label>
                                        <input type="number" class="form-control" id="habitaciones" name="habitaciones" 
                                               min="0" max="50" placeholder="Ej: 4">
                                    </div>
                                    <div class="col-6 mb-3">
                                        <label for="banos" class="form-label font-weight-bold">Baños</label>
                                        <input type="number" class="form-control" id="banos" name="banos" 
                                               min="0" max="50" placeholder="Ej: 3">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-6 mb-3">
                                        <label for="garajes" class="form-label font-weight-bold">Garajes</label>
                                        <input type="number" class="form-control" id="garajes" name="garajes" 
                                               min="0" max="20" placeholder="Ej: 2">
                                    </div>
                                    <div class="col-6 mb-3">
                                        <label for="piso" class="form-label font-weight-bold">Piso</label>
                                        <input type="number" class="form-control" id="piso" name="piso" 
                                               min="0" max="100" placeholder="Ej: 3">
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
                                           required maxlength="300" placeholder="Ej: Carrera 43A #12-45">
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="ciudad" class="form-label font-weight-bold">Ciudad *</label>
                                        <input type="text" class="form-control" id="ciudad" name="ciudad" 
                                               required maxlength="100" placeholder="Ej: Medellín">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="departamento" class="form-label font-weight-bold">Departamento *</label>
                                        <input type="text" class="form-control" id="departamento" name="departamento" 
                                               required maxlength="100" placeholder="Ej: Antioquia">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <label for="codigo_postal" class="form-label font-weight-bold">Código Postal</label>
                                        <input type="text" class="form-control" id="codigo_postal" name="codigo_postal" 
                                               maxlength="20" placeholder="Ej: 050021">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="latitud" class="form-label font-weight-bold">Latitud</label>
                                        <input type="number" class="form-control" id="latitud" name="latitud" 
                                               step="0.000001" min="-90" max="90" placeholder="Ej: 6.244203">
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="longitud" class="form-label font-weight-bold">Longitud</label>
                                        <input type="number" class="form-control" id="longitud" name="longitud" 
                                               step="0.000001" min="-180" max="180" placeholder="Ej: -75.581212">
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
                                        <label for="imagen_principal_url" class="form-label font-weight-bold">URL de Imagen Principal</label>
                                        <input type="url" class="form-control" id="imagen_principal_url" name="imagen_principal_url"
                                            maxlength="500" placeholder="https://ejemplo.com/imagen.jpg">
                                        <small class="form-text text-muted">URL directa a la imagen principal de la propiedad</small>
                                    </div>
                        
                                    <div class="mb-3">
                                        <label for="video_url" class="form-label font-weight-bold">URL del Video</label>
                                        <input type="url" class="form-control" id="video_url" name="video_url" maxlength="255"
                                            placeholder="https://youtube.com/watch?v=...">
                                        <small class="form-text text-muted">YouTube, Vimeo, etc.</small>
                                    </div>
                        
                                    <div class="mb-3">
                                        <label for="tour_virtual_url" class="form-label font-weight-bold">URL del Tour Virtual</label>
                                        <input type="url" class="form-control" id="tour_virtual_url" name="tour_virtual_url" maxlength="255"
                                            placeholder="https://matterport.com/...">
                                        <small class="form-text text-muted">Matterport, 360°, etc.</small>
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
                                    <i class="fas fa-save mr-2"></i>Crear Propiedad
                                </button>
                                <button type="reset" class="btn btn-lg btn-warning mr-3" onclick="limpiarFormulario()">
                                    <i class="fas fa-eraser mr-2"></i>Limpiar Formulario
                                </button>
                                <% if ("ADMINISTRADOR".equals(usuarioRol)) { %>
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

.input-group-text {
    background-color: var(--vino);
    color: white;
    border-color: var(--vino);
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

/* Animaciones para el formulario */
.form-control:valid {
    border-color: #28a745;
}

.form-control:invalid {
    border-color: #dc3545;
}
</style>

<!-- JavaScript para validación y mejoras -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formCrearPropiedad');
    
    // Validación del formulario
    form.addEventListener('submit', function(event) {
        let isValid = true;
        
        // Validar campos requeridos
        const requiredInputs = form.querySelectorAll('input[required], select[required]');
        requiredInputs.forEach(input => {
            if (!input.value.trim()) {
                input.classList.add('is-invalid');
                isValid = false;
            } else {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
            }
        });
        
        // Validar precio
        const precio = document.getElementById('precio');
        if (precio.value && parseInt(precio.value) < 1) {
            precio.classList.add('is-invalid');
            isValid = false;
            alert('El precio debe ser mayor a 0');
        }
        
        // Validar URLs si están presentes
        const videoUrl = document.getElementById('video_url');
        const tourUrl = document.getElementById('tour_virtual_url');
        const imagenUrl = document.getElementById('imagen_principal_url');
        
        if (videoUrl.value && !isValidUrl(videoUrl.value)) {
            videoUrl.classList.add('is-invalid');
            isValid = false;
            alert('La URL del video no es válida');
        }
        
        if (tourUrl.value && !isValidUrl(tourUrl.value)) {
            tourUrl.classList.add('is-invalid');
            isValid = false;
            alert('La URL del tour virtual no es válida');
        }
        
        if (imagenUrl.value && !isValidUrl(imagenUrl.value)) {
            imagenUrl.classList.add('is-invalid');
            isValid = false;
            alert('La URL de la imagen no es válida');
        }
        
        if (!isValid) {
            event.preventDefault();
            alert('Por favor corrige los errores en el formulario.');
            return false;
        }
        
        // Confirmar antes de guardar
        if (!confirm('¿Estás seguro de que deseas crear esta propiedad con la información proporcionada?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Validación en tiempo real
    const inputs = form.querySelectorAll('input[required], select[required]');
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
            this.value = this.value.replace(/[^0-9]/g, '');
        });
    }
    
    // Validar coordenadas geográficas
    const latitudInput = document.getElementById('latitud');
    const longitudInput = document.getElementById('longitud');
    
    latitudInput.addEventListener('blur', function() {
        const lat = parseFloat(this.value);
        if (this.value && (lat < -90 || lat > 90)) {
            this.setCustomValidity('La latitud debe estar entre -90 y 90');
            this.classList.add('is-invalid');
        } else {
            this.setCustomValidity('');
            this.classList.remove('is-invalid');
        }
    });
    
    longitudInput.addEventListener('blur', function() {
        const lng = parseFloat(this.value);
        if (this.value && (lng < -180 || lng > 180)) {
            this.setCustomValidity('La longitud debe estar entre -180 y 180');
            this.classList.add('is-invalid');
        } else {
            this.setCustomValidity('');
            this.classList.remove('is-invalid');
        }
    });
    
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
    
    // Contador de caracteres para descripción
    const descripcion = document.getElementById('descripcion');
    if (descripcion) {
        const contador = document.createElement('small');
        contador.className = 'form-text text-muted';
        contador.id = 'contadorDescripcion';
        descripcion.parentElement.appendChild(contador);
        
        function actualizarContador() {
            const caracteres = descripcion.value.length;
            const restantes = 1000 - caracteres;
            contador.textContent = `${caracteres}/1000 caracteres (${restantes} restantes)`;
            
            if (restantes < 100) {
                contador.className = 'form-text text-warning';
            } else if (restantes < 0) {
                contador.className = 'form-text text-danger';
            } else {
                contador.className = 'form-text text-muted';
            }
        }
        
        descripcion.addEventListener('input', actualizarContador);
        actualizarContador();
    }
    
    // Autocompletar ubicación
    const ciudades = {
        'Medellín': 'Antioquia',
        'Bogotá': 'Cundinamarca',
        'Cali': 'Valle del Cauca',
        'Barranquilla': 'Atlántico',
        'Cartagena': 'Bolívar',
        'Bucaramanga': 'Santander',
        'Pereira': 'Risaralda',
        'Manizales': 'Caldas'
    };
    
    const ciudadInput = document.getElementById('ciudad');
    const departamentoInput = document.getElementById('departamento');
    
    ciudadInput.addEventListener('blur', function() {
        const ciudad = this.value.trim();
        if (ciudades[ciudad] && !departamentoInput.value) {
            departamentoInput.value = ciudades[ciudad];
        }
    });
});

// Función para limpiar formulario
function limpiarFormulario() {
    if (confirm('¿Estás seguro de que deseas limpiar todo el formulario?')) {
        document.getElementById('formCrearPropiedad').reset();
        
        // Remover clases de validación
        const inputs = document.querySelectorAll('.form-control');
        inputs.forEach(input => {
            input.classList.remove('is-valid', 'is-invalid');
        });
        
        // Enfocar el primer campo
        document.getElementById('titulo').focus();
    }
}
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />