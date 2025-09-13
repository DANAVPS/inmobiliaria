<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.text.*" %>

<%
    // Verificar que el usuario esté logueado y sea inmobiliaria
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String nombreUsuario = (String) session.getAttribute("usuario_nombre");
    String apellidoUsuario = (String) session.getAttribute("usuario_apellido");
    
    if (usuarioId == null || !"INMOBILIARIA".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Obtener ID de la cita
    String citaIdParam = request.getParameter("id");
    if (citaIdParam == null || citaIdParam.trim().isEmpty()) {
        response.sendRedirect("solicitudes.jsp");
        return;
    }
    
    int citaId = 0;
    try {
        citaId = Integer.parseInt(citaIdParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("solicitudes.jsp");
        return;
    }
    
    // Variables para los datos de la solicitud
    Map<String, Object> solicitud = null;
    String mensaje = "";
    String tipoMensaje = "";
    
    // Manejar acciones (actualizar estado)
    String accion = request.getParameter("accion");
    if (accion != null) {
        Connection connAccion = null;
        PreparedStatement stmtAccion = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            connAccion = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            if ("actualizar_estado".equals(accion)) {
                String nuevoEstado = request.getParameter("nuevo_estado");
                String notas = request.getParameter("notas");
                
                // Verificar que la cita pertenece a una propiedad del usuario
                String sqlVerificar = "SELECT c.id_cita FROM citas c " +
                                     "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                                     "WHERE c.id_cita = ? AND p.id_propietario = ?";
                stmtAccion = connAccion.prepareStatement(sqlVerificar);
                stmtAccion.setInt(1, citaId);
                stmtAccion.setInt(2, usuarioId);
                ResultSet rsVerificar = stmtAccion.executeQuery();
                
                if (rsVerificar.next()) {
                    rsVerificar.close();
                    stmtAccion.close();
                    
                    String sqlActualizar = "UPDATE citas SET estado = ?, notas = ? WHERE id_cita = ?";
                    stmtAccion = connAccion.prepareStatement(sqlActualizar);
                    stmtAccion.setString(1, nuevoEstado);
                    stmtAccion.setString(2, notas != null && !notas.trim().isEmpty() ? notas.trim() : null);
                    stmtAccion.setInt(3, citaId);
                    
                    int resultado = stmtAccion.executeUpdate();
                    if (resultado > 0) {
                        String estadoTexto = "";
                        switch(nuevoEstado) {
                            case "CONFIRMADA": estadoTexto = "confirmada"; break;
                            case "REALIZADA": estadoTexto = "marcada como realizada"; break;
                            case "CANCELADA": estadoTexto = "cancelada"; break;
                            default: estadoTexto = "actualizada"; break;
                        }
                        mensaje = "Cita " + estadoTexto + " correctamente.";
                        tipoMensaje = "success";
                    } else {
                        mensaje = "Error al actualizar el estado de la cita.";
                        tipoMensaje = "error";
                    }
                } else {
                    mensaje = "No tienes permisos para modificar esta cita.";
                    tipoMensaje = "error";
                }
                rsVerificar.close();
            }
            
        } catch (Exception e) {
            mensaje = "Error al procesar la acción: " + e.getMessage();
            tipoMensaje = "error";
        } finally {
            if (stmtAccion != null) try { stmtAccion.close(); } catch (SQLException e) {}
            if (connAccion != null) try { connAccion.close(); } catch (SQLException e) {}
        }
    }
    
    // Cargar datos de la solicitud
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        String sqlSolicitud = "SELECT c.*, p.titulo as propiedad_titulo, p.descripcion as propiedad_descripcion, " +
                             "p.direccion, p.ciudad, p.departamento, p.precio, p.area_construida, " +
                             "p.habitaciones, p.banos, p.garajes, p.tipo_operacion, " +
                             "u.nombre as cliente_nombre, u.apellido as cliente_apellido, " +
                             "u.email as cliente_email, u.telefono as cliente_telefono, " +
                             "u.direccion as cliente_direccion, " +
                             "tp.nombre_tipo " +
                             "FROM citas c " +
                             "INNER JOIN propiedades p ON c.id_propiedad = p.id_propiedad " +
                             "INNER JOIN usuarios u ON c.id_cliente = u.id_usuario " +
                             "INNER JOIN tipos_propiedad tp ON p.id_tipo = tp.id_tipo " +
                             "WHERE c.id_cita = ? AND p.id_propietario = ?";
        
        stmt = conn.prepareStatement(sqlSolicitud);
        stmt.setInt(1, citaId);
        stmt.setInt(2, usuarioId);
        rs = stmt.executeQuery();
        
        if (rs.next()) {
            solicitud = new HashMap<>();
            solicitud.put("id_cita", rs.getInt("id_cita"));
            solicitud.put("id_propiedad", rs.getInt("id_propiedad"));
            solicitud.put("id_cliente", rs.getInt("id_cliente"));
            solicitud.put("fecha_cita", rs.getTimestamp("fecha_cita"));
            solicitud.put("estado", rs.getString("estado"));
            solicitud.put("notas", rs.getString("notas"));
            solicitud.put("telefono_contacto", rs.getString("telefono_contacto"));
            solicitud.put("fecha_solicitud", rs.getTimestamp("fecha_solicitud"));
            solicitud.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
            
            // Datos de la propiedad
            solicitud.put("propiedad_titulo", rs.getString("propiedad_titulo"));
            solicitud.put("propiedad_descripcion", rs.getString("propiedad_descripcion"));
            solicitud.put("direccion", rs.getString("direccion"));
            solicitud.put("ciudad", rs.getString("ciudad"));
            solicitud.put("departamento", rs.getString("departamento"));
            solicitud.put("precio", rs.getBigDecimal("precio"));
            solicitud.put("area_construida", rs.getBigDecimal("area_construida"));
            solicitud.put("habitaciones", rs.getInt("habitaciones"));
            solicitud.put("banos", rs.getInt("banos"));
            solicitud.put("garajes", rs.getInt("garajes"));
            solicitud.put("tipo_operacion", rs.getString("tipo_operacion"));
            solicitud.put("nombre_tipo", rs.getString("nombre_tipo"));
            
            // Datos del cliente
            solicitud.put("cliente_nombre", rs.getString("cliente_nombre"));
            solicitud.put("cliente_apellido", rs.getString("cliente_apellido"));
            solicitud.put("cliente_email", rs.getString("cliente_email"));
            solicitud.put("cliente_telefono", rs.getString("cliente_telefono"));
            solicitud.put("cliente_direccion", rs.getString("cliente_direccion"));
        }
        
    } catch (Exception e) {
        if (mensaje.isEmpty()) {
            mensaje = "Error al cargar la solicitud: " + e.getMessage();
            tipoMensaje = "error";
        }
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    
    // Si no se encontró la solicitud, redirigir
    if (solicitud == null) {
        response.sendRedirect("solicitudes.jsp");
        return;
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Detalle Solicitud - Inmobiliaria" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="solicitudes" />
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
                                        <i class="fas fa-eye mr-2"></i>Detalle de Solicitud #<%= solicitud.get("id_cita") %>
                                    </h2>
                                    <p class="text-muted mb-0">
                                        Información completa de la solicitud de cita
                                    </p>
                                </div>
                                <div class="col-md-4 text-md-right">
                                    <a href="solicitudes.jsp" class="btn btn-secondary">
                                        <i class="fas fa-arrow-left mr-2"></i>Volver a Solicitudes
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
            
            <!-- Estado de la solicitud -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-body text-center">
                            <% 
                                String estado = (String)solicitud.get("estado");
                                String badgeClass = "";
                                String icono = "";
                                String estadoTexto = "";
                                switch(estado) {
                                    case "PENDIENTE":
                                        badgeClass = "badge-warning";
                                        icono = "clock";
                                        estadoTexto = "PENDIENTE DE CONFIRMACIÓN";
                                        break;
                                    case "CONFIRMADA":
                                        badgeClass = "badge-success";
                                        icono = "check-circle";
                                        estadoTexto = "CONFIRMADA";
                                        break;
                                    case "REALIZADA":
                                        badgeClass = "badge-info";
                                        icono = "handshake";
                                        estadoTexto = "REALIZADA";
                                        break;
                                    case "CANCELADA":
                                        badgeClass = "badge-secondary";
                                        icono = "times-circle";
                                        estadoTexto = "CANCELADA";
                                        break;
                                }
                            %>
                            <h3 class="mb-3">Estado Actual</h3>
                            <span class="badge <%= badgeClass %> px-4 py-2" style="font-size: 1.2rem;">
                                <i class="fas fa-<%= icono %> mr-2"></i><%= estadoTexto %>
                            </span>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Información principal -->
            <div class="row">
                
                <!-- Información del Cliente -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header bg-primary text-white">
                            <h5 class="mb-0">
                                <i class="fas fa-user mr-2"></i>Información del Cliente
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row mb-3">
                                <div class="col-sm-4"><strong>Nombre:</strong></div>
                                <div class="col-sm-8"><%= solicitud.get("cliente_nombre") %> <%= solicitud.get("cliente_apellido") %></div>
                            </div>
                            <div class="row mb-3">
                                <div class="col-sm-4"><strong>Email:</strong></div>
                                <div class="col-sm-8"><%= solicitud.get("cliente_email") %></div>
                            </div>
                            <% if (solicitud.get("cliente_telefono") != null) { %>
                                <div class="row mb-3">
                                    <div class="col-sm-4"><strong>Teléfono:</strong></div>
                                    <div class="col-sm-8"><%= solicitud.get("cliente_telefono") %></div>
                                </div>
                            <% } %>
                            <% if (solicitud.get("telefono_contacto") != null && !solicitud.get("telefono_contacto").equals(solicitud.get("cliente_telefono"))) { %>
                                <div class="row mb-3">
                                    <div class="col-sm-4"><strong>Tel. Contacto:</strong></div>
                                    <div class="col-sm-8"><%= solicitud.get("telefono_contacto") %></div>
                                </div>
                            <% } %>
                            <% if (solicitud.get("cliente_direccion") != null) { %>
                                <div class="row mb-3">
                                    <div class="col-sm-4"><strong>Dirección:</strong></div>
                                    <div class="col-sm-8"><%= solicitud.get("cliente_direccion") %></div>
                                </div>
                            <% } %>
                            
                            <!-- Botones de contacto -->
                            <div class="mt-4">
                                <button type="button" class="btn btn-outline-primary btn-sm mr-2" onclick="contactarEmail()">
                                    <i class="fas fa-envelope mr-1"></i>Enviar Email
                                </button>
                                <% if (solicitud.get("cliente_telefono") != null) { %>
                                    <button type="button" class="btn btn-outline-success btn-sm" onclick="contactarTelefono()">
                                        <i class="fas fa-phone mr-1"></i>Llamar
                                    </button>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Información de la Cita -->
                <div class="col-lg-6 mb-4">
                    <div class="card shadow h-100">
                        <div class="card-header bg-success text-white">
                            <h5 class="mb-0">
                                <i class="fas fa-calendar-alt mr-2"></i>Información de la Cita
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row mb-3">
                                <div class="col-sm-4"><strong>Fecha:</strong></div>
                                <div class="col-sm-8">
                                    <%= new SimpleDateFormat("EEEE, dd 'de' MMMM 'de' yyyy", new Locale("es", "ES")).format((java.util.Date)solicitud.get("fecha_cita")) %>
                                </div>
                            </div>
                            <div class="row mb-3">
                                <div class="col-sm-4"><strong>Hora:</strong></div>
                                <div class="col-sm-8">
                                    <%= new SimpleDateFormat("HH:mm").format((java.util.Date)solicitud.get("fecha_cita")) %>
                                </div>
                            </div>
                            <div class="row mb-3">
                                <div class="col-sm-4"><strong>Solicitada:</strong></div>
                                <div class="col-sm-8">
                                    <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format((java.util.Date)solicitud.get("fecha_solicitud")) %>
                                </div>
                            </div>
                            <% if (solicitud.get("fecha_actualizacion") != null && !solicitud.get("fecha_actualizacion").equals(solicitud.get("fecha_solicitud"))) { %>
                                <div class="row mb-3">
                                    <div class="col-sm-4"><strong>Última actualización:</strong></div>
                                    <div class="col-sm-8">
                                        <%= new SimpleDateFormat("dd/MM/yyyy HH:mm").format((java.util.Date)solicitud.get("fecha_actualizacion")) %>
                                    </div>
                                </div>
                            <% } %>
                            <% if (solicitud.get("notas") != null && !((String)solicitud.get("notas")).trim().isEmpty()) { %>
                                <div class="row mb-3">
                                    <div class="col-sm-4"><strong>Notas:</strong></div>
                                    <div class="col-sm-8">
                                        <div class="border rounded p-2 bg-light">
                                            <%= solicitud.get("notas") %>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                        </div>
                    </div>
                </div>
                
            </div>
            
            <!-- Información de la Propiedad -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header bg-info text-white">
                            <h5 class="mb-0">
                                <i class="fas fa-home mr-2"></i>Información de la Propiedad
                            </h5>
                        </div>
                        <div class="card-body">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Título:</strong></div>
                                        <div class="col-sm-8"><%= solicitud.get("propiedad_titulo") %></div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Tipo:</strong></div>
                                        <div class="col-sm-8"><%= solicitud.get("nombre_tipo") %></div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Operación:</strong></div>
                                        <div class="col-sm-8">
                                            <span class="badge badge-primary"><%= solicitud.get("tipo_operacion") %></span>
                                        </div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Precio:</strong></div>
                                        <div class="col-sm-8">
                                            <strong class="text-success">
                                                $<%= String.format("%,.0f", ((java.math.BigDecimal)solicitud.get("precio")).doubleValue()) %>
                                            </strong>
                                        </div>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Dirección:</strong></div>
                                        <div class="col-sm-8"><%= solicitud.get("direccion") %></div>
                                    </div>
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Ciudad:</strong></div>
                                        <div class="col-sm-8"><%= solicitud.get("ciudad") %>, <%= solicitud.get("departamento") %></div>
                                    </div>
                                    <% if (solicitud.get("area_construida") != null) { %>
                                        <div class="row mb-3">
                                            <div class="col-sm-4"><strong>Área:</strong></div>
                                            <div class="col-sm-8"><%= solicitud.get("area_construida") %> m²</div>
                                        </div>
                                    <% } %>
                                    <div class="row mb-3">
                                        <div class="col-sm-4"><strong>Características:</strong></div>
                                        <div class="col-sm-8">
                                            <span class="badge badge-light mr-1"><%= solicitud.get("habitaciones") %> hab</span>
                                            <span class="badge badge-light mr-1"><%= solicitud.get("banos") %> baños</span>
                                            <span class="badge badge-light"><%= solicitud.get("garajes") %> garajes</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                            <% if (solicitud.get("propiedad_descripcion") != null && !((String)solicitud.get("propiedad_descripcion")).trim().isEmpty()) { %>
                                <div class="row mt-3">
                                    <div class="col-12">
                                        <strong>Descripción:</strong>
                                        <div class="border rounded p-3 bg-light mt-2">
                                            <%= solicitud.get("propiedad_descripcion") %>
                                        </div>
                                    </div>
                                </div>
                            <% } %>
                            
                            <!-- Enlace para ver la propiedad -->
                            <div class="mt-3">
                                <a href="../properties/verPropiedad.jsp?id=<%= solicitud.get("id_propiedad") %>" 
                                   class="btn btn-outline-info" target="_blank">
                                    <i class="fas fa-external-link-alt mr-1"></i>Ver Propiedad Completa
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Acciones -->
            <div class="row mb-4">
                <div class="col-12">
                    <div class="card shadow">
                        <div class="card-header bg-dark text-white">
                            <h5 class="mb-0">
                                <i class="fas fa-cogs mr-2"></i>Acciones
                            </h5>
                        </div>
                        <div class="card-body">
                            
                            <% if ("PENDIENTE".equals(estado)) { %>
                                <!-- Estados para PENDIENTE -->
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <form method="POST" action="verSolicitud.jsp">
                                            <input type="hidden" name="accion" value="actualizar_estado">
                                            <input type="hidden" name="id" value="<%= solicitud.get("id_cita") %>">
                                            <input type="hidden" name="nuevo_estado" value="CONFIRMADA">
                                            <button type="submit" class="btn btn-success btn-lg btn-block" 
                                                    onclick="return confirm('¿Confirmar esta cita?')">
                                                <i class="fas fa-check mr-2"></i>Confirmar Cita
                                            </button>
                                        </form>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <form method="POST" action="verSolicitud.jsp">
                                            <input type="hidden" name="accion" value="actualizar_estado">
                                            <input type="hidden" name="id" value="<%= solicitud.get("id_cita") %>">
                                            <input type="hidden" name="nuevo_estado" value="CANCELADA">
                                            <div class="form-group">
                                                <label for="notas">Motivo de cancelación (opcional):</label>
                                                <textarea class="form-control" name="notas" rows="2" 
                                                          placeholder="Motivo de la cancelación..."></textarea>
                                            </div>
                                            <button type="submit" class="btn btn-danger btn-lg btn-block" 
                                                    onclick="return confirm('¿Cancelar esta cita?')">
                                                <i class="fas fa-times mr-2"></i>Cancelar Cita
                                            </button>
                                        </form>
                                    </div>
                                </div>
                                
                            <% } else if ("CONFIRMADA".equals(estado)) { %>
                                <!-- Estados para CONFIRMADA -->
                                <div class="row">
                                    <div class="col-md-12 mb-3">
                                        <form method="POST" action="verSolicitud.jsp">
                                            <input type="hidden" name="accion" value="actualizar_estado">
                                            <input type="hidden" name="id" value="<%= solicitud.get("id_cita") %>">
                                            <input type="hidden" name="nuevo_estado" value="REALIZADA">
                                            <div class="form-group">
                                                <label for="notas">Notas de la visita (opcional):</label>
                                                <textarea class="form-control" name="notas" rows="3" 
                                                          placeholder="Comentarios sobre la visita realizada..."></textarea>
                                            </div>
                                            <button type="submit" class="btn btn-info btn-lg btn-block" 
                                                    onclick="return confirm('¿Marcar como realizada?')">
                                                <i class="fas fa-handshake mr-2"></i>Marcar como Realizada
                                            </button>
                                        </form>
                                    </div>
                                </div>
                                
                            <% } else { %>
                                <!-- Para estados REALIZADA y CANCELADA -->
                                <div class="text-center py-4">
                                    <% if ("REALIZADA".equals(estado)) { %>
                                        <i class="fas fa-check-circle fa-3x text-success mb-3"></i>
                                        <h4 class="text-success">Cita Realizada</h4>
                                        <p class="text-muted">Esta cita ya fue completada.</p>
                                    <% } else if ("CANCELADA".equals(estado)) { %>
                                        <i class="fas fa-times-circle fa-3x text-secondary mb-3"></i>
                                        <h4 class="text-secondary">Cita Cancelada</h4>
                                        <p class="text-muted">Esta cita fue cancelada.</p>
                                    <% } %>
                                </div>
                            <% } %>
                            
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

.btn:hover {
    transform: translateY(-1px);
    transition: transform 0.2s;
}

.badge {
    font-size: 0.9rem;
    padding: 0.5rem 0.7rem;
}

/* Estilos para badges de estado grandes */
.badge.px-4.py-2 {
    border-radius: 25px;
}

/* Cards con headers coloridos */
.card-header.bg-primary {
    background: linear-gradient(135deg, #007bff 0%, #0056b3 100%) !important;
}

.card-header.bg-success {
    background: linear-gradient(135deg, #28a745 0%, #1e7e34 100%) !important;
}

.card-header.bg-info {
    background: linear-gradient(135deg, #17a2b8 0%, #138496 100%) !important;
}

.card-header.bg-dark {
    background: linear-gradient(135deg, #343a40 0%, #23272b 100%) !important;
}

/* Efectos hover para las cards */
.h-100:hover {
    box-shadow: 0 1rem 3rem rgba(0,0,0,.175) !important;
}
