package dao;

import model.Usuario;
import java.sql.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.List;

/**
 * Data Access Object para la entidad Usuario
 * Maneja todas las operaciones CRUD de la tabla usuarios
 */
public class UsuarioDAO {

    /**
     * Registrar un nuevo usuario en la base de datos
     * 
     * @param usuario Usuario a registrar
     * @return true si el registro fue exitoso
     * @throws SQLException si hay error en la BD
     */
    public boolean registrarUsuario(Usuario usuario) throws SQLException {
        String sql = "INSERT INTO usuarios (nombre, apellido, email, password, telefono, direccion, fecha_nacimiento, id_rol) "
                +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);

            // Establecer parámetros
            stmt.setString(1, usuario.getNombre());
            stmt.setString(2, usuario.getApellido());
            stmt.setString(3, usuario.getEmail());
            stmt.setString(4, encriptarPassword(usuario.getPassword())); // MD5
            stmt.setString(5, usuario.getTelefono());
            stmt.setString(6, usuario.getDireccion());

            // Manejar fecha de nacimiento (puede ser null)
            if (usuario.getFechaNacimiento() != null) {
                stmt.setDate(7, new java.sql.Date(usuario.getFechaNacimiento().getTime()));
            } else {
                stmt.setNull(7, Types.DATE);
            }

            stmt.setInt(8, usuario.getIdRol());

            // Ejecutar inserción
            int filasAfectadas = stmt.executeUpdate();
            boolean exitoso = filasAfectadas > 0;

            if (exitoso) {
                System.out.println("✓ Usuario registrado exitosamente: " + usuario.getEmail());
            } else {
                System.out.println("✗ Error al registrar usuario: " + usuario.getEmail());
            }

            return exitoso;

        } catch (SQLException e) {
            System.err.println("✗ Error SQL al registrar usuario: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, null);
        }
    }

    /**
     * Verificar si un email ya está registrado
     * 
     * @param email Email a verificar
     * @return true si el email ya existe
     * @throws SQLException si hay error en la BD
     */
    public boolean emailExiste(String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM usuarios WHERE email = ?";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, email.toLowerCase().trim());

            rs = stmt.executeQuery();

            if (rs.next()) {
                int count = rs.getInt(1);
                return count > 0;
            }

            return false;

        } catch (SQLException e) {
            System.err.println("✗ Error al verificar email: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Autenticar usuario con email y contraseña
     * 
     * @param email    Email del usuario
     * @param password Contraseña en texto plano
     * @return Usuario autenticado o null si falla
     * @throws SQLException si hay error en la BD
     */
    public Usuario autenticarUsuario(String email, String password) throws SQLException {
        String sql = "SELECT u.*, r.nombre_rol " +
                "FROM usuarios u " +
                "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                "WHERE u.email = ? AND u.password = ? AND u.activo = 1";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, email.toLowerCase().trim());
            stmt.setString(2, encriptarPassword(password)); // Comparar con MD5

            rs = stmt.executeQuery();

            if (rs.next()) {
                Usuario usuario = mapearResultSetAUsuario(rs);
                System.out.println("✓ Autenticación exitosa para: " + email);
                return usuario;
            } else {
                System.out.println("✗ Autenticación fallida para: " + email);
                return null;
            }

        } catch (SQLException e) {
            System.err.println("✗ Error al autenticar usuario: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Obtener usuario por ID
     * 
     * @param idUsuario ID del usuario
     * @return Usuario encontrado o null
     * @throws SQLException si hay error en la BD
     */
    public Usuario obtenerUsuarioPorId(int idUsuario) throws SQLException {
        String sql = "SELECT u.*, r.nombre_rol " +
                "FROM usuarios u " +
                "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                "WHERE u.id_usuario = ?";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, idUsuario);

            rs = stmt.executeQuery();

            if (rs.next()) {
                return mapearResultSetAUsuario(rs);
            }

            return null;

        } catch (SQLException e) {
            System.err.println("✗ Error al obtener usuario por ID: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Obtener usuario por email
     * 
     * @param email Email del usuario
     * @return Usuario encontrado o null
     * @throws SQLException si hay error en la BD
     */
    public Usuario obtenerUsuarioPorEmail(String email) throws SQLException {
        String sql = "SELECT u.*, r.nombre_rol " +
                "FROM usuarios u " +
                "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                "WHERE u.email = ?";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setString(1, email.toLowerCase().trim());

            rs = stmt.executeQuery();

            if (rs.next()) {
                return mapearResultSetAUsuario(rs);
            }

            return null;

        } catch (SQLException e) {
            System.err.println("✗ Error al obtener usuario por email: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Actualizar información del usuario
     * 
     * @param usuario Usuario con datos actualizados
     * @return true si la actualización fue exitosa
     * @throws SQLException si hay error en la BD
     */
    public boolean actualizarUsuario(Usuario usuario) throws SQLException {
        String sql = "UPDATE usuarios SET nombre = ?, apellido = ?, telefono = ?, direccion = ?, " +
                "fecha_nacimiento = ?, fecha_actualizacion = CURRENT_TIMESTAMP " +
                "WHERE id_usuario = ?";

        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);

            stmt.setString(1, usuario.getNombre());
            stmt.setString(2, usuario.getApellido());
            stmt.setString(3, usuario.getTelefono());
            stmt.setString(4, usuario.getDireccion());

            if (usuario.getFechaNacimiento() != null) {
                stmt.setDate(5, new java.sql.Date(usuario.getFechaNacimiento().getTime()));
            } else {
                stmt.setNull(5, Types.DATE);
            }

            stmt.setInt(6, usuario.getIdUsuario());

            int filasAfectadas = stmt.executeUpdate();
            boolean exitoso = filasAfectadas > 0;

            if (exitoso) {
                System.out.println("✓ Usuario actualizado exitosamente: " + usuario.getEmail());
            }

            return exitoso;

        } catch (SQLException e) {
            System.err.println("✗ Error al actualizar usuario: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, null);
        }
    }

    /**
     * Listar todos los usuarios activos
     * 
     * @return Lista de usuarios
     * @throws SQLException si hay error en la BD
     */
    public List<Usuario> listarUsuarios() throws SQLException {
        String sql = "SELECT u.*, r.nombre_rol " +
                "FROM usuarios u " +
                "INNER JOIN roles r ON u.id_rol = r.id_rol " +
                "WHERE u.activo = 1 " +
                "ORDER BY u.fecha_registro DESC";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;
        List<Usuario> usuarios = new ArrayList<>();

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            rs = stmt.executeQuery();

            while (rs.next()) {
                usuarios.add(mapearResultSetAUsuario(rs));
            }

            System.out.println("✓ Se obtuvieron " + usuarios.size() + " usuarios");
            return usuarios;

        } catch (SQLException e) {
            System.err.println("✗ Error al listar usuarios: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Mapear ResultSet a objeto Usuario
     * 
     * @param rs ResultSet con datos del usuario
     * @return Usuario mapeado
     * @throws SQLException si hay error al leer datos
     */
    private Usuario mapearResultSetAUsuario(ResultSet rs) throws SQLException {
        Usuario usuario = new Usuario();

        usuario.setIdUsuario(rs.getInt("id_usuario"));
        usuario.setNombre(rs.getString("nombre"));
        usuario.setApellido(rs.getString("apellido"));
        usuario.setEmail(rs.getString("email"));
        usuario.setPassword(rs.getString("password"));
        usuario.setTelefono(rs.getString("telefono"));
        usuario.setDireccion(rs.getString("direccion"));

        // Manejar fecha de nacimiento que puede ser null
        Date fechaNac = rs.getDate("fecha_nacimiento");
        if (fechaNac != null) {
            usuario.setFechaNacimiento(new java.util.Date(fechaNac.getTime()));
        }

        usuario.setIdRol(rs.getInt("id_rol"));
        usuario.setNombreRol(rs.getString("nombre_rol"));
        usuario.setActivo(rs.getBoolean("activo"));
        usuario.setFechaRegistro(rs.getTimestamp("fecha_registro"));
        usuario.setFechaActualizacion(rs.getTimestamp("fecha_actualizacion"));

        return usuario;
    }

    /**
     * Encriptar contraseña usando MD5
     * 
     * @param password Contraseña en texto plano
     * @return String contraseña encriptada en MD5
     */
    public static String encriptarPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] hashBytes = md.digest(password.getBytes());

            // Convertir bytes a hexadecimal
            StringBuilder sb = new StringBuilder();
            for (byte b : hashBytes) {
                sb.append(String.format("%02x", b));
            }

            return sb.toString();

        } catch (NoSuchAlgorithmException e) {
            System.err.println("✗ Error al encriptar contraseña: " + e.getMessage());
            // En caso de error, devolver la contraseña original (no recomendado en
            // producción)
            return password;
        }
    }

    /**
     * Cambiar contraseña del usuario
     * 
     * @param idUsuario       ID del usuario
     * @param passwordAntigua Contraseña actual
     * @param passwordNueva   Nueva contraseña
     * @return true si el cambio fue exitoso
     * @throws SQLException si hay error en la BD
     */
    public boolean cambiarPassword(int idUsuario, String passwordAntigua, String passwordNueva) throws SQLException {
        // Primero verificar la contraseña actual
        String sqlVerificar = "SELECT COUNT(*) FROM usuarios WHERE id_usuario = ? AND password = ?";
        String sqlActualizar = "UPDATE usuarios SET password = ?, fecha_actualizacion = CURRENT_TIMESTAMP WHERE id_usuario = ?";

        Connection conn = null;
        PreparedStatement stmtVerificar = null;
        PreparedStatement stmtActualizar = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();

            // Verificar contraseña actual
            stmtVerificar = conn.prepareStatement(sqlVerificar);
            stmtVerificar.setInt(1, idUsuario);
            stmtVerificar.setString(2, encriptarPassword(passwordAntigua));

            rs = stmtVerificar.executeQuery();

            if (rs.next() && rs.getInt(1) > 0) {
                // Contraseña actual es correcta, proceder con el cambio
                stmtActualizar = conn.prepareStatement(sqlActualizar);
                stmtActualizar.setString(1, encriptarPassword(passwordNueva));
                stmtActualizar.setInt(2, idUsuario);

                int filasAfectadas = stmtActualizar.executeUpdate();
                boolean exitoso = filasAfectadas > 0;

                if (exitoso) {
                    System.out.println("✓ Contraseña cambiada exitosamente para usuario ID: " + idUsuario);
                }

                return exitoso;
            } else {
                System.out.println("✗ Contraseña actual incorrecta para usuario ID: " + idUsuario);
                return false;
            }

        } catch (SQLException e) {
            System.err.println("✗ Error al cambiar contraseña: " + e.getMessage());
            throw e;
        } finally {
            if (rs != null)
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            if (stmtVerificar != null)
                try {
                    stmtVerificar.close();
                } catch (SQLException e) {
                }
            if (stmtActualizar != null)
                try {
                    stmtActualizar.close();
                } catch (SQLException e) {
                }
            ConexionDB.closeConnection(conn);
        }
    }

    /**
     * Activar o desactivar usuario
     * 
     * @param idUsuario ID del usuario
     * @param activo    true para activar, false para desactivar
     * @return true si el cambio fue exitoso
     * @throws SQLException si hay error en la BD
     */
    public boolean cambiarEstadoUsuario(int idUsuario, boolean activo) throws SQLException {
        String sql = "UPDATE usuarios SET activo = ?, fecha_actualizacion = CURRENT_TIMESTAMP WHERE id_usuario = ?";

        Connection conn = null;
        PreparedStatement stmt = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setBoolean(1, activo);
            stmt.setInt(2, idUsuario);

            int filasAfectadas = stmt.executeUpdate();
            boolean exitoso = filasAfectadas > 0;

            if (exitoso) {
                System.out.println(
                        "✓ Usuario " + (activo ? "activado" : "desactivado") + " exitosamente ID: " + idUsuario);
            }

            return exitoso;

        } catch (SQLException e) {
            System.err.println("✗ Error al cambiar estado de usuario: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, null);
        }
    }

    /**
     * Contar usuarios por rol
     * 
     * @param idRol ID del rol a contar
     * @return cantidad de usuarios con ese rol
     * @throws SQLException si hay error en la BD
     */
    public int contarUsuariosPorRol(int idRol) throws SQLException {
        String sql = "SELECT COUNT(*) FROM usuarios WHERE id_rol = ? AND activo = 1";

        Connection conn = null;
        PreparedStatement stmt = null;
        ResultSet rs = null;

        try {
            conn = ConexionDB.getConnection();
            stmt = conn.prepareStatement(sql);
            stmt.setInt(1, idRol);

            rs = stmt.executeQuery();

            if (rs.next()) {
                return rs.getInt(1);
            }

            return 0;

        } catch (SQLException e) {
            System.err.println("✗ Error al contar usuarios por rol: " + e.getMessage());
            throw e;
        } finally {
            ConexionDB.closeResources(conn, stmt, rs);
        }
    }

    /**
     * Método de testing para verificar que el DAO funcione
     */
    public static void main(String[] args) {
        UsuarioDAO dao = new UsuarioDAO();

        System.out.println("=== TESTING UsuarioDAO ===");

        try {
            // Test 1: Verificar conexión
            System.out.println("\n1. Testing conexión...");
            boolean conexionOk = ConexionDB.testConnection();
            System.out.println("Conexión: " + (conexionOk ? "✓ OK" : "✗ FALLO"));

            if (!conexionOk) {
                System.out.println("No se puede continuar sin conexión a BD");
                return;
            }

            // Test 2: Verificar email existente
            System.out.println("\n2. Testing verificación de email...");
            boolean emailExists = dao.emailExiste("admin@inmobiliaria.com");
            System.out.println("Email 'admin@inmobiliaria.com' existe: " + emailExists);

            // Test 3: Crear usuario de prueba
            System.out.println("\n3. Testing creación de usuario...");
            Usuario usuarioPrueba = new Usuario();
            usuarioPrueba.setNombre("Usuario");
            usuarioPrueba.setApellido("Prueba");
            usuarioPrueba.setEmail("prueba@test.com");
            usuarioPrueba.setPassword("123456");
            usuarioPrueba.setTelefono("300-123-4567");
            usuarioPrueba.setIdRol(3); // Cliente

            // Solo registrar si no existe
            if (!dao.emailExiste(usuarioPrueba.getEmail())) {
                boolean registrado = dao.registrarUsuario(usuarioPrueba);
                System.out.println("Usuario de prueba registrado: " + registrado);
            } else {
                System.out.println("Usuario de prueba ya existe");
            }

            // Test 4: Autenticación
            System.out.println("\n4. Testing autenticación...");
            Usuario usuarioAutenticado = dao.autenticarUsuario("admin@inmobiliaria.com", "admin123");
            if (usuarioAutenticado != null) {
                System.out.println("✓ Autenticación exitosa: " + usuarioAutenticado.getNombreCompleto());
                System.out.println("  Rol: " + usuarioAutenticado.getNombreRol());
            } else {
                System.out.println("✗ Autenticación fallida");
            }

            // Test 5: Contar usuarios
            System.out.println("\n5. Testing conteo por roles...");
            System.out.println("Administradores: " + dao.contarUsuariosPorRol(1));
            System.out.println("Usuarios: " + dao.contarUsuariosPorRol(2));
            System.out.println("Clientes: " + dao.contarUsuariosPorRol(3));
            System.out.println("Inmobiliarias: " + dao.contarUsuariosPorRol(4));

        } catch (SQLException e) {
            System.err.println("✗ Error durante testing: " + e.getMessage());
            e.printStackTrace();
        }

        System.out.println("\n=== FIN TESTING ===");
    }
}