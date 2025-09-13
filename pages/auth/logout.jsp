<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Obtener nombre del usuario antes de cerrar sesión
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    if (nombreUsuario == null) {
        nombreUsuario = "Usuario";
    }
    
    // Invalidar sesión completamente
    if (session != null) {
        session.invalidate();
    }
    
    // Redirigir al inicio después de 3 segundos
    response.setHeader("Refresh", "3; URL=" + request.getContextPath() + "/");
%>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cerrando Sesión - Inmobiliaria J de la Espriella</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        .logout-container {
            min-height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .logout-card {
            border: none;
            border-radius: 15px;
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.1);
        }
    </style>
</head>
<body>

<div class="logout-container">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6 col-lg-4">
                <div class="card logout-card">
                    <div class="card-body text-center p-5">
                        
                        <!-- Icono de logout -->
                        <div class="mb-4">
                            <i class="fas fa-sign-out-alt text-primary" style="font-size: 4rem;"></i>
                        </div>
                        
                        <!-- Mensaje -->
                        <h4 class="text-primary mb-3">¡Hasta pronto, <%= nombreUsuario %>!</h4>
                        <p class="text-muted mb-4">
                            Has cerrado sesión exitosamente. Tu información está segura.
                        </p>
                        
                        <!-- Spinner -->
                        <div class="mb-4">
                            <div class="spinner-border text-primary" role="status">
                                <span class="sr-only">Cargando...</span>
                            </div>
                        </div>
                        
                        <!-- Mensaje de redirección -->
                        <p class="text-muted mb-4">
                            <small>
                                <i class="fas fa-clock mr-1"></i>
                                Redirigiendo al inicio en 3 segundos...
                            </small>
                        </p>
                        
                        <!-- Botones de acción -->
                        <div class="d-grid gap-2">
                            <a href="<%= request.getContextPath() %>/" class="btn btn-primary btn-block mb-2">
                                <i class="fas fa-home mr-2"></i>Ir al Inicio Ahora
                            </a>
                            <a href="login.jsp" class="btn btn-outline-primary btn-block">
                                <i class="fas fa-sign-in-alt mr-2"></i>Iniciar Sesión Nuevamente
                            </a>
                        </div>
                        
                        <!-- Mensaje de seguridad -->
                        <div class="mt-4 pt-3 border-top">
                            <small class="text-muted">
                                <i class="fas fa-shield-alt mr-1"></i>
                                Por tu seguridad, cierra completamente el navegador si usas un equipo compartido.
                            </small>
                        </div>
                        
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.slim.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.min.js"></script>

</body>
</html>