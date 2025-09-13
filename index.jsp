<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    List<String> ciudades = new ArrayList<>();
    String ciudadFiltro = request.getParameter("ciudad");
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Cargar ciudades disponibles para filtros
        String sqlCiudades = "SELECT DISTINCT ciudad FROM propiedades WHERE disponible = 1 ORDER BY ciudad";
        stmt = conn.prepareStatement(sqlCiudades);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            ciudades.add(rs.getString("ciudad"));
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!-- Incluir header -->
<jsp:include page="includes/header.jsp">
    <jsp:param name="title" value="Inmobiliaria J de la Espriella - Inicio" />
</jsp:include>

<!-- Hero con buscador -->
<section class="hero d-flex align-items-center text-blue">
    <div class="container text-center">
        <h1 class="display-4 font-weight-bold">Haciendo realidad <br> casas soñadas.</h1>
        <p class="lead">Encuentra la propiedad perfecta para ti</p>
        
        <!-- Formulario de búsqueda adaptado a la BD -->
        <form action="pages/properties/list-properties.jsp" method="get" class="bg-light p-4 rounded mt-4">
            <div class="form-row">
                <div class="col-lg-3 col-md-6 mb-2">
                    <select class="form-control form-control-sm" name="ciudad">
                        <option value="">Todas las ciudades</option>
                        <% for (String ciudad : ciudades) { %>
                            <option value="<%= ciudad %>" <%= (ciudadFiltro != null && ciudad.equals(ciudadFiltro)) ? "selected" : "" %>>
                                <%= ciudad %>
                            </option>
                        <% } %>
                    </select>
                </div>
                <div class="col-lg-2 col-md-6 mb-2">
                    <input type="number" name="precio_min" class="form-control" placeholder="Precio mín." 
                           value="<%= request.getParameter("precio_min") != null ? request.getParameter("precio_min") : "" %>">
                </div>
                <div class="col-lg-2 col-md-6 mb-2">
                    <input type="number" name="precio_max" class="form-control" placeholder="Precio máx." 
                           value="<%= request.getParameter("precio_max") != null ? request.getParameter("precio_max") : "" %>">
                </div>
                <div class="col-lg-3 col-md-6 mb-2">
                    <select name="tipo" class="form-control">
                        <option value="">Tipo de propiedad</option>
                        <option value="1" <%= "1".equals(request.getParameter("tipo")) ? "selected" : "" %>>Casa</option>
                        <option value="2" <%= "2".equals(request.getParameter("tipo")) ? "selected" : "" %>>Apartamento</option>
                        <option value="3" <%= "3".equals(request.getParameter("tipo")) ? "selected" : "" %>>Terreno</option>
                        <option value="4" <%= "4".equals(request.getParameter("tipo")) ? "selected" : "" %>>Local Comercial</option>
                        <option value="5" <%= "5".equals(request.getParameter("tipo")) ? "selected" : "" %>>Oficina</option>
                        <option value="6" <%= "6".equals(request.getParameter("tipo")) ? "selected" : "" %>>Bodega</option>
                    </select>
                </div>
                <div class="col-lg-2 col-md-12 mb-2">
                    <button type="submit" class="btn btn-primary btn-block">
                        <i class="fas fa-search mr-1"></i>Buscar
                    </button>
                </div>
            </div>
        
            <!-- Filtros adicionales -->
            <div class="form-row mt-2">
                <div class="col-md-3 mb-2">
                    <select name="habitaciones" class="form-control">
                        <option value="">Habitaciones</option>
                        <option value="1" <%= "1".equals(request.getParameter("habitaciones")) ? "selected" : "" %>>1+</option>
                        <option value="2" <%= "2".equals(request.getParameter("habitaciones")) ? "selected" : "" %>>2+</option>
                        <option value="3" <%= "3".equals(request.getParameter("habitaciones")) ? "selected" : "" %>>3+</option>
                        <option value="4" <%= "4".equals(request.getParameter("habitaciones")) ? "selected" : "" %>>4+</option>
                    </select>
                </div>
                <div class="col-md-3 mb-2">
                    <select name="operacion" class="form-control">
                        <option value="">Venta o Arriendo</option>
                        <option value="VENTA" <%= "VENTA".equals(request.getParameter("operacion")) ? "selected" : "" %>>Venta</option>
                        <option value="ARRIENDO" <%= "ARRIENDO".equals(request.getParameter("operacion")) ? "selected" : "" %>>Arriendo</option>
                        <option value="VENTA_ARRIENDO" <%= "VENTA_ARRIENDO".equals(request.getParameter("operacion")) ? "selected" : "" %>>Venta/Arriendo</option>
                    </select>
                </div>
            </div>
        </form>
    </div>
</section>

<!-- Sobre nosotros -->
<section class="py-5 text-center">
    <div class="container">
        <h6 class="text-uppercase text-muted">Sobre nosotros</h6>
        <p class="lead mt-3">
            J De La Espriella ha estado vendiendo y comprando casas durante más de 20 años.
            Estamos orgullosos de ser una de las inmobiliarias más importantes de la región.
        </p>
        <div class="row mt-4">
            <div class="col-md-4">
                <h2 class="text-primary font-weight-bold">500+</h2>
                <p>Propiedades vendidas</p>
            </div>
            <div class="col-md-4">
                <h2 class="text-primary font-weight-bold">20+</h2>
                <p>Años de experiencia</p>
            </div>
            <div class="col-md-4">
                <h2 class="text-primary font-weight-bold">1000+</h2>
                <p>Clientes satisfechos</p>
            </div>
        </div>
    </div>
</section>

<!-- Propiedades destacadas -->

<!-- Servicios inmobiliarios -->
<section class="py-5">
    <div class="container text-center">
        <h4 class="mb-5">Servicios Inmobiliarios</h4>
        <div class="row">
            <div class="col-md-4 mb-4">
                <div class="service-item p-3">
                    <i class="fas fa-home fa-3x mb-3 text-primary"></i>
                    <h6>Compra de Propiedades</h6>
                    <p>¿Estás buscando tu hogar ideal? Tenemos justo lo que necesitas con las mejores opciones del mercado.</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="service-item p-3">
                    <i class="fas fa-sign fa-3x mb-3 text-primary"></i>
                    <h6>Venta de Propiedades</h6>
                    <p>Te ayudamos a vender tu propiedad de manera rápida y segura, con el mejor precio del mercado.</p>
                </div>
            </div>
            <div class="col-md-4 mb-4">
                <div class="service-item p-3">
                    <i class="fas fa-map-marker-alt fa-3x mb-3 text-primary"></i>
                    <h6>Asesoría Especializada</h6>
                    <p>Si te mudas de ciudad o necesitas asesoría, hacemos el proceso más fácil y confiable.</p>
                </div>
            </div>
        </div>
        
        <!-- Llamada a la acción -->
        <div class="row mt-5">
            <div class="col-12">
                <div class="bg-primary text-white p-4 rounded">
                    <h5 class="mb-3">¿Listo para encontrar tu propiedad ideal?</h5>
                    <p class="mb-3">Únete a miles de personas que ya han encontrado su hogar con nosotros</p>
                    <a href="pages/properties/list-properties.jsp" class="btn btn-light btn-lg mr-2">
                        <i class="fas fa-search mr-1"></i>Explorar Propiedades
                    </a>
                    <a href="pages/auth/register.jsp" class="btn btn-outline-light btn-lg">
                        <i class="fas fa-user-plus mr-1"></i>Registrarse Gratis
                    </a>
                </div>
            </div>
        </div>
    </div>
</section>

<!-- Incluir footer -->
<jsp:include page="includes/footer.jsp" />