<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.security.MessageDigest" %>

<%
    // Variables para el formulario
    String mensaje = "";
    String tipoMensaje = "";
    boolean loginExitoso = false;
    
    // Verificar si ya hay una sesión activa
    if (session.getAttribute("usuario_id") != null) {
        // Usuario ya logueado, redirigir según su rol
        String rol = (String) session.getAttribute("usuario_rol");
        String redirectUrl = request.getContextPath() + "/";
        
        if ("ADMINISTRADOR".equals(rol)) {
            redirectUrl = request.getContextPath() + "/pages/admin/index.jsp";
        } else if ("CLIENTE".equals(rol)) {
            redirectUrl = request.getContextPath() + "/pages/client/index.jsp";
        } else if ("INMOBILIARIA".equals(rol)) {
            redirectUrl = request.getContextPath() + "/pages/inmobiliaria/index.jsp";
        }
        
        response.sendRedirect(redirectUrl);
        return;
    }
    
    // Verificar si es un POST (envío del formulario)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        
        // Obtener parámetros del formulario
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String remember = request.getParameter("remember");
        
        // Validaciones básicas
        if (email == null || email.trim().isEmpty()) {
            mensaje = "El email es obligatorio.";
            tipoMensaje = "error";
        } else if (password == null || password.trim().isEmpty()) {
            mensaje = "La contraseña es obligatoria.";
            tipoMensaje = "error";
        } else {
            // Intentar autenticar
            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;
            
            try {
                // Conectar a la base de datos
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
                
                // Encriptar contraseña con MD5 (igual que en registro)
                MessageDigest md = MessageDigest.getInstance("MD5");
                byte[] hashBytes = md.digest(password.getBytes());
                StringBuilder sb = new StringBuilder();
                for (byte b : hashBytes) {
                    sb.append(String.format("%02x", b));
                }
                String passwordEncriptada = sb.toString();
                
                // Buscar usuario en la base de datos
                String sql = "SELECT u.id_usuario, u.nombre, u.apellido, u.email, u.telefono, " +
                           "u.id_rol, r.nombre_rol " +
                           "FROM usuarios u " +
                           "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                           "WHERE u.email = ? AND u.password = ? AND u.activo = 1";
                
                stmt = conn.prepareStatement(sql);
                stmt.setString(1, email.trim().toLowerCase());
                stmt.setString(2, passwordEncriptada);
                
                rs = stmt.executeQuery();
                
                if (rs.next()) {
                    // Login exitoso - Crear sesión
                    session.setAttribute("usuario_id", rs.getInt("id_usuario"));
                    session.setAttribute("usuario_nombre", rs.getString("nombre"));
                    session.setAttribute("usuario_apellido", rs.getString("apellido"));
                    session.setAttribute("usuario_email", rs.getString("email"));
                    session.setAttribute("usuario_telefono", rs.getString("telefono"));
                    session.setAttribute("usuario_rol_id", rs.getInt("id_rol"));
                    session.setAttribute("usuario_rol", rs.getString("nombre_rol"));
                    session.setAttribute("usuario_nombre_completo", rs.getString("nombre") + " " + rs.getString("apellido"));
                    
                    // Configurar duración de la sesión
                    if (remember != null) {
                        session.setMaxInactiveInterval(7 * 24 * 60 * 60); // 7 días
                    } else {
                        session.setMaxInactiveInterval(30 * 60); // 30 minutos
                    }
                    
                    loginExitoso = true;
                    String rolUsuario = rs.getString("nombre_rol");
                    
                    // Redirigir según el rol
                    String redirectUrl = request.getContextPath() + "/";
                    
                    if ("ADMINISTRADOR".equals(rolUsuario)) {
                        redirectUrl = request.getContextPath() + "/pages/admin/index.jsp";
                    } else if ("CLIENTE".equals(rolUsuario)) {
                        redirectUrl = request.getContextPath() + "/pages/client/index.jsp";
                    } else if ("INMOBILIARIA".equals(rolUsuario)) {
                        redirectUrl = request.getContextPath() + "/pages/inmobiliaria/index.jsp";
                    } else if ("USUARIO".equals(rolUsuario)) {
                        redirectUrl = request.getContextPath() + "/";
                    }
                    
                    // Mensaje de bienvenida
                    session.setAttribute("mensaje_bienvenida", "¡Bienvenido " + rs.getString("nombre") + "!");
                    
                    // Redirigir después de 2 segundos
                    response.setHeader("Refresh", "2; URL=" + redirectUrl);
                    mensaje = "¡Login exitoso! Bienvenido " + rs.getString("nombre") + ". Redirigiendo...";
                    tipoMensaje = "success";
                    
                } else {
                    // Credenciales incorrectas
                    mensaje = "Email o contraseña incorrectos. Verifica tus datos e intenta nuevamente.";
                    tipoMensaje = "error";
                }
                
            } catch (SQLException e) {
                mensaje = "Error de conexión a la base de datos: " + e.getMessage();
                tipoMensaje = "error";
            } catch (Exception e) {
                mensaje = "Error interno: " + e.getMessage();
                tipoMensaje = "error";
            } finally {
                // Cerrar recursos
                if (rs != null) try { rs.close(); } catch (SQLException e) {}
                if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
                if (conn != null) try { conn.close(); } catch (SQLException e) {}
            }
        }
    }
    
    // Verificar si hay mensaje desde registro
    String mensajeRegistro = (String) session.getAttribute("mensaje");
    String tipoMensajeRegistro = (String) session.getAttribute("tipoMensaje");
    if (mensajeRegistro != null) {
        mensaje = mensajeRegistro;
        tipoMensaje = tipoMensajeRegistro;
        session.removeAttribute("mensaje");
        session.removeAttribute("tipoMensaje");
    }
%>

<body>
<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Crear Cuenta - Inmobiliaria J de la Espriella" />
    <jsp:param name="additionalCSS" value="auth.css" />
</jsp:include>

<!-- Contenido de login -->
<div class="login-container d-flex justify-content-center align-items-center">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-5 col-md-7 col-sm-9">
                <div class="card login-card shadow-lg">
                    
                    <!-- Header de la tarjeta -->
                    <div class="card-header bg-primary text-white text-center py-4">
                        <h3 class="mb-0 font-weight-bold">
                            <i class="fas fa-sign-in-alt mr-2"></i>Iniciar Sesión
                        </h3>
                        <p class="mb-0 small mt-2">Accede a tu cuenta</p>
                    </div>
                    
                    <div class="card-body p-4">
                        
                        <!-- Mostrar mensajes -->
                        <% if (!mensaje.isEmpty()) { %>
                            <div class="alert alert-<%= "success".equals(tipoMensaje) ? "success" : "danger" %> alert-dismissible fade show" role="alert">
                                <i class="fas fa-<%= "success".equals(tipoMensaje) ? "check-circle" : "exclamation-triangle" %> mr-2"></i>
                                <%= mensaje %>
                                <% if (loginExitoso) { %>
                                    <br><small><i class="fas fa-clock mr-1"></i>Redirigiendo en 2 segundos...</small>
                                <% } %>
                                <button type="button" class="close" data-dismiss="alert">
                                    <span>&times;</span>
                                </button>
                            </div>
                        <% } %>

                        <% if (!loginExitoso) { %>
                        <!-- Formulario de login -->
                        <form method="post" action="" class="needs-validation" novalidate>
                            
                            <!-- Email -->
                            <div class="form-group">
                                <label for="email" class="font-weight-semibold">
                                    <i class="fas fa-envelope mr-1"></i>Correo Electrónico
                                </label>
                                <input type="email" 
                                       class="form-control form-control-lg" 
                                       id="email" 
                                       name="email"
                                       placeholder="ejemplo@correo.com" 
                                       value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>"
                                       required>
                                <div class="invalid-feedback">
                                    Por favor ingresa un email válido.
                                </div>
                            </div>
                            
                            <!-- Contraseña -->
                            <div class="form-group">
                                <label for="password" class="font-weight-semibold">
                                    <i class="fas fa-lock mr-1"></i>Contraseña
                                </label>
                                <div class="input-group">
                                    <input type="password" 
                                           class="form-control form-control-lg" 
                                           id="password" 
                                           name="password" 
                                           placeholder="Ingresa tu contraseña"
                                           required>
                                    <div class="input-group-append">
                                        <button type="button" 
                                                class="btn btn-outline-secondary" 
                                                onclick="togglePassword()"
                                                id="toggleBtn">
                                            <i class="fas fa-eye" id="eyeIcon"></i>
                                        </button>
                                    </div>
                                </div>
                                <div class="invalid-feedback">
                                    Por favor ingresa tu contraseña.
                                </div>
                            </div>
                            
                            <!-- Recordar sesión -->
                            <div class="form-group">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="remember" name="remember">
                                    <label class="form-check-label" for="remember">
                                        Recordar mi sesión (7 días)
                                    </label>
                                </div>
                            </div>
                            
                            <!-- Botón de login -->
                            <button type="submit" class="btn btn-primary btn-lg btn-block mb-3">
                                <i class="fas fa-sign-in-alt mr-2"></i>Ingresar
                            </button>
                        </form>
                        
                        <!-- Separador -->
                        <div class="text-center my-3">
                            <small class="text-muted">o</small>
                        </div>
                        
                        <!-- Enlaces adicionales -->
                        <div class="text-center">
                            <a href="register.jsp" class="btn btn-outline-primary btn-block mb-2">
                                <i class="fas fa-user-plus mr-2"></i>¿No tienes cuenta? Regístrate
                            </a>
                            <a href="#" class="small text-muted">
                                <i class="fas fa-key mr-1"></i>¿Olvidaste tu contraseña?
                            </a>
                        </div>
                        
                        <% } else { %>
                        <!-- Mensaje de login exitoso -->
                        <div class="text-center">
                            <div class="mb-4">
                                <i class="fas fa-check-circle text-success" style="font-size: 4rem;"></i>
                            </div>
                            <h5 class="text-success">¡Bienvenido!</h5>
                            <p class="text-muted">Has iniciado sesión correctamente.</p>
                            <div class="spinner-border text-primary" role="status">
                                <span class="sr-only">Cargando...</span>
                            </div>
                            <p class="mt-2"><small>Redirigiendo a tu dashboard...</small></p>
                        </div>
                        <% } %>
                        
                        <!-- Link para volver al inicio -->
                        <div class="text-center mt-4 pt-3 border-top">
                            <a href="<%= request.getContextPath() %>/" class="text-primary">
                                <i class="fas fa-arrow-left mr-1"></i>Volver al inicio
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Panel de usuarios de prueba -->
<div class="position-fixed" style="bottom: 20px; right: 20px;">
    <div class="card shadow-sm" style="width: 300px;">
        <div class="card-header bg-info text-white">
            <small><i class="fas fa-users mr-1"></i>Usuarios de Prueba</small>
        </div>
        <div class="card-body p-3">
            <small>
                <strong>Admin:</strong> admin@inmobiliaria.com / admin123<br>
                <strong>Cliente:</strong> cliente@test.com / cliente123<br>
                <strong>Inmobiliaria:</strong> inmobiliaria@test.com / inmob123
            </small>
        </div>
    </div>
</div>

<!-- Estilos adicionales -->
<style>
.login-container {
    min-height: calc(100vh - 120px);
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px 0;
}

.login-card {
    border: none;
    border-radius: 15px;
    overflow: hidden;
    max-width: 100%;
}

.login-card .card-header {
    border-bottom: none;
    background: linear-gradient(135deg, #007bff, #0056b3) !important;
}

.form-control-lg {
    border-radius: 8px;
    border: 2px solid #e9ecef;
    transition: all 0.3s ease;
}

.form-control-lg:focus {
    border-color: #007bff;
    box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}

.btn-primary {
    background: linear-gradient(135deg, #007bff, #0056b3);
    border: none;
    border-radius: 8px;
    transition: all 0.3s ease;
}

.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0, 123, 255, 0.3);
}

@media (max-width: 768px) {
    .login-container {
        padding: 10px;
        min-height: calc(100vh - 120px);
    }
    
    .login-card {
        margin: 10px;
    }
    
    .card-body {
        padding: 1.5rem !important;
    }
    
    .position-fixed {
        position: relative !important;
        bottom: auto !important;
        right: auto !important;
        margin: 20px auto;
    }
}
</style>

<!-- Script para toggle de contraseña -->
<script>
function togglePassword() {
    var passwordField = document.getElementById("password");
    var eyeIcon = document.getElementById("eyeIcon");
    
    if (passwordField.type === "password") {
        passwordField.type = "text";
        eyeIcon.className = "fas fa-eye-slash";
    } else {
        passwordField.type = "password";
        eyeIcon.className = "fas fa-eye";
    }
}

// Auto-focus en el primer campo vacío
document.addEventListener('DOMContentLoaded', function() {
    var emailField = document.getElementById('email');
    var passwordField = document.getElementById('password');
    
    if (emailField.value === '') {
        emailField.focus();
    } else if (passwordField.value === '') {
        passwordField.focus();
    }
});

// Validación de Bootstrap
(function() {
    'use strict';
    window.addEventListener('load', function() {
        var forms = document.getElementsByClassName('needs-validation');
        var validation = Array.prototype.filter.call(forms, function(form) {
            form.addEventListener('submit', function(event) {
                if (form.checkValidity() === false) {
                    event.preventDefault();
                    event.stopPropagation();
                }
                form.classList.add('was-validated');
            }, false);
        });
    }, false);
})();
</script>

<!-- Scripts de Bootstrap -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.slim.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.min.js"></script>

</body>
</html>