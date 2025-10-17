/**
 * MarqueeController - Универсальный класс для создания бегущей строки
 * Поддерживает паузу при наведении, разные направления и скорости
 */
class MarqueeController {
    constructor(selector, options = {}) {
        this.track = typeof selector === 'string' 
            ? document.querySelector(selector) 
            : selector;
            
        if (!this.track) {
            console.warn('MarqueeController: Element not found', selector);
            return;
        }

        // Настройки по умолчанию
        this.options = {
            speed: 50, // пикселей в секунду
            pauseOnHover: true,
            direction: 'left', // 'left' или 'right'
            gap: 20, // расстояние между клонами
            autoStart: true,
            ...options
        };

        this.isPaused = false;
        this.animationId = null;
        this.position = 0;
        this.trackWidth = 0;
        this.contentWidth = 0;

        this.init();
    }

    init() {
        // Подготовка контейнера
        this.setupContainer();
        
        // Клонирование контента для бесшовного цикла
        this.duplicateContent();
        
        // Расчет размеров
        this.calculateDimensions();
        
        // Настройка событий
        this.setupEventListeners();
        
        // Запуск анимации
        if (this.options.autoStart) {
            this.start();
        }
        
        // Обновление при изменении размера окна
        this.handleResize();
    }

    setupContainer() {
        // Убеждаемся, что у трека правильные стили
        this.track.style.display = 'flex';
        this.track.style.flexWrap = 'nowrap';
        
        // Сохраняем оригинальные элементы
        this.originalItems = Array.from(this.track.children);
    }

    duplicateContent() {
        // Очищаем предыдущие клоны если есть
        const clones = this.track.querySelectorAll('[data-marquee-clone]');
        clones.forEach(clone => clone.remove());
        
        // Определяем сколько нужно копий для бесшовности
        const viewportWidth = window.innerWidth;
        const itemsWidth = this.getItemsWidth();
        const copiesNeeded = Math.ceil(viewportWidth / itemsWidth) + 2;
        
        // Создаем нужное количество копий
        for (let i = 0; i < copiesNeeded; i++) {
            this.originalItems.forEach(item => {
                const clone = item.cloneNode(true);
                clone.setAttribute('data-marquee-clone', 'true');
                clone.setAttribute('aria-hidden', 'true'); // Для доступности
                this.track.appendChild(clone);
            });
        }
    }

    getItemsWidth() {
        let totalWidth = 0;
        this.originalItems.forEach(item => {
            const rect = item.getBoundingClientRect();
            totalWidth += rect.width + this.options.gap;
        });
        return totalWidth;
    }

    calculateDimensions() {
        const items = this.track.children;
        let totalWidth = 0;
        
        Array.from(items).forEach(item => {
            const rect = item.getBoundingClientRect();
            totalWidth += rect.width + this.options.gap;
        });
        
        this.contentWidth = totalWidth / 2; // Половина, так как контент дублирован
        this.trackWidth = this.track.getBoundingClientRect().width;
    }

    setupEventListeners() {
        if (this.options.pauseOnHover) {
            this.track.addEventListener('mouseenter', () => this.pause());
            this.track.addEventListener('mouseleave', () => this.resume());
            
            // Поддержка тач-устройств
            this.track.addEventListener('touchstart', () => this.pause());
            this.track.addEventListener('touchend', () => this.resume());
        }
        
        // Обработка изменения видимости страницы
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.pause();
            } else {
                this.resume();
            }
        });
    }

    animate() {
        if (this.isPaused) return;
        
        const speed = this.options.speed / 60; // Конвертируем в пиксели за кадр
        
        if (this.options.direction === 'left') {
            this.position -= speed;
            if (Math.abs(this.position) >= this.contentWidth) {
                this.position = 0;
            }
        } else {
            this.position += speed;
            if (this.position >= this.contentWidth) {
                this.position = 0;
            }
        }
        
        this.track.style.transform = `translateX(${this.position}px)`;
        
        this.animationId = requestAnimationFrame(() => this.animate());
    }

    start() {
        if (this.animationId) return;
        this.isPaused = false;
        this.animate();
    }

    stop() {
        this.isPaused = true;
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
            this.animationId = null;
        }
    }

    pause() {
        this.isPaused = true;
    }

    resume() {
        this.isPaused = false;
        if (!this.animationId) {
            this.animate();
        }
    }

    setSpeed(speed) {
        this.options.speed = speed;
    }

    setDirection(direction) {
        if (direction !== 'left' && direction !== 'right') return;
        this.options.direction = direction;
    }

    handleResize() {
        let resizeTimer;
        window.addEventListener('resize', () => {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(() => {
                this.duplicateContent();
                this.calculateDimensions();
            }, 250);
        });
    }

    destroy() {
        this.stop();
        
        // Удаляем клоны
        const clones = this.track.querySelectorAll('[data-marquee-clone]');
        clones.forEach(clone => clone.remove());
        
        // Сбрасываем стили
        this.track.style.transform = '';
        
        // Удаляем обработчики событий
        this.track.removeEventListener('mouseenter', () => this.pause());
        this.track.removeEventListener('mouseleave', () => this.resume());
        this.track.removeEventListener('touchstart', () => this.pause());
        this.track.removeEventListener('touchend', () => this.resume());
    }
}

// Экспортируем для использования
window.MarqueeController = MarqueeController;

// Автоматическая инициализация всех marquee на странице
document.addEventListener('DOMContentLoaded', () => {
    // Логотипы клиентов на главной
    const clientMarquee = document.querySelector('#logo-masonry-marquee');
    if (clientMarquee) {
        new MarqueeController(clientMarquee, {
            speed: 30,
            pauseOnHover: true,
            direction: 'left'
        });
    }
    
    // Команда
    const teamMarquees = document.querySelectorAll('.marquee-track-top, .client-marquee-track, #marquee-track');
    teamMarquees.forEach(track => {
        new MarqueeController(track, {
            speed: 50,
            pauseOnHover: true,
            direction: 'left'
        });
    });
});