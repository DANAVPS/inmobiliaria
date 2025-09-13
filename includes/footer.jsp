<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String contextPath = request.getContextPath();
%>

<!-- Footer -->
<footer class="bg-dark text-white py-5">
    <div class="container">
        <div class="row">
            <!-- Información de la empresa -->
            <div class="col-md-4 mb-4">
                <h5 class="font-weight-bold mb-3">
                    <i class="fas fa-home mr-2"></i>J DE LA ESPRIELLA
                </h5>
                <p class="mb-2">
                    <i class="fas fa-envelope mr-2"></i>
                    <a href="mailto:jdelasp@unsitiogenial.es" class="text-light">jdelasp@unsitiogenial.es</a>
                </p>
                <p class="mb-2">
                    <i class="fas fa-phone mr-2"></i>
                    <a href="tel:+571234567890" class="text-light">(+57) 123 4567890</a>
                </p>
                <p class="mb-0">
                    <small>Más de 20 años conectando personas con sus hogares ideales.</small>
                </p>
            </div>
            
            <!-- Información de contacto -->
            <div class="col-md-4 mb-4">
                <h6 class="font-weight-bold mb-3">Información de Contacto</h6>
                <p class="mb-2">
                    <i class="fas fa-map-marker-alt mr-2"></i>
                    <strong>Dirección:</strong><br>
                    Calle Vista Alegre, 13<br>
                    Valencia, C.P. 10445
                </p>
                <p class="mb-2">
                    <i class="fas fa-clock mr-2"></i>
                    <strong>Horarios:</strong><br>
                    Lun - Vie: 8:00 AM - 6:00 PM<br>
                    Sáb: 9:00 AM - 2:00 PM
                </p>
            </div>
            
            <!-- Enlaces útiles -->
            <div class="col-md-4 mb-4">
                <h6 class="font-weight-bold mb-3">Enlaces Útiles</h6>
                <ul class="list-unstyled">
                    <li class="mb-2">
                        <a href="<%= contextPath %>/" class="text-light">
                            <i class="fas fa-home mr-2"></i>Inicio
                        </a>
                    </li>
                    <li class="mb-2">
                        <a href="<%= contextPath %>/pages/properties/list-properties.jsp" class="text-light">
                            <i class="fas fa-building mr-2"></i>Propiedades
                        </a>
                    </li>
                    <li class="mb-2">
                        <a href="<%= contextPath %>/pages/common/about.jsp" class="text-light">
                            <i class="fas fa-info-circle mr-2"></i>Sobre Nosotros
                        </a>
                    </li>
                    <li class="mb-2">
                        <a href="<%= contextPath %>/pages/common/contact.jsp" class="text-light">
                            <i class="fas fa-envelope mr-2"></i>Contacto
                        </a>
                    </li>
                    <%
                        String usuario = (String) session.getAttribute("usuario_nombre");
                        if (usuario == null) {
                    %>
                    <li class="mb-2">
                        <a href="<%= contextPath %>/pages/auth/register.jsp" class="text-light">
                            <i class="fas fa-user-plus mr-2"></i>Registrarse
                        </a>
                    </li>
                    <li class="mb-2">
                        <a href="<%= contextPath %>/pages/auth/login.jsp" class="text-light">
                            <i class="fas fa-sign-in-alt mr-2"></i>Iniciar Sesión
                        </a>
                    </li>
                    <%
                        }
                    %>
                </ul>
                
                <!-- Redes sociales -->
                <div class="mt-3">
                    <h6 class="font-weight-bold mb-2">Síguenos:</h6>
                    <a href="#" class="text-white mr-3" title="Facebook">
                        <i class="fab fa-facebook-f fa-lg"></i>
                    </a>
                    <a href="#" class="text-white mr-3" title="Instagram">
                        <i class="fab fa-instagram fa-lg"></i>
                    </a>
                    <a href="#" class="text-white mr-3" title="Twitter">
                        <i class="fab fa-twitter fa-lg"></i>
                    </a>
                    <a href="#" class="text-white" title="LinkedIn">
                        <i class="fab fa-linkedin fa-lg"></i>
                    </a>
                </div>
            </div>
        </div>
        
        <!-- Línea separadora -->
        <hr class="border-light my-4">
        
        <!-- Copyright y enlaces legales -->
        <div class="row align-items-center">
            <div class="col-md-8">
                <p class="mb-0">
                    <small>
                        © 2025 Inmobiliaria J de la Espriella. Todos los derechos reservados.
                        | Desarrollado por Dana Valentina Pacheco Sandoval - UTS
                    </small>
                </p>
            </div>
            <div class="col-md-4 text-md-right">
                <small>
                    <a href="#" class="text-light mr-2">Política de Privacidad</a> |
                    <a href="#" class="text-light ml-2">Términos de Uso</a>
                </small>
            </div>
        </div>
    </div>
</footer>

<!-- Scripts de Bootstrap -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.5.1/jquery.slim.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.16.1/umd/popper.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/4.6.0/js/bootstrap.min.js"></script>

</body>
</html>