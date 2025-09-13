<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>

<%
    // Verificar que el usuario esté logueado y sea cliente
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"CLIENTE".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para almacenar datos del usuario
    Map<String, Object> usuario = null;
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
%>
<%!
    // Función para encriptar contraseña (método de la clase)
    private String encriptarPassword(String password) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");
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
            String passwordActual = request.getParameter("password_actual");
            String passwordNueva = request.getParameter("password_nueva");
            String confirmarPassword = request.getParameter("confirmar_password");
            
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
            } else {
                boolean actualizarPassword = false;
                
                // Validar cambio de contraseña si se proporcionó
                if (passwordActual != null && !passwordActual.trim().isEmpty()) {
                    if (passwordNueva == null || passwordNueva.trim().isEmpty()) {
                        mensaje = "Debe proporcionar la nueva contraseña.";
                        tipoMensaje = "error";
                    } else if (passwordNueva.length() < 6) {
                        mensaje = "La nueva contraseña debe tener al menos 6 caracteres.";
                        tipoMensaje = "error";
                    } else if (!passwordNueva.equals(confirmarPassword)) {
                        mensaje = "La nueva contraseña y su confirmación no coinciden.";
                        tipoMensaje = "error";
                    } else {
                        // Verificar contraseña actual
                        String sqlVerificarPassword = "SELECT password FROM usuarios WHERE id_usuario = ?";
                        stmt = conn.prepareStatement(sqlVerificarPassword);
                        stmt.setInt(1, usuarioId);
                        rs = stmt.executeQuery();
                        
                        if (rs.next()) {
                            String passwordBD = rs.getString("password");
                            String passwordActualEncriptada = encriptarPassword(passwordActual);
                            
                            if (!passwordBD.equals(passwordActualEncriptada)) {
                                mensaje = "La contraseña actual es incorrecta.";
                                tipoMensaje = "error";
                            } else {
                                actualizarPassword = true;
                            }
                        }
                        rs.close();
                        stmt.close();
                    }
                }
                
                if (mensaje.isEmpty()) {
                    try {
                        // Verificar que el email no esté en uso por otro usuario
                        String sqlVerificarEmail = "SELECT id_usuario FROM usuarios WHERE email = ? AND id_usuario != ?";
                        stmt = conn.prepareStatement(sqlVerificarEmail);
                        stmt.setString(1, email.trim());
                        stmt.setInt(2, usuarioId);
                        rs = stmt.executeQuery();
                        
                        if (rs.next()) {
                            mensaje = "El email ya está en uso por otro usuario.";
                            tipoMensaje = "error";
                        } else {
                            rs.close();
                            stmt.close();
                            
                            // Construir SQL de actualización
                            String sqlUpdate;
                            if (actualizarPassword) {
                                sqlUpdate = "UPDATE usuarios SET nombre=?, apellido=?, email=?, telefono=?, direccion=?, " +
                                          "fecha_nacimiento=?, password=?, fecha_actualizacion=CURRENT_TIMESTAMP " +
                                          "WHERE id_usuario=?";
                            } else {
                                sqlUpdate = "UPDATE usuarios SET nombre=?, apellido=?, email=?, telefono=?, direccion=?, " +
                                          "fecha_nacimiento=?, fecha_actualizacion=CURRENT_TIMESTAMP " +
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
                                stmt.setDate(paramIndex++, (java.sql.Date)null);
                            }
                            
                            // Contraseña si se actualiza
                            if (actualizarPassword) {
                                stmt.setString(paramIndex++, encriptarPassword(passwordNueva));
                            }
                            
                            stmt.setInt(paramIndex++, usuarioId);
                            
                            int rowsUpdated = stmt.executeUpdate();
                            
                            if (rowsUpdated > 0) {
                                mensaje = "Perfil actualizado exitosamente.";
                                tipoMensaje = "success";
                                
                                // Actualizar datos de sesión
                                session.setAttribute("usuario_nombre", nombre.trim());
                                session.setAttribute("usuario_apellido", apellido.trim());
                                session.setAttribute("usuario_email", email.trim());
                            } else {
                                mensaje = "No se pudo actualizar el perfil.";
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
                        mensaje = "Error al actualizar perfil: " + e.getMessage();
                        tipoMensaje = "error";
                    }
                }
            }
        }
        
        // Cargar datos actuales del usuario
        String sqlUsuario = "SELECT u.*, r.nombre_rol FROM usuarios u " +
                           "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                           "WHERE u.id_usuario = ?";
        
        stmt = conn.prepareStatement(sqlUsuario);
        stmt.setInt(1, usuarioId);
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
            usuario.put("nombre_rol", rs.getString("nombre_rol"));
            usuario.put("activo", rs.getBoolean("activo"));
            usuario.put("fecha_registro", rs.getTimestamp("fecha_registro"));
            usuario.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar información del perfil: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Mi Perfil - Cliente" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="perfil" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="index.jsp">Dashboard</a></li>
                    <li class="breadcrumb-item active">Mi Perfil</li>
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
                                        <i class="fas fa-user-circle mr-2"></i>Mi Perfil
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Gestiona tu información personal y configuración de cuenta
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <span class="badge badge-success badge-pill p-2">
                                        <i class="fas fa-check-circle mr-1"></i>
                                        Cuenta <%= (Boolean)usuario.get("activo") ? "Activa" : "Inactiva" %>
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Formulario de perfil -->
            <form method="POST" action="" id="formPerfil">
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
                                        <small class="form-text text-muted">
                                            Este email se usará para iniciar sesión
                                        </small>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label for="telefono" class="form-label font-weight-bold">Teléfono</label>
                                        <input type="tel" class="form-control" id="telefono" name="telefono" 
                                               value="<%= usuario.get("telefono") != null ? usuario.get("telefono") : "" %>" 
                                               maxlength="20">
                                        <small class="form-text text-muted">
                                            Para contacto sobre las citas programadas
                                        </small>
                                    </div>
                                </div>
                                
                                <div class="mb-3">
                                    <label for="direccion" class="form-label font-weight-bold">Dirección</label>
                                    <textarea class="form-control" id="direccion" name="direccion" rows="3" 
                                              maxlength="500"><%= usuario.get("direccion") != null ? usuario.get("direccion") : "" %></textarea>
                                    <small class="form-text text-muted">
                                        Dirección de residencia (opcional)
                                    </small>
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label for="fecha_nacimiento" class="form-label font-weight-bold">Fecha de Nacimiento</label>
                                        <input type="date" class="form-control" id="fecha_nacimiento" name="fecha_nacimiento" 
                                               value="<%= usuario.get("fecha_nacimiento") != null ? usuario.get("fecha_nacimiento") : "" %>">
                                        <small class="form-text text-muted">
                                            Campo opcional
                                        </small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Información de cuenta -->
                    <div class="col-lg-4 mb-4">
                        <div class="card shadow">
                            <div class="card-header text-white" style="background-color: var(--naranja);">
                                <h6 class="mb-0">
                                    <i class="fas fa-info-circle mr-2"></i>Información de Cuenta
                                </h6>
                            </div>
                            <div class="card-body">
                                <table class="table table-borderless">
                                    <tr>
                                        <td class="font-weight-bold">ID de Usuario:</td>
                                        <td>#<%= usuario.get("id") %></td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold">Tipo de Cuenta:</td>
                                        <td>
                                            <span class="badge badge-primary">
                                                <%= usuario.get("nombre_rol") %>
                                            </span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold">Estado:</td>
                                        <td>
                                            <span class="badge <%= (Boolean)usuario.get("activo") ? "badge-success" : "badge-danger" %>">
                                                <%= (Boolean)usuario.get("activo") ? "Activa" : "Inactiva" %>
                                            </span>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td class="font-weight-bold">Registrado:</td>
                                        <td>
                                            <small>
                                                <%= new java.text.SimpleDateFormat("dd/MM/yyyy").format(usuario.get("fecha_registro")) %>
                                            </small>
                                        </td>
                                    </tr>
                                    <% if (usuario.get("fecha_actualizacion") != null) { %>
                                    <tr>
                                        <td class="font-weight-bold">Última actualización:</td>
                                        <td>
                                            <small>
                                                <%= new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm").format(usuario.get("fecha_actualizacion")) %>
                                            </small>
                                        </td>
                                    </tr>
                                    <% } %>
                                </table>
                                
                                <hr>
                                
                                <div class="alert alert-info">
                                    <i class="fas fa-shield-alt mr-2"></i>
                                    <strong>Seguridad:</strong><br>
                                    <small>
                                        Tu información está protegida y solo tú puedes modificarla.
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
                                    <strong>Importante:</strong> Solo completa estos campos si deseas cambiar tu contraseña.
                                    Deja los campos vacíos si no quieres modificarla.
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <label for="password_actual" class="form-label font-weight-bold">Contraseña Actual</label>
                                        <input type="password" class="form-control" id="password_actual" name="password_actual" 
                                               maxlength="255">
                                        <small class="form-text text-muted">
                                            Ingresa tu contraseña actual para confirmar
                                        </small>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="password_nueva" class="form-label font-weight-bold">Nueva Contraseña</label>
                                        <input type="password" class="form-control" id="password_nueva" name="password_nueva" 
                                               minlength="6" maxlength="255">
                                        <small class="form-text text-muted">Mínimo 6 caracteres</small>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <label for="confirmar_password" class="form-label font-weight-bold">Confirmar Nueva Contraseña</label>
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
                                <button type="reset" class="btn btn-lg btn-secondary mr-3">
                                    <i class="fas fa-undo mr-2"></i>Restablecer
                                </button>
                                <a href="index.jsp" class="btn btn-lg btn-outline-primary">
                                    <i class="fas fa-arrow-left mr-2"></i>Volver al Dashboard
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

.table-borderless td {
    border: none;
    padding: 0.5rem 0;
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

.alert-warning {
    border-left: 4px solid var(--amarillo);
}

.alert-info {
    border-left: 4px solid #17a2b8;
}
</style>

<!-- JavaScript para validación -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formPerfil');
    const passwordActual = document.getElementById('password_actual');
    const passwordNueva = document.getElementById('password_nueva');
    const confirmarPassword = document.getElementById('confirmar_password');
    
    // Validar coincidencia de contraseñas
    function validarPasswords() {
        if (passwordNueva.value && confirmarPassword.value) {
            if (passwordNueva.value !== confirmarPassword.value) {
                confirmarPassword.setCustomValidity('Las contraseñas no coinciden');
                confirmarPassword.classList.add('is-invalid');
                passwordNueva.classList.add('is-invalid');
            } else {
                confirmarPassword.setCustomValidity('');
                confirmarPassword.classList.remove('is-invalid');
                passwordNueva.classList.remove('is-invalid');
                confirmarPassword.classList.add('is-valid');
                passwordNueva.classList.add('is-valid');
            }
        }
    }
    
    // Validar que si se llena contraseña nueva, se llene también la actual
    function validarCambioPassword() {
        if (passwordNueva.value && !passwordActual.value) {
            passwordActual.setCustomValidity('Debe ingresar su contraseña actual');
            passwordActual.classList.add('is-invalid');
        } else {
            passwordActual.setCustomValidity('');
            passwordActual.classList.remove('is-invalid');
        }
    }
    
    passwordNueva.addEventListener('input', function() {
        validarPasswords();
        validarCambioPassword();
    });
    
    confirmarPassword.addEventListener('input', validarPasswords);
    passwordActual.addEventListener('input', validarCambioPassword);
    
    // Validación del formulario
    form.addEventListener('submit', function(event) {
        let isValid = true;
        
        // Validar campos requeridos
        const requiredInputs = form.querySelectorAll('input[required]');
        requiredInputs.forEach(input => {
            if (!input.value.trim()) {
                input.classList.add('is-invalid');
                isValid = false;
            } else {
                input.classList.remove('is-invalid');
            }
        });
        
        // Validar contraseñas si se proporcionaron
        if (passwordNueva.value || confirmarPassword.value || passwordActual.value) {
            if (!passwordActual.value) {
                passwordActual.classList.add('is-invalid');
                isValid = false;
            }
            if (passwordNueva.value.length < 6) {
                passwordNueva.classList.add('is-invalid');
                isValid = false;
            }
            if (passwordNueva.value !== confirmarPassword.value) {
                passwordNueva.classList.add('is-invalid');
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
        if (!confirm('¿Estás seguro de que deseas actualizar tu perfil?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Validación en tiempo real
    const inputs = form.querySelectorAll('input[required]');
    inputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (!this.value.trim()) {
                this.classList.add('is-invalid');
                this.classList.remove('is-valid');
            } else {
                this.classList.remove('is-invalid');
                this.classList.add('is-valid');
            }
        });
    });
    
    // Formatear teléfono
    const telefonoInput = document.getElementById('telefono');
    telefonoInput.addEventListener('input', function() {
        // Remover caracteres no numéricos excepto + y espacios
        this.value = this.value.replace(/[^+0-9\s-]/g, '');
    });
    
    // Validar fecha de nacimiento (no puede ser futura)
    const fechaNacimiento = document.getElementById('fecha_nacimiento');
    fechaNacimiento.addEventListener('change', function() {
        const fechaSeleccionada = new Date(this.value);
        const fechaActual = new Date();
        
        if (fechaSeleccionada > fechaActual) {
            this.setCustomValidity('La fecha de nacimiento no puede ser futura');
            this.classList.add('is-invalid');
        } else {
            this.setCustomValidity('');
            this.classList.remove('is-invalid');
        }
    });
    
    // Mostrar/ocultar indicador de fuerza de contraseña
    passwordNueva.addEventListener('input', function() {
        const password = this.value;
        let strength = 0;
        let strengthText = '';
        let strengthClass = '';
        
        if (password.length >= 6) strength++;
        if (password.match(/[a-z]/) && password.match(/[A-Z]/)) strength++;
        if (password.match(/[0-9]/)) strength++;
        if (password.match(/[^a-zA-Z0-9]/)) strength++;
        
        // Remover indicador anterior si existe
        const existingIndicator = this.parentElement.querySelector('.password-strength');
        if (existingIndicator) {
            existingIndicator.remove();
        }
        
        if (password.length > 0) {
            switch (strength) {
                case 1:
                    strengthText = 'Muy débil';
                    strengthClass = 'text-danger';
                    break;
                case 2:
                    strengthText = 'Débil';
                    strengthClass = 'text-warning';
                    break;
                case 3:
                    strengthText = 'Buena';
                    strengthClass = 'text-info';
                    break;
                case 4:
                    strengthText = 'Muy fuerte';
                    strengthClass = 'text-success';
                    break;
                default:
                    strengthText = 'Muy débil';
                    strengthClass = 'text-danger';
            }
            
            const strengthIndicator = document.createElement('small');
            strengthIndicator.className = `form-text password-strength ${strengthClass}`;
            strengthIndicator.innerHTML = `<i class="fas fa-shield-alt mr-1"></i>Seguridad: ${strengthText}`;
            this.parentElement.appendChild(strengthIndicator);
        }
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />