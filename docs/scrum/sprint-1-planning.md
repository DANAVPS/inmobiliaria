# Sprint 1 Planning - Sistema Inmobiliaria

## Información del Sprint
- **Sprint:** #1
- **Duración:** 7 días (01/09/2025 - 07/09/2025)
- **Sprint Goal:** Establecer base del sistema con autenticación funcional y estructura inicial
- **Scrum Master:** Dana Valentina Pacheco Sandoval
- **Product Owner:** Dana Valentina Pacheco Sandoval
- **Development Team:** Dana Valentina Pacheco Sandoval

## Sprint Goal

"Al final de este sprint, tendremos un sistema básico funcional donde los usuarios pueden registrarse, iniciar sesión, y acceder a dashboards personalizados según su rol, además de una landing page atractiva que presente la inmobiliaria."

## Capacidad del Sprint
- **Días disponibles:** 7 días
- **Horas por día:** 6 horas
- **Capacidad total:** 42 horas
- **Velocity estimada:** 31 Story Points

## User Stories Seleccionadas

### US-01: Landing Page Atractiva
- **Story Points:** 8
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Crear página de inicio responsive con buscador básico y presentación de la empresa

**Tareas:**
1. Diseñar mockup de la landing page (2h)
2. Implementar HTML/CSS con Bootstrap (4h)
3. Crear JSP con contenido dinámico (2h)
4. Implementar buscador básico (3h)
5. Testing responsive y navegadores (1h)

**Definition of Done:**
- ✅ Página responsive funcional
- ✅ Buscador conectado a BD
- ✅ Navegación intuitiva
- ✅ Información clara de la empresa

---

### US-02: Registro de Usuarios
- **Story Points:** 5
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Sistema completo de registro con validaciones

**Tareas:**
1. Crear formulario de registro JSP (2h)
2. Implementar servlet de registro (2h)
3. Validaciones frontend y backend (2h)
4. Encriptación de contraseñas (1h)
5. Testing y manejo de errores (1h)

**Definition of Done:**
- ✅ Formulario funcional con validaciones
- ✅ Datos guardados en BD correctamente
- ✅ Contraseñas encriptadas
- ✅ Manejo de errores implementado

---

### US-03: Login de Usuarios
- **Story Points:** 5
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Sistema de autenticación con manejo de sesiones

**Tareas:**
1. Crear formulario de login JSP (1h)
2. Implementar servlet de autenticación (2h)
3. Manejo de sesiones seguro (2h)
4. Redirección por roles (1h)
5. Implementar logout (1h)
6. Testing de seguridad (1h)

**Definition of Done:**
- ✅ Autenticación segura funcional
- ✅ Sessions manejadas correctamente
- ✅ Redirección por rol
- ✅ Logout funcional

---

### US-04: Dashboard por Rol
- **Story Points:** 13
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Crear dashboards personalizados para cada rol de usuario

**Tareas:**
1. Diseñar layout base para dashboards (2h)
2. Implementar dashboard de Administrador (3h)
3. Implementar dashboard de Cliente (3h)
4. Implementar dashboard de Inmobiliaria (3h)
5. Implementar dashboard de Usuario básico (2h)
6. Navegación y menús por rol (2h)
7. Testing de accesos por rol (1h)

**Definition of Done:**
- ✅ Dashboard funcional para cada rol
- ✅ Acceso restringido por rol
- ✅ Navegación intuitiva
- ✅ Información relevante por rol

## Backlog del Sprint

| Tarea | Estimación | Estado | Asignado | Notas |
|-------|------------|--------|----------|-------|
| Configurar proyecto base | 2h | ✅ Done | Dana | Estructura MVC creada |
| Configurar BD y conexión | 2h | ✅ Done | Dana | MySQL local configurado |
| Landing page diseño | 2h | ✅ Done | Dana | Bootstrap implementado |
| Landing page desarrollo | 6h | ✅ Done | Dana | JSP con buscador básico |
| Formulario registro | 2h | ✅ Done | Dana | Validaciones incluidas |
| Servlet registro | 3h | ✅ Done | Dana | Encriptación implementada |
| Formulario login | 1h | ✅ Done | Dana | Design consistente |
| Servlet autenticación | 3h | ✅ Done | Dana | Sessions seguras |
| Dashboard Admin | 3h | ✅ Done | Dana | Estadísticas básicas |
| Dashboard Cliente | 3h | ✅ Done | Dana | Búsqueda y perfil |
| Dashboard Inmobiliaria | 3h | ✅ Done | Dana | Gestión propiedades |
| Dashboard Usuario | 2h | ✅ Done | Dana | Vista limitada |
| Testing general | 3h | ✅ Done | Dana | Todos los roles probados |

## Daily Scrum Summary

### Día 1 (01/09)
**Hecho ayer:** N/A (inicio de sprint)  
**Plan hoy:** Configurar proyecto base y estructura de BD  
**Impedimentos:** Ninguno  

### Día 2 (02/09)
**Hecho ayer:** Proyecto configurado, BD creada  
**Plan hoy:** Desarrollar landing page completa  
**Impedimentos:** Ninguno  

### Día 3 (03/09)
**Hecho ayer:** Landing page funcional  
**Plan hoy:** Sistema de registro completo  
**Impedimentos:** Ninguno  

### Día 4 (04/09)
**Hecho ayer:** Registro implementado y probado  
**Plan hoy:** Sistema de login y sesiones  
**Impedimentos:** Ninguno  

### Día 5 (05/09)
**Hecho ayer:** Login funcional  
**Plan hoy:** Dashboard de Administrador y Cliente  
**Impedimentos:** Ninguno  

### Día 6 (06/09)
**Hecho ayer:** Dashboards Admin y Cliente  
**Plan hoy:** Dashboard Inmobiliaria y Usuario  
**Impedimentos:** Ninguno  

### Día 7 (07/09)
**Hecho ayer:** Todos los dashboards  
**Plan hoy:** Testing final y documentación  
**Impedimentos:** Ninguno  

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación Aplicada |
|--------|--------------|---------|---------------------|
| Complejidad de manejo de sesiones | Media | Alto | Investigación previa, ejemplos simples |
| Problemas con Bootstrap | Baja | Medio | Documentación oficial, templates |
| Configuración BD compleja | Baja | Alto | Scripts preparados, testing temprano |

## Definición de Terminado (DoD)

Para que una User Story se considere "Done":

1. ✅ **Código desarrollado** según especificaciones
2. ✅ **Validaciones** implementadas (frontend y backend)
3. ✅ **Testing manual** completado
4. ✅ **Responsive design** verificado
5. ✅ **Integración BD** funcional
6. ✅ **Revisión de código** realizada
7. ✅ **Documentación** básica incluida

## Burndown Chart (Story Points)

| Día | Story Points Restantes | Ideal | Real |
|-----|------------------------|-------|------|
| 0 | 31 | 31 | 31 |
| 1 | 31 | 26.5 | 28 |
| 2 | 31 | 22 | 23 |
| 3 | 31 | 17.5 | 18 |
| 4 | 31 | 13 | 13 |
| 5 | 31 | 8.5 | 8 |
| 6 | 31 | 4 | 3 |
| 7 | 31 | 0 | 0 |

## Retrospectiva Sprint 1

### ¿Qué funcionó bien? (Keep)
- ✅ Configuración inicial del proyecto fue fluida
- ✅ Bootstrap aceleró el desarrollo del frontend
- ✅ Estructura MVC clara facilitó el desarrollo
- ✅ Planning detallado ayudó a mantener el foco

### ¿Qué no funcionó bien? (Stop)
- ❌ Subestimé tiempo para manejo de sesiones
- ❌ No consideré tiempo suficiente para debugging
- ❌ Faltó tiempo para refinamiento visual

### ¿Qué podemos mejorar? (Start)
- 🔄 Agregar más tiempo para testing en próximos sprints
- 🔄 Investigar tecnologías complejas antes del sprint
- 🔄 Crear templates reutilizables para JSPs
- 🔄 Implementar logging para facilitar debugging

### Acciones para Sprint 2
1. Agregar 20% más tiempo para testing
2. Crear biblioteca de componentes reutilizables
3. Investigar JDBC avanzado antes de iniciar
4. Preparar datos de prueba más realistas

## Entregables del Sprint 1

### Funcionalidades Implementadas
1. ✅ **Landing Page** - Página de inicio responsive con buscador
2. ✅ **Sistema de Registro** - Formulario completo con validaciones
3. ✅ **Sistema de Login** - Autenticación segura con sesiones
4. ✅ **Dashboards por Rol** - Vista personalizada para cada tipo de usuario

### Archivos Entregados
- `index.jsp` - Landing page
- `pages/register.jsp` - Formulario de registro
- `pages/login.jsp` - Formulario de login
- `pages/dashboard/` - Dashboards por rol

### Métricas del Sprint
- **Story Points completados:** 31/31 (100%)
- **Horas trabajadas:** 42/42 (100%)
- **User Stories completadas:** 4/4 (100%)
- **Bugs encontrados:** 3 (todos resueltos)
- **Velocity real:** 31 Story Points

## Sprint Review - Demostración

### Demo Script
1. **Mostrar Landing Page** - Navegación, responsive, buscador
2. **Proceso de Registro** - Validaciones, guardado en BD
3. **Login y Redirección** - Diferentes roles, manejo de sesiones
4. **Tour por Dashboards** - Admin, Inmobiliaria, Cliente, Usuario
5. **Logout y Seguridad** - Protección de rutas

### Feedback del Product Owner
- ✅ Cumple con expectativas básicas
- ✅ Interfaz limpia y profesional
- ✅ Funcionalidad core establecida
- 🔄 Mejorar mensajes de validación
- 🔄 Agregar más información en dashboards

### Próximos Pasos
- Sprint 2 se enfocará en gestión de propiedades
- Priorizar CRUD completo de propiedades
- Implementar búsqueda avanzada
- Mejorar experiencia de usuario

---

**Sprint 1 Status: ✅ COMPLETADO**  
**Fecha de finalización:** 07/09/2025  
**Próximo Sprint Planning:** 08/09/2025