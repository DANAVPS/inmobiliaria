package model;

import java.sql.Timestamp;
import java.util.Date;

/**
 * Modelo de datos para la entidad Usuario
 * Corresponde a la tabla 'usuarios' en la base de datos
 */
public class Usuario {

    // Campos de la tabla usuarios
    private int idUsuario;
    private String nombre;
    private String apellido;
    private String email;
    private String password;
    private String telefono;
    private String direccion;
    private Date fechaNacimiento;
    private int idRol;
    private String nombreRol; // Para joins con tabla roles
    private boolean activo;
    private Timestamp fechaRegistro;
    private Timestamp fechaActualizacion;

    // Constructores
    public Usuario() {
        this.activo = true; // Por defecto los usuarios están activos
    }

    public Usuario(String nombre, String apellido, String email, String password, int idRol) {
        this();
        this.nombre = nombre;
        this.apellido = apellido;
        this.email = email;
        this.password = password;
        this.idRol = idRol;
    }

    // Constructor completo
    public Usuario(int idUsuario, String nombre, String apellido, String email, String password,
            String telefono, String direccion, Date fechaNacimiento, int idRol,
            boolean activo, Timestamp fechaRegistro, Timestamp fechaActualizacion) {
        this.idUsuario = idUsuario;
        this.nombre = nombre;
        this.apellido = apellido;
        this.email = email;
        this.password = password;
        this.telefono = telefono;
        this.direccion = direccion;
        this.fechaNacimiento = fechaNacimiento;
        this.idRol = idRol;
        this.activo = activo;
        this.fechaRegistro = fechaRegistro;
        this.fechaActualizacion = fechaActualizacion;
    }

    // Getters y Setters
    public int getIdUsuario() {
        return idUsuario;
    }

    public void setIdUsuario(int idUsuario) {
        this.idUsuario = idUsuario;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre != null ? nombre.trim() : null;
    }

    public String getApellido() {
        return apellido;
    }

    public void setApellido(String apellido) {
        this.apellido = apellido != null ? apellido.trim() : null;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email != null ? email.trim().toLowerCase() : null;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono != null ? telefono.trim() : null;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion != null ? direccion.trim() : null;
    }

    public Date getFechaNacimiento() {
        return fechaNacimiento;
    }

    public void setFechaNacimiento(Date fechaNacimiento) {
        this.fechaNacimiento = fechaNacimiento;
    }

    public int getIdRol() {
        return idRol;
    }

    public void setIdRol(int idRol) {
        this.idRol = idRol;
    }

    public String getNombreRol() {
        return nombreRol;
    }

    public void setNombreRol(String nombreRol) {
        this.nombreRol = nombreRol;
    }

    public boolean isActivo() {
        return activo;
    }

    public void setActivo(boolean activo) {
        this.activo = activo;
    }

    public Timestamp getFechaRegistro() {
        return fechaRegistro;
    }

    public void setFechaRegistro(Timestamp fechaRegistro) {
        this.fechaRegistro = fechaRegistro;
    }

    public Timestamp getFechaActualizacion() {
        return fechaActualizacion;
    }

    public void setFechaActualizacion(Timestamp fechaActualizacion) {
        this.fechaActualizacion = fechaActualizacion;
    }

    // Métodos de utilidad

    /**
     * Obtiene el nombre completo del usuario
     * 
     * @return String nombre + apellido
     */
    public String getNombreCompleto() {
        StringBuilder nombreCompleto = new StringBuilder();
        if (nombre != null && !nombre.isEmpty()) {
            nombreCompleto.append(nombre);
        }
        if (apellido != null && !apellido.isEmpty()) {
            if (nombreCompleto.length() > 0) {
                nombreCompleto.append(" ");
            }
            nombreCompleto.append(apellido);
        }
        return nombreCompleto.toString();
    }

    /**
     * Verifica si el usuario es administrador
     * 
     * @return true si es administrador (rol 1)
     */
    public boolean isAdministrador() {
        return idRol == 1;
    }

    /**
     * Verifica si el usuario es cliente
     * 
     * @return true si es cliente (rol 3)
     */
    public boolean isCliente() {
        return idRol == 3;
    }

    /**
     * Verifica si el usuario es inmobiliaria
     * 
     * @return true si es inmobiliaria (rol 4)
     */
    public boolean isInmobiliaria() {
        return idRol == 4;
    }

    /**
     * Verifica si el usuario es usuario básico
     * 
     * @return true si es usuario básico (rol 2)
     */
    public boolean isUsuarioBasico() {
        return idRol == 2;
    }

    /**
     * Obtiene el nombre del rol basado en el ID
     * 
     * @return String nombre del rol
     */
    public String getNombreRolById() {
        switch (idRol) {
            case 1:
                return "ADMINISTRADOR";
            case 2:
                return "USUARIO";
            case 3:
                return "CLIENTE";
            case 4:
                return "INMOBILIARIA";
            default:
                return "DESCONOCIDO";
        }
    }

    /**
     * Valida si los datos básicos del usuario están completos
     * 
     * @return true si tiene nombre, apellido, email y rol
     */
    public boolean datosBasicosCompletos() {
        return nombre != null && !nombre.isEmpty() &&
                apellido != null && !apellido.isEmpty() &&
                email != null && !email.isEmpty() &&
                idRol > 0;
    }

    /**
     * Valida formato de email básico
     * 
     * @return true si el email tiene formato válido
     */
    public boolean emailValido() {
        if (email == null || email.isEmpty()) {
            return false;
        }
        return email.matches("^[A-Za-z0-9+_.-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$");
    }

    /**
     * Calcula la edad del usuario basada en fecha de nacimiento
     * 
     * @return int edad en años, -1 si no tiene fecha de nacimiento
     */
    public int calcularEdad() {
        if (fechaNacimiento == null) {
            return -1;
        }

        Date fechaActual = new Date();
        long diferencia = fechaActual.getTime() - fechaNacimiento.getTime();
        return (int) (diferencia / (365.25 * 24 * 60 * 60 * 1000));
    }

    // toString para debugging
    @Override
    public String toString() {
        return "Usuario{" +
                "idUsuario=" + idUsuario +
                ", nombre='" + nombre + '\'' +
                ", apellido='" + apellido + '\'' +
                ", email='" + email + '\'' +
                ", telefono='" + telefono + '\'' +
                ", idRol=" + idRol +
                ", nombreRol='" + nombreRol + '\'' +
                ", activo=" + activo +
                ", fechaRegistro=" + fechaRegistro +
                '}';
    }

    // equals y hashCode basados en email (único)
    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null || getClass() != obj.getClass())
            return false;

        Usuario usuario = (Usuario) obj;
        return email != null ? email.equals(usuario.email) : usuario.email == null;
    }

    @Override
    public int hashCode() {
        return email != null ? email.hashCode() : 0;
    }
}