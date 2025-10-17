// Slider functionality
document.addEventListener('DOMContentLoaded', function() {
    console.log('Slider script loaded');
    
    const sliderContainers = document.querySelectorAll('.slider-container');
    console.log('Found slider containers:', sliderContainers.length);
    
    sliderContainers.forEach((container, containerIndex) => {
        console.log(`Initializing slider ${containerIndex + 1}`);
        
        const track = container.querySelector('.slider-track');
        const items = container.querySelectorAll('.slider-item');
        const controlsContainer = container.querySelector('.slider-controls');
        
        console.log('Track:', track);
        console.log('Items:', items.length);
        console.log('Controls container:', controlsContainer);
        
        if (!track || !items.length || !controlsContainer) {
            console.log('Missing required elements, skipping slider');
            return;
        }
        
        let currentSlide = 0;
        let startX = 0;
        let currentX = 0;
        let isDragging = false;
        
        // Build controls dynamically based on number of items
        console.log('Building controls for', items.length, 'items');
        controlsContainer.innerHTML = ''; // Clear existing controls
        
        items.forEach((_, index) => {
            const control = document.createElement('div');
            control.className = `slider-control ${index === 0 ? 'active' : ''}`;
            control.setAttribute('data-slide', index);
            control.setAttribute('role', 'button');
            control.setAttribute('tabindex', '0');
            control.setAttribute('aria-label', `Go to slide ${index + 1}`);
            controlsContainer.appendChild(control);
            console.log(`Created control ${index + 1}`);
        });
        
        const controls = container.querySelectorAll('.slider-control');
        console.log('Controls created:', controls.length);
        
        // Function to show slide
        function showSlide(index) {
            if (index < 0 || index >= items.length) return;
            
            console.log(`Showing slide ${index + 1}`);
            
            // Remove active class from all items and controls
            items.forEach(item => item.classList.remove('active'));
            controls.forEach(control => control.classList.remove('active'));
            
            // Add active class to current slide and control
            if (items[index]) {
                items[index].classList.add('active');
            }
            if (controls[index]) {
                controls[index].classList.add('active');
            }
            
            currentSlide = index;
        }
        
        // Add click event listeners to controls
        controls.forEach((control, index) => {
            control.addEventListener('click', () => {
                console.log(`Control ${index + 1} clicked`);
                showSlide(index);
            });
            
            // Keyboard support
            control.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    showSlide(index);
                }
            });
        });
        
        // Touch/Swipe functionality
        function handleTouchStart(e) {
            startX = e.type === 'mousedown' ? e.clientX : e.touches[0].clientX;
            isDragging = true;
            track.style.cursor = 'grabbing';
        }
        
        function handleTouchMove(e) {
            if (!isDragging) return;
            
            e.preventDefault();
            currentX = e.type === 'mousemove' ? e.clientX : e.touches[0].clientX;
        }
        
        function handleTouchEnd() {
            if (!isDragging) return;
            
            isDragging = false;
            track.style.cursor = 'grab';
            
            const diffX = startX - currentX;
            const threshold = 50; // Minimum distance for swipe
            
            if (Math.abs(diffX) > threshold) {
                if (diffX > 0) {
                    // Swipe left - next slide
                    showSlide(currentSlide + 1);
                } else {
                    // Swipe right - previous slide
                    showSlide(currentSlide - 1);
                }
            }
        }
        
        // Mouse events
        track.addEventListener('mousedown', handleTouchStart);
        document.addEventListener('mousemove', handleTouchMove);
        document.addEventListener('mouseup', handleTouchEnd);
        
        // Touch events
        track.addEventListener('touchstart', handleTouchStart, { passive: false });
        track.addEventListener('touchmove', handleTouchMove, { passive: false });
        track.addEventListener('touchend', handleTouchEnd);
        
        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (e.target.closest('.slider-container')) {
                if (e.key === 'ArrowLeft') {
                    e.preventDefault();
                    showSlide(currentSlide - 1);
                } else if (e.key === 'ArrowRight') {
                    e.preventDefault();
                    showSlide(currentSlide + 1);
                }
            }
        });
        
        // Initialize first slide
        console.log('Initializing first slide');
        showSlide(0);
        
        console.log(`Slider ${containerIndex + 1} initialized successfully`);
    });
});

// Marquee Animation Controller - Reusable across the site
class MarqueeController {
    constructor(selector, options = {}) {
        this.track = document.querySelector(selector);
        if (!this.track) return;
        
        this.options = {
            speed: options.speed || 50, // pixels per second
            pauseOnHover: options.pauseOnHover !== false,
            direction: options.direction || 'left', // 'left' or 'right'
            ...options
        };
        
        this.isPaused = false;
        this.animationId = null;
        this.lastTime = null;
        this.currentPosition = 0;
        this.contentWidth = 0;
        
        this.init();
    }
    
    init() {
        // Clone content for seamless loop
        this.cloneContent();
        
        // Calculate content width
        this.calculateContentWidth();
        
        // Set initial position
        this.resetPosition();
        
        // Start animation
        this.start();
        
        // Add hover pause functionality
        if (this.options.pauseOnHover) {
            this.addHoverPause();
        }
    }
    
    cloneContent() {
        const originalContent = this.track.innerHTML;
        this.track.innerHTML = originalContent + originalContent;
    }
    
    calculateContentWidth() {
        // Get the width of the original content (before cloning)
        const originalWidth = this.track.scrollWidth / 2;
        this.contentWidth = originalWidth;
    }
    
    resetPosition() {
        if (this.options.direction === 'left') {
            this.currentPosition = 0;
            this.track.style.transform = 'translateX(0px)';
        } else {
            this.currentPosition = -this.contentWidth;
            this.track.style.transform = `translateX(${-this.contentWidth}px)`;
        }
    }
    
    start() {
        this.lastTime = performance.now();
        this.animate();
    }
    
    animate(currentTime = performance.now()) {
        if (this.isPaused) {
            this.animationId = requestAnimationFrame((time) => this.animate(time));
            return;
        }
        
        const deltaTime = currentTime - this.lastTime;
        this.lastTime = currentTime;
        
        // Calculate movement in pixels based on speed (pixels per second)
        const pixelsPerFrame = (this.options.speed * deltaTime) / 1000;
        
        if (this.options.direction === 'left') {
            this.currentPosition -= pixelsPerFrame;
            
            // Reset position when content has moved completely off screen
            if (this.currentPosition <= -this.contentWidth) {
                this.currentPosition = 0;
            }
        } else {
            this.currentPosition += pixelsPerFrame;
            
            // Reset position when content has moved completely off screen
            if (this.currentPosition >= 0) {
                this.currentPosition = -this.contentWidth;
            }
        }
        
        this.track.style.transform = `translateX(${this.currentPosition}px)`;
        
        this.animationId = requestAnimationFrame((time) => this.animate(time));
    }
    
    pause() {
        this.isPaused = true;
    }
    
    resume() {
        this.isPaused = false;
        this.lastTime = performance.now(); // Reset time to avoid jump
    }
    
    setSpeed(speed) {
        this.options.speed = speed;
    }
    
    destroy() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
    }
    
    addHoverPause() {
        this.track.addEventListener('mouseenter', () => this.pause());
        this.track.addEventListener('mouseleave', () => this.resume());
    }
}

// Make MarqueeController globally available for manual initialization
window.MarqueeController = MarqueeController;

// Global marquee control functions
window.marqueeControl = {
    // Control client logos marquee
    client: {
        setSpeed: (speed) => window.clientMarquee?.setSpeed(speed),
        pause: () => window.clientMarquee?.pause(),
        resume: () => window.clientMarquee?.resume()
    },
    
    // Control team marquee
    team: {
        setSpeed: (speed) => window.teamMarquee?.setSpeed(speed),
        pause: () => window.teamMarquee?.pause(),
        resume: () => window.teamMarquee?.resume()
    },
    
    // Create new marquee instance
    create: (selector, options) => new MarqueeController(selector, options)
};
