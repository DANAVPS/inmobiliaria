<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    // Obtener parámetros
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String usuarioRol = (String) session.getAttribute("usuario_rol");
    String action = request.getParameter("action");
    String propiedadIdParam = request.getParameter("propiedadId");
    
    boolean success = false;
    String message = "";
    
    // Validar sesión y rol
    if (usuarioId == null || !"CLIENTE".equals(usuarioRol)) {
        message = "No tienes permisos para realizar esta acción";
    } else if (action == null || propiedadIdParam == null) {
        message = "Parámetros incompletos";
    } else {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            int propiedadId = Integer.parseInt(propiedadIdParam);
            
            if ("add".equals(action)) {
                // Verificar que la propiedad existe y está disponible
                stmt = conn.prepareStatement("SELECT disponible FROM propiedades WHERE id_propiedad = ?");
                stmt.setInt(1, propiedadId);
                rs = stmt.executeQuery();
                
                if (!rs.next()) {
                    message = "La propiedad no existe";
                } else if (!rs.getBoolean("disponible")) {
                    message = "La propiedad no está disponible";
                } else {
                    rs.close();
                    stmt.close();
                    
                    // Verificar si ya está en favoritos
                    stmt = conn.prepareStatement("SELECT COUNT(*) FROM favoritos WHERE id_usuario = ? AND id_propiedad = ?");
                    stmt.setInt(1, usuarioId);
                    stmt.setInt(2, propiedadId);
                    rs = stmt.executeQuery();
                    
                    if (rs.next() && rs.getInt(1) > 0) {
                        message = "La propiedad ya está en tus favoritos";
                        success = true; // No es error, pero no se agrega
                    } else {
                        rs.close();
                        stmt.close();
                        
                        // Agregar a favoritos
                        stmt = conn.prepareStatement("INSERT INTO favoritos (id_usuario, id_propiedad, fecha_agregado) VALUES (?, ?, NOW())");
                        stmt.setInt(1, usuarioId);
                        stmt.setInt(2, propiedadId);
                        
                        int result = stmt.executeUpdate();
                        if (result > 0) {
                            success = true;
                            message = "Propiedad agregada a favoritos exitosamente";
                        } else {
                            message = "No se pudo agregar a favoritos";
                        }
                    }
                }
                
            } else if ("remove".equals(action)) {
                // Eliminar de favoritos
                stmt = conn.prepareStatement("DELETE FROM favoritos WHERE id_usuario = ? AND id_propiedad = ?");
                stmt.setInt(1, usuarioId);
                stmt.setInt(2, propiedadId);
                
                int result = stmt.executeUpdate();
                if (result > 0) {
                    success = true;
                    message = "Propiedad eliminada de favoritos exitosamente";
                } else {
                    message = "La propiedad no estaba en favoritos";
                    success = true; // No es error, pero no se elimina
                }
                
            } else {
                message = "Acción no válida";
            }
            
        } catch (NumberFormatException e) {
            message = "ID de propiedad inválido";
        } catch (SQLException e) {
            if (e.getMessage().contains("Duplicate entry")) {
                message = "La propiedad ya está en favoritos";
                success = true;
            } else {
                message = "Error de base de datos: " + e.getMessage();
            }
        } catch (Exception e) {
            message = "Error interno del servidor: " + e.getMessage();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }
    
    // Escapar caracteres especiales en el mensaje
    message = message.replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    
    // Generar respuesta JSON
    out.print("{");
    out.print("\"success\": " + success);
    out.print(", \"message\": \"" + message + "\"");
    out.print("}");
%>