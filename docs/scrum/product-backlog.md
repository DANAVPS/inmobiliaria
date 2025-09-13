# Product Backlog - Sistema de Gestión Inmobiliaria

## Información del Proyecto
- **Producto:** Sistema Web de Gestión Inmobiliaria
- **Product Owner:** Dana Valentina Pacheco Sandoval
- **Scrum Master:** Dana Valentina Pacheco Sandoval
- **Development Team:** Dana Valentina Pacheco Sandoval
- **Duración del Proyecto:** 21 días (3 sprints de 7 días)
- **Fecha de Inicio:** 01 de Septiembre 2025

## Visión del Producto

Crear una aplicación web integral para la administración de una inmobiliaria que permita gestionar propiedades, usuarios con roles diferenciados y operaciones de búsqueda, alquiler/venta, implementando metodología ágil Scrum para garantizar entregas incrementales de valor.

## Épicas del Proyecto

### Épica 1: Gestión de Usuarios y Autenticación
Implementar sistema completo de usuarios con roles diferenciados y autenticación segura.

### Épica 2: Gestión de Propiedades
Desarrollar CRUD completo para administración de propiedades inmobiliarias.

### Épica 3: Sistema de Búsqueda y Filtrado
Crear funcionalidades de búsqueda avanzada para usuarios finales.

### Épica 4: Sistema de Citas y Visitas
Implementar gestión de citas entre clientes e inmobiliarias.

## Product Backlog Priorizado

| ID | User Story | Épica | Prioridad | Estimación | Sprint | Estado |
|----|------------|-------|-----------|------------|--------|--------|
| US-01 | Landing page atractiva | Búsqueda | Alta | 8 | 1 | ✅ Done |
| US-02 | Registro de usuarios | Usuarios | Alta | 5 | 1 | ✅ Done |
| US-03 | Login de usuarios | Usuarios | Alta | 5 | 1 | ✅ Done |
| US-04 | Dashboard por rol | Usuarios | Alta | 13 | 1 | ✅ Done |
| US-05 | CRUD de propiedades | Propiedades | Alta | 13 | 2 | ✅ Done |
| US-06 | Búsqueda básica | Búsqueda | Alta | 8 | 2 | ✅ Done |
| US-07 | Filtros avanzados | Búsqueda | Media | 8 | 2 | ✅ Done |
| US-08 | Gestión de usuarios (Admin) | Usuarios | Media | 8 | 2 | ✅ Done |
| US-09 | Sistema de citas | Citas | Media | 13 | 3 | ✅ Done |
| US-10 | Detalles de propiedad | Propiedades | Media | 5 | 3 | ✅ Done |
| US-11 | Perfil de usuario | Usuarios | Baja | 5 | 3 | ✅ Done |
| US-12 | Reportes básicos | Propiedades | Baja | 8 | 3 | ✅ Done |

## Definición de User Stories

### US-01: Landing Page Atractiva
**Como** visitante del sitio web  
**Quiero** una página de inicio atractiva y funcional  
**Para** conocer la inmobiliaria y realizar búsquedas rápidas de propiedades  

**Criterios de Aceptación:**
- [ ] Diseño responsive y atractivo
- [ ] Buscador prominente en la página principal
- [ ] Información clara sobre la empresa
- [ ] Enlaces visibles a registro/login
- [ ] Muestra de propiedades destacadas
- [ ] Navegación intuitiva

**Definition of Done:**
- Página funcional en móvil y desktop
- Buscador conectado a base de datos
- Validaciones básicas implementadas
- Tested en múltiples navegadores

---

### US-02: Registro de Usuarios
**Como** visitante del sitio  
**Quiero** poder registrarme en el sistema  
**Para** acceder a funcionalidades personalizadas según mi rol  

**Criterios de Aceptación:**
- [ ] Formulario de registro con campos obligatorios
- [ ] Validación de email único
- [ ] Selección de rol (cliente/inmobiliaria)
- [ ] Validación de contraseña segura
- [ ] Confirmación de registro exitoso
- [ ] Redirección automática tras registro

**Definition of Done:**
- Validaciones frontend y backend
- Datos guardados correctamente en BD
- Manejo de errores implementado
- Encriptación de contraseñas

---

### US-03: Login de Usuarios
**Como** usuario registrado  
**Quiero** poder iniciar sesión  
**Para** acceder a las funcionalidades del sistema según mi rol  

**Criterios de Aceptación:**
- [ ] Formulario de login con email/contraseña
- [ ] Validación de credenciales
- [ ] Manejo de sesiones seguro
- [ ] Redirección por rol tras login
- [ ] Opción de cerrar sesión
- [ ] Mensajes de error claros

**Definition of Done:**
- Autenticación segura implementada
- Sessions manejadas correctamente
- Protección contra accesos no autorizados
- Logout funcional

---

### US-04: Dashboard por Rol
**Como** usuario autenticado  
**Quiero** un dashboard personalizado según mi rol  
**Para** acceder rápidamente a las funciones que necesito  

**Criterios de Aceptación:**

**Administrador:**
- [ ] Vista de estadísticas generales
- [ ] Acceso a gestión de usuarios
- [ ] Enlaces a reportes del sistema
- [ ] Configuraciones generales

**Cliente:**
- [ ] Búsqueda de propiedades
- [ ] Mis citas programadas
- [ ] Propiedades favoritas
- [ ] Perfil personal

**Inmobiliaria:**
- [ ] Mis propiedades publicadas
- [ ] Solicitudes de citas pendientes
- [ ] Estadísticas de mis propiedades
- [ ] Agregar nueva propiedad

**Definition of Done:**
- Dashboards funcionales para todos los roles
- Navegación intuitiva
- Datos actualizados en tiempo real
- Responsive design

---

### US-05: CRUD de Propiedades
**Como** usuario con rol inmobiliaria  
**Quiero** gestionar mis propiedades (crear, leer, actualizar, eliminar)  
**Para** mantener actualizado mi catálogo de inmuebles  

**Criterios de Aceptación:**
- [ ] Formulario para agregar propiedad
- [ ] Listado de mis propiedades
- [ ] Edición de propiedades existentes
- [ ] Eliminación (lógica) de propiedades
- [ ] Validaciones de campos obligatorios
- [ ] Subida de imágenes/URLs
- [ ] Cambio de estado (disponible/vendida/alquilada)

**Definition of Done:**
- Todas las operaciones CRUD funcionales
- Validaciones completas
- Interfaz intuitiva
- Datos persistidos correctamente

---

### US-06: Búsqueda Básica
**Como** visitante o usuario  
**Quiero** buscar propiedades por criterios básicos  
**Para** encontrar inmuebles que se ajusten a mis necesidades  

**Criterios de Aceptación:**
- [ ] Búsqueda por ubicación
- [ ] Filtro por tipo de operación (venta/alquiler)
- [ ] Filtro por tipo de propiedad
- [ ] Resultados en formato lista/tarjetas
- [ ] Información básica visible en resultados
- [ ] Enlaces a detalle de propiedad

**Definition of Done:**
- Búsqueda funcional desde cualquier página
- Resultados precisos
- Performance optimizada
- Diseño responsive

---

### US-07: Filtros Avanzados
**Como** usuario buscando propiedades  
**Quiero** aplicar filtros específicos  
**Para** refinar mi búsqueda y encontrar exactamente lo que necesito  

**Criterios de Aceptación:**
- [ ] Filtro por rango de precios
- [ ] Filtro por número de habitaciones
- [ ] Filtro por número de baños
- [ ] Filtro por área mínima
- [ ] Combinación de múltiples filtros
- [ ] Limpiar filtros fácilmente
- [ ] Conteo de resultados

**Definition of Done:**
- Filtros funcionan individualmente y en combinación
- Interface intuitiva
- Resultados actualizados dinámicamente
- Performance optimizada

---

### US-08: Gestión de Usuarios (Admin)
**Como** administrador del sistema  
**Quiero** gestionar todos los usuarios  
**Para** mantener control sobre los accesos y roles del sistema  

**Criterios de Aceptación:**
- [ ] Listar todos los usuarios
- [ ] Ver detalles de cada usuario
- [ ] Editar información de usuarios
- [ ] Cambiar roles de usuarios
- [ ] Activar/desactivar usuarios
- [ ] Búsqueda de usuarios
- [ ] Reportes de actividad

**Definition of Done:**
- CRUD completo de usuarios
- Solo accesible por administradores
- Validaciones de seguridad
- Logs de cambios

---

### US-09: Sistema de Citas
**Como** cliente interesado  
**Quiero** solicitar citas para visitar propiedades  
**Para** conocer personalmente los inmuebles que me interesan  

**Criterios de Aceptación:**

**Cliente:**
- [ ] Solicitar cita desde detalle de propiedad
- [ ] Seleccionar fecha y hora preferida
- [ ] Agregar notas/comentarios
- [ ] Ver mis citas programadas
- [ ] Cancelar citas si es necesario

**Inmobiliaria:**
- [ ] Ver solicitudes de citas pendientes
- [ ] Confirmar o rechazar citas
- [ ] Reprogramar citas
- [ ] Marcar citas como realizadas
- [ ] Contactar al cliente

**Definition of Done:**
- Flujo completo de citas funcional
- Notificaciones de estado
- Validaciones de fechas
- Interface intuitiva para ambos roles

---

### US-10: Detalles de Propiedad
**Como** usuario interesado  
**Quiero** ver información completa de una propiedad  
**Para** evaluar si cumple con mis expectativas  

**Criterios de Aceptación:**
- [ ] Información completa de la propiedad
- [ ] Galería de imágenes
- [ ] Datos de contacto de la inmobiliaria
- [ ] Mapa de ubicación (opcional)
- [ ] Botón para solicitar cita
- [ ] Compartir propiedad
- [ ] Agregar a favoritos

**Definition of Done:**
- Página de detalle completamente funcional
- Diseño atractivo y responsive
- Información precisa
- Navegación fluida

---

### US-11: Perfil de Usuario
**Como** usuario registrado  
**Quiero** gestionar mi información personal  
**Para** mantener mis datos actualizados  

**Criterios de Aceptación:**
- [ ] Ver mi información actual
- [ ] Editar datos personales
- [ ] Cambiar contraseña
- [ ] Actualizar foto de perfil
- [ ] Configuraciones de privacidad
- [ ] Eliminar cuenta (opcional)

**Definition of Done:**
- Perfil completamente editable
- Validaciones de seguridad
- Cambios persistidos correctamente
- Interface amigable

---

### US-12: Reportes Básicos
**Como** inmobiliaria o administrador  
**Quiero** generar reportes de actividad  
**Para** analizar el rendimiento y tomar decisiones  

**Criterios de Aceptación:**

**Inmobiliaria:**
- [ ] Reporte de mis propiedades por estado
- [ ] Citas programadas/realizadas
- [ ] Propiedades más vistas
- [ ] Estadísticas de ventas/alquileres

**Administrador:**
- [ ] Total de usuarios por rol
- [ ] Propiedades totales por estado
- [ ] Actividad general del sistema
- [ ] Reportes de citas

**Definition of Done:**
- Reportes precisos y actualizados
- Exportación a PDF/Excel (opcional)
- Visualización clara de datos
- Acceso restringido por rol

## Criterios de Aceptación Generales

### Definition of Done (DoD) del Proyecto
Una funcionalidad se considera "Done" cuando:

1. **Desarrollo completado** según especificaciones
2. **Código revisado** y siguiendo estándares
3. **Testing manual** realizado
4. **Responsive design** verificado
5. **Validaciones** implementadas (frontend y backend)
6. **Integración** con base de datos funcional
7. **Documentación** básica incluida
8. **Deploy** en ambiente de desarrollo exitoso

### Estándares de Calidad

- **Código:** Comentarios en funciones complejas, nombres descriptivos
- **UI/UX:** Bootstrap para consistencia, navegación intuitiva
- **Seguridad:** Validación de inputs, manejo de sesiones seguro
- **Performance:** Consultas optimizadas, imágenes comprimidas
- **Compatibilidad:** Funcional en Chrome, Firefox, Safari

## Riesgos Identificados

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Complejidad técnica mayor a esperada | Media | Alto | Simplificar funcionalidades, MVP primero |
| Problemas de conexión BD | Baja | Alto | Configuración temprana, backups |
| Tiempo insuficiente | Alta | Medio | Priorización estricta, MVP claro |
| Falta de experiencia en JSP | Media | Medio | Investigación temprana, ejemplos |

## Velocidad del Equipo

- **Sprint 1:** 31 Story Points
- **Sprint 2:** 37 Story Points  
- **Sprint 3:** 31 Story Points
- **Velocidad promedio:** 33 Story Points por sprint

## Notas del Product Owner

- Prioridad en funcionalidades core sobre características avanzadas
- Diseño responsive es crítico
- Documentación Scrum debe ser detallada para evaluación académica
- Base de datos online es deseable pero no crítica para aprobación