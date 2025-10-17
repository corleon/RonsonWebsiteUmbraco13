/**
 * FormValidator - Универсальный класс для валидации форм
 * Поддерживает различные типы валидации и кастомные сообщения
 */
class FormValidator {
    constructor(formId, options = {}) {
        this.form = document.getElementById(formId);
        if (!this.form) {
            console.warn('FormValidator: Form not found', formId);
            return;
        }

        this.options = {
            validateOnBlur: true,
            validateOnInput: true,
            validateOnSubmit: true,
            scrollToError: true,
            submitUrl: '/api/forms/submit',
            successMessage: 'Форма успешно отправлена!',
            errorClass: 'error',
            successClass: 'success',
            ...options
        };

        this.rules = {};
        this.messages = {};
        this.isSubmitting = false;

        this.init();
    }

    init() {
        this.setupDefaultRules();
        this.attachEventListeners();
        this.setupPhoneMask();
    }

    setupDefaultRules() {
        // Правила валидации по умолчанию
        this.rules = {
            name: {
                required: true,
                minLength: 2,
                maxLength: 50,
                pattern: /^[а-яёА-ЯЁa-zA-Z\s-]+$/
            },
            company: {
                required: true,
                maxLength: 100
            },
            email: {
                required: true,
                pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            },
            phone: {
                required: true,
                pattern: /^\+7\s?\(\d{3}\)\s?\d{3}-\d{2}-\d{2}$/
            },
            message: {
                required: true,
                minLength: 10,
                maxLength: 1000
            },
            agreement: {
                required: true
            }
        };

        // Сообщения об ошибках
        this.messages = {
            name: {
                required: 'Введите ваше имя',
                minLength: 'Имя должно содержать минимум 2 символа',
                maxLength: 'Имя не должно превышать 50 символов',
                pattern: 'Имя может содержать только буквы, пробелы и дефисы'
            },
            company: {
                required: 'Введите название компании',
                maxLength: 'Название компании не должно превышать 100 символов'
            },
            email: {
                required: 'Введите email адрес',
                pattern: 'Введите корректный email адрес'
            },
            phone: {
                required: 'Введите номер телефона',
                pattern: 'Формат: +7 (XXX) XXX-XX-XX'
            },
            message: {
                required: 'Введите ваш запрос',
                minLength: 'Запрос должен содержать минимум 10 символов',
                maxLength: 'Запрос не должен превышать 1000 символов'
            },
            agreement: {
                required: 'Необходимо согласие на обработку персональных данных'
            }
        };
    }

    attachEventListeners() {
        // Валидация при отправке формы
        if (this.options.validateOnSubmit) {
            this.form.addEventListener('submit', (e) => this.handleSubmit(e));
        }

        // Валидация при вводе
        if (this.options.validateOnInput) {
            this.form.addEventListener('input', (e) => {
                if (e.target.name && this.rules[e.target.name]) {
                    this.validateField(e.target);
                }
            });
        }

        // Валидация при потере фокуса
        if (this.options.validateOnBlur) {
            this.form.addEventListener('blur', (e) => {
                if (e.target.name && this.rules[e.target.name]) {
                    this.validateField(e.target);
                }
            }, true);
        }

        // Особая обработка для чекбоксов
        const checkboxes = this.form.querySelectorAll('input[type="checkbox"]');
        checkboxes.forEach(checkbox => {
            checkbox.addEventListener('change', () => this.validateField(checkbox));
        });
    }

    setupPhoneMask() {
        const phoneInput = this.form.querySelector('input[name="phone"]');
        if (!phoneInput) return;

        phoneInput.addEventListener('input', (e) => {
            let value = e.target.value.replace(/\D/g, '');
            
            if (value.startsWith('7')) {
                value = value.substring(1);
            } else if (value.startsWith('8')) {
                value = value.substring(1);
            }
            
            if (value.length > 0) {
                let formatted = '+7';
                if (value.length > 0) {
                    formatted += ' (' + value.substring(0, 3);
                }
                if (value.length > 3) {
                    formatted += ') ' + value.substring(3, 6);
                }
                if (value.length > 6) {
                    formatted += '-' + value.substring(6, 8);
                }
                if (value.length > 8) {
                    formatted += '-' + value.substring(8, 10);
                }
                e.target.value = formatted;
            }
        });

        phoneInput.addEventListener('focus', (e) => {
            if (e.target.value === '') {
                e.target.value = '+7 ';
            }
        });
    }

