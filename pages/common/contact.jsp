<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<!-- Incluir header -->
<jsp:include page="../../includes/header.jsp">
    <jsp:param name="title" value="Contacto - Inmobiliaria J de la Espriella" />
    <jsp:param name="additionalCSS" value="contact.css" />
</jsp:include>

<style>
:root {
    --vino: #722f37;
    --rojo: #d32f2f;
    --naranja: #ff9800;
    --amarillo: #ffc107;
}

.hero-contact {
    background: linear-gradient(135deg, var(--vino), var(--rojo));
    color: white;
    padding: 80px 0;
    text-align: center;
}

.hero-contact h1 {
    font-size: 3rem;
    margin-bottom: 1rem;
    font-weight: bold;
}

.hero-contact p {
    font-size: 1.2rem;
    max-width: 600px;
    margin: 0 auto;
    line-height: 1.6;
}

.contact-content {
    padding: 80px 0;
}

.contact-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 60px;
    align-items: start;
}

.contact-info {
    background: #f8f9fa;
    padding: 40px;
    border-radius: 10px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.contact-info h2 {
    color: var(--vino);
    font-size: 2rem;
    margin-bottom: 2rem;
}

.info-item {
    display: flex;
    align-items: center;
    margin-bottom: 2rem;
    padding: 15px;
    background: white;
    border-radius: 8px;
    transition: transform 0.3s ease;
}

.info-item:hover {
    transform: translateX(5px);
}

.info-icon {
    width: 50px;
    height: 50px;
    background: linear-gradient(45deg, var(--naranja), var(--amarillo));
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-right: 15px;
    color: white;
    font-size: 1.2rem;
}

.info-details h3 {
    color: var(--vino);
    margin: 0 0 5px 0;
    font-size: 1.1rem;
}

.info-details p {
    color: #666;
    margin: 0;
    font-size: 0.95rem;
}

.contact-form {
    background: white;
    padding: 40px;
    border-radius: 10px;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.contact-form h2 {
    color: var(--vino);
    font-size: 2rem;
    margin-bottom: 2rem;
}

.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    margin-bottom: 0.5rem;
    color: var(--vino);
    font-weight: bold;
}

.form-control {
    width: 100%;
    padding: 12px 15px;
    border: 2px solid #ddd;
    border-radius: 5px;
    font-size: 1rem;
    transition: border-color 0.3s ease;
}

.form-control:focus {
    outline: none;
    border-color: var(--rojo);
    box-shadow: 0 0 5px rgba(211, 47, 47, 0.3);
}

textarea.form-control {
    resize: vertical;
    min-height: 120px;
}

.btn-submit {
    background: linear-gradient(45deg, var(--rojo), var(--naranja));
    color: white;
    border: none;
    padding: 15px 30px;
    border-radius: 5px;
    font-size: 1.1rem;
    font-weight: bold;
    cursor: pointer;
    transition: transform 0.3s ease;
    width: 100%;
}

.btn-submit:hover {
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(211, 47, 47, 0.4);
}

.map-section {
    background: #f8f9fa;
    padding: 80px 0;
}

.map-container {
    background: white;
    border-radius: 10px;
    overflow: hidden;
    box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
    height: 400px;
    display: flex;
    align-items: center;
    justify-content: center;
    color: #666;
    font-size: 1.1rem;
}

.office-hours {
    background: linear-gradient(135deg, var(--vino), var(--rojo));
    color: white;
    padding: 60px 0;
}

.hours-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 30px;
}

.hours-card {
    background: rgba(255, 255, 255, 0.1);
    padding: 30px;
    border-radius: 10px;
    text-align: center;
    backdrop-filter: blur(10px);
}

.hours-card h3 {
    color: var(--amarillo);
    margin-bottom: 1rem;
    font-size: 1.3rem;
}

.hours-card p {
    margin: 0.5rem 0;
    font-size: 1rem;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

.social-links {
    display: flex;
    gap: 15px;
    margin-top: 20px;
}

.social-link {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    background: linear-gradient(45deg, var(--naranja), var(--amarillo));
    color: white;
    border-radius: 50%;
    text-decoration: none;
    transition: transform 0.3s ease;
}

.social-link:hover {
    transform: scale(1.1);
    color: white;
}

@media (max-width: 768px) {
    .hero-contact h1 {
        font-size: 2rem;
    }
    
    .contact-grid {
        grid-template-columns: 1fr;
        gap: 40px;
    }
    
    .contact-info,
    .contact-form {
        padding: 20px;
    }
    
    .hours-grid {
        grid-template-columns: 1fr;
    }
}
</style>

<main>
    <!-- Hero Section -->
    <section class="hero-contact">
        <div class="container">
            <h1>Contáctanos</h1>
            <p>Estamos aquí para ayudarte a encontrar la propiedad perfecta. Nuestro equipo de expertos está listo para atenderte.</p>
        </div>
    </section>

    <!-- Formulario y Info de Contacto -->
    <section class="contact-content">
        <div class="container">
            <div class="contact-grid">
                
                <!-- Información de Contacto -->
                <div class="contact-info">
                    <h2>Información de Contacto</h2>
                    
                    <div class="info-item">
                        <div class="info-icon">📍</div>
                        <div class="info-details">
                            <h3>Oficina Principal</h3>
                            <p>Calle Vista Alegre, 13<br>Valencia<br>C.P. 10445</p>
                        </div>
                    </div>

                    <div class="info-item">
                        <div class="info-icon">📞</div>
                        <div class="info-details">
                            <h3>Teléfonos</h3>
                            <p>Fijo: (+57) 7 622-3456<br>Móvil:  (+57) 123 4567890<br>WhatsApp: (+57) 300 123-4567</p>
                        </div>
                    </div>

                    <div class="info-item">
                        <div class="info-icon">✉️</div>
                        <div class="info-details">
                            <h3>Correo Electrónico</h3>
                            <p> jdelasp@unsitiogenial.es<br>ventas@jdelaespriella.com<br>administracion@jdelaespriella.com</p>
                        </div>
                    </div>

                    <div class="info-item">
                        <div class="info-icon">🌐</div>
                        <div class="info-details">
                            <h3>Redes Sociales</h3>
                            <p>Síguenos en nuestras redes</p>
                            <div class="social-links">
                                <a href="#" class="social-link" title="Facebook">📘</a>
                                <a href="#" class="social-link" title="Instagram">📷</a>
                                <a href="#" class="social-link" title="WhatsApp">💬</a>
                                <a href="#" class="social-link" title="YouTube">🎥</a>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Formulario de Contacto -->
                <div class="contact-form">
                    <h2>Envíanos un Mensaje</h2>
                    <form action="contact" method="post">
                        <div class="form-group">
                            <label for="nombre">Nombre Completo *</label>
                            <input type="text" id="nombre" name="nombre" class="form-control" required>
                        </div>

                        <div class="form-group">
                            <label for="email">Correo Electrónico *</label>
                            <input type="email" id="email" name="email" class="form-control" required>
                        </div>

                        <div class="form-group">
                            <label for="telefono">Teléfono</label>
                            <input type="tel" id="telefono" name="telefono" class="form-control">
                        </div>

                        <div class="form-group">
                            <label for="asunto">Asunto *</label>
                            <select id="asunto" name="asunto" class="form-control" required>
                                <option value="">Selecciona un asunto</option>
                                <option value="compra">Quiero Comprar</option>
                                <option value="venta">Quiero Vender</option>
                                <option value="arriendo">Arriendo</option>
                                <option value="avaluo">Avalúo</option>
                                <option value="administracion">Administración</option>
                                <option value="otro">Otro</option>
                            </select>
                        </div>

                        <div class="form-group">
                            <label for="mensaje">Mensaje *</label>
                            <textarea id="mensaje" name="mensaje" class="form-control" 
                                    placeholder="Cuéntanos en qué podemos ayudarte..." required></textarea>
                        </div>

                        <a href="#" class="btn-submit" title="Enviar Mensaje 📨">
                        Enviar Mensaje 📨
                        </a>
                    </form>
                </div>
            </div>
        </div>
    </section>

    <!-- Horarios de Atención -->
    <section class="office-hours">
        <div class="container">
            <h2 style="text-align: center; margin-bottom: 3rem; color: var(--amarillo);">Horarios de Atención</h2>
            <div class="hours-grid">
                <div class="hours-card">
                    <h3>🏢 Oficina Principal</h3>
                    <p><strong>Lunes a Viernes:</strong> 8:00 AM - 6:00 PM</p>
                    <p><strong>Sábados:</strong> 8:00 AM - 4:00 PM</p>
                    <p><strong>Domingos:</strong> Cerrado</p>
                </div>
                
                <div class="hours-card">
                    <h3>💬 Atención WhatsApp</h3>
                    <p><strong>Lunes a Viernes:</strong> 7:00 AM - 8:00 PM</p>
                    <p><strong>Sábados:</strong> 8:00 AM - 6:00 PM</p>
                    <p><strong>Domingos:</strong> 9:00 AM - 5:00 PM</p>
                </div>
                
                <div class="hours-card">
                    <h3>🚨 Emergencias</h3>
                    <p><strong>Administración:</strong> 24/7</p>
                    <p><strong>Mantenimiento:</strong> 24/7</p>
                    <p><strong>Teléfono:</strong> (+57) 300 123-4567</p>
                </div>
            </div>
        </div>
    </section>

    <!-- Información Adicional -->
    <section class="contact-content">
        <div class="container">
            <div style="text-align: center; max-width: 800px; margin: 0 auto;">
                <h2 style="color: var(--vino); margin-bottom: 2rem;">¿Cómo Podemos Ayudarte?</h2>
                
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 30px; margin: 40px 0;">
                    <div style="padding: 20px; border-left: 4px solid var(--rojo);">
                        <h4 style="color: var(--vino); margin-bottom: 1rem;">🏠 Compra y Venta</h4>
                        <p style="color: #666; margin: 0;">Te acompañamos en todo el proceso de compra o venta de tu propiedad.</p>
                    </div>
                    
                    <div style="padding: 20px; border-left: 4px solid var(--naranja);">
                        <h4 style="color: var(--vino); margin-bottom: 1rem;">🔑 Arrendamiento</h4>
                        <p style="color: #666; margin: 0;">Servicios integrales de arrendamiento para propietarios e inquilinos.</p>
                    </div>
                    
                    <div style="padding: 20px; border-left: 4px solid var(--amarillo);">
                        <h4 style="color: var(--vino); margin-bottom: 1rem;">📊 Avalúos</h4>
                        <p style="color: #666; margin: 0;">Avalúos comerciales certificados por profesionales especializados.</p>
                    </div>
                    
                    <div style="padding: 20px; border-left: 4px solid var(--vino);">
                        <h4 style="color: var(--vino); margin-bottom: 1rem;">🏢 Administración</h4>
                        <p style="color: #666; margin: 0;">Administración profesional de propiedades y conjuntos residenciales.</p>
                    </div>
                </div>
                
                <div style="background: #f8f9fa; padding: 30px; border-radius: 10px; margin-top: 40px;">
                    <p style="margin: 0; font-size: 1.1rem; color: var(--vino);">
                        <strong>💡 ¿Tienes una consulta específica?</strong><br>
                        No dudes en contactarnos. Nuestro equipo de profesionales está listo para brindarte la mejor asesoría en el mercado inmobiliario.
                    </p>
                </div>
            </div>
        </div>
    </section>
</main>

<!-- Incluir footer -->
<jsp:include page="../../includes/footer.jsp" />