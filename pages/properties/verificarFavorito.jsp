<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    
    // Obtener parámetros
    Integer usuarioId = (Integer) session.getAttribute("usuario_id");
    String propiedadIdParam = request.getParameter("propiedadId");
    
    boolean esFavorito = false;
    String error = null;
    
    if (usuarioId != null && propiedadIdParam != null) {
        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection("jdbc:mysql://localhost:3306/inmobiliaria_db", "root", "");
            
            String sql = "SELECT COUNT(*) FROM favoritos WHERE id_usuario = ? AND id_propiedad = ?";
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, usuarioId);
            stmt.setInt(2, Integer.parseInt(propiedadIdParam));
            rs = stmt.executeQuery();
            
            if (rs.next()) {
                esFavorito = rs.getInt(1) > 0;
            }
            
        } catch (NumberFormatException e) {
            error = "ID de propiedad inválido";
        } catch (SQLException e) {
            error = "Error de base de datos";
        } catch (Exception e) {
            error = "Error interno del servidor";
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (stmt != null) try { stmt.close(); } catch (SQLException e) {}
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    } else {
        error = "Parámetros faltantes";
    }
    
    // Generar respuesta JSON
    out.print("{");
    out.print("\"esFavorito\": " + esFavorito);
    if (error != null) {
        out.print(", \"error\": \"" + error + "\"");
    }
    out.print("}");
%>