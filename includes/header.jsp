<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${param.title != null ? param.title : 'Inmobiliaria J de la Espriella'}</title>
    
    <!-- Bootstrap 4.6 CSS -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/css/bootstrap.min.css">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    
    <!-- CSS personalizado según la página -->
    <% String currentPage = request.getRequestURI();
       String contextPath = request.getContextPath();
       String cssFile = "style.css"; // CSS por defecto
        if (currentPage.contains("admin/")) {
            cssFile = "admin.css";
        } else if (currentPage.contains("client/")) {
            cssFile = "client.css";
        } else if (currentPage.contains("auth/")) {
            cssFile = "auth.css";
        }else if (currentPage.contains("inmobiliaria/")) {
            cssFile = "inmobiliaria.css";
        }
    %>
    <link rel="stylesheet" href="<%= contextPath %>/assets/css/<%= cssFile %>">
    
    <!-- CSS adicional si se especifica -->
    <% if (request.getParameter("additionalCSS") != null) { %>
        <link rel="stylesheet" href="<%= contextPath %>/assets/css/<%= request.getParameter("additionalCSS") %>">
    <% } %>
</head>
<body>

<!-- Navbar dinámico según el usuario logueado -->
<nav class="navbar navbar-expand-lg navbar-light bg-light py-3 shadow-sm">
    <div class="container">
        <a class="navbar-brand font-weight-bold text-uppercase text-dark" href="<%= contextPath %>/">
            <i class="fas fa-home mr-2"></i>J DE LA ESPRIELLA
        </a>
        
        <!-- Botón hamburguesa para móvil -->
        <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav mr-auto">
                <li class="nav-item">
                    <a class="nav-link" href="<%= contextPath %>/">Inicio</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= contextPath %>/pages/properties/list-properties.jsp">Propiedades</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= contextPath %>/pages/common/about.jsp">Nosotros</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link" href="<%= contextPath %>/pages/common/contact.jsp">Contacto</a>
                </li>
            </ul>
            
            <!-- Menú derecho - dinámico según sesión -->
            <div class="ml-auto">
                <%
                    String usuario = (String) session.getAttribute("usuario_nombre");
                    String rol = (String) session.getAttribute("usuario_rol");
                    
                    if (usuario != null) {
                        // Usuario logueado - mostrar menú según rol
                %>
                    <div class="dropdown">
                        <button class="btn btn-outline-primary dropdown-toggle" type="button" data-toggle="dropdown">
                            <i class="fas fa-user mr-1"></i><%= usuario %>
                        </button>
                        <div class="dropdown-menu">
                            <%
                                if ("ADMINISTRADOR".equals(rol)) {
                            %>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/admin/index.jsp">
                                    <i class="fas fa-tachometer-alt mr-2"></i>Dashboard Admin
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/admin/usuarios.jsp">
                                    <i class="fas fa-users mr-2"></i>Usuarios
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/properties/propiedades.jsp">
                                    <i class="fas fa-building mr-2"></i>Propiedades
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/admin/reportes.jsp">
                                    <i class="fas fa-chart-bar mr-2"></i>Reportes
                                </a>
                            <%
                                } else if ("CLIENTE".equals(rol)) {
                            %>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/client/index.jsp">
                                    <i class="fas fa-tachometer-alt mr-2"></i>Mi Dashboard
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/client/perfil.jsp">
                                    <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/appointments/list-appointments.jsp">
                                    <i class="fas fa-calendar mr-2"></i>Mis Citas
                                </a>
                            <%
                                } else if ("INMOBILIARIA".equals(rol)) {
                            %>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/inmobiliaria/index.jsp">
                                    <i class="fas fa-tachometer-alt mr-2"></i>Mi Dashboard
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/inmobiliaria/misPropiedades.jsp">
                                    <i class="fas fa-building mr-2"></i>Mis Propiedades
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/inmobiliaria/solicitudes.jsp">
                                    <i class="fas fa-envelope mr-2"></i>Solicitudes
                                </a>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/inmobiliaria/perfil.jsp">
                                    <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                                </a>
                            <%
                                } else if ("USUARIO".equals(rol)) {
                            %>
                                <a class="dropdown-item" href="<%= contextPath %>/pages/user/perfil.jsp">
                                    <i class="fas fa-user-edit mr-2"></i>Mi Perfil
                                </a>
                            <%
                                }
                            %>
                            <div class="dropdown-divider"></div>
                            <a class="dropdown-item" href="<%= contextPath %>/pages/auth/logout.jsp">
                                <i class="fas fa-sign-out-alt mr-2"></i>Cerrar Sesión
                            </a>
                        </div>
                    </div>
                <%
                    } else {
                        // Usuario no logueado - mostrar botones de login/registro
                %>
                    <a href="<%= contextPath %>/pages/properties/list-properties.jsp" class="btn btn-outline-primary btn-sm mx-2">
                        <i class="fas fa-search mr-1"></i>Ver Propiedades
                    </a>
                    <a href="<%= contextPath %>/pages/auth/register.jsp" class="btn btn-outline-success btn-sm mx-1">
                        <i class="fas fa-user-plus mr-1"></i>Registrarse
                    </a>
                    <a href="<%= contextPath %>/pages/auth/login.jsp" class="btn btn-primary btn-sm">
                        <i class="fas fa-sign-in-alt mr-1"></i>Ingresar
                    </a>
                <%
                    }
                %>
            </div>
        </div>
    </div>
</nav>

<!-- Mensajes de alerta (si existen) -->
<%
    String mensaje = (String) session.getAttribute("mensaje");
    String tipoMensaje = (String) session.getAttribute("tipoMensaje");
    if (mensaje != null) {
        session.removeAttribute("mensaje");
        session.removeAttribute("tipoMensaje");
        String alertClass = "alert-info";
        if ("error".equals(tipoMensaje)) alertClass = "alert-danger";
        else if ("success".equals(tipoMensaje)) alertClass = "alert-success";
        else if ("warning".equals(tipoMensaje)) alertClass = "alert-warning";
%>
    <div class="container mt-3">
        <div class="alert <%= alertClass %> alert-dismissible fade show" role="alert">
            <%= mensaje %>
            <button type="button" class="close" data-dismiss="alert">
                <span>&times;</span>
            </button>
        </div>
    </div>
<%
    }
%>