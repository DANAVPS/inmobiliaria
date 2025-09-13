<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"INMOBILIARIA".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para datos del usuario
    Map<String, Object> datosUsuario = new HashMap<>();
    
    // Variables para mensajes
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones POST
    String accion = request.getParameter("accion");
    if ("POST".equals(request.getMethod()) && accion != null) {
        Connection connAccion = null;
        PreparedStatement stmtAccion = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            connAccion = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("actualizar_perfil".equals(accion)) {
                String nombre = request.getParameter("nombre");
                String apellido = request.getParameter("apellido");
                String email = request.getParameter("email");
                String telefono = request.getParameter("telefono");
                String direccion = request.getParameter("direccion");
                String fechaNacimiento = request.getParameter("fecha_nacimiento");
                
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
                    // Verificar que el email no esté en uso por otro usuario
                    String sqlVerificarEmail = "SELECT id_usuario FROM usuarios WHERE email = ? AND id_usuario != ?";
                    stmtAccion = connAccion.prepareStatement(sqlVerificarEmail);
                    stmtAccion.setString(1, email.trim());
                    stmtAccion.setInt(2, usuarioId);
                    ResultSet rsEmail = stmtAccion.executeQuery();
                    
                    if (rsEmail.next()) {
                        mensaje = "Este email ya está en uso por otro usuario.";
                        tipoMensaje = "error";
                        rsEmail.close();
                    } else {
                        rsEmail.close();
                        stmtAccion.close();
                        
                        // Actualizar datos del usuario
                        String sqlActualizar = "UPDATE usuarios SET nombre = ?, apellido = ?, email = ?, telefono = ?, direccion = ?, fecha_nacimiento = ? WHERE id_usuario = ?";
                        stmtAccion = connAccion.prepareStatement(sqlActualizar);
                        stmtAccion.setString(1, nombre.trim());
                        stmtAccion.setString(2, apellido.trim());
                        stmtAccion.setString(3, email.trim());
                        stmtAccion.setString(4, telefono != null && !telefono.trim().isEmpty() ? telefono.trim() : null);
                        stmtAccion.setString(5, direccion != null && !direccion.trim().isEmpty() ? direccion.trim() : null);
                        
                        if (fechaNacimiento != null && !fechaNacimiento.trim().isEmpty()) {
                            stmtAccion.setDate(6, java.sql.Date.valueOf(fechaNacimiento));
                        } else {
                            stmtAccion.setNull(6, java.sql.Types.DATE);
                        }
                        stmtAccion.setInt(7, usuarioId);
                        
                        int resultado = stmtAccion.executeUpdate();
                        if (resultado > 0) {
                            mensaje = "Perfil actualizado correctamente.";
                            tipoMensaje = "success";
                            
                            // Actualizar variables de sesión
                            session.setAttribute("usuario_nombre", nombre.trim());
                            session.setAttribute("usuario_apellido", apellido.trim());
                            session.setAttribute("usuario_email", email.trim());
                        } else {
                            mensaje = "Error al actualizar el perfil.";
                            tipoMensaje = "error";
                        }
                    }
                }
                
            } else if ("cambiar_password".equals(accion)) {
                String passwordActual = request.getParameter("password_actual");
                String passwordNuevo = request.getParameter("password_nuevo");
                String passwordConfirmar = request.getParameter("password_confirmar");
                
                // Validaciones
                if (passwordActual == null || passwordActual.trim().isEmpty()) {
                    mensaje = "Debe ingresar su contraseña actual.";
                    tipoMensaje = "error";
                } else if (passwordNuevo == null || passwordNuevo.trim().isEmpty()) {
                    mensaje = "Debe ingresar la nueva contraseña.";
                    tipoMensaje = "error";
                } else if (passwordNuevo.length() < 6) {
                    mensaje = "La nueva contraseña debe tener al menos 6 caracteres.";
                    tipoMensaje = "error";
                } else if (!passwordNuevo.equals(passwordConfirmar)) {
                    mensaje = "La confirmación de contraseña no coincide.";
                    tipoMensaje = "error";
                } else {
                    // Verificar contraseña actual
                    String sqlVerificarPassword = "SELECT id_usuario FROM usuarios WHERE id_usuario = ? AND password = MD5(?)";
                    stmtAccion = connAccion.prepareStatement(sqlVerificarPassword);
                    stmtAccion.setInt(1, usuarioId);
                    stmtAccion.setString(2, passwordActual);
                    ResultSet rsPassword = stmtAccion.executeQuery();
                    
                    if (!rsPassword.next()) {
                        mensaje = "La contraseña actual es incorrecta.";
                        tipoMensaje = "error";
                        rsPassword.close();
                    } else {
                        rsPassword.close();
                        stmtAccion.close();
                        
                        // Actualizar contraseña
                        String sqlActualizarPassword = "UPDATE usuarios SET password = MD5(?) WHERE id_usuario = ?";
                        stmtAccion = connAccion.prepareStatement(sqlActualizarPassword);
                        stmtAccion.setString(1, passwordNuevo);
                        stmtAccion.setInt(2, usuarioId);
                        
                        int resultado = stmtAccion.executeUpdate();
                        if (resultado > 0) {
                            mensaje = "Contraseña cambiada correctamente.";
                            tipoMensaje = "success";
                        } else {
                            mensaje = "Error al cambiar la contraseña.";
                            tipoMensaje = "error";
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            mensaje = "Error al procesar la solicitud: " + e.getMessage();
            tipoMensaje = "error";
            e.printStackTrace();
        } finally {
            if (stmtAccion != null) try { stmtAccion.close(); } catch (SQLException e) {}
            if (connAccion != null) try { connAccion.close(); } catch (SQLException e) {}
        }
    }
    
    // Cargar datos del usuario
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Obtener datos completos del usuario
        String sqlUsuario = "SELECT u.*, r.nombre_rol, r.descripcion as rol_descripcion " +
                           "FROM usuarios u " +
                           "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                           "WHERE u.id_usuario = ?";
        stmt = conn.prepareStatement(sqlUsuario);
        stmt.setInt(1, usuarioId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            datosUsuario.put("id_usuario", rs.getInt("id_usuario"));
            datosUsuario.put("nombre", rs.getString("nombre"));
            datosUsuario.put("apellido", rs.getString("apellido"));
            datosUsuario.put("email", rs.getString("email"));
            datosUsuario.put("telefono", rs.getString("telefono"));
            datosUsuario.put("direccion", rs.getString("direccion"));
            datosUsuario.put("fecha_nacimiento", rs.getDate("fecha_nacimiento"));
            datosUsuario.put("nombre_rol", rs.getString("nombre_rol"));
            datosUsuario.put("rol_descripcion", rs.getString("rol_descripcion"));
            datosUsuario.put("activo", rs.getBoolean("activo"));
            datosUsuario.put("fecha_registro", rs.getTimestamp("fecha_registro"));
            datosUsuario.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        if (mensaje.isEmpty()) {
            mensaje = "Error al cargar los datos del usuario: " + e.getMessage();
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
    <jsp:param name="title" value="Mi Perfil - Inmobiliaria" />
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
            
            <!-- Encabezado -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h2 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                                    </h2>
                                    <p class="text-muted mb-0">
                                        Gestiona tu información personal y configuración de cuenta
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <span class="badge badge-success badge-lg">
                                        <i class="fas fa-check-circle mr-1"></i>
                                        <%= datosUsuario.get("nombre_rol") %>
                                    </span>
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
            
            <div class="row">
                
                <!-- Información de cuenta -->
                <div class="col-lg-4 mb-4">
                    <div class="card shadow">
                        <div class="card-header">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-id-card mr-2"></i>Información de Cuenta
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="text-center mb-3">
                                <div class="avatar-circle mx-auto mb-3" style="width: 80px; height: 80px; background-color: var(--vino); color: white; display: flex; align-items: center; justify-content: center; border-radius: 50%; font-size: 2rem; font-weight: bold;">
                                    <%= datosUsuario.get("nombre").toString().substring(0,1).toUpperCase() +
                                        datosUsuario.get("apellido").toString().substring(0,1).toUpperCase() %>
                                </div>
                                <h5 class="mb-0"><%= datosUsuario.get("nombre") %> <%= datosUsuario.get("apellido") %></h5>
                                <p class="text-muted mb-0"><%= datosUsuario.get("email") %></p>
                            </div>
                            
                            <hr>
                            
                            <div class="row text-center">
                                <div class="col-6">
                                    <div class="mb-2">
                                        <i class="fas fa-calendar-plus text-primary"></i>
                                        <small class="d-block text-muted">Miembro desde</small>
                                        <strong>
                                            <%= new SimpleDateFormat("MMM yyyy").format((java.util.Date)datosUsuario.get("fecha_registro")) %>
                                        </strong>
                                    </div>
                                </div>
                                <div class="col-6">
                                    <div class="mb-2">
                                        <i class="fas fa-sync-alt text-success"></i>
                                        <small class="d-block text-muted">Última actualización</small>
                                        <strong>
                                            <%= new SimpleDateFormat("dd/MM/yy").format((java.util.Date)datosUsuario.get("fecha_actualizacion")) %>
                                        </strong>
                                    </div>
                                </div>
                            </div>
                            
                            <hr>
                            
                            <div class="text-center">
                                <span class="badge badge-<%= (Boolean)datosUsuario.get("activo") ? "success" : "danger" %> badge-lg">
                                    <i class="fas fa-<%= (Boolean)datosUsuario.get("activo") ? "check" : "times" %> mr-1"></i>
                                    <%= (Boolean)datosUsuario.get("activo") ? "Cuenta Activa" : "Cuenta Inactiva" %>
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Formularios de edición -->
                <div class="col-lg-8">
                    
                    <!-- Datos personales -->
                    <div class="card shadow mb-4">
                        <div class="card-header">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-user mr-2"></i>Datos Personales
                            </h6>
                        </div>
                        <div class="card-body">
                            <form method="POST" action="perfil.jsp">
                                <input type="hidden" name="accion" value="actualizar_perfil">
                                
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="nombre">Nombre <span class="text-danger">*</span></label>
                                            <input type="text" class="form-control" id="nombre" name="nombre" 
                                                   value="<%= datosUsuario.get("nombre") %>" required maxlength="100">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="apellido">Apellido <span class="text-danger">*</span></label>
                                            <input type="text" class="form-control" id="apellido" name="apellido" 
                                                   value="<%= datosUsuario.get("apellido") %>" required maxlength="100">
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="form-group">
                                    <label for="email">Email <span class="text-danger">*</span></label>
                                    <input type="email" class="form-control" id="email" name="email" 
                                           value="<%= datosUsuario.get("email") %>" required maxlength="150">
                                </div>
                                
                                <div class="row">
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="telefono">Teléfono</label>
                                            <input type="tel" class="form-control" id="telefono" name="telefono" 
                                                   value="<%= datosUsuario.get("telefono") != null ? datosUsuario.get("telefono") : "" %>" 
                                                   maxlength="20" placeholder="+57 300 123 4567">
                                        </div>
                                    </div>
                                    <div class="col-md-6">
                                        <div class="form-group">
                                            <label for="fecha_nacimiento">Fecha de Nacimiento</label>
                                            <input type="date" class="form-control" id="fecha_nacimiento" name="fecha_nacimiento" 
                                                   value="<%= datosUsuario.get("fecha_nacimiento") != null ? 
                                                           new SimpleDateFormat("yyyy-MM-dd").format((java.util.Date)datosUsuario.get("fecha_nacimiento")) : "" %>">
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="form-group">
                                    <label for="direccion">Dirección</label>
                                    <textarea class="form-control" id="direccion" name="direccion" rows="3" 
                                              maxlength="500" placeholder="Dirección completa..."><%= datosUsuario.get("direccion") != null ? datosUsuario.get("direccion") : "" %></textarea>
                                </div>
                                
                                <div class="text-right">
                                    <button type="submit" class="btn text-white" style="background-color: var(--vino);">
                                        <i class="fas fa-save mr-1"></i>Guardar Cambios
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                    <!-- Cambiar contraseña -->
                    <div class="card shadow">
                        <div class="card-header">
                            <h6 class="m-0 font-weight-bold" style="color: var(--vino);">
                                <i class="fas fa-lock mr-2"></i>Cambiar Contraseña
                            </h6>
                        </div>
                        <div class="card-body">
                            <form method="POST" action="perfil.jsp" id="formPassword">
                                <input type="hidden" name="accion" value="cambiar_password">
                                
                                <div class="form-group">
                                    <label for="password_actual">Contraseña Actual <span class="text-danger">*</span></label>
                                    <div class="input-group">
                                        <input type="password" class="form-control" id="password_actual" name="password_actual" required>
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('password_actual')">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="form-group">
                                    <label for="password_nuevo">Nueva Contraseña <span class="text-danger">*</span></label>
                                    <div class="input-group">
                                        <input type="password" class="form-control" id="password_nuevo" name="password_nuevo" required minlength="6">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('password_nuevo')">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                    <small class="form-text text-muted">Mínimo 6 caracteres</small>
                                </div>
                                
                                <div class="form-group">
                                    <label for="password_confirmar">Confirmar Nueva Contraseña <span class="text-danger">*</span></label>
                                    <div class="input-group">
                                        <input type="password" class="form-control" id="password_confirmar" name="password_confirmar" required minlength="6">
                                        <div class="input-group-append">
                                            <button class="btn btn-outline-secondary" type="button" onclick="togglePassword('password_confirmar')">
                                                <i class="fas fa-eye"></i>
                                            </button>
                                        </div>
                                    </div>
                                </div>
                                
                                <div class="text-right">
                                    <button type="submit" class="btn btn-warning">
                                        <i class="fas fa-key mr-1"></i>Cambiar Contraseña
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                    
                </div>
            </div>
            
            <!-- Información adicional -->
            <div class="row mt-4">
                <div class="col-12">
                    <div class="card shadow border-left-info">
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-8">
                                    <h6 class="font-weight-bold text-info">
                                        <i class="fas fa-info-circle mr-2"></i>Información Importante
                                    </h6>
                                    <ul class="mb-0">
                                        <li>Mantén tu información de contacto actualizada para que los clientes puedan comunicarse contigo.</li>
                                        <li>Cambia tu contraseña regularmente por seguridad.</li>
                                        <li>Tu email se utiliza para notificaciones importantes del sistema.</li>
                                        <li>Si tienes problemas para acceder a tu cuenta, contacta al administrador.</li>
                                    </ul>
                                </div>
                                <div class="col-md-4 text-center">
                                    <i class="fas fa-shield-alt fa-3x text-info mb-2"></i>
                                    <h6 class="text-info">Cuenta Segura</h6>
                                    <small class="text-muted">Tus datos están protegidos</small>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
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
    transition: transform 0.2s;
}

.card:hover {
    transform: translateY(-2px);
}

.border-left-info {
    border-left: 4px solid #17a2b8 !important;
}

.avatar-circle {
    box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.badge-lg {
    font-size: 0.9rem;
    padding: 0.5rem 0.8rem;
}

.form-control:focus {
    border-color: var(--vino);
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

.btn:hover {
    transform: translateY(-1px);
    transition: transform 0.2s;
}

.input-group-append .btn {
    border-color: #ced4da;
}

.input-group-append .btn:hover {
    background-color: #e9ecef;
    transform: none;
}

/* Responsividad */
@media (max-width: 768px) {
    .container-fluid {
        padding: 0.5rem;
    }
    
    .card-body {
        padding: 1rem;
    }
    
    .avatar-circle {
        width: 60px !important;
        height: 60px !important;
        font-size: 1.5rem !important;
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

/* Mejoras en formularios */
.form-group label {
    font-weight: 600;
    color: #495057;
}

.text-danger {
    font-weight: bold;
}

/* Estados de validación */
.is-valid {
    border-color: #28a745;
}

.is-invalid {
    border-color: #dc3545;
}

.valid-feedback {
    color: #28a745;
}

.invalid-feedback {
    color: #dc3545;
}
</style>

<!-- JavaScript -->
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
    
    // Validación en tiempo real de contraseñas
    const passwordNuevo = document.getElementById('password_nuevo');
    const passwordConfirmar = document.getElementById('password_confirmar');
    
    function validarPasswords() {
        if (passwordNuevo.value.length >= 6 && passwordConfirmar.value.length >= 6) {
            if (passwordNuevo.value === passwordConfirmar.value) {
                passwordConfirmar.classList.remove('is-invalid');
                passwordConfirmar.classList.add('is-valid');
                return true;
            } else {
                passwordConfirmar.classList.remove('is-valid');
                passwordConfirmar.classList.add('is-invalid');
                return false;
            }
        } else {
            passwordConfirmar.classList.remove('is-valid', 'is-invalid');
            return false;
        }
    }
    
    passwordNuevo.addEventListener('input', validarPasswords);
    passwordConfirmar.addEventListener('input', validarPasswords);
    
    // Validación del formulario de contraseña
    document.getElementById('formPassword').addEventListener('submit', function(e) {
        if (!validarPasswords()) {
            e.preventDefault();
            alert('Las contraseñas no coinciden o no cumplen con los requisitos mínimos.');
        }
    });
    
    // Validación de email en tiempo real
    const emailInput = document.getElementById('email');
    emailInput.addEventListener('input', function() {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (this.value.length > 0) {
            if (emailRegex.test(this.value)) {
                this.classList.remove('is-invalid');
                this.classList.add('is-valid');
            } else {
                this.classList.remove('is-valid');
                this.classList.add('is-invalid');
            }
        } else {
            this.classList.remove('is-valid', 'is-invalid');
        }
    });
    
    // Validación de teléfono
    const telefonoInput = document.getElementById('telefono');
    telefonoInput.addEventListener('input', function() {
        // Permitir solo números, espacios, + y -
        this.value = this.value.replace(/[^0-9\s\+\-]/g, '');
    });
    
    // Confirmación antes de enviar cambios importantes
    const formPerfil = document.querySelector('form[action="perfil.jsp"]:not(#formPassword)');
    formPerfil.addEventListener('submit', function(e) {
        const emailOriginal = '<%= datosUsuario.get("email") %>';
        const emailNuevo = document.getElementById('email').value;
        
        if (emailOriginal !== emailNuevo) {
            if (!confirm('¿Estás seguro de cambiar tu email? Se utilizará para todas las notificaciones del sistema.')) {
                e.preventDefault();
            }
        }
    });
});

// Función para mostrar/ocultar contraseñas
function togglePassword(inputId) {
    const input = document.getElementById(inputId);
    const icon = input.nextElementSibling.querySelector('i');
    
    if (input.type === 'password') {
        input.type = 'text';
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = 'password';
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

// Función para validar fortaleza de contraseña
function validarFortalezaPassword(password) {
    let puntuacion = 0;
    let feedback = [];
    
    if (password.length >= 8) puntuacion++;
    else feedback.push('Al menos 8 caracteres');
    
    if (/[a-z]/.test(password)) puntuacion++;
    else feedback.push('Una letra minúscula');
    
    if (/[A-Z]/.test(password)) puntuacion++;
    else feedback.push('Una letra mayúscula');
    
    if (/[0-9]/.test(password)) puntuacion++;
    else feedback.push('Un número');
    
    if (/[^A-Za-z0-9]/.test(password)) puntuacion++;
    else feedback.push('Un carácter especial');
    
    return {
        puntuacion: puntuacion,
        feedback: feedback,
        esSegura: puntuacion >= 3
    };
}

// Mostrar indicador de fortaleza de contraseña
document.addEventListener('DOMContentLoaded', function() {
    const passwordNuevo = document.getElementById('password_nuevo');
    
    // Crear indicador de fortaleza
    const indicador = document.createElement('div');
    indicador.className = 'password-strength mt-2';
    indicador.innerHTML = `
        <div class="progress" style="height: 5px;">
            <div class="progress-bar" role="progressbar" style="width: 0%"></div>
        </div>
        <small class="text-muted"></small>
    `;
    passwordNuevo.parentNode.appendChild(indicador);
    
    passwordNuevo.addEventListener('input', function() {
        const validacion = validarFortalezaPassword(this.value);
        const progressBar = indicador.querySelector('.progress-bar');
        const texto = indicador.querySelector('small');
        
        const porcentaje = (validacion.puntuacion / 5) * 100;
        progressBar.style.width = porcentaje + '%';
        
        if (validacion.puntuacion <= 2) {
            progressBar.className = 'progress-bar bg-danger';
            texto.textContent = 'Contraseña débil';
            texto.className = 'text-danger';
        } else if (validacion.puntuacion <= 3) {
            progressBar.className = 'progress-bar bg-warning';
            texto.textContent = 'Contraseña media';
            texto.className = 'text-warning';
        } else {
            progressBar.className = 'progress-bar bg-success';
            texto.textContent = 'Contraseña fuerte';
            texto.className = 'text-success';
        }
        
        if (this.value.length === 0) {
            progressBar.style.width = '0%';
            texto.textContent = '';
        }
    });
});


// Guardar cambios automáticamente en localStorage como borrador
document.addEventListener('DOMContentLoaded', function() {
    const inputs = document.querySelectorAll('input[type="text"], input[type="email"], input[type="tel"], input[type="date"], textarea');
    
    inputs.forEach(input => {
        // Cargar valor guardado
        const valorGuardado = localStorage.getItem('perfil_' + input.name);
        if (valorGuardado && input.value === '') {
            input.value = valorGuardado;
        }
        
        // Guardar cambios
        input.addEventListener('input', function() {
            localStorage.setItem('perfil_' + this.name, this.value);
        });
    });
    
    // Limpiar localStorage al enviar formulario exitosamente
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', function() {
            // Solo limpiar si es el formulario de perfil, no el de contraseña
            if (this.querySelector('input[name="accion"][value="actualizar_perfil"]')) {
                inputs.forEach(input => {
                    localStorage.removeItem('perfil_' + input.name);
                });
            }
        });
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />