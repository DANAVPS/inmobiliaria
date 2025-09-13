<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Verificar que el usuario esté logueado y sea administrador
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    
    if (usuarioId == null || !"ADMINISTRADOR".equals(usuarioRol)) {
        response.sendRedirect(request.getContextPath() + "/pages/auth/login.jsp");
        return;
    }
    
    // Variables para mensajes y configuraciones
    String mensaje = "";
    String tipoMensaje = "";
    Map<String, Map<String, Object>> configuraciones = new LinkedHashMap<>();
    
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
        
        // Procesar formulario si se envió
        if ("POST".equals(request.getMethod())) {
            String action = request.getParameter("action");
            
            if ("update".equals(action)) {
                // Actualizar configuraciones
                boolean actualizacionExitosa = true;
                StringBuilder errores = new StringBuilder();
                
                // Obtener todas las configuraciones del formulario
                Enumeration<String> paramNames = request.getParameterNames();
                while (paramNames.hasMoreElements()) {
                    String paramName = paramNames.nextElement();
                    if (paramName.startsWith("config_")) {
                        String clave = paramName.substring(7); // Remover "config_" del inicio
                        String valor = request.getParameter(paramName);
                        
                        try {
                            // Validaciones específicas
                            if ("propiedades_por_pagina".equals(clave) || "max_imagenes_propiedad".equals(clave)) {
                                int valorNumerico = Integer.parseInt(valor);
                                if (valorNumerico < 1) {
                                    errores.append("El valor para ").append(clave).append(" debe ser mayor a 0. ");
                                    actualizacionExitosa = false;
                                    continue;
                                }
                            }
                            
                            // Actualizar en base de datos
                            String sqlUpdate = "UPDATE configuracion SET valor = ?, fecha_actualizacion = CURRENT_TIMESTAMP WHERE clave = ?";
                            stmt = conn.prepareStatement(sqlUpdate);
                            stmt.setString(1, valor);
                            stmt.setString(2, clave);
                            
                            int rowsUpdated = stmt.executeUpdate();
                            if (rowsUpdated == 0) {
                                errores.append("No se pudo actualizar ").append(clave).append(". ");
                                actualizacionExitosa = false;
                            }
                            stmt.close();
                            
                        } catch (NumberFormatException e) {
                            errores.append("Valor inválido para ").append(clave).append(". ");
                            actualizacionExitosa = false;
                        } catch (SQLException e) {
                            errores.append("Error de base de datos para ").append(clave).append(": ").append(e.getMessage()).append(" ");
                            actualizacionExitosa = false;
                        }
                    }
                }
                
                if (actualizacionExitosa) {
                    mensaje = "Configuraciones actualizadas exitosamente.";
                    tipoMensaje = "success";
                } else {
                    mensaje = "Errores al actualizar configuraciones: " + errores.toString();
                    tipoMensaje = "error";
                }
            }
        }
        
        // Cargar configuraciones actuales
        String sqlConfiguraciones = "SELECT clave, valor, descripcion, fecha_actualizacion FROM configuracion ORDER BY clave";
        stmt = conn.prepareStatement(sqlConfiguraciones);
        rs = stmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> configItem  = new HashMap<>();
            configItem.put("valor", rs.getString("valor"));
            configItem.put("descripcion", rs.getString("descripcion"));
            configItem.put("fecha_actualizacion", rs.getTimestamp("fecha_actualizacion"));
            configuraciones.put(rs.getString("clave"), configItem);
        }
        rs.close();
        stmt.close();
        
    } catch (Exception e) {
        mensaje = "Error al cargar configuraciones: " + e.getMessage();
        tipoMensaje = "error";
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Configuración del Sistema - Admin" />
</jsp:include>

<div class="container-fluid mt-4">
    <div class="row">
        
        <!-- Sidebar -->
        <div class="col-md-3 col-lg-2">
            <jsp:include page="../../includes/sidebar.jsp">
                <jsp:param name="pagina" value="configuracion" />
            </jsp:include>
        </div>
        
        <!-- Contenido principal -->
        <div class="col-md-9 col-lg-10">
            
            <!-- Encabezado -->
            <div class="d-flex justify-content-between align-items-center mb-4">
                <div>
                    <h3 style="color: var(--vino);" class="font-weight-bold">
                        <i class="fas fa-cogs mr-2"></i>Configuración del Sistema
                    </h3>
                    <p class="text-muted mb-0">Gestiona las configuraciones generales de la plataforma inmobiliaria</p>
                </div>
                <div>
                    <button type="button" class="btn btn-info" data-toggle="modal" data-target="#modalAyuda">
                        <i class="fas fa-question-circle mr-1"></i>Ayuda
                    </button>
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
            
            <!-- Formulario de configuración -->
            <form method="POST" action="" id="formConfiguracion">
                <input type="hidden" name="action" value="update">
                
                <!-- Configuración de la empresa -->
                <div class="card shadow mb-4">
                    <div class="card-header text-white" style="background-color: var(--vino);">
                        <h6 class="mb-0">
                            <i class="fas fa-building mr-2"></i>Información de la Empresa
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="nombre_empresa" class="form-label font-weight-bold">Nombre de la Empresa</label>
                                <input type="text" class="form-control" id="nombre_empresa" name="config_nombre_empresa" 
                                       value="<%= configuraciones.get("nombre_empresa") != null ? configuraciones.get("nombre_empresa").get("valor") : "" %>" 
                                       required maxlength="100">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("nombre_empresa") != null ? configuraciones.get("nombre_empresa").get("descripcion") : "" %>
                                </small>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="email_contacto" class="form-label font-weight-bold">Email de Contacto</label>
                                <input type="email" class="form-control" id="email_contacto" name="config_email_contacto" 
                                       value="<%= configuraciones.get("email_contacto") != null ? configuraciones.get("email_contacto").get("valor") : "" %>" 
                                       required maxlength="150">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("email_contacto") != null ? configuraciones.get("email_contacto").get("descripcion") : "" %>
                                </small>
                            </div>
                        </div>
                        
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="telefono_contacto" class="form-label font-weight-bold">Teléfono de Contacto</label>
                                <input type="tel" class="form-control" id="telefono_contacto" name="config_telefono_contacto" 
                                       value="<%= configuraciones.get("telefono_contacto") != null ? configuraciones.get("telefono_contacto").get("valor") : "" %>" 
                                       maxlength="20">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("telefono_contacto") != null ? configuraciones.get("telefono_contacto").get("descripcion") : "" %>
                                </small>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="direccion_empresa" class="form-label font-weight-bold">Dirección de la Empresa</label>
                                <input type="text" class="form-control" id="direccion_empresa" name="config_direccion_empresa" 
                                       value="<%= configuraciones.get("direccion_empresa") != null ? configuraciones.get("direccion_empresa").get("valor") : "" %>" 
                                       maxlength="200">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("direccion_empresa") != null ? configuraciones.get("direccion_empresa").get("descripcion") : "" %>
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Configuración del sistema -->
                <div class="card shadow mb-4">
                    <div class="card-header text-white" style="background-color: var(--rojo);">
                        <h6 class="mb-0">
                            <i class="fas fa-server mr-2"></i>Configuración del Sistema
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-md-6 mb-3">
                                <label for="propiedades_por_pagina" class="form-label font-weight-bold">Propiedades por Página</label>
                                <input type="number" class="form-control" id="propiedades_por_pagina" name="config_propiedades_por_pagina" 
                                       value="<%= configuraciones.get("propiedades_por_pagina") != null ? configuraciones.get("propiedades_por_pagina").get("valor") : "12" %>" 
                                       required min="1" max="50">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("propiedades_por_pagina") != null ? configuraciones.get("propiedades_por_pagina").get("descripcion") : "" %>
                                </small>
                            </div>
                            <div class="col-md-6 mb-3">
                                <label for="max_imagenes_propiedad" class="form-label font-weight-bold">Máximo de Imágenes por Propiedad</label>
                                <input type="number" class="form-control" id="max_imagenes_propiedad" name="config_max_imagenes_propiedad" 
                                       value="<%= configuraciones.get("max_imagenes_propiedad") != null ? configuraciones.get("max_imagenes_propiedad").get("valor") : "10" %>" 
                                       required min="1" max="20">
                                <small class="form-text text-muted">
                                    <%= configuraciones.get("max_imagenes_propiedad") != null ? configuraciones.get("max_imagenes_propiedad").get("descripcion") : "" %>
                                </small>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Información del sistema -->
                <div class="card shadow mb-4">
                    <div class="card-header bg-info text-white">
                        <h6 class="mb-0">
                            <i class="fas fa-info-circle mr-2"></i>Información del Sistema
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <% if (!configuraciones.isEmpty()) { %>
                                <div class="col-md-6">
                                    <h6>Última Actualización de Configuraciones:</h6>
                                    <% 
                                    java.util.Date ultimaActualizacion = null;
                                    for (Map<String, Object> configData : configuraciones.values()) {
                                        java.util.Date fecha = (java.util.Date) configData.get("fecha_actualizacion");
                                        if (fecha != null && (ultimaActualizacion == null || fecha.after(ultimaActualizacion))) {
                                            ultimaActualizacion = fecha;
                                        }
                                    }
                                    %>
                                    <p class="text-muted">
                                        <%= ultimaActualizacion != null ? new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(ultimaActualizacion) : "No disponible" %>
                                    </p>
                                </div>
                            <% } %>
                            <div class="col-md-6">
                                <h6>Total de Configuraciones:</h6>
                                <p class="text-muted"><%= configuraciones.size() %> parámetros configurables</p>
                            </div>
                        </div>
                        
                        <div class="alert alert-warning mt-3">
                            <i class="fas fa-exclamation-triangle mr-2"></i>
                            <strong>Importante:</strong> Los cambios en la configuración afectarán el comportamiento general del sistema. 
                            Asegúrate de revisar cuidadosamente antes de guardar.
                        </div>
                    </div>
                </div>
                
                <!-- Botones de acción -->
                <div class="card shadow">
                    <div class="card-body text-center">
                        <button type="submit" class="btn btn-lg text-white mr-3" style="background-color: var(--vino);">
                            <i class="fas fa-save mr-2"></i>Guardar Configuraciones
                        </button>
                        <button type="reset" class="btn btn-lg btn-secondary mr-3">
                            <i class="fas fa-undo mr-2"></i>Restablecer
                        </button>
                        <a href="index.jsp" class="btn btn-lg btn-outline-primary">
                            <i class="fas fa-arrow-left mr-2"></i>Volver al Dashboard
                        </a>
                    </div>
                </div>
            </form>
            
        </div>
    </div>
</div>

<!-- Modal de Ayuda -->
<div class="modal fade" id="modalAyuda" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header" style="background-color: var(--vino); color: white;">
                <h5 class="modal-title">
                    <i class="fas fa-question-circle mr-2"></i>Ayuda - Configuración del Sistema
                </h5>
                <button type="button" class="close text-white" data-dismiss="modal">
                    <span>&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <h6 class="text-primary"><i class="fas fa-building mr-2"></i>Información de la Empresa</h6>
                <ul>
                    <li><strong>Nombre de la Empresa:</strong> Se muestra en toda la plataforma y comunicaciones.</li>
                    <li><strong>Email de Contacto:</strong> Email principal para contacto con clientes.</li>
                    <li><strong>Teléfono de Contacto:</strong> Número principal de la inmobiliaria.</li>
                    <li><strong>Dirección:</strong> Dirección física de la empresa.</li>
                </ul>
                
                <hr>
                
                <h6 class="text-success"><i class="fas fa-server mr-2"></i>Configuración del Sistema</h6>
                <ul>
                    <li><strong>Propiedades por Página:</strong> Cantidad de propiedades que se muestran en cada página de listado.</li>
                    <li><strong>Máximo de Imágenes:</strong> Número máximo de imágenes que se pueden subir por propiedad.</li>
                </ul>
                
                <hr>
                
                <div class="alert alert-info">
                    <i class="fas fa-lightbulb mr-2"></i>
                    <strong>Tip:</strong> Después de guardar cambios, algunas configuraciones pueden requerir 
                    que los usuarios actualicen sus páginas para ver los cambios reflejados.
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">Cerrar</button>
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

.alert-warning {
    border-left: 4px solid var(--amarillo);
}

.alert-info {
    border-left: 4px solid #17a2b8;
}
</style>

<!-- JavaScript para validación -->
<script>
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('formConfiguracion');
    
    // Validación del formulario
    form.addEventListener('submit', function(event) {
        let isValid = true;
        const inputs = form.querySelectorAll('input[required]');
        
        inputs.forEach(input => {
            if (!input.value.trim()) {
                input.classList.add('is-invalid');
                isValid = false;
            } else {
                input.classList.remove('is-invalid');
                input.classList.add('is-valid');
            }
        });
        
        // Validaciones específicas
        const propiedadesPorPagina = document.getElementById('propiedades_por_pagina');
        const maxImagenes = document.getElementById('max_imagenes_propiedad');
        
        if (parseInt(propiedadesPorPagina.value) < 1 || parseInt(propiedadesPorPagina.value) > 50) {
            propiedadesPorPagina.classList.add('is-invalid');
            isValid = false;
        }
        
        if (parseInt(maxImagenes.value) < 1 || parseInt(maxImagenes.value) > 20) {
            maxImagenes.classList.add('is-invalid');
            isValid = false;
        }
        
        if (!isValid) {
            event.preventDefault();
            alert('Por favor corrige los errores en el formulario antes de continuar.');
            return false;
        }
        
        // Confirmar antes de guardar
        if (!confirm('¿Estás seguro de que deseas actualizar la configuración del sistema?')) {
            event.preventDefault();
            return false;
        }
    });
    
    // Validación en tiempo real
    const inputs = form.querySelectorAll('input');
    inputs.forEach(input => {
        input.addEventListener('blur', function() {
            if (this.hasAttribute('required') && !this.value.trim()) {
                this.classList.add('is-invalid');
                this.classList.remove('is-valid');
            } else if (this.value.trim()) {
                this.classList.remove('is-invalid');
                this.classList.add('is-valid');
            }
        });
    });
    
    // Formatear teléfono
    const telefonoInput = document.getElementById('telefono_contacto');
    telefonoInput.addEventListener('input', function() {
        // Remover caracteres no numéricos excepto + y espacios
        this.value = this.value.replace(/[^+0-9\s-]/g, '');
    });
});
</script>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />