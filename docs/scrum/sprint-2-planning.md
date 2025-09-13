# Sprint 2 Planning - Sistema Inmobiliaria

## Información del Sprint
- **Sprint:** #2
- **Duración:** 7 días (08/09/2025 - 14/09/2025)
- **Sprint Goal:** Implementar gestión completa de propiedades y búsqueda avanzada
- **Scrum Master:** Dana Valentina Pacheco Sandoval
- **Product Owner:** Dana Valentina Pacheco Sandoval
- **Development Team:** Dana Valentina Pacheco Sandoval

## Sprint Goal

"Al final de este sprint, las inmobiliarias podrán gestionar completamente sus propiedades (agregar, editar, eliminar) y todos los usuarios podrán buscar y filtrar propiedades de manera eficiente, además los administradores podrán gestionar usuarios del sistema."

## Capacidad del Sprint
- **Días disponibles:** 7 días
- **Horas por día:** 6 horas
- **Capacidad total:** 42 horas
- **Velocity estimada:** 37 Story Points (ajustada por experiencia Sprint 1)

## User Stories Seleccionadas

### US-05: CRUD de Propiedades
- **Story Points:** 13
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Sistema completo para que inmobiliarias gestionen sus propiedades

**Tareas:**
1. Crear modelo/entidad Propiedad (1h)
2. Implementar formulario agregar propiedad JSP (3h)
3. Servlet para crear propiedades (2h)
4. Listado de propiedades de la inmobiliaria (2h)
5. Formulario editar propiedad (2h)
6. Servlet para actualizar propiedades (1h)
7. Función eliminar (lógica) propiedades (1h)
8. Validaciones y manejo de errores (1h)

**Definition of Done:**
- ✅ CRUD completo funcional
- ✅ Validaciones implementadas
- ✅ Solo inmobiliarias pueden gestionar sus propiedades
- ✅ Interface intuitiva

---

### US-06: Búsqueda Básica
- **Story Points:** 8
- **Prioridad:** Alta
- **Asignado a:** Dana Pacheco
- **Descripción:** Mejorar el buscador básico de la landing page

**Tareas:**
1. Servlet de búsqueda de propiedades (2h)
2. Página de resultados JSP (2h)
3. Búsqueda por ubicación (1h)
4. Filtro por tipo de operación (1h)
5. Filtro por tipo de propiedad (1h)
6. Paginación de resultados (1h)

**Definition of Done:**
- ✅ Búsqueda funcional desde landing page
- ✅ Resultados precisos y ordenados
- ✅ Interface responsive
- ✅ Performance optimizada

---

### US-07: Filtros Avanzados
- **Story Points:** 8
- **Prioridad:** Media
- **Asignado a:** Dana Pacheco
- **Descripción:** Implementar filtros específicos para búsqueda avanzada

**Tareas:**
1. Filtros por rango de precios (2h)
2. Filtros por número de habitaciones/baños (2h)
3. Filtro por área mínima (1h)
4. Combinación de múltiples filtros (2h)
5. Limpiar filtros y reset (1h)

**Definition of Done:**
- ✅ Filtros funcionan individualmente y combinados
- ✅ Interface intuitiva para usar filtros
- ✅ Resultados actualizados dinámicamente
- ✅ Opción de limpiar filtros

---

### US-08: Gestión de Usuarios (Admin)
- **Story Points:** 8
- **Prioridad:** Media
- **Asignado a:** Dana Pacheco
- **Descripción:** Panel de administración para gestionar todos los usuarios del sistema

**Tareas:**
1. Listado completo de usuarios (2h)
2. Ver detalles de cada usuario (1h)
3. Editar información de usuarios (2h)
4. Cambiar roles de usuarios (1h)
5. Activar/desactivar usuarios (1h)
6. Búsqueda de usuarios (1h)

**Definition of Done:**
- ✅ CRUD completo de usuarios para admin
- ✅ Solo accesible por administradores
- ✅ Validaciones de seguridad
- ✅ Interface clara y funcional

## Backlog del Sprint

| Tarea | Estimación | Estado | Asignado | Notas |
|-------|------------|--------|----------|-------|
| Modelo Propiedad | 1h | ✅ Done | Dana | Entidad con todos los campos |
| Formulario agregar propiedad | 3h | ✅ Done | Dana | Validaciones incluidas |
| Servlet crear propiedad | 2h | ✅ Done | Dana | Conexión BD funcional |
| Listado propiedades inmobiliaria | 2h | ✅ Done | Dana | Paginación implementada |
| Formulario editar propiedad | 2h | ✅ Done | Dana | Pre-carga de datos |
| Servlet actualizar propiedad | 1h | ✅ Done | Dana | Validaciones incluidas |
| Eliminar propiedades (lógica) | 1h | ✅ Done | Dana | Cambio de estado |
| Validaciones CRUD propiedades | 1h | ✅ Done | Dana | Frontend y backend |
| Servlet búsqueda básica | 2h | ✅ Done | Dana | Consultas optimizadas |
| Página resultados búsqueda | 2h | ✅ Done | Dana | Design responsive |
| Filtros tipo operación/propiedad | 2h | ✅ Done | Dana | Dropdowns dinámicos |
| Paginación resultados | 1h | ✅ Done | Dana | Navegación fluida |
| Filtros rango precios | 2h | ✅ Done | Dana | Sliders implementados |
| Filtros habitaciones/baños | 2h | ✅ Done | Dana | Contadores intuitivos |
| Filtro área mínima | 1h | ✅ Done | Dana | Input numérico |
| Combinación filtros | 2h | ✅ Done | Dana | Lógica compleja |
| Reset filtros | 1h | ✅ Done | Dana | Botón limpiar |
| Listado usuarios admin | 2h | ✅ Done | Dana | Tabla completa |
| Editar usuarios | 3h | ✅ Done | Dana | CRUD funcional |
| Cambiar roles | 1h | ✅ Done | Dana | Dropdown roles |
| Activar/desactivar usuarios | 1h | ✅ Done | Dana | Toggle estado |
| Búsqueda usuarios | 1h | ✅ Done | Dana | Filtro por nombre/email |
| Testing integración | 3h | ✅ Done | Dana | Todos los módulos |

## Daily Scrum Summary

### Día 1 (08/09)
**Hecho ayer:** Sprint 1 completado exitosamente  
**Plan hoy:** Modelo Propiedad y formulario agregar  
**Impedimentos:** Ninguno  

### Día 2 (09/09)
**Hecho ayer:** Formulario agregar propiedad funcional  
**Plan hoy:** Servlets CRUD y listado propiedades  
**Impedimentos:** Complejidad de consultas SQL  

### Día 3 (10/09)
**Hecho ayer:** CRUD propiedades básico  
**Plan hoy:** Editar/eliminar propiedades  
**Impedimentos:** Validaciones complejas  

### Día 4 (11/09)
**Hecho ayer:** CRUD completo de propiedades  
**Plan hoy:** Sistema de búsqueda básica  
**Impedimentos:** Ninguno  

### Día 5 (12/09)
**Hecho ayer:** Búsqueda básica funcional  
**Plan hoy:** Filtros avanzados  
**Impedimentos:** Combinación de filtros compleja  

### Día 6 (13/09)
**Hecho ayer:** Filtros avanzados implementados  
**Plan hoy:** Gestión de usuarios admin  
**Impedimentos:** Ninguno  

### Día 7 (14/09)
**Hecho ayer:** Gestión usuarios completa  
**Plan hoy:** Testing final y refinamiento  
**Impedimentos:** Ninguno  

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación Aplicada |
|--------|--------------|---------|---------------------|
| Consultas SQL complejas | Alta | Medio | Investigación previa, pruebas unitarias |
| Performance en búsquedas | Media | Alto | Índices en BD, consultas optimizadas |
| Validaciones complejas | Media | Medio | Validaciones incrementales |
| Combinación de filtros | Alta | Medio | Lógica modular, testing exhaustivo |

## Burndown Chart (Story Points)

| Día | Story Points Restantes | Ideal | Real |
|-----|------------------------|-------|------|
| 0 | 37 | 37 | 37 |
| 1 | 37 | 31.5 | 32 |
| 2 | 37 | 26 | 25 |
| 3 | 37 | 20.5 | 18 |
| 4 | 37 | 15 | 12 |
| 5 | 37 | 9.5 | 8 |
| 6 | 37 | 4 | 3 |
| 7 | 37 | 0 | 0 |

## Retrospectiva Sprint 2

### ¿Qué funcionó bien? (Keep)
- ✅ CRUD de propiedades más complejo pero exitoso
- ✅ Búsqueda básica implementada eficientemente
- ✅ Filtros avanzados funcionan correctamente
- ✅ Gestión de usuarios admin completamente funcional
- ✅ Performance de consultas acceptable

### ¿Qué no funcionó bien? (Stop)
- ❌ Subestimé complejidad de combinación de filtros
- ❌ Validaciones tomaron más tiempo del esperado
- ❌ Faltó tiempo para optimización de queries

### ¿Qué podemos mejorar? (Start)
- 🔄 Crear queries preparadas reutilizables
- 🔄 Implementar logging para debugging
- 🔄 Agregar más datos de prueba realistas
- 🔄 Considerar paginación desde el inicio

### Acciones para Sprint 3
1. Optimizar consultas antes de implementar nuevas funciones
2. Crear más datos de prueba para testing realista
3. Implementar manejo de errores más robusto
4. Preparar componentes reutilizables para Sprint 3

## Entregables del Sprint 2

### Funcionalidades Implementadas
1. ✅ **CRUD Propiedades** - Gestión completa para inmobiliarias
2. ✅ **Búsqueda Básica** - Sistema de búsqueda mejorado
3. ✅ **Filtros Avanzados** - Filtrado específico de propiedades
4. ✅ **Gestión Usuarios** - Panel administrativo completo

### Archivos Entregados
- `/pages/properties` -  Páginas de Propiedad
- `/pages/inmobiliaria/` - Páginas gestión propiedades
- `/pages/admin/` - Panel administración usuarios

### Métricas del Sprint
- **Story Points completados:** 37/37 (100%)
- **Horas trabajadas:** 42/42 (100%)
- **User Stories completadas:** 4/4 (100%)
- **Bugs encontrados:** 5 (todos resueltos)
- **Velocity real:** 37 Story Points

## Sprint Review - Demostración

### Demo Script
1. **Login como Inmobiliaria** - Acceso al dashboard
2. **Agregar Nueva Propiedad** - Formulario completo, validaciones
3. **Editar Propiedad Existente** - Modificar datos, guardar cambios
4. **Eliminar Propiedad** - Cambio de estado, confirmación
5. **Búsqueda desde Landing** - Diferentes criterios de búsqueda
6. **Filtros Avanzados** - Rango precios, habitaciones, combinaciones
7. **Login como Admin** - Gestión de usuarios, cambio de roles

### Feedback del Product Owner
- ✅ CRUD de propiedades robusto y completo
- ✅ Sistema de búsqueda intuitivo y rápido
- ✅ Filtros avanzados funcionan perfectamente
- ✅ Panel admin muy útil y completo
- 🔄 Mejorar mensajes de confirmación
- 🔄 Agregar preview de imágenes en formularios

### Próximos Pasos
- Sprint 3 se enfocará en sistema de citas
- Implementar detalles de propiedades
- Mejorar perfil de usuario
- Agregar reportes básicos

## Impedimentos Resueltos

1. **Consultas SQL complejas:** Resuelto con investigación y pruebas incrementales
2. **Validaciones complejas:** Implementadas gradualmente con testing
3. **Combinación filtros:** Lógica modular facilitó implementación
4. **Performance búsquedas:** Índices en BD mejoraron velocidad

## Lecciones Aprendidas

1. **Planificación detallada** reduce impedimentos técnicos
2. **Testing incremental** detecta errores temprano
3. **Consultas optimizadas** son críticas para performance
4. **Validaciones robustas** mejoran experiencia usuario
5. **Modularidad** facilita mantenimiento y testing

---

**Sprint 2 Status: ✅ COMPLETADO**  
**Fecha de finalización:** 14/09/2025  
**Próximo Sprint Planning:** 15/09/2025