    validateField(field) {
        const fieldName = field.name;
        const value = field.type === 'checkbox' ? field.checked : field.value;
        const rules = this.rules[fieldName];
        const messages = this.messages[fieldName];

        if (!rules) return true;

        // Проверка обязательного поля
        if (rules.required) {
            if (field.type === 'checkbox' && !value) {
                this.showError(field, messages.required);
                return false;
            } else if (!value || value.trim() === '') {
                this.showError(field, messages.required);
                return false;
            }
        }

        // Для необязательных полей - если пусто, то валидно
        if (!value || value.trim() === '') {
            this.showSuccess(field);
            return true;
        }

        // Проверка минимальной длины
        if (rules.minLength && value.length < rules.minLength) {
            this.showError(field, messages.minLength);
            return false;
        }

        // Проверка максимальной длины
        if (rules.maxLength && value.length > rules.maxLength) {
            this.showError(field, messages.maxLength);
            return false;
        }

        // Проверка паттерна
        if (rules.pattern && !rules.pattern.test(value)) {
            this.showError(field, messages.pattern);
            return false;
        }

        this.showSuccess(field);
        return true;
    }

    validateForm() {
        let isValid = true;
        const fields = this.form.querySelectorAll('[name]');
        
        fields.forEach(field => {
            if (this.rules[field.name]) {
                if (!this.validateField(field)) {
                    isValid = false;
                }
            }
        });

        return isValid;
    }

    showError(field, message) {
        // Удаляем предыдущие классы
        field.classList.remove(this.options.successClass);
        field.classList.add(this.options.errorClass);

        // Находим или создаем элемент для ошибки
        let errorElement = field.parentElement.querySelector('.error-message');
        if (!errorElement) {
            errorElement = document.createElement('div');
            errorElement.className = 'error-message';
            field.parentElement.appendChild(errorElement);
        }

        errorElement.textContent = message;
        errorElement.classList.remove('hidden');
        errorElement.classList.add('show');
    }

    showSuccess(field) {
        // Удаляем класс ошибки
        field.classList.remove(this.options.errorClass);
        field.classList.add(this.options.successClass);

        // Скрываем сообщение об ошибке
        const errorElement = field.parentElement.querySelector('.error-message');
        if (errorElement) {
            errorElement.classList.remove('show');
            errorElement.classList.add('hidden');
        }
    }

    async handleSubmit(e) {
        e.preventDefault();

        if (this.isSubmitting) return;

        if (!this.validateForm()) {
            if (this.options.scrollToError) {
                const firstError = this.form.querySelector('.' + this.options.errorClass);
                if (firstError) {
                    firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }
            return;
        }

        this.isSubmitting = true;
        const submitBtn = this.form.querySelector('[type="submit"]');
        const originalText = submitBtn ? submitBtn.textContent : '';
        
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Отправка...';
        }

        try {
            const formData = new FormData(this.form);
            const response = await fetch(this.options.submitUrl, {
                method: 'POST',
                body: formData
            });

            if (response.ok) {
                this.showSuccessMessage();
                this.form.reset();
                this.clearAllValidation();
            } else {
                throw new Error('Ошибка при отправке формы');
            }
        } catch (error) {
            console.error('Form submission error:', error);
            alert('Произошла ошибка при отправке формы. Пожалуйста, попробуйте позже.');
        } finally {
            this.isSubmitting = false;
            if (submitBtn) {
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
            }
        }
    }

    showSuccessMessage() {
        // Создаем модальное окно с сообщением об успехе
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center';
        modal.innerHTML = `
            <div class="bg-white rounded-2xl p-8 max-w-md mx-4 transform scale-100 transition-transform">
                <div class="text-center">
                    <div class="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg class="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                        </svg>
                    </div>
                    <h3 class="text-xl font-semibold mb-2">Спасибо за заявку!</h3>
                    <p class="text-gray-600">${this.options.successMessage}</p>
                    <button onclick="this.closest('.fixed').remove()" 
                            class="mt-6 px-6 py-2 bg-accent text-white rounded-lg hover:bg-accent-hover transition-colors">
                        Закрыть
                    </button>
                </div>
            </div>
        `;
        document.body.appendChild(modal);

        // Автоматически закрываем через 5 секунд
        setTimeout(() => {
            modal.remove();
        }, 5000);
    }

    clearAllValidation() {
        const fields = this.form.querySelectorAll('[name]');
        fields.forEach(field => {
            field.classList.remove(this.options.errorClass, this.options.successClass);
        });

        const errorMessages = this.form.querySelectorAll('.error-message');
        errorMessages.forEach(error => {
            error.classList.remove('show');
            error.classList.add('hidden');
        });
    }

    destroy() {
        this.form.removeEventListener('submit', this.handleSubmit);
        this.clearAllValidation();
    }
}

// Инициализация форм на странице
document.addEventListener('DOMContentLoaded', () => {
    // Форма в футере
    if (document.getElementById('footerForm')) {
        new FormValidator('footerForm', {
            submitUrl: '/api/contact/submit'
        });
    }

    // Другие формы на странице
    const forms = document.querySelectorAll('[data-validate]');
    forms.forEach(form => {
        new FormValidator(form.id);
    });
});

// Экспорт для использования
window.FormValidator = FormValidator;