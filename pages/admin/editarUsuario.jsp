<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>

<%!
    // Función para encriptar contraseña
    private String encriptarPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] bytes = md.digest(password.getBytes());
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception e) {
            return password;
        }
    }
%>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID del usuario a editar
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.isEmpty()) {
        response.sendRedirect("usuarios.jsp");
        return;
    }
    
    // Variables para almacenar datos
    Map<String, Object> usuario = null;
    List<Map<String, Object>> roles = new ArrayList<>();
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
            String nombre = request.getParameter("nombre");
            String apellido = request.getParameter("apellido");
            String email = request.getParameter("email");
            String telefono = request.getParameter("telefono");
            String direccion = request.getParameter("direccion");
            String fechaNacimientoStr = request.getParameter("fecha_nacimiento");
            String passwordNuevo = request.getParameter("password");
            String confirmarPassword = request.getParameter("confirmar_password");
            String rolStr = request.getParameter("id_rol");
            String activoStr = request.getParameter("activo");
            
            // Validaciones básicas
            if (nombre == null || nombre.trim().isEmpty()) {
                mensaje = "El nombre es obligatorio.";
                tipoMensaje = "error";
            } else if (apellido == null || apellido.trim().isEmpty()) {
                mensaje = "El apellido es obligatorio.";
                tipoMensaje = "error";
            } else if (email == null || email.trim().isEmpty()) {
                mensaje = "El email es obligatorio.";
                tipoMensaje = "error";
            } else if (rolStr == null || rolStr.trim().isEmpty()) {
                mensaje = "El rol es obligatorio.";
                tipoMensaje = "error";
            } else {
                // Validar contraseña si se proporcionó
                if (passwordNuevo != null && !passwordNuevo.trim().isEmpty()) {
                    if (passwordNuevo.length() < 6) {
                        mensaje = "La contraseña debe tener al menos 6 caracteres.";
                        tipoMensaje = "error";
                    } else if (!passwordNuevo.equals(confirmarPassword)) {
                        mensaje = "Las contraseñas no coinciden.";
                        tipoMensaje = "error";
                    }
                }
                
                if (mensaje.isEmpty()) {
                    try {
                        // Verificar que el email no esté en uso por otro usuario
                        String sqlVerificar = "SELECT id_usuario FROM usuarios WHERE email = ? AND id_usuario != ?";
                        stmt = conn.prepareStatement(sqlVerificar);
                        stmt.setString(1, email.trim());
                        stmt.setInt(2, Integer.parseInt(idParam));
                        rs = stmt.executeQuery();
                        
                        if (rs.next()) {
                            mensaje = "El email ya está en uso por otro usuario.";
                            tipoMensaje = "error";
                        } else {
                            rs.close();
                            stmt.close();
                            
                            // Construir SQL de actualización
                            String sqlUpdate;
                            if (passwordNuevo != null && !passwordNuevo.trim().isEmpty()) {
                                sqlUpdate = "UPDATE usuarios SET nombre=?, apellido=?, email=?, telefono=?, direccion=?, " +
                                          "fecha_nacimiento=?, password=?, id_rol=?, activo=?, fecha_actualizacion=CURRENT_TIMESTAMP " +
                                          "WHERE id_usuario=?";
                            } else {
                                sqlUpdate = "UPDATE usuarios SET nombre=?, apellido=?, email=?, telefono=?, direccion=?, " +
                                          "fecha_nacimiento=?, id_rol=?, activo=?, fecha_actualizacion=CURRENT_TIMESTAMP " +
                                          "WHERE id_usuario=?";
                            }
                            
                            stmt = conn.prepareStatement(sqlUpdate);
                            int paramIndex = 1;
                            
                            stmt.setString(paramIndex++, nombre.trim());
                            stmt.setString(paramIndex++, apellido.trim());
                            stmt.setString(paramIndex++, email.trim());
                            stmt.setString(paramIndex++, telefono != null && !telefono.trim().isEmpty() ? telefono.trim() : null);
                            stmt.setString(paramIndex++, direccion != null && !direccion.trim().isEmpty() ? direccion.trim() : null);
                            
                            // Fecha de nacimiento
                            if (fechaNacimientoStr != null && !fechaNacimientoStr.trim().isEmpty()) {
                                stmt.setDate(paramIndex++, java.sql.Date.valueOf(fechaNacimientoStr));
                            } else {
                                stmt.setDate(paramIndex++, null);
                            }
                            
                            // Contraseña si se proporcionó
                            if (passwordNuevo != null && !passwordNuevo.trim().isEmpty()) {
                                stmt.setString(paramIndex++, encriptarPassword(passwordNuevo));
                            }
                            
                            stmt.setInt(paramIndex++, Integer.parseInt(rolStr));
                            stmt.setBoolean(paramIndex++, "1".equals(activoStr));
                            stmt.setInt(paramIndex++, Integer.parseInt(idParam));
                            
                            int rowsUpdated = stmt.executeUpdate();
                            
                            if (rowsUpdated > 0) {
                                mensaje = "Usuario actualizado exitosamente.";
                                tipoMensaje = "success";
                            } else {
                                mensaje = "No se pudo actualizar el usuario.";
                                tipoMensaje = "error";
                            }
                            
                            stmt.close();
                        }
                        
                    } catch (SQLException e) {
                        if (e.getMessage().contains("Duplicate entry")) {
                            mensaje = "El email ya está registrado.";
                        } else {
                            mensaje = "Error de base de datos: " + e.getMessage();
                        }
                        tipoMensaje = "error";
                    } catch (Exception e) {
                        mensaje = "Error al actualizar usuario: " + e.getMessage();
                        tipoMensaje = "error";
                    }
                }
            }
        }
        
        // Cargar roles disponibles
        String sqlRoles = "SELECT id_rol, nombre_rol, descripcion FROM roles ORDER BY nombre_rol";
        stmt = conn.prepareStatement(sqlRoles);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> rol = new HashMap<>();
            rol.put("id", rs.getInt("id_rol"));
            rol.put("nombre", rs.getString("nombre_rol"));
            rol.put("descripcion", rs.getString("descripcion"));
            roles.add(rol);
        }
        rs.close();
        stmt.close();
        
        // Cargar datos del usuario
        String sqlUsuario = "SELECT u.*, r.nombre_rol FROM usuarios u " +
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
            usuario.put("activo", rs.getBoolean("activo"));
            usuario.put("fecha_registro", rs.getTimestamp("fecha_registro"));
            usuario.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
        } else {
            mensaje = "Usuario no encontrado.";
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
    
    // Si no se encontró el usuario, redirigir
    if (usuario == null && mensaje.isEmpty()) {
        response.sendRedirect("usuarios.jsp");
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Editar Usuario - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <div class="card shadow-sm">
                <div class="card-header text-white" style="background-color: var(--vino);">
                    <h6 class="mb-0">
                        <i class="fas fa-user-shield mr-2"></i>Panel Admin
                    </h6>
                </div>
                <div class="list-group list-group-flush">
                    <a href="index.jsp" class="list-group-item list-group-item-action">
                        <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
                    </a>
                    <a href="usuarios.jsp" class="list-group-item list-group-item-action active">
                        <i class="fas fa-users mr-2"></i>Usuarios
                    </a>
                    <a href="../properties/propiedades.jsp" class="list-group-item list-group-item-action">
                        <i class="fas fa-building mr-2"></i>Propiedades
                    </a>
                    <a href="reportes.jsp" class="list-group-item list-group-item-action">
                        <i class="fas fa-chart-bar mr-2"></i>Reportes
                    </a>
                    <a href="configuracion.jsp" class="list-group-item list-group-item-action">
                        <i class="fas fa-cog mr-2"></i>Configuración
                    </a>
                    <a href="../auth/logout.jsp" class="list-group-item list-group-item-action text-danger">
                        <i class="fas fa-sign-out-alt mr-2"></i>Cerrar Sesión
                    </a>
                </div>
            </div>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="index.jsp">Dashboard</a></li>
                    <li class="breadcrumb-item"><a href="usuarios.jsp">Usuarios</a></li>
                    <li class="breadcrumb-item active">Editar Usuario</li>
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
            
            <!-- Header -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-user-edit mr-2"></i>Editar Usuario
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Modificar información del usuario: <strong><%= usuario.get("nombre") %> <%= usuario.get("apellido") %></strong>
                                        <span class="badge badge-<%= (Boolean)usuario.get("activo") ? "success" : "danger" %> ml-2">
                                            <%= (Boolean)usuario.get("activo") ? "Activo" : "Inactivo" %>
                                        </span>
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="ver-usuario.jsp?id=<%= usuario.get("id") %>" class="btn btn-info mr-2">
                                        <i class="fas fa-eye mr-1"></i>Ver Detalles
                                    </a>
                                    <a href="usuarios.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-1"></i>Volver
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Formulario de edición -->
            <form method="POST" action="" id="formEditarUsuario">
                <div class="row">
                    
                    <!-- Información personal -->
                    <div class="col-lg-8 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--vino);">
                                <h6 class="mb-0">
                                    <i class="fas fa-user mr-2"></i>Información Personal
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="nombre" class="form-label font-weight-bold">Nombre *</label>
                                        <input type="text" class="form-control" id="nombre" name="nombre" 
                                               value="<%= usuario.get("nombre") != null ? usuario.get("nombre") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="apellido" class="form-label font-weight-bold">Apellido *</label>
                                        <input type="text" class="form-control" id="apellido" name="apellido" 
                                               value="<%= usuario.get("apellido") != null ? usuario.get("apellido") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="email" class="form-label font-weight-bold">Email *</label>
                                        <input type="email" class="form-control" id="email" name="email" 
                                               value="<%= usuario.get("email") != null ? usuario.get("email") : "" %>" 
                                               required maxlength="150">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="telefono" class="form-label font-weight-bold">Teléfono</label>
                                        <input type="tel" class="form-control" id="telefono" name="telefono" 
                                               value="<%= usuario.get("telefono") != null ? usuario.get("telefono") : "" %>" 
                                               maxlength="20">
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="direccion" class="form-label font-weight-bold">Dirección</label>
                                    <textarea class="form-control" id="direccion" name="direccion" rows="3" 
                                              maxlength="500"><%= usuario.get("direccion") != null ? usuario.get("direccion") : "" %></textarea>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="fecha_nacimiento" class="form-label font-weight-bold">Fecha de Nacimiento</label>
                                        <input type="date" class="form-control" id="fecha_nacimiento" name="fecha_nacimiento" 
                                               value="<%= usuario.get("fecha_nacimiento") != null ? usuario.get("fecha_nacimiento") : "" %>">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Configuración de cuenta -->
                    <div class="col-lg-4 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--naranja);">
                                <h6 class="mb-0">
                                    <i class="fas fa-cog mr-2"></i>Configuración de Cuenta
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="id_rol" class="form-label font-weight-bold">Rol del Usuario *</label>
                                    <select class="form-control" id="id_rol" name="id_rol" required>
                                        <option value="">Seleccionar rol</option>
                                        <% for (Map<String, Object> rol : roles) { %>
                                            <option value="<%= rol.get("id") %>" 
                                                    <%= rol.get("id").equals(usuario.get("id_rol")) ? "selected" : "" %>>
                                                <%= rol.get("nombre") %>
                                            </option>
                                        <% } %>
                                    </select>
                                    <small class="form-text text-muted">Define los permisos del usuario</small>
                                </div>
                                
                                <div class="mb-3">
                                    <label class="form-label font-weight-bold">Estado de la Cuenta</label>
                                    <div class="form-check">
                                        <input type="checkbox" class="form-check-input" id="activo" name="activo" value="1"
                                               <%= (Boolean)usuario.get("activo") ? "checked" : "" %>>
                                        <label class="form-check-label" for="activo">
                                            <strong>Cuenta Activa</strong>
                                        </label>
                                    </div>
                                    <small class="form-text text-muted">
                                        Usuarios inactivos no pueden iniciar sesión
                                    </small>
                                </div>
                                
                                <hr>
                                
                                <div class="alert alert-info">
                                    <i class="fas fa-info-circle mr-2"></i>
                                    <strong>Información:</strong><br>
                                    <small>
                                        Registrado: <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_registro")) %><br>
                                        <% if (usuario.get("fecha_actualizacion") != null) { %>
                                            Actualizado: <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_actualizacion")) %>
                                        <% } %>
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Cambio de contraseña -->
                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--rojo);">
                                <h6 class="mb-0">
                                    <i class="fas fa-key mr-2"></i>Cambio de Contraseña (Opcional)
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-warning">
                                    <i class="fas fa-exclamation-triangle mr-2"></i>
                                    <strong>Atención:</strong> Solo completa estos campos si deseas cambiar la contraseña del usuario.
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="password" class="form-label font-weight-bold">Nueva Contraseña</label>
                                        <input type="password" class="form-control" id="password" name="password" 
                                               minlength="6" maxlength="255">
                                        <small class="form-text text-muted">Mínimo 6 caracteres</small>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="confirmar_password" class="form-label font-weight-bold">Confirmar Contraseña</label>
                                        <input type="password" class="form-control" id="confirmar_password" name="confirmar_password" 
                                               minlength="6" maxlength="255">
                                    </div>
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
                                <a href="ver-usuario.jsp?id=<%= usuario.get("id") %>" class="btn btn-lg btn-info mr-3">
                                    <i class="fas fa-eye mr-2"></i>Ver Usuario
                                </a>
                                <a href="usuarios.jsp" class="btn btn-lg btn-secondary">
                                    <i class="fas fa-times mr-2"></i>Cancelar
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            
            <% } %>
            
        </div>
    </div>
</div>

<!-- Descripción de roles (Modal) -->
<div class="modal fade" id="modalRoles" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--vino); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-users-cog mr-2"></i>Descripción de Roles
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <% for (Map<String, Object> rol : roles) { %>
                    <div class="mb-3">
                        <h6 class="text-primary font-weight-bold">
                            <i class="fas fa-user-tag mr-2"></i><%= rol.get("nombre") %>
                        </h6>
                        <p class="text-muted mb-0"><%= rol.get("descripcion") %></p>
                    </div>
                    <% if (!rol.equals(roles.get(roles.size() - 1))) { %>
                        <hr>
                    <% } %>
                <% } %>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
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
</style>

<!-- JavaScript para validación -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formEditarUsuario');
    const password = document.getElementById('password');
    const confirmarPassword = document.getElementById('confirmar_password');
    
    // Validar coincidencia de contraseñas
    function validarPasswords() {
        if (password.value && confirmarPassword.value) {
            if (password.value !== confirmarPassword.value) {
                confirmarPassword.setCustomValidity('Las contraseñas no coinciden');
                confirmarPassword.classList.add('is-invalid');
                password.classList.add('is-invalid');
            } else {
                confirmarPassword.setCustomValidity('');
                confirmarPassword.classList.remove('is-invalid');
                password.classList.remove('is-invalid');
                confirmarPassword.classList.add('is-valid');
                password.classList.add('is-valid');
            }
        }
    }
    
    password.addEventListener('input', validarPasswords);
    confirmarPassword.addEventListener('input', validarPasswords);
    
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
            }
        });
        
        // Validar contraseñas si se proporcionaron
        if (password.value || confirmarPassword.value) {
            if (password.value.length < 6) {
                password.classList.add('is-invalid');
                isValid = false;
            }
            if (password.value !== confirmarPassword.value) {
                password.classList.add('is-invalid');
                confirmarPassword.classList.add('is-invalid');
                isValid = false;
            }
        }
        
        if (!isValid) {
            event.preventDefault();
            alert('Por favor corrige los errores en el formulario.');
            return false;
        }
        
        // Confirmar antes de guardar
        if (!confirm('¿Estás seguro de que deseas guardar los cambios en este usuario?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Agregar botón para mostrar descripción de roles
    const rolSelect = document.getElementById('id_rol');
    const rolContainer = rolSelect.parentElement;
    const infoButton = document.createElement('button');
    infoButton.type = 'button';
    infoButton.className = 'btn btn-sm btn-outline-info mt-2';
    infoButton.innerHTML = '<i class="fas fa-info-circle mr-1"></i>Ver descripción de roles';
    infoButton.onclick = function() {
        $('#modalRoles').modal('show');
    };
    rolContainer.appendChild(infoButton);
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Editar Usuario - Admin" />
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
                    <li class="breadcrumb-item active">Editar Usuario</li>
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
            
            <!-- Header -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-user-edit mr-2"></i>Editar Usuario
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Modificar información del usuario: <strong><%= usuario.get("nombre") %> <%= usuario.get("apellido") %></strong>
                                        <span class="badge badge-<%= (Boolean)usuario.get("activo") ? "success" : "danger" %> ml-2">
                                            <%= (Boolean)usuario.get("activo") ? "Activo" : "Inactivo" %>
                                        </span>
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="ver-usuario.jsp?id=<%= usuario.get("id") %>" class="btn btn-info mr-2">
                                        <i class="fas fa-eye mr-1"></i>Ver Detalles
                                    </a>
                                    <a href="usuarios.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-1"></i>Volver
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Formulario de edición -->
            <form method="POST" action="" id="formEditarUsuario">
                <div class="row">
                    
                    <!-- Información personal -->
                    <div class="col-lg-8 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--vino);">
                                <h6 class="mb-0">
                                    <i class="fas fa-user mr-2"></i>Información Personal
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="nombre" class="form-label font-weight-bold">Nombre *</label>
                                        <input type="text" class="form-control" id="nombre" name="nombre" 
                                               value="<%= usuario.get("nombre") != null ? usuario.get("nombre") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="apellido" class="form-label font-weight-bold">Apellido *</label>
                                        <input type="text" class="form-control" id="apellido" name="apellido" 
                                               value="<%= usuario.get("apellido") != null ? usuario.get("apellido") : "" %>" 
                                               required maxlength="100">
                                    </div>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="email" class="form-label font-weight-bold">Email *</label>
                                        <input type="email" class="form-control" id="email" name="email" 
                                               value="<%= usuario.get("email") != null ? usuario.get("email") : "" %>" 
                                               required maxlength="150">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="telefono" class="form-label font-weight-bold">Teléfono</label>
                                        <input type="tel" class="form-control" id="telefono" name="telefono" 
                                               value="<%= usuario.get("telefono") != null ? usuario.get("telefono") : "" %>" 
                                               maxlength="20">
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="direccion" class="form-label font-weight-bold">Dirección</label>
                                    <textarea class="form-control" id="direccion" name="direccion" rows="3" 
                                              maxlength="500"><%= usuario.get("direccion") != null ? usuario.get("direccion") : "" %></textarea>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="fecha_nacimiento" class="form-label font-weight-bold">Fecha de Nacimiento</label>
                                        <input type="date" class="form-control" id="fecha_nacimiento" name="fecha_nacimiento" 
                                               value="<%= usuario.get("fecha_nacimiento") != null ? usuario.get("fecha_nacimiento") : "" %>">
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Configuración de cuenta -->
                    <div class="col-lg-4 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--naranja);">
                                <h6 class="mb-0">
                                    <i class="fas fa-cog mr-2"></i>Configuración de Cuenta
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="mb-3">
                                    <label for="id_rol" class="form-label font-weight-bold">Rol del Usuario *</label>
                                    <select class="form-control" id="id_rol" name="id_rol" required>
                                        <option value="">Seleccionar rol</option>
                                        <% for (Map<String, Object> rol : roles) { %>
                                            <option value="<%= rol.get("id") %>" 
                                                    <%= rol.get("id").equals(usuario.get("id_rol")) ? "selected" : "" %>>
                                                <%= rol.get("nombre") %>
                                            </option>
                                        <% } %>
                                    </select>
                                    <small class="form-text text-muted">Define los permisos del usuario</small>
                                </div>
                                
                                <div class="mb-3">
                                    <label class="form-label font-weight-bold">Estado de la Cuenta</label>
                                    <div class="form-check">
                                        <input type="checkbox" class="form-check-input" id="activo" name="activo" value="1"
                                               <%= (Boolean)usuario.get("activo") ? "checked" : "" %>>
                                        <label class="form-check-label" for="activo">
                                            <strong>Cuenta Activa</strong>
                                        </label>
                                    </div>
                                    <small class="form-text text-muted">
                                        Usuarios inactivos no pueden iniciar sesión
                                    </small>
                                </div>
                                
                                <hr>
                                
                                <div class="alert alert-info">
                                    <i class="fas fa-info-circle mr-2"></i>
                                    <strong>Información:</strong><br>
                                    <small>
                                        Registrado: <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_registro")) %><br>
                                        <% if (usuario.get("fecha_actualizacion") != null) { %>
                                            Actualizado: <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_actualizacion")) %>
                                        <% } %>
                                    </small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Cambio de contraseña -->
                <div class="row">
                    <div class="col-12 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--rojo);">
                                <h6 class="mb-0">
                                    <i class="fas fa-key mr-2"></i>Cambio de Contraseña (Opcional)
                                </h6>
                            </div>
                            <div class="card-body">
                                <div class="alert alert-warning">
                                    <i class="fas fa-exclamation-triangle mr-2"></i>
                                    <strong>Atención:</strong> Solo completa estos campos si deseas cambiar la contraseña del usuario.
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="password" class="form-label font-weight-bold">Nueva Contraseña</label>
                                        <input type="password" class="form-control" id="password" name="password" 
                                               minlength="6" maxlength="255">
                                        <small class="form-text text-muted">Mínimo 6 caracteres</small>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="confirmar_password" class="form-label font-weight-bold">Confirmar Contraseña</label>
                                        <input type="password" class="form-control" id="confirmar_password" name="confirmar_password" 
                                               minlength="6" maxlength="255">
                                    </div>
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
                                <a href="ver-usuario.jsp?id=<%= usuario.get("id") %>" class="btn btn-lg btn-info mr-3">
                                    <i class="fas fa-eye mr-2"></i>Ver Usuario
                                </a>
                                <a href="usuarios.jsp" class="btn btn-lg btn-secondary">
                                    <i class="fas fa-times mr-2"></i>Cancelar
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </form>
            
            <% } %>
            
        </div>
    </div>
</div>

<!-- Descripción de roles (Modal) -->
<div class="modal fade" id="modalRoles" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--vino); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-users-cog mr-2"></i>Descripción de Roles
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <% for (Map<String, Object> rol : roles) { %>
                    <div class="mb-3">
                        <h6 class="text-primary font-weight-bold">
                            <i class="fas fa-user-tag mr-2"></i><%= rol.get("nombre") %>
                        </h6>
                        <p class="text-muted mb-0"><%= rol.get("descripcion") %></p>
                    </div>
                    <% if (!rol.equals(roles.get(roles.size() - 1))) { %>
                        <hr>
                    <% } %>
                <% } %>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
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
</style>

<!-- JavaScript para validación -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formEditarUsuario');
    const password = document.getElementById('password');
    const confirmarPassword = document.getElementById('confirmar_password');
    
    // Validar coincidencia de contraseñas
    function validarPasswords() {
        if (password.value && confirmarPassword.value) {
            if (password.value !== confirmarPassword.value) {
                confirmarPassword.setCustomValidity('Las contraseñas no coinciden');
                confirmarPassword.classList.add('is-invalid');
                password.classList.add('is-invalid');
            } else {
                confirmarPassword.setCustomValidity('');
                confirmarPassword.classList.remove('is-invalid');
                password.classList.remove('is-invalid');
                confirmarPassword.classList.add('is-valid');
                password.classList.add('is-valid');
            }
        }
    }
    
    password.addEventListener('input', validarPasswords);
    confirmarPassword.addEventListener('input', validarPasswords);
    
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
            }
        });
        
        // Validar contraseñas si se proporcionaron
        if (password.value || confirmarPassword.value) {
            if (password.value.length < 6) {
                password.classList.add('is-invalid');
                isValid = false;
            }
            if (password.value !== confirmarPassword.value) {
                password.classList.add('is-invalid');
                confirmarPassword.classList.add('is-invalid');
                isValid = false;
            }
        }
        
        if (!isValid) {
            event.preventDefault();
            alert('Por favor corrige los errores en el formulario.');
            return false;
        }
        
        // Confirmar antes de guardar
        if (!confirm('¿Estás seguro de que deseas guardar los cambios en este usuario?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Agregar botón para mostrar descripción de roles
    const rolSelect = document.getElementById('id_rol');
    const rolContainer = rolSelect.parentElement;
    const infoButton = document.createElement('button');
    infoButton.type = 'button';
    infoButton.className = 'btn btn-sm btn-outline-info mt-2';
    infoButton.innerHTML = '<i class="fas fa-info-circle mr-1"></i>Ver descripción de roles';
    infoButton.onclick = function() {
        $('#modalRoles').modal('show');
    };
    rolContainer.appendChild(infoButton);
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />