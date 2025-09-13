<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.security.MessageDigest, java.text.SimpleDateFormat, java.util.Date" %>

<%
    // Variables para el formulario
    String mensaje = "";
    String tipoMensaje = "";
    boolean mostrarFormulario = true;
    
    // Verificar si es un POST (envío del formulario)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        
        // Obtener parámetros del formulario
        String nombre = request.getParameter("nombre");
        String apellido = request.getParameter("apellido");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        String telefono = request.getParameter("telefono");
        String direccion = request.getParameter("direccion");
        String fechaNacimientoStr = request.getParameter("fecha_nacimiento");
        String idRolStr = request.getParameter("id_rol");
        String terms = request.getParameter("terms");
        
        // Validaciones básicas
        StringBuilder errores = new StringBuilder();
        
        if (nombre == null || nombre.trim().isEmpty()) {
            errores.append("El nombre es obligatorio. ");
        }
        if (apellido == null || apellido.trim().isEmpty()) {
            errores.append("El apellido es obligatorio. ");
        }
        if (email == null || email.trim().isEmpty()) {
            errores.append("El email es obligatorio. ");
        } else if (!email.matches("^[A-Za-z0-9+_.-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$")) {
            errores.append("El formato del email no es válido. ");
        }
        if (password == null || password.trim().isEmpty()) {
            errores.append("La contraseña es obligatoria. ");
        } else if (password.length() < 6) {
            errores.append("La contraseña debe tener al menos 6 caracteres. ");
        }
        if (confirmPassword == null || !password.equals(confirmPassword)) {
            errores.append("Las contraseñas no coinciden. ");
        }
        if (idRolStr == null || idRolStr.trim().isEmpty()) {
            errores.append("Debe seleccionar un tipo de cuenta. ");
        }
        if (terms == null) {
            errores.append("Debe aceptar los términos y condiciones. ");
        }
        
        // Si no hay errores, procesar registro
        if (errores.length() == 0) {
            Connection conn = null;
            PreparedStatement stmtVerificar = null;
            PreparedStatement stmtInsertar = null;
            ResultSet rs = null;
            
            try {
                // Conectar a la base de datos
                Class.forName("com.mysql.cj.jdbc.Driver");
                conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
                
                // Verificar si el email ya existe
                String sqlVerificar = "SELECT COUNT(*) FROM usuarios WHERE email = ?";
                stmtVerificar = conn.prepareStatement(sqlVerificar);
                stmtVerificar.setString(1, email.trim().toLowerCase());
                rs = stmtVerificar.executeQuery();
                
                if (rs.next() && rs.getInt(1) > 0) {
                    errores.append("Este email ya está registrado. ");
                } else {
                    // Encriptar contraseña con MD5
                    MessageDigest md = MessageDigest.getInstance("MD5");
                    byte[] hashBytes = md.digest(password.getBytes());
                    StringBuilder sb = new StringBuilder();
                    for (byte b : hashBytes) {
                        sb.append(String.format("%02x", b));
                    }
                    String passwordEncriptada = sb.toString();
                    
                    // Insertar nuevo usuario
                    String sqlInsertar = "INSERT INTO usuarios (nombre, apellido, email, password, telefono, direccion, fecha_nacimiento, id_rol) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                    stmtInsertar = conn.prepareStatement(sqlInsertar);
                    
                    stmtInsertar.setString(1, nombre.trim());
                    stmtInsertar.setString(2, apellido.trim());
                    stmtInsertar.setString(3, email.trim().toLowerCase());
                    stmtInsertar.setString(4, passwordEncriptada);
                    stmtInsertar.setString(5, telefono != null ? telefono.trim() : null);
                    stmtInsertar.setString(6, direccion != null ? direccion.trim() : null);
                    
                    // Manejar fecha de nacimiento
                    if (fechaNacimientoStr != null && !fechaNacimientoStr.trim().isEmpty()) {
                        try {
                            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                            Date fechaNacimiento = sdf.parse(fechaNacimientoStr);
                            
                            // Validar edad (mayor de 18)
                            Date fechaActual = new Date();
                            long diferencia = fechaActual.getTime() - fechaNacimiento.getTime();
                            int edad = (int) (diferencia / (365.25 * 24 * 60 * 60 * 1000));
                            
                            if (edad < 18) {
                                errores.append("Debe ser mayor de 18 años para registrarse. ");
                            } else {
                                stmtInsertar.setDate(7, new java.sql.Date(fechaNacimiento.getTime()));
                            }
                        } catch (Exception e) {
                            errores.append("Formato de fecha no válido. ");
                        }
                    } else {
                        stmtInsertar.setNull(7, Types.DATE);
                    }
                    
                    // Validar rol
                    int idRol = Integer.parseInt(idRolStr);
                    if (idRol < 2 || idRol > 4) { // Solo permitir Usuario(2), Cliente(3), Inmobiliaria(4)
                        errores.append("Tipo de cuenta no válido. ");
                    } else {
                        stmtInsertar.setInt(8, idRol);
                    }
                    
                    // Si todavía no hay errores, ejecutar inserción
                    if (errores.length() == 0) {
                        int filasAfectadas = stmtInsertar.executeUpdate();
                        
                        if (filasAfectadas > 0) {
                            // Registro exitoso
                            mensaje = "¡Registro exitoso! Ya puedes iniciar sesión con tu nueva cuenta.";
                            tipoMensaje = "success";
                            mostrarFormulario = false;
                            
                            // Opcional: Redirigir después de 3 segundos
                            response.setHeader("Refresh", "3; URL=" + request.getContextPath() + "/pages/auth/login.jsp");
                            
                        } else {
                            errores.append("Error al registrar el usuario. Intente nuevamente. ");
                        }
                    }
                }
                
            } catch (SQLException e) {
                if (e.getMessage().contains("Duplicate entry") && e.getMessage().contains("email")) {
                    errores.append("Este email ya está registrado. ");
                } else {
                    errores.append("Error en la base de datos: " + e.getMessage() + " ");
                }
            } catch (Exception e) {
                errores.append("Error interno: " + e.getMessage() + " ");
            } finally {
                // Cerrar recursos
                if (rs != null) try { rs.close(); } catch (SQLException e) {}
                if (stmtVerificar != null) try { stmtVerificar.close(); } catch (SQLException e) {}
                if (stmtInsertar != null) try { stmtInsertar.close(); } catch (SQLException e) {}
                if (conn != null) try { conn.close(); } catch (SQLException e) {}
            }
        }
        
        // Si hay errores, mostrarlos
        if (errores.length() > 0) {
            mensaje = errores.toString().trim();
            tipoMensaje = "error";
        }
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Crear Cuenta - Inmobiliaria J de la Espriella" />
    <jsp:param name="additionalCSS" value="auth.css" />
</jsp:include>

<!-- Contenido de registro -->
<div class="register-container d-flex justify-content-center align-items-center">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8 col-md-10">
                <div class="card register-card shadow-lg">
                    
                    <!-- Header de la tarjeta -->
                    <div class="card-header bg-primary text-white text-center py-4">
                        <h3 class="mb-0 font-weight-bold">
                            <i class="fas fa-user-plus mr-2"></i>Crear Cuenta
                        </h3>
                        <p class="mb-0 small mt-2">Únete a nuestra comunidad inmobiliaria</p>
                    </div>
                    
                    <div class="card-body p-4">
                        
                        <!-- Mostrar mensajes -->
                        <% if (!mensaje.isEmpty()) { %>
                            <div class="alert alert-<%= "success".equals(tipoMensaje) ? "success" : "danger" %> alert-dismissible fade show" role="alert">
                                <i class="fas fa-<%= "success".equals(tipoMensaje) ? "check-circle" : "exclamation-triangle" %> mr-2"></i>
                                <%= mensaje %>
                                <% if ("success".equals(tipoMensaje)) { %>
                                    <br><small><i class="fas fa-clock mr-1"></i>Redirigiendo al login en 3 segundos...</small>
                                <% } %>
                                <button type="button" class="close" data-dismiss="alert">
                                    <span>&times;</span>
                                </button>
                            </div>
                        <% } %>

                        <% if (mostrarFormulario) { %>
                        <!-- Formulario de registro -->
                        <form method="post" action="" class="needs-validation" novalidate>
                            
                            <!-- Información Personal -->
                            <div class="mb-4">
                                <h5 class="text-primary mb-3">
                                    <i class="fas fa-user mr-2"></i>Información Personal
                                </h5>
                                
                                <!-- Nombre y Apellido -->
                                <div class="form-row">
                                    <div class="form-group col-md-6">
                                        <label for="nombre" class="font-weight-semibold">
                                            <i class="fas fa-user mr-1"></i>Nombre <span class="text-danger">*</span>
                                        </label>
                                        <input type="text" 
                                               class="form-control form-control-lg" 
                                               id="nombre" 
                                               name="nombre"
                                               value="<%= request.getParameter("nombre") != null ? request.getParameter("nombre") : "" %>"
                                               placeholder="Tu nombre"
                                               required>
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="apellido" class="font-weight-semibold">
                                            <i class="fas fa-user mr-1"></i>Apellido <span class="text-danger">*</span>
                                        </label>
                                        <input type="text" 
                                               class="form-control form-control-lg" 
                                               id="apellido" 
                                               name="apellido"
                                               value="<%= request.getParameter("apellido") != null ? request.getParameter("apellido") : "" %>"
                                               placeholder="Tu apellido"
                                               required>
                                    </div>
                                </div>

                                <!-- Email -->
                                <div class="form-group">
                                    <label for="email" class="font-weight-semibold">
                                        <i class="fas fa-envelope mr-1"></i>Correo Electrónico <span class="text-danger">*</span>
                                    </label>
                                    <input type="email" 
                                           class="form-control form-control-lg" 
                                           id="email" 
                                           name="email"
                                           value="<%= request.getParameter("email") != null ? request.getParameter("email") : "" %>"
                                           placeholder="ejemplo@correo.com" 
                                           required>
                                    <small class="form-text text-muted">
                                        <i class="fas fa-info-circle mr-1"></i>Será tu nombre de usuario para iniciar sesión
                                    </small>
                                </div>

                                <!-- Teléfono y Fecha de Nacimiento -->
                                <div class="form-row">
                                    <div class="form-group col-md-6">
                                        <label for="telefono" class="font-weight-semibold">
                                            <i class="fas fa-phone mr-1"></i>Teléfono
                                        </label>
                                        <input type="tel" 
                                               class="form-control form-control-lg" 
                                               id="telefono" 
                                               name="telefono"
                                               value="<%= request.getParameter("telefono") != null ? request.getParameter("telefono") : "" %>"
                                               placeholder="+57 300 123 4567">
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="fecha_nacimiento" class="font-weight-semibold">
                                            <i class="fas fa-calendar mr-1"></i>Fecha de Nacimiento
                                        </label>
                                        <input type="date" 
                                               class="form-control form-control-lg" 
                                               id="fecha_nacimiento" 
                                               name="fecha_nacimiento"
                                               value="<%= request.getParameter("fecha_nacimiento") != null ? request.getParameter("fecha_nacimiento") : "" %>"
                                               max="<%= java.time.LocalDate.now().minusYears(18) %>">
                                    </div>
                                </div>

                                <!-- Dirección -->
                                <div class="form-group">
                                    <label for="direccion" class="font-weight-semibold">
                                        <i class="fas fa-map-marker-alt mr-1"></i>Dirección
                                    </label>
                                    <textarea class="form-control form-control-lg" 
                                              id="direccion" 
                                              name="direccion" 
                                              rows="2"
                                              placeholder="Tu dirección completa"><%= request.getParameter("direccion") != null ? request.getParameter("direccion") : "" %></textarea>
                                </div>
                            </div>

                            <!-- Información de Seguridad -->
                            <div class="mb-4">
                                <h5 class="text-primary mb-3">
                                    <i class="fas fa-lock mr-2"></i>Información de Seguridad
                                </h5>
                                
                                <!-- Contraseñas -->
                                <div class="form-row">
                                    <div class="form-group col-md-6">
                                        <label for="password" class="font-weight-semibold">
                                            <i class="fas fa-key mr-1"></i>Contraseña <span class="text-danger">*</span>
                                        </label>
                                        <input type="password" 
                                               class="form-control form-control-lg" 
                                               id="password" 
                                               name="password"
                                               placeholder="Mínimo 6 caracteres"
                                               minlength="6"
                                               required>
                                        <small class="form-text text-muted">
                                            <i class="fas fa-shield-alt mr-1"></i>Mínimo 6 caracteres
                                        </small>
                                    </div>
                                    <div class="form-group col-md-6">
                                        <label for="confirmPassword" class="font-weight-semibold">
                                            <i class="fas fa-key mr-1"></i>Confirmar Contraseña <span class="text-danger">*</span>
                                        </label>
                                        <input type="password" 
                                               class="form-control form-control-lg" 
                                               id="confirmPassword" 
                                               name="confirmPassword"
                                               placeholder="Repite la contraseña"
                                               required>
                                    </div>
                                </div>
                            </div>

                            <!-- Tipo de Cuenta -->
                            <div class="mb-4">
                                <h5 class="text-primary mb-3">
                                    <i class="fas fa-users mr-2"></i>Tipo de Cuenta
                                </h5>
                                
                                <div class="form-group">
                                    <label for="id_rol" class="font-weight-semibold">
                                        <i class="fas fa-user-tag mr-1"></i>¿Cómo vas a usar la plataforma? <span class="text-danger">*</span>
                                    </label>
                                    <select class="form-control form-control-lg" id="id_rol" name="id_rol" required>
                                        <option value="">Seleccione una opción</option>
                                        <option value="3" <%= "3".equals(request.getParameter("id_rol")) ? "selected" : "" %>>
                                            Cliente - Buscar propiedades para comprar/arrendar
                                        </option>
                                        <option value="4" <%= "4".equals(request.getParameter("id_rol")) ? "selected" : "" %>>
                                            Inmobiliaria - Publicar y gestionar propiedades
                                        </option>
                                        <option value="2" <%= "2".equals(request.getParameter("id_rol")) ? "selected" : "" %>>
                                            Usuario - Solo navegar y ver propiedades
                                        </option>
                                    </select>
                                    <small class="form-text text-muted">
                                        <i class="fas fa-info-circle mr-1"></i>Puedes cambiar esto más tarde en tu perfil
                                    </small>
                                </div>
                            </div>

                            <!-- Términos y Condiciones -->
                            <div class="form-group">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="terms" name="terms" required>
                                    <label class="form-check-label" for="terms">
                                        Acepto los <a href="#" class="text-primary">términos y condiciones</a> y la 
                                        <a href="#" class="text-primary">política de privacidad</a> <span class="text-danger">*</span>
                                    </label>
                                </div>
                            </div>

                            <!-- Botón de registro -->
                            <button type="submit" class="btn btn-primary btn-lg btn-block mb-3">
                                <i class="fas fa-user-plus mr-2"></i>Crear Mi Cuenta
                            </button>
                        </form>
                        <% } else { %>
                        <!-- Mensaje de éxito -->
                        <div class="text-center">
                            <div class="mb-4">
                                <i class="fas fa-check-circle text-success" style="font-size: 4rem;"></i>
                            </div>
                            <h5 class="text-success">¡Cuenta creada exitosamente!</h5>
                            <p class="text-muted">Tu cuenta ha sido registrada correctamente.</p>
                            <a href="<%= request.getContextPath() %>/pages/auth/login.jsp" class="btn btn-primary btn-lg">
                                <i class="fas fa-sign-in-alt mr-2"></i>Iniciar Sesión Ahora
                            </a>
                        </div>
                        <% } %>
                        
                        <!-- Separador -->
                        <div class="text-center my-3">
                            <small class="text-muted">o</small>
                        </div>
                        
                        <!-- Enlaces adicionales -->
                        <div class="text-center">
                            <a href="login.jsp" class="btn btn-outline-primary btn-block mb-2">
                                <i class="fas fa-sign-in-alt mr-2"></i>¿Ya tienes cuenta? Inicia Sesión
                            </a>
                        </div>
                        
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

<!-- Estilos adicionales específicos para registro -->
<style>
.register-container {
    min-height: calc(100vh - 120px);
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 30px 0;
}

.register-card {
    border: none;
    border-radius: 15px;
    overflow: hidden;
}

.register-card .card-header {
    border-bottom: none;
    background: linear-gradient(135deg, #007bff, #0056b3) !important;
}

.register-container h5 {
    border-bottom: 2px solid #e9ecef;
    padding-bottom: 10px;
}

@media (max-width: 768px) {
    .register-container {
        padding: 15px 5px;
    }
}
</style>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />