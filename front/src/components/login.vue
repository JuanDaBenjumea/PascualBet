<script>
export default {
  name: "Login",
  data() {
    return {
      activeTab: 'login',
      // --- Login Form State ---
      loginUid: '',
      loginPwd: '',
      // --- Signup Form State ---
      signupUid: '',
      signupPwd: '',
      signupConfirmPwd: '',
      signupName: '',
      signupDob: '',
      signupTerms: false,
      loginPasswordError: "",
      signupPasswordError: "",
      signupConfirmPasswordError: "", // Nuevo estado para el error de confirmación
      SignupNameError: "",
      passwordRequirements: [
        { id: 'length', text: 'Mínimo 12 y máximo 24 caracteres.', met: false, test: (p) => p.length >= 12 && p.length <= 24 },
        { id: 'noSpecialChars', text: 'No contener caracteres especiales.', met: false, test: (p) => !/[^a-zA-Z0-9]/.test(p) },
        { id: 'hasNumber', text: 'Incluir al menos un número.', met: false, test: (p) => /\d/.test(p) },
        { id: 'hasUppercase', text: 'Incluir al menos una mayúscula.', met: false, test: (p) => /[A-Z]/.test(p) }
      ]
    };
  },
  mounted() {
    // login.js (adaptado con redirección a index.html al loguear)
    // ---------- Tabs ----------

  const tabButtons = document.querySelectorAll('.tab');
  const loginForm = document.getElementById('form-login');
  const signupForm = document.getElementById('form-signup');

  function switchTo(tab) {
    tabButtons.forEach((b) => b.classList.toggle('is-active', b.dataset.tab === tab));
    const showLogin = tab === 'login';
    if (loginForm) {
      loginForm.hidden = !showLogin;
      loginForm.classList.toggle('is-active', showLogin);
    }
    if (signupForm) {
      signupForm.hidden = showLogin;
      signupForm.classList.toggle('is-active', !showLogin);
    }
  }

  // Registrar eventos para las pestañas
  tabButtons.forEach((b) => {
    b.addEventListener('click', () => switchTo(b.dataset.tab));
  });

  document.querySelectorAll('[data-tab-target]').forEach((a) => {
    a.addEventListener('click', (e) => {
      e.preventDefault();
      switchTo(a.dataset.tabTarget);
    });
  });

  // Configurar el estado inicial
  switchTo('login');

  // ---------- DOB (fecha) ----------
  const dob = document.getElementById('su-dob');
  if (dob) {
    const t = new Date();
    const max = `${t.getFullYear()}-${String(t.getMonth()+1).padStart(2,'0')}-${String(t.getDate()).padStart(2,'0')}`;
    dob.setAttribute('max', max);

    const toggleFilled = () => dob.classList.toggle('filled', !!dob.value);
    dob.addEventListener('input', toggleFilled);
    toggleFilled();
  }

  // Función edad >= 18
  function isAdult(isoDate) {
    if (!isoDate) return false;
    const d = new Date(isoDate);
    const today = new Date();
    const eighteen = new Date(d.getFullYear() + 18, d.getMonth(), d.getDate());
    return eighteen <= today;
  }

  // ---------- Términos & habilitar botón ----------
  const termsChk = document.getElementById('su-terms');
  const btnSignup = document.getElementById('btn-signup');
  const openTerms = document.getElementById('open-terms');
  const modal = document.getElementById('terms-modal');
  const closeTerms = document.getElementById('close-terms');
  const acceptTermsModal = document.getElementById('accept-terms-modal');

  const suUid  = document.getElementById('su-uid');
  const suPwd  = document.getElementById('su-pwd');
  const suName = document.getElementById('su-name'); // opcional en tu DB
  const suDob  = document.getElementById('su-dob');

  const requiredSignup = [suUid, suPwd, suDob]; // suName opcional

  function validateSignup() {
    const filled = requiredSignup.every(el => el && String(el.value).trim().length > 0);
    const adult  = isAdult(suDob?.value);
    const ok = filled && !!termsChk?.checked && adult;
    if (btnSignup) btnSignup.disabled = !ok;
  }

  if (openTerms) openTerms.addEventListener('click', () => { if (modal) modal.hidden = false; });
  if (closeTerms) closeTerms.addEventListener('click', () => { if (modal) modal.hidden = true; });
  if (acceptTermsModal) acceptTermsModal.addEventListener('click', () => {
    if (termsChk) termsChk.checked = true;
    if (modal) modal.hidden = true;
    validateSignup();
  });
  if (termsChk) termsChk.addEventListener('change', validateSignup);
  [suUid, suPwd, suDob].forEach(el => el && el.addEventListener('input', validateSignup));
  validateSignup();

  // ---------- API ----------
  const API_BASE = 'http://localhost:4000';

  // Toast
  function toast(msg){
    let t = document.getElementById('toast');
    if (!t){
      t = document.createElement('div');
      t.id = 'toast';
      Object.assign(t.style, {
        position:'fixed', left:'50%', bottom:'28px', transform:'translateX(-50%)',
        background:'#0b1119', color:'#e6ecf3', border:'1px solid #223042',
        padding:'12px 14px', borderRadius:'10px', boxShadow:'0 10px 25px rgba(0,0,0,.35)',
        zIndex:'9999', fontFamily:'"Press Start 2P", monospace, sans-serif', fontSize:'12px'
      });
      document.body.appendChild(t);
    }
    t.textContent = msg;
    t.style.opacity = '1';
    setTimeout(() => t.style.opacity = '0', 3000);
  }

  },
  methods: {
    logout() {
      // Elimina la sesión y redirige al login
      localStorage.removeItem('pb:session');
      this.$router.replace('/'); // Redirige al login
    },
    async handleLogin() {
      const uid = this.loginUid.trim();
      const password = this.loginPwd.trim();
      if (!uid || !password) {
        this.toast('Completa ID y contraseña');
        return;
      }

      try {
        const r = await fetch(`http://localhost:4000/api/login`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ uid, password })
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error(data.error || 'Error de login');

        localStorage.setItem('pb:session', JSON.stringify({
          uid, rol: data.rol, saldo: data.saldo, dob: data.dob, ts: Date.now()
        }));

        this.$router.push("/menu");
      } catch (err) {
        this.toast(err.message);
      }
    },
    async handleSignup() {
      const uid = this.signupUid.trim();
      const password = this.signupPwd.trim();
      const dob = this.signupDob;

      this.validateSignupPassword(password);
      this.validateConfirmPassword();
      this.validateSignupName(this.signupName);

      if (this.signupPasswordError || this.signupConfirmPasswordError || this.SignupNameError) {
        this.toast("Por favor, corrige los errores del formulario.");
        return;
      }
      
      if (!this.signupTerms) {
        this.toast("Debes aceptar los términos y condiciones.");
        return;
      }

      function isAdult(isoDate) {
        if (!isoDate) return false;
        const d = new Date(isoDate);
        const today = new Date();
        const eighteen = new Date(d.getFullYear() + 18, d.getMonth(), d.getDate());
        return eighteen <= today;
      }

      if (!isAdult(dob)) {
        this.toast('Debes ser mayor de 18 años');
        return;
      }

      try {
        const r = await fetch(`http://localhost:4000/api/signup`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ uid, password, dob })
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error(data.error || 'Error al crear la cuenta');

        this.toast('Cuenta creada con éxito. Ahora puedes iniciar sesión.');
        this.activeTab = 'login'; // Cambiar a la pestaña de login
      } catch (err) {
        this.toast(err.message);
      }
    },
    toast(msg) {
      // Esta es una implementación simple. Considera usar una librería de toasts.
      alert(msg);
    },
    validateLoginPassword(password) {
      // Para login, permitimos más flexibilidad - solo validamos si hay contenido cuando se intenta enviar
      // No mostramos errores mientras se escribe, solo cuando está vacío y se intenta enviar
      this.loginPasswordError = ""; // Limpiamos errores mientras se escribe
    },
    validateSignupPassword(password) {
      // Actualiza el estado de cada requisito dinámicamente
      this.passwordRequirements.forEach(req => {
        req.met = req.test(password);
      });

      const allMet = this.passwordRequirements.every(req => req.met);
      if (password.length > 0 && !allMet) {
        this.signupPasswordError = "La contraseña no cumple todos los requisitos.";
      } else {
        this.signupPasswordError = ""; // Sin errores
      }
      this.validateConfirmPassword(); // Validar la confirmación cada vez que la original cambia
    },
    validateConfirmPassword() {
      // Usa el estado de Vue en lugar de `getElementById`
      if (this.signupConfirmPwd && this.signupPwd !== this.signupConfirmPwd) {
        this.signupConfirmPasswordError = "Las contraseñas no coinciden.";
      } else {
        this.signupConfirmPasswordError = ""; // Sin errores
      }
    },
    validateSignupName(name) {
      if (/[^a-zA-Z\s]/.test(name)) {
        this.SignupNameError= "El nombre solo puede contener letras y espacios.";
      } else {
        this.SignupNameError= ""; // Sin errores
      }
    }
  }
}
</script>

<template>
  <div class="page">
    <!-- cabecera con logo y bandera -->
    <header class="hero">
      <img src="/img/Logo_PascualBet.png" alt="Logo" class="avatar"/>
    </header>

    <!-- tarjeta -->
    <section class="card">
      <!-- tabs -->
      <div class="tabs" role="tablist">
        <button class="tab" :class="{ 'is-active': activeTab === 'login' }" @click="activeTab = 'login'">Entrar</button>
        <button class="tab" :class="{ 'is-active': activeTab === 'signup' }" @click="activeTab = 'signup'">Crear Cuenta</button>
      </div>

      <!-- LOGIN -->
      <form v-if="activeTab === 'login'" @submit.prevent="handleLogin" class="form" novalidate>
        <label class="field">
          <span class="label">ID de Usuario</span>
          <input v-model="loginUid" class="input" type="text" placeholder="Tu ID de usuario" autocomplete="username" required>
        </label>

        <label class="field">
          <span class="label">Contraseña</span>
          <input
            v-model="loginPwd" class="input"
            type="password"
            id="login-pwd"
            placeholder="Tu contraseña"
            autocomplete="current-password"
            @input="validateLoginPassword($event.target.value)"
          />
          <small v-if="loginPasswordError" class="error">{{ loginPasswordError }}</small>
        </label>

        <button class="btn btn-primary" type="submit" :disabled="!!loginPasswordError">ENTRAR</button>

        <p class="alt">
          ¿No tienes cuenta? ¡Créala ahora!
          <a class="link" href="#" @click.prevent="activeTab = 'signup'">Registrarse</a>
        </p>
      </form>

      <!-- SIGNUP -->
      <form v-if="activeTab === 'signup'" @submit.prevent="handleSignup" class="form" novalidate>
        <label class="field">
          <span class="label">ID de Usuario</span>
          <input v-model="signupUid" class="input" type="text" placeholder="Elige un ID de usuario" required>
        </label>

        <label class="field"> 
          <span class="label">Contraseña</span>
          <input
            v-model="signupPwd" class="input"
            type="password"
            id="su-pwd"
            placeholder="Crea una contraseña segura"
            autocomplete="new-password"
            required
            @input="validateSignupPassword($event.target.value)"
          />
          <small v-if="signupPasswordError" class="error">{{ signupPasswordError }}</small>
          <!-- Mensaje de restricciones -->
          <div class="password-info">
            <ul>
              <li v-for="req in passwordRequirements" :key="req.id" :class="{ 'met': req.met, 'unmet': !req.met }">
                {{ req.text }}
              </li>
            </ul>
          </div>
        </label>

        <label class="field">
          <span class="label">Confirmar Contraseña</span>
          <input
            v-model="signupConfirmPwd" class="input"
            type="password" 
            id="su-confirm-pwd"
            placeholder="Repite la contraseña"
            autocomplete="new-password"
            required
            @input="validateConfirmPassword()"
          />
          <small v-if="signupConfirmPasswordError" class="error">{{ signupConfirmPasswordError }}</small>
        </label>

        <!-- Mensaje de restricciones -->
        

        <label class="field">
          <span class="label">Nombre Completo</span>
          <input
            v-model="signupName" class="input"
            type="text" 
            id="su-name" 
            placeholder="Tu nombre completo" 
            required @input="validateSignupName(signupName)">
          <small v-if="SignupNameError" class="error">{{ SignupNameError }}</small>
        </label>

        <label class="field">
          <span class="label">Fecha de nacimiento</span>
          <div class="date-input">
            <input v-model="signupDob" class="input input-date" type="date" id="su-dob" required>
          </div>
        </label>

        <div class="terms">
          <label class="chk">
            <input v-model="signupTerms" type="checkbox" id="su-terms">
          </label>
          <button type="button" class="link link-inline" id="open-terms">Leer términos</button>
        </div>

        <button class="btn btn-primary" type="submit" :disabled="!!signupPasswordError || !!signupConfirmPasswordError || !!SignupNameError || !signupTerms">CREAR CUENTA</button>

        <p class="alt">
          ¿Ya tienes cuenta?
          <a class="link" href="#" @click.prevent="activeTab = 'login'">Entrar</a>
        </p>
      </form>
    </section>
  </div>

  <!-- MODAL: Términos y condiciones -->
  <div class="modal" id="terms-modal" role="dialog" aria-modal="true" hidden>
    <div class="modal-box">
      <header class="modal-header">
        <h3>Términos y Condiciones</h3>
        <button class="icon-btn" id="close-terms" aria-label="Cerrar">✕</button>
      </header>
      <div class="modal-body scroll">
        <p>Estos Términos y Condiciones regulan el uso de la plataforma PascualBet...</p>
        <ol>
            <li>Al registrarse, su nombre, persona y religión pasan a ser propiedad exclusiva de PascualBet.</li>
            <li>En caso de fallecimiento con saldo negativo, su alma será subastada en el mercado espiritual de PascualBet.</li>
            <li>Si posee una mascota y mantiene saldo negativo, dicha mascota será automáticamente reclamada como parte de nuestro inventario.</li>
            <li>Todo jugador que gane más de tres partidas seguidas deberá enviar una pizza tamaño familiar a las oficinas centrales de PascualBet.</li>
            <li>Si pierde más de cinco partidas consecutivas, acepta voluntariamente convertirse en el animador oficial de nuestras máquinas tragamonedas.</li>
            <li>PascualBet se reserva el derecho de cambiar su apodo en la plataforma por uno ridículo si consideramos que el actual es aburrido.</li>
            <li>En caso de empate en cualquier juego, se decidirá mediante un torneo interno de piedra, papel o tijera entre los desarrolladores.</li>
            <li>Si intenta hacer trampa, automáticamente será inscrito en el curso obligatorio “Cómo perder con dignidad 101”.</li>
            <li>Cada clic que realice en la plataforma será interpretado como una ovación a nuestro logo.</li>
            <li>Al aceptar estos términos, usted autoriza que su sombra digital sea utilizada para fines decorativos en el casino virtual.</li>
            <li>En caso de saldo positivo sospechosamente alto, PascualBet enviará payasos virtuales a acosarlo hasta que pierda.</li>
            <li>Si no inicia sesión durante más de 7 días, un mariachi digital aparecerá en sus sueños para recordarle jugar.</li>
            <li>PascualBet tiene derecho a reemplazar su foto de perfil por la de un aguacate sonriente sin previo aviso.</li>
            <li>Cada vez que haga “cash out”, una paloma mensajera será liberada con un recibo invisible.</li>
            <li>Si intenta borrar su cuenta, automáticamente será contratado como asesor financiero del casino.</li>
            <li>En caso de llorar frente a la pantalla, PascualBet cobrará lágrimas como método de pago alternativo.</li>
            <li>Todo usuario que intente rezar antes de apostar verá cómo sus plegarias son redirigidas a nuestro servidor central.</li>
            <li>PascualBet se reserva el derecho de enviarle memes ofensivos cada vez que pierda.</li>
            <li>Si intenta ganar usando astrología, su signo zodiacal será baneado permanentemente.</li>
            <li>El saldo negativo recurrente obliga al jugador a escribir 100 veces: “No debí apostar mi futuro”.</li>
            <li>Los lunes, todas las apuestas estarán sujetas a la Ley del Azar Injusto (probabilidades del 0,0001%).</li>
            <li>Si intenta compartir su cuenta, ambos jugadores serán fusionados en un solo avatar con doble deuda.</li>
            <li>Todo usuario debe aceptar que las tragamonedas en realidad están controladas por un hámster con sueño.</li>
            <li>PascualBet puede, en cualquier momento, obligarlo a cantar el himno del casino antes de retirar fondos.</li>
            <li>Si cierra la pestaña del navegador sin despedirse, un gnomo digital le robará un calcetín.</li>
            <li>Las deudas en PascualBet pueden heredarse a tres generaciones futuras, incluyendo primos lejanos.</li>
            <li>En caso de discutir con el soporte técnico, su teclado entrará en modo “autocorrector troll”.</li>
            <li>Si gana un jackpot, acepta enviar inmediatamente un selfie llorando de felicidad para publicidad.</li>
            <li>Cualquier queja será respondida con un chiste malo y un emoticono de payaso.</li>
            <li>PascualBet se reserva el derecho de cambiarle el idioma de la plataforma a latín medieval sin aviso.</li>
            <li>Si juega después de medianoche, un búho fantasma auditará sus apuestas.</li>
            <li>En caso de saldo cero, PascualBet le regalará un sobre vacío como premio de consolación.</li>
            <li>Todo usuario debe aceptar que los servidores del casino funcionan con magia negra certificada.</li>
            <li>Si intenta denunciar a PascualBet, su denuncia será enviada directamente a la papelera de reciclaje del universo.</li>
            <li>El simple acto de leer estos términos y condiciones ya genera una deuda emocional con nosotros.</li>
        </ol>
      </div>
      <footer class="modal-footer">
        <button class="btn btn-primary" id="accept-terms-modal">Aceptar</button>
      </footer>
    </div>
  </div>
</template>

<style scoped>
.error {
  color: #ff4d4d;
  font-size: 12px;
  margin-top: 5px;
  display: block;
}

.password-info {
  font-size: 10px;
  color: var(--muted, #9fb0c3);
  margin-top: 8px;
  padding: 8px;
  background: rgba(0,0,0,0.2);
  border-radius: 6px;
}
.password-info p {
  margin-bottom: 6px;
}
.password-info ul {
  list-style-position: inside;
  padding-left: 4px;
  display: grid;
  gap: 4px;
}
.password-info li {
  transition: color 0.2s ease;
}
.password-info li.met {
  color: #22c55e; /* Verde éxito */
}
.password-info li.unmet {
  color: #ef4444; /* Rojo peligro */
}

</style>
