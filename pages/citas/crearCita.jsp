<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea cliente
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null || !"CLIENTE".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID de la propiedad (puede venir como parámetro)
    String propiedadParam = request.getParameter("propiedad");
    
    // Variables para datos
    Map<String, Object> propiedadSeleccionada = null;
    List<Map<String, Object>> propiedadesDisponibles = new ArrayList<>();
    String mensaje = "";
    String tipoMensaje = "";
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    // Conexión a la base de datos
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar formulario si se envió
        if ("POST".equals(request.getMethod())) {
            String propiedadId = request.getParameter("id_propiedad");
            String fechaCitaStr = request.getParameter("fecha_cita");
            String horaCitaStr = request.getParameter("hora_cita");
            String telefonoContacto = request.getParameter("telefono_contacto");
            String notas = request.getParameter("notas");
            
            // Validaciones básicas
            if (propiedadId == null || propiedadId.trim().isEmpty()) {
                mensaje = "Debe seleccionar una propiedad.";
                tipoMensaje = "error";
            } else if (fechaCitaStr == null || fechaCitaStr.trim().isEmpty()) {
                mensaje = "La fecha de la cita es obligatoria.";
                tipoMensaje = "error";
            } else if (horaCitaStr == null || horaCitaStr.trim().isEmpty()) {
                mensaje = "La hora de la cita es obligatoria.";
                tipoMensaje = "error";
            } else {
                try {
                    // Combinar fecha y hora
                    String fechaHoraCompleta = fechaCitaStr + " " + horaCitaStr + ":00";
                    Timestamp fechaCita = Timestamp.valueOf(fechaHoraCompleta);
                    
                    // Validar que la fecha no sea en el pasado
                    if (fechaCita.before(new Timestamp(System.currentTimeMillis()))) {
                        mensaje = "No puedes programar una cita en el pasado.";
                        tipoMensaje = "error";
                    } else {
                        // Verificar que la propiedad existe y está disponible
                        String sqlVerificar = "SELECT titulo FROM propiedades WHERE id_propiedad = ? AND disponible = 1";
                        stmt = conn.prepareStatement(sqlVerificar);
                        stmt.setInt(1, Integer.parseInt(propiedadId));
                        rs = stmt.executeQuery();
                        
                        if (!rs.next()) {
                            mensaje = "La propiedad seleccionada no está disponible.";
                            tipoMensaje = "error";
                        } else {
                            rs.close();
                            stmt.close();
                            
                            // Verificar que no exista ya una cita para la misma propiedad, cliente y fecha/hora
                            String sqlDuplicada = "SELECT id_cita FROM citas WHERE id_cliente = ? AND id_propiedad = ? " +
                                                 "AND fecha_cita = ? AND estado IN ('PENDIENTE', 'CONFIRMADA')";
                            stmt = conn.prepareStatement(sqlDuplicada);
                            stmt.setInt(1, usuarioId);
                            stmt.setInt(2, Integer.parseInt(propiedadId));
                            stmt.setTimestamp(3, fechaCita);
                            rs = stmt.executeQuery();
                            
                            if (rs.next()) {
                                mensaje = "Ya tienes una cita programada para esta propiedad en esa fecha y hora.";
                                tipoMensaje = "error";
                            } else {
                                rs.close();
                                stmt.close();
                                
                                // Insertar la nueva cita
                                String sqlInsert = "INSERT INTO citas (id_propiedad, id_cliente, fecha_cita, estado, " +
                                                 "telefono_contacto, notas, fecha_solicitud) VALUES (?, ?, ?, 'PENDIENTE', ?, ?, CURRENT_TIMESTAMP)";
                                
                                stmt = conn.prepareStatement(sqlInsert);
                                stmt.setInt(1, Integer.parseInt(propiedadId));
                                stmt.setInt(2, usuarioId);
                                stmt.setTimestamp(3, fechaCita);
                                stmt.setString(4, telefonoContacto != null && !telefonoContacto.trim().isEmpty() ? telefonoContacto.trim() : null);
                                stmt.setString(5, notas != null && !notas.trim().isEmpty() ? notas.trim() : null);
                                
                                int rowsInserted = stmt.executeUpdate();
                                
                                if (rowsInserted > 0) {
                                    mensaje = "¡Cita solicitada exitosamente! El propietario será notificado y te contactará para confirmar.";
                                    tipoMensaje = "success";
                                    
                                    // Limpiar formulario después del éxito
                                    propiedadParam = null;
                                } else {
                                    mensaje = "Error al crear la cita. Inténtalo nuevamente.";
                                    tipoMensaje = "error";
                                }
                                stmt.close();
                            }
                        }
                    }
                    
                } catch (IllegalArgumentException e) {
                    mensaje = "Formato de fecha u hora inválido.";
                    tipoMensaje = "error";
                } catch (Exception e) {
                    mensaje = "Error al procesar la solicitud: " + e.getMessage();
                    tipoMensaje = "error";
                }
            }
        }
        
        // Si hay una propiedad específica, cargar sus datos
        if (propiedadParam != null && !propiedadParam.trim().isEmpty() && 
            !"null".equals(propiedadParam) && !"undefined".equals(propiedadParam)) {
            
            try {
                int propiedadId = Integer.parseInt(propiedadParam);
                
                String sqlPropiedad = "SELECT p.*, tp.nombre_tipo " +
                                     "FROM propiedades p " +
                                     "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                                     "WHERE p.id_propiedad = ? AND p.disponible = 1";
                
                stmt = conn.prepareStatement(sqlPropiedad);
                stmt.setInt(1, propiedadId);
                rs = stmt.executeQuery();
                
                if (rs.next()) {
                    propiedadSeleccionada = new HashMap<>();
                    propiedadSeleccionada.put("id", rs.getInt("id_propiedad"));
                    propiedadSeleccionada.put("titulo", rs.getString("titulo"));
                    propiedadSeleccionada.put("direccion", rs.getString("direccion"));
                    propiedadSeleccionada.put("ciudad", rs.getString("ciudad"));
                    propiedadSeleccionada.put("precio", rs.getLong("precio"));
                    propiedadSeleccionada.put("nombre_tipo", rs.getString("nombre_tipo"));
                    propiedadSeleccionada.put("imagen_principal", rs.getString("imagen_principal"));
                    propiedadSeleccionada.put("tipo_operacion", rs.getString("tipo_operacion"));
                }
                rs.close();
                stmt.close();
                
            } catch (NumberFormatException e) {
                // Si el ID no es un número válido, ignorar el parámetro
                propiedadParam = null;
                mensaje = "El ID de la propiedad no es válido.";
                tipoMensaje = "error";
            } catch (SQLException e) {
                // Error de base de datos
                mensaje = "Error al cargar la propiedad: " + e.getMessage();
                tipoMensaje = "error";
            }
        }
    
        
        // Cargar todas las propiedades disponibles para el select
        String sqlPropiedades = "SELECT p.id_propiedad, p.titulo, p.direccion, p.ciudad, p.precio, tp.nombre_tipo " +
                               "FROM propiedades p " +
                               "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                               "WHERE p.disponible = 1 " +
                               "ORDER BY p.destacada DESC, p.fecha_publicacion DESC";
        
        stmt = conn.prepareStatement(sqlPropiedades);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> propiedad = new HashMap<>();
            propiedad.put("id", rs.getInt("id_propiedad"));
            propiedad.put("titulo", rs.getString("titulo"));
            propiedad.put("direccion", rs.getString("direccion"));
            propiedad.put("ciudad", rs.getString("ciudad"));
            propiedad.put("precio", rs.getLong("precio"));
            propiedad.put("nombre_tipo", rs.getString("nombre_tipo"));
            propiedadesDisponibles.add(propiedad);
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
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Solicitar Cita - Cliente" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="citas" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Navegación -->
            <nav aria-label="breadcrumb">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="../client/index.jsp">Dashboard</a></li>
                    <li class="breadcrumb-item"><a href="../client/citas.jsp">Mis Citas</a></li>
                    <li class="breadcrumb-item active">Solicitar Cita</li>
                </ol>
            </nav>
            
            <!-- Encabezado -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-8">
                                    <h3 class="mb-1" style="color: var(--vino);">
                                        <i class="fas fa-calendar-plus mr-2"></i>Solicitar Cita para Visita
                                    </h3>
                                    <p class="text-muted mb-0">
                                        Programa una cita para visitar la propiedad que te interesa
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="citas.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-1"></i>Volver a Mis Citas
                                    </a>
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
            
            <!-- Información de la propiedad seleccionada -->
            <% if (propiedadSeleccionada != null) { %>
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow border-left-success">
                        <div class="card-header bg-success text-white">
                            <h6 class="mb-0">
                                <i class="fas fa-home mr-2"></i>Propiedad Seleccionada
                            </h6>
                        </div>
                        <div class="card-body">
                            <div class="row align-items-center">
                                <div class="col-md-2">
                                    <% if (propiedadSeleccionada.get("imagen_principal") != null) { %>
                                        <img src="<%= request.getContextPath() %>/assets/uploads/properties/<%= propiedadSeleccionada.get("imagen_principal") %>" 
                                             alt="<%= propiedadSeleccionada.get("titulo") %>" 
                                             class="img-fluid rounded"
                                             onerror="this.src='<%= request.getContextPath() %>/assets/img/default-property.jpg'">
                                    <% } else { %>
                                        <img src="<%= request.getContextPath() %>/assets/img/default-property.jpg" 
                                             alt="Sin imagen" class="img-fluid rounded">
                                    <% } %>
                                </div>
                                <div class="col-md-7">
                                    <h5 class="mb-1"><%= propiedadSeleccionada.get("titulo") %></h5>
                                    <p class="text-muted mb-2">
                                        <i class="fas fa-map-marker-alt mr-1"></i>
                                        <%= propiedadSeleccionada.get("direccion") %>, <%= propiedadSeleccionada.get("ciudad") %>
                                    </p>
                                    <div>
                                        <span class="badge badge-info mr-2"><%= propiedadSeleccionada.get("nombre_tipo") %></span>
                                        <span class="badge badge-primary">
                                            <%= ((String)propiedadSeleccionada.get("tipo_operacion")).replace("_", "/") %>
                                        </span>
                                    </div>
                                </div>
                                <div class="col-md-3 text-right">
                                    <h4 class="text-success font-weight-bold">
                                        $<%= String.format("%,d", (Long)propiedadSeleccionada.get("precio")) %>
                                    </h4>
                                    <a href="../properties/verPropiedad.jsp?id=<%= propiedadSeleccionada.get("id") %>" 
                                       class="btn btn-sm btn-outline-primary">
                                        <i class="fas fa-eye mr-1"></i>Ver Detalles
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
            
            <!-- Formulario de solicitud de cita -->
            <div class="row">
                <div class="col-lg-8 mx-auto">
                    <div class="card shadow">
                        <div class="card-header text-white" style="background-color: var(--vino);">
                            <h6 class="mb-0">
                                <i class="fas fa-calendar-plus mr-2"></i>Datos de la Cita
                            </h6>
                        </div>
                        <div class="card-body">
                            <form method="POST" action="" id="formCita">
                                
                                <!-- Selección de propiedad -->
                                <div class="mb-4">
                                    <label for="id_propiedad" class="form-label font-weight-bold">Propiedad a Visitar *</label>
                                    <select class="form-control" id="id_propiedad" name="id_propiedad" required onchange="mostrarInfoPropiedad()">
                                        <option value="">Selecciona una propiedad</option>
                                        <% for (Map<String, Object> propiedad : propiedadesDisponibles) { %>
                                            <option value="<%= propiedad.get("id") %>" 
                                                    <%= propiedadSeleccionada != null && propiedad.get("id").equals(propiedadSeleccionada.get("id")) ? "selected" : "" %>
                                                    data-titulo="<%= propiedad.get("titulo") %>"
                                                    data-direccion="<%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %>"
                                                    data-precio="<%= String.format("%,d", (Long)propiedad.get("precio")) %>"
                                                    data-tipo="<%= propiedad.get("nombre_tipo") %>">
                                                <%= propiedad.get("titulo") %> - <%= propiedad.get("direccion") %>, <%= propiedad.get("ciudad") %> 
                                                ($<%= String.format("%,d", (Long)propiedad.get("precio")) %>)
                                            </option>
                                        <% } %>
                                    </select>
                                    <small class="form-text text-muted">
                                        Selecciona la propiedad que deseas visitar
                                    </small>
                                </div>
                                
                                <!-- Información del cliente -->
                                <div class="row mb-4">
                                    <div class="col-md-6">
                                        <label for="cliente_nombre" class="form-label font-weight-bold">Tu Nombre</label>
                                        <input type="text" class="form-control" id="cliente_nombre" 
                                               value="<%= nombreUsuario %> <%= apellidoUsuario %>" readonly>
                                    </div>
                                    <div class="col-md-6">
                                        <label for="telefono_contacto" class="form-label font-weight-bold">Teléfono de Contacto</label>
                                        <input type="tel" class="form-control" id="telefono_contacto" name="telefono_contacto" 
                                               maxlength="20" placeholder="Número donde te podemos contactar">
                                        <small class="form-text text-muted">Opcional - Teléfono para confirmación</small>
                                    </div>
                                </div>
                                
                                <!-- Fecha y hora de la cita -->
                                <div class="row mb-4">
                                    <div class="col-md-6">
                                        <label for="fecha_cita" class="form-label font-weight-bold">Fecha Preferida *</label>
                                        <input type="date" class="form-control" id="fecha_cita" name="fecha_cita" 
                                               required min="<%= new SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
                                        <small class="form-text text-muted">Selecciona el día que prefieres</small>
                                    </div>
                                    <div class="col-md-6">
                                        <label for="hora_cita" class="form-label font-weight-bold">Hora Preferida *</label>
                                        <select class="form-control" id="hora_cita" name="hora_cita" required>
                                            <option value="">Selecciona una hora</option>
                                            <option value="08:00">8:00 AM</option>
                                            <option value="09:00">9:00 AM</option>
                                            <option value="10:00">10:00 AM</option>
                                            <option value="11:00">11:00 AM</option>
                                            <option value="12:00">12:00 PM</option>
                                            <option value="14:00">2:00 PM</option>
                                            <option value="15:00">3:00 PM</option>
                                            <option value="16:00">4:00 PM</option>
                                            <option value="17:00">5:00 PM</option>
                                            <option value="18:00">6:00 PM</option>
                                        </select>
                                        <small class="form-text text-muted">Horario de atención: 8:00 AM - 6:00 PM</small>
                                    </div>
                                </div>
                                
                                <!-- Notas adicionales -->
                                <div class="mb-4">
                                    <label for="notas" class="form-label font-weight-bold">Notas Adicionales</label>
                                    <textarea class="form-control" id="notas" name="notas" rows="4" 
                                              maxlength="500" placeholder="Comentarios, preguntas específicas o solicitudes especiales..."></textarea>
                                    <small class="form-text text-muted">Máximo 500 caracteres - Opcional</small>
                                </div>
                                
                                <!-- Información importante -->
                                <div class="alert alert-info">
                                    <h6><i class="fas fa-info-circle mr-2"></i>Información Importante:</h6>
                                    <ul class="mb-0">
                                        <li>Tu solicitud será enviada al propietario de la propiedad</li>
                                        <li>Recibirás una confirmación por email una vez sea aprobada</li>
                                        <li>El propietario puede contactarte para coordinar detalles</li>
                                        <li>Puedes cancelar o reprogramar desde "Mis Citas"</li>
                                    </ul>
                                </div>
                                
                                <!-- Botones -->
                                <div class="text-center">
                                    <button type="submit" class="btn btn-lg text-white mr-3" style="background-color: var(--vino);">
                                        <i class="fas fa-calendar-check mr-2"></i>Solicitar Cita
                                    </button>
                                    <a href="../client/citas.jsp" class="btn btn-lg btn-secondary">
                                        <i class="fas fa-times mr-2"></i>Cancelar
                                    </a>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
            
        </div>
    </div>
</div>

<!-- Modal de confirmación -->
<div class="modal fade" id="modalConfirmacion" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--vino); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-calendar-check mr-2"></i>Confirmar Solicitud de Cita
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <p><strong>¿Confirmas que deseas solicitar esta cita?</strong></p>
                <div id="resumenCita"></div>
                <div class="alert alert-warning mt-3">
                    <i class="fas fa-exclamation-triangle mr-2"></i>
                    <small>Una vez enviada, el propietario será notificado y deberá aprobar tu solicitud.</small>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Revisar</button>
                <button type="button" class="btn text-white" style="background-color: var(--vino);" onclick="enviarFormulario()">
                    <i class="fas fa-paper-plane mr-1"></i>Enviar Solicitud
                </button>
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

.border-left-success {
    border-left: 0.25rem solid #28a745 !important;
}

.form-control:focus {
    border-color: var(--vino);
    box-shadow: 0 0 0 0.2rem rgba(114, 47, 55, 0.25);
}

.btn:focus, .btn.focus {
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

<!-- JavaScript -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formCita');
    
    // Validación del formulario
    form.addEventListener('submit', function(event) {
        event.preventDefault();
        
        // Validar campos requeridos
        const propiedad = document.getElementById('id_propiedad').value;
        const fecha = document.getElementById('fecha_cita').value;
        const hora = document.getElementById('hora_cita').value;
        
        if (!propiedad || !fecha || !hora) {
            alert('Por favor completa todos los campos obligatorios.');
            return false;
        }
        
        // Validar que la fecha no sea en el pasado
        const fechaSeleccionada = new Date(fecha);
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);
        
        if (fechaSeleccionada < hoy) {
            alert('No puedes seleccionar una fecha en el pasado.');
            return false;
        }
        
        // Mostrar modal de confirmación
        mostrarResumenCita();
        $('#modalConfirmacion').modal('show');
    });
    
    // Formatear teléfono
    const telefonoInput = document.getElementById('telefono_contacto');
    telefonoInput.addEventListener('input', function() {
        this.value = this.value.replace(/[^+0-9\s-]/g, '');
    });
    
    // Contador de caracteres para notas
    const notasTextarea = document.getElementById('notas');
    const maxLength = 500;
    
    notasTextarea.addEventListener('input', function() {
        const remaining = maxLength - this.value.length;
        const helpText = this.nextElementSibling;
        helpText.textContent = `${remaining} caracteres restantes`;
        
        if (remaining < 50) {
            helpText.style.color = '#dc3545';
        } else {
            helpText.style.color = '#6c757d';
        }
    });
});

function mostrarInfoPropiedad() {
    const select = document.getElementById('id_propiedad');
    const option = select.options[select.selectedIndex];
    
    if (option.value) {
        console.log('Propiedad seleccionada:', {
            titulo: option.dataset.titulo,
            direccion: option.dataset.direccion,
            precio: option.dataset.precio,
            tipo: option.dataset.tipo
        });
    }
}

function mostrarResumenCita() {
    const propiedad = document.getElementById('id_propiedad');
    const fecha = document.getElementById('fecha_cita').value;
    const hora = document.getElementById('hora_cita').value;
    const telefono = document.getElementById('telefono_contacto').value;
    const notas = document.getElementById('notas').value;
    
    const selectedOption = propiedad.options[propiedad.selectedIndex];
    
    // Formatear fecha
    const fechaObj = new Date(fecha);
    const fechaFormateada = fechaObj.toLocaleDateString('es-ES', {
        weekday: 'long',
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
    
    // Formatear hora
    const horaFormateada = new Date('2000-01-01T' + hora + ':00').toLocaleTimeString('es-ES', {
        hour: '2-digit',
        minute: '2-digit'
    });
    
    // Construir el resumen paso a paso para evitar conflictos con EL
    let resumen = '<div class="border rounded p-3">';
    resumen += '<p><strong>Propiedad:</strong> ' + selectedOption.dataset.titulo + '</p>';
    resumen += '<p><strong>Dirección:</strong> ' + selectedOption.dataset.direccion + '</p>';
    resumen += '<p><strong>Precio:</strong> $' + selectedOption.dataset.precio + '</p>';
    resumen += '<p><strong>Tipo:</strong> ' + selectedOption.dataset.tipo + '</p>';
    resumen += '<hr>';
    resumen += '<p><strong>Fecha:</strong> ' + fechaFormateada + '</p>';
    resumen += '<p><strong>Hora:</strong> ' + horaFormateada + '</p>';
    
    if (telefono && telefono.trim() !== '') {
        resumen += '<p><strong>Teléfono:</strong> ' + telefono + '</p>';
    }
    
    if (notas && notas.trim() !== '') {
        resumen += '<p><strong>Notas:</strong> ' + notas + '</p>';
    } else {
        resumen += '<p><em>Sin notas adicionales</em></p>';
    }
    
    resumen += '</div>';
    
    document.getElementById('resumenCita').innerHTML = resumen;
}

function enviarFormulario() {
    $('#modalConfirmacion').modal('hide');
    document.getElementById('formCita').submit();
}

// Validación en tiempo real
document.addEventListener('DOMContentLoaded', function() {
    const inputs = document.querySelectorAll('input[required], select[required]');
    
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
        
        input.addEventListener('input', function() {
            if (this.classList.contains('is-invalid') && this.value.trim()) {
                this.classList.remove('is-invalid');
                this.classList.add('is-valid');
            }
        });
    });
    
    // Validación específica para fecha
    const fechaInput = document.getElementById('fecha_cita');
    fechaInput.addEventListener('change', function() {
        const fechaSeleccionada = new Date(this.value);
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);
        
        if (fechaSeleccionada < hoy) {
            this.classList.add('is-invalid');
            this.setCustomValidity('No puedes seleccionar una fecha en el pasado');
        } else {
            this.classList.remove('is-invalid');
            this.classList.add('is-valid');
            this.setCustomValidity('');
        }
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />