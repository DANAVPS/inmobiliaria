<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Acerca de Nosotros - Inmobiliaria J de la Espriella" />
    <jsp:param name="additionalCSS" value="about.css" />
</jsp:include>

<style>
:root {
    --vino: #722f37;
    --rojo: #d32f2f;
    --naranja: #ff9800;
    --amarillo: #ffc107;
}

.hero-about {
    background: linear-gradient(135deg, var(--vino), var(--rojo));
    color: white;
    padding: 80px 0;
    text-align: center;
}

.hero-about h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
    font-weight: bold;
}

.hero-about p {
    font-size: 1.2rem;
    max-width: 800px;
    margin: 0 auto;
    line-height: 1.6;
}

.about-content {
    padding: 80px 0;
}

.section {
    margin-bottom: 60px;
}

.section h2 {
    color: var(--vino);
    font-size: 2.5rem;
    margin-bottom: 2rem;
    text-align: center;
}

.section h3 {
    color: var(--rojo);
    font-size: 1.8rem;
    margin-bottom: 1rem;
}

.section p {
    font-size: 1.1rem;
    line-height: 1.8;
    color: #555;
    margin-bottom: 1.5rem;
}

.values-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
    gap: 30px;
    margin-top: 40px;
}

.value-card {
    background: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 4px 15px rgba(114, 47, 55, 0.1);
    text-align: center;
    transition: transform 0.3s ease;
}

.value-card:hover {
    transform: translateY(-5px);
}

.value-icon {
    width: 60px;
    height: 60px;
    background: linear-gradient(45deg, var(--naranja), var(--amarillo));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 20px;
    font-size: 1.5rem;
    color: white;
}

.stats-section {
    background: linear-gradient(135deg, var(--vino), var(--rojo));
    color: white;
    padding: 60px 0;
    text-align: center;
}

.stats-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 30px;
    max-width: 1000px;
    margin: 0 auto;
}

.stat-item h3 {
    font-size: 3rem;
    margin-bottom: 0.5rem;
    color: var(--amarillo);
}

.stat-item p {
    font-size: 1.1rem;
    margin: 0;
}

.team-section {
    background: #f8f9fa;
    padding: 80px 0;
}

.team-member {
    text-align: center;
    background: white;
    padding: 30px;
    border-radius: 10px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.member-photo {
    width: 150px;
    height: 150px;
    border-radius: 50%;
    background: linear-gradient(45deg, var(--vino), var(--rojo));
    margin: 0 auto 20px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 3rem;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

@media (max-width: 768px) {
    .hero-about h1 {
        font-size: 2rem;
    }
    
    .hero-about p {
        font-size: 1rem;
    }
    
    .section h2 {
        font-size: 2rem;
    }
    
    .values-grid {
        grid-template-columns: 1fr;
    }
}
</style>

<main>
    <!-- Hero Section -->
    <section class="hero-about">
        <div class="container">
            <h1>Inmobiliaria J de la Espriella</h1>
            <p>Más de dos décadas construyendo sueños y conectando familias con su hogar ideal en Colombia. Somos tu socio de confianza en cada paso del proceso inmobiliario.</p>
        </div>
    </section>

    <!-- Contenido Principal -->
    <section class="about-content">
        <div class="container">
            
            <!-- Nuestra Historia -->
            <div class="section">
                <h2>Nuestra Historia</h2>
                <p>Fundada en el corazón de Colombia, Inmobiliaria J de la Espriella nació con la visión de transformar el mercado inmobiliario mediante un servicio excepcional y un compromiso inquebrantable con nuestros clientes.</p>
                
                <p>Desde nuestros inicios, hemos sido testigos y protagonistas del crecimiento urbano del país, adaptándonos a las necesidades cambiantes del mercado y manteniéndonos siempre a la vanguardia de las mejores prácticas inmobiliarias.</p>
                
                <p>Nuestra trayectoria está marcada por miles de familias que han encontrado su hogar perfecto gracias a nuestro acompañamiento profesional y dedicado. Cada proyecto, cada venta, cada arrendamiento representa no solo una transacción comercial, sino la materialización de un sueño.</p>
            </div>

            <!-- Misión y Visión -->
            <div class="section">
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 40px;">
                    <div>
                        <h3>🎯 Nuestra Misión</h3>
                        <p>Facilitar el acceso a la vivienda y la inversión inmobiliaria, brindando servicios integrales de alta calidad que superen las expectativas de nuestros clientes, contribuyendo al desarrollo sostenible de las comunidades donde operamos.</p>
                    </div>
                    <div>
                        <h3>🔭 Nuestra Visión</h3>
                        <p>Ser la inmobiliaria líder en Colombia, reconocida por nuestra excelencia en el servicio, innovación tecnológica y compromiso social, construyendo un futuro donde cada persona tenga acceso a la vivienda que merece.</p>
                    </div>
                </div>
            </div>

            <!-- Nuestros Valores -->
            <div class="section">
                <h2>Nuestros Valores</h2>
                <div class="values-grid">
                    <div class="value-card">
                        <div class="value-icon">🏠</div>
                        <h3>Confianza</h3>
                        <p>Construimos relaciones duraderas basadas en la transparencia, honestidad y cumplimiento de nuestros compromisos.</p>
                    </div>
                    <div class="value-card">
                        <div class="value-icon">⭐</div>
                        <h3>Excelencia</h3>
                        <p>Nos esforzamos por superar las expectativas en cada servicio, manteniendo los más altos estándares de calidad.</p>
                    </div>
                    <div class="value-card">
                        <div class="value-icon">🤝</div>
                        <h3>Compromiso</h3>
                        <p>Dedicamos toda nuestra experiencia y recursos para lograr los objetivos de nuestros clientes.</p>
                    </div>
                    <div class="value-card">
                        <div class="value-icon">🚀</div>
                        <h3>Innovación</h3>
                        <p>Incorporamos constantemente nuevas tecnologías y metodologías para mejorar nuestros servicios.</p>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- Estadísticas -->
    <section class="stats-section">
        <div class="container">
            <h2 style="margin-bottom: 3rem;">Nuestros Logros</h2>
            <div class="stats-grid">
                <div class="stat-item">
                    <h3>25+</h3>
                    <p>Años de Experiencia</p>
                </div>
                <div class="stat-item">
                    <h3>5,000+</h3>
                    <p>Propiedades Vendidas</p>
                </div>
                <div class="stat-item">
                    <h3>15,000+</h3>
                    <p>Clientes Satisfechos</p>
                </div>
                <div class="stat-item">
                    <h3>98%</h3>
                    <p>Tasa de Satisfacción</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Equipo -->
    <section class="team-section">
        <div class="container">
            <h2 style="color: var(--vino); text-align: center; margin-bottom: 3rem;">Nuestro Equipo</h2>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 30px;">
                <div class="team-member">
                    <div class="member-photo">JE</div>
                    <h3>J. de la Espriella</h3>
                    <p style="color: var(--rojo); font-weight: bold;">Fundador y Director General</p>
                    <p>Visionario líder con más de 25 años de experiencia en el sector inmobiliario colombiano.</p>
                </div>
                <div class="team-member">
                    <div class="member-photo">👩‍💼</div>
                    <h3>Equipo Comercial</h3>
                    <p style="color: var(--rojo); font-weight: bold;">Asesores Especializados</p>
                    <p>Profesionales certificados dedicados a encontrar la propiedad perfecta para cada cliente.</p>
                </div>
                <div class="team-member">
                    <div class="member-photo">⚖️</div>
                    <h3>Departamento Legal</h3>
                    <p style="color: var(--rojo); font-weight: bold;">Asesoría Jurídica</p>
                    <p>Expertos legales que garantizan procesos transparentes y seguros en cada transacción.</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Compromiso Social -->
    <section class="about-content">
        <div class="container">
            <div class="section">
                <h2>Compromiso Social</h2>
                <p>En J de la Espriella creemos que el desarrollo inmobiliario debe ir de la mano con el progreso social. Por eso, participamos activamente en programas de vivienda de interés social y apoyamos iniciativas que contribuyen al mejoramiento de las comunidades.</p>
                
                <p>Nuestro compromiso va más allá de las transacciones comerciales: trabajamos por construir un futuro más equitativo donde el acceso a una vivienda digna sea una realidad para todos los colombianos.</p>
            </div>
        </div>
    </section>
</main>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />