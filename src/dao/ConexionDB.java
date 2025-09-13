package dao;

import java.sql.*;

/**
 * Clase para manejar la conexión a la base de datos MySQL
 * Soporte para conexión local y online
 */
public class ConexionDB {
    
    // Configuración de base de datos local (XAMPP)
    private static final String URL_LOCAL = "jdbc:mysql://localhost:3306/inmobiliaria_db";
    private static final String USER_LOCAL = "root";
    private static final String PASSWORD_LOCAL = "";
    
    // Configuración de base de datos online (cambiar cuando sea necesario)
    private static final String URL_ONLINE = "jdbc:mysql://sql12.freemysqlhosting.net:3306/sql12345678";
    private static final String USER_ONLINE = "sql12345678";
    private static final String PASSWORD_ONLINE = "abcd1234";
    
    // Driver de MySQL
    private static final String DRIVER = "com.mysql.cj.jdbc.Driver";
    
    // Variable para cambiar entre local y online
    private static boolean useOnline = false;
    
    /**
     * Obtiene una conexión a la base de datos
     * @return Connection - Conexión activa a la BD
     * @throws SQLException si hay error en la conexión
     */
    public static Connection getConnection() throws SQLException {
        Connection connection = null;
        
        try {
            // Cargar el driver de MySQL
            Class.forName(DRIVER);
            
            if (useOnline) {
                // Conexión online
                connection = DriverManager.getConnection(URL_ONLINE, USER_ONLINE, PASSWORD_ONLINE);
                System.out.println("✓ Conexión exitosa a BD ONLINE");
            } else {
                // Conexión local (XAMPP)
                connection = DriverManager.getConnection(URL_LOCAL, USER_LOCAL, PASSWORD_LOCAL);
                System.out.println("✓ Conexión exitosa a BD LOCAL");
            }
            
        } catch (ClassNotFoundException e) {
            System.err.println("✗ Error: Driver MySQL no encontrado");
            System.err.println("Detalles: " + e.getMessage());
            throw new SQLException("Driver MySQL no disponible", e);
            
        } catch (SQLException e) {
            System.err.println("✗ Error al conectar con la base de datos");
            System.err.println("URL: " + (useOnline ? URL_ONLINE : URL_LOCAL));
            System.err.println("Usuario: " + (useOnline ? USER_ONLINE : USER_LOCAL));
            System.err.println("Detalles: " + e.getMessage());
            throw e;
        }
        
        return connection;
    }
    
    /**
     * Cambiar entre conexión local y online
     * @param online true para usar BD online, false para local
     */
    public static void setUseOnline(boolean online) {
        useOnline = online;
        System.out.println("Modo de conexión cambiado a: " + (online ? "ONLINE" : "LOCAL"));
    }
    
    /**
     * Verificar si la conexión está funcionando
     * @return true si la conexión es exitosa
     */
    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            if (conn != null && !conn.isClosed()) {
                // Probar con una consulta simple
                try (Statement stmt = conn.createStatement();
                    ResultSet rs = stmt.executeQuery("SELECT 1 as test")) {
                    
                    if (rs.next()) {
                        System.out.println("✓ Test de conexión exitoso - BD funcionando correctamente");
                        return true;
                    }
                }
            }
        } catch (SQLException e) {
            System.err.println("✗ Test de conexión fallido: " + e.getMessage());
        }
        return false;
    }
    
    /**
     * Cerrar recursos de BD de forma segura
     * @param conn Connection a cerrar
     */
    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
                System.out.println("✓ Conexión cerrada correctamente");
            } catch (SQLException e) {
                System.err.println("✗ Error al cerrar conexión: " + e.getMessage());
            }
        }
    }
    
    /**
     * Cerrar recursos de BD de forma segura
     * @param conn Connection
     * @param stmt Statement  
     * @param rs ResultSet
     */
    public static void closeResources(Connection conn, Statement stmt, ResultSet rs) {
        // Cerrar ResultSet
        if (rs != null) {
            try {
                rs.close();
            } catch (SQLException e) {
                System.err.println("Error al cerrar ResultSet: " + e.getMessage());
            }
        }
        
        // Cerrar Statement
        if (stmt != null) {
            try {
                stmt.close();
            } catch (SQLException e) {
                System.err.println("Error al cerrar Statement: " + e.getMessage());
            }
        }
        
        // Cerrar Connection
        closeConnection(conn);
    }
    
    /**
     * Obtener información de la conexión actual
     * @return String con información de la BD
     */
    public static String getConnectionInfo() {
        try (Connection conn = getConnection()) {
            if (conn != null) {
                DatabaseMetaData metaData = conn.getMetaData();
                StringBuilder info = new StringBuilder();
                info.append("=== INFORMACIÓN DE LA BASE DE DATOS ===\n");
                info.append("Modo: ").append(useOnline ? "ONLINE" : "LOCAL").append("\n");
                info.append("URL: ").append(metaData.getURL()).append("\n");
                info.append("Usuario: ").append(metaData.getUserName()).append("\n");
                info.append("Producto: ").append(metaData.getDatabaseProductName()).append("\n");
                info.append("Versión: ").append(metaData.getDatabaseProductVersion()).append("\n");
                info.append("Driver: ").append(metaData.getDriverName()).append("\n");
                info.append("Versión Driver: ").append(metaData.getDriverVersion()).append("\n");
                return info.toString();
            }
        } catch (SQLException e) {
            return "Error al obtener información: " + e.getMessage();
        }
        return "No hay conexión disponible";
    }
    
    /**
     * Método main para probar la conexión (solo para testing)
     */
    public static void main(String[] args) {
        System.out.println("=== PROBANDO CONEXIÓN A BASE DE DATOS ===");
        
        // Probar conexión local
        System.out.println("\n1. Probando conexión LOCAL:");
        setUseOnline(false);
        boolean localOk = testConnection();
        
        if (localOk) {
            System.out.println(getConnectionInfo());
        }
        
        // Descomentar para probar conexión online
        /*
        System.out.println("\n2. Probando conexión ONLINE:");
        setUseOnline(true);
        boolean onlineOk = testConnection();
        
        if (onlineOk) {
            System.out.println(getConnectionInfo());
        }
        */
        
        System.out.println("\n=== RESULTADOS ===");
        System.out.println("Conexión Local: " + (localOk ? "✓ OK" : "✗ FALLO"));
        // System.out.println("Conexión Online: " + (onlineOk ? "✓ OK" : "✗ FALLO"));
        
        // Volver a modo local para uso normal
        setUseOnline(false);
    }
}