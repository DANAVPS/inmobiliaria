<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Obtener parámetros
    String sidebarRol = request.getParameter("rol");
    String paginaActiva = request.getParameter("pagina");
    String contextPath = request.getContextPath();
    
    // Si no se pasa rol, obtener de la sesión
    if (sidebarRol == null) {
        sidebarRol = (String) session.getAttribute("usuario_rol");
    }
    
    // Definir título del panel según el rol
    String tituloPanel = "";
    String iconoPanel = "";
    
    if ("ADMINISTRADOR".equals(sidebarRol)) {
        tituloPanel = "Panel Admin";
        iconoPanel = "fas fa-user-shield";
    } else if ("INMOBILIARIA".equals(sidebarRol)) {
        tituloPanel = "Panel Inmobiliaria";
        iconoPanel = "fas fa-building";
    } else if ("CLIENTE".equals(sidebarRol)) {
        tituloPanel = "Panel Cliente";
        iconoPanel = "fas fa-user";
    } else {
        tituloPanel = "Panel Usuario";
        iconoPanel = "fas fa-user";
    }
%>

<div class="card shadow-sm">
    <div class="card-header text-white" style="background-color: var(--vino);">
        <h6 class="mb-0">
            <i class="<%= iconoPanel %> mr-2"></i><%= tituloPanel %>
        </h6>
    </div>
    <div class="list-group list-group-flush">
        
        <% if ("ADMINISTRADOR".equals(sidebarRol)) { %>
            <!-- Menú Administrador -->
            <a href="<%= contextPath %>/pages/admin/index.jsp" 
               class="list-group-item list-group-item-action <%= "dashboard".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
            </a>
            <a href="<%= contextPath %>/pages/admin/usuarios.jsp" 
               class="list-group-item list-group-item-action <%= "usuarios".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-users mr-2"></i>Usuarios
            </a>
            <a href="<%= contextPath %>/pages/properties/propiedades.jsp" 
               class="list-group-item list-group-item-action <%= "propiedades".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-building mr-2"></i>Propiedades
            </a>
            <a href="<%= contextPath %>/pages/admin/reportes.jsp" 
               class="list-group-item list-group-item-action <%= "reportes".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-chart-bar mr-2"></i>Reportes
            </a>
            <a href="<%= contextPath %>/pages/admin/configuracion.jsp" 
               class="list-group-item list-group-item-action <%= "configuracion".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-cog mr-2"></i>Configuración
            </a>
            
        <% } else if ("INMOBILIARIA".equals(sidebarRol)) { %>
            <!-- Menú Inmobiliaria -->
            <a href="<%= contextPath %>/pages/inmobiliaria/index.jsp" 
               class="list-group-item list-group-item-action <%= "dashboard".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-tachometer-alt mr-2"></i>Dashboard
            </a>
            <a href="<%= contextPath %>/pages/inmobiliaria/misPropiedades.jsp" 
               class="list-group-item list-group-item-action <%= "propiedades".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-building mr-2"></i>Mis Propiedades
            </a>
            <a href="<%= contextPath %>/pages/properties/nuevaPropiedad.jsp" 
               class="list-group-item list-group-item-action <%= "nueva-propiedad".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-plus mr-2"></i>Agregar Propiedad
            </a>
            <a href="<%= contextPath %>/pages/inmobiliaria/solicitudes.jsp" 
               class="list-group-item list-group-item-action <%= "solicitudes".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-calendar-alt mr-2"></i>Solicitudes
            </a>
            <a href="<%= contextPath %>/pages/inmobiliaria/perfil.jsp" 
               class="list-group-item list-group-item-action <%= "perfil".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-user mr-2"></i>Mi Perfil
            </a>
            
        <% } else if ("CLIENTE".equals(sidebarRol)) { %>
            <!-- Menú Cliente -->
            <a href="<%= contextPath %>/pages/client/index.jsp" 
               class="list-group-item list-group-item-action <%= "dashboard".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-tachometer-alt mr-2"></i>Mi Panel
            </a>
            <a href="<%= contextPath %>/pages/properties/list-properties.jsp" 
               class="list-group-item list-group-item-action <%= "buscar".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-search mr-2"></i>Buscar Propiedades
            </a>
            <a href="<%= contextPath %>/pages/client/favoritos.jsp" 
               class="list-group-item list-group-item-action <%= "favoritos".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-heart mr-2"></i>Mis Favoritos
            </a>
            <a href="<%= contextPath %>/pages/citas/citas.jsp" 
               class="list-group-item list-group-item-action <%= "citas".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-calendar mr-2"></i>Mis Citas
            </a>
            <a href="<%= contextPath %>/pages/client/perfil.jsp" 
               class="list-group-item list-group-item-action <%= "perfil".equals(paginaActiva) ? "active" : "" %>">
                <i class="fas fa-user mr-2"></i>Mi Perfil
            </a>
            
        <% } else { %>
            <!-- Menú Usuario básico -->
            <a href="<%= contextPath %>/index.jsp" 
               class="list-group-item list-group-item-action">
                <i class="fas fa-home mr-2"></i>Inicio
            </a>
            <a href="<%= contextPath %>/pages/properties/list-properties.jsp" 
               class="list-group-item list-group-item-action">
                <i class="fas fa-building mr-2"></i>Propiedades
            </a>
        <% } %>
        
        <!-- Separador -->
        <div class="list-group-item p-0">
            <hr class="my-0">
        </div>
        
        <!-- Cerrar Sesión -->
        <a href="<%= contextPath %>/pages/auth/logout.jsp" 
           class="list-group-item list-group-item-action text-danger">
            <i class="fas fa-sign-out-alt mr-2"></i>Cerrar Sesión
        </a>
    </div>
</div>

<!-- Estilos del sidebar -->
<style>
.list-group-item.active {
    background-color: var(--vino) !important;
    border-color: var(--vino) !important;
    color: white !important;
}

.list-group-item.active i {
    color: white !important;
}

.list-group-item:hover:not(.active) {
    background-color: #f8f9fa;
}

.list-group-item.text-danger:hover {
    background-color: #f8d7da;
    color: #f8f9fa !important;
}
</style>