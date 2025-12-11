// Smooth scroll functionality
function scrollToSection(sectionId) {
    const section = document.getElementById(sectionId);
    if (section) {
        section.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

// Add scroll listener for navbar blur effect
let lastScroll = 0;
window.addEventListener('scroll', () => {
    const navbar = document.querySelector('.navbar');
    const currentScroll = window.pageYOffset;
    
    if (currentScroll > 50) {
        navbar.style.background = 'rgba(17, 24, 39, 0.95)';
        navbar.style.backdropFilter = 'blur(20px)';
    } else {
        navbar.style.background = 'rgba(17, 24, 39, 0.8)';
        navbar.style.backdropFilter = 'blur(10px)';
    }
    
    lastScroll = currentScroll;
});

// Animated counter for stats
function animateCounter(element, target, duration = 2000, suffix = '') {
    const start = 0;
    const increment = target / (duration / 16);
    let current = start;
    
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            current = target;
            clearInterval(timer);
        }
        
        // Format number with commas or decimals based on target
        let displayValue;
        if (target >= 1000000) {
            displayValue = (current / 1000000).toFixed(1) + 'M';
        } else if (target >= 1000) {
            displayValue = (current / 1000).toFixed(1) + 'K';
        } else if (target < 100) {
            displayValue = current.toFixed(1);
        } else {
            displayValue = Math.floor(current).toLocaleString();
        }
        
        element.textContent = displayValue + suffix;
    }, 16);
}

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -100px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            
            // Trigger counter animation for stats
            if (entry.target.classList.contains('stat-card')) {
                const numberElement = entry.target.querySelector('.stat-number');
                const valueAttr = numberElement.getAttribute('data-value');
                const suffix = numberElement.getAttribute('data-suffix') || '';
                
                if (valueAttr && !numberElement.classList.contains('animated')) {
                    const targetValue = parseFloat(valueAttr);
                    animateCounter(numberElement, targetValue, 2000, suffix);
                    numberElement.classList.add('animated');
                }
            }
            
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all feature cards, how-it-works steps, and stat cards
document.addEventListener('DOMContentLoaded', () => {
    // Add fade-in class to elements that should animate
    const animatedElements = document.querySelectorAll('.feature-card, .step-card, .stat-card, .cta-content');
    animatedElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(30px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
    
    // Add visible class helper
    const style = document.createElement('style');
    style.textContent = `
        .visible {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);
    
    // Initialize stat numbers with data attributes
    const stats = [
        { selector: '#tvl-stat', value: 150000000, suffix: '' },  // $150M
        { selector: '#transactions-stat', value: 50000, suffix: '+' },  // 50,000+
        { selector: '#institutions-stat', value: 200, suffix: '+' },  // 200+
        { selector: '#apy-stat', value: 12.5, suffix: '%' }  // 12.5%
    ];
    
    stats.forEach(stat => {
        const element = document.querySelector(stat.selector);
        if (element) {
            element.setAttribute('data-value', stat.value);
            element.setAttribute('data-suffix', stat.suffix);
            element.textContent = '0' + stat.suffix;
        }
    });
});

// Blob animation for hero background
function animateBlobs() {
    const blobs = document.querySelectorAll('.blob');
    
    blobs.forEach((blob, index) => {
        const duration = 20 + (index * 5);
        const delay = index * 2;
        
        blob.style.animation = `float ${duration}s ease-in-out ${delay}s infinite`;
    });
}

// Add custom float animation
const floatKeyframes = `
    @keyframes float {
        0%, 100% {
            transform: translate(0, 0) scale(1);
        }
        25% {
            transform: translate(30px, -30px) scale(1.1);
        }
        50% {
            transform: translate(-20px, 20px) scale(0.9);
        }
        75% {
            transform: translate(20px, 30px) scale(1.05);
        }
    }
`;

const styleSheet = document.createElement('style');
styleSheet.textContent = floatKeyframes;
document.head.appendChild(styleSheet);

// Initialize blob animations
animateBlobs();

// Mobile menu toggle
const mobileMenuButton = document.querySelector('.mobile-menu-btn');
const navLinks = document.querySelector('.nav-links');

if (mobileMenuButton) {
    mobileMenuButton.addEventListener('click', () => {
        navLinks.classList.toggle('active');
    });
}

// Particle effect on hero (optional enhancement)
function createParticles() {
    const hero = document.querySelector('.hero');
    const particleCount = 50;
    
    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement('div');
        particle.className = 'particle';
        particle.style.cssText = `
            position: absolute;
            width: 2px;
            height: 2px;
            background: rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            left: ${Math.random() * 100}%;
            top: ${Math.random() * 100}%;
            animation: twinkle ${2 + Math.random() * 3}s ease-in-out infinite;
            animation-delay: ${Math.random() * 2}s;
        `;
        hero.appendChild(particle);
    }
}

const twinkleKeyframes = `
    @keyframes twinkle {
        0%, 100% { opacity: 0; }
        50% { opacity: 1; }
    }
`;

const twinkleStyle = document.createElement('style');
twinkleStyle.textContent = twinkleKeyframes;
document.head.appendChild(twinkleStyle);

// Initialize particles
createParticles();

// Launch app button handler
document.querySelectorAll('.cta-button, .btn-primary').forEach(button => {
    if (button.textContent.includes('Launch App')) {
        button.addEventListener('click', (e) => {
            e.preventDefault();
            window.location.href = 'app.html';
        });
    }
});

// Add hover effect to feature cards
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mouseenter', () => {
        card.style.transform = 'translateY(-10px)';
    });
    
    card.addEventListener('mouseleave', () => {
        card.style.transform = 'translateY(0)';
    });
});

// Parallax effect for hero content
window.addEventListener('scroll', () => {
    const scrolled = window.pageYOffset;
    const heroContent = document.querySelector('.hero-content');
    
    if (heroContent && scrolled < window.innerHeight) {
        heroContent.style.transform = `translateY(${scrolled * 0.5}px)`;
        heroContent.style.opacity = 1 - (scrolled / 600);
    }
});

// Console welcome message
console.log('%cTradeFlow Protocol', 'color: #667eea; font-size: 20px; font-weight: bold;');
console.log('%cMaking trade finance accessible through DeFi', 'color: #a0aec0; font-size: 12px;');
console.log('%cBuilt on Uniswap V4 Hooks', 'color: #48bb78; font-size: 12px;');

