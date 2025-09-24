<script>
export default {
  name: "Login",
  data() {
    return {
      loginPasswordError: "",
      signupPasswordError: "",
      SignupNameError: ""
    };
  },
  mounted() {
    // login.js (adaptado con redirección a index.html al loguear)
document.addEventListener('DOMContentLoaded', () => {
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

  // ---------- Submit: LOGIN ----------
  const loginUid = document.getElementById('login-uid');
  const loginPwd = document.getElementById('login-pwd');

  if (loginForm) {
    loginForm.addEventListener('submit', async e => {
      e.preventDefault();
      const uid = loginUid?.value.trim();
      const password = loginPwd?.value.trim();
      
      // Validar en el momento del submit
      if (!uid || !password) { 
        toast('Completa ID y contraseña'); 
        return; 
      }

      // Bloquear botón para evitar doble submit
      const btn = loginForm.querySelector('button[type="submit"]');
      if (btn) btn.disabled = true;

      try {
        const r = await fetch(`${API_BASE}/api/login`, {
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body: JSON.stringify({ uid, password })
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error(data.error || 'Error de login');

        // Guardar mini sesión (ajústalo a tus necesidades)
        localStorage.setItem('pb:session', JSON.stringify({
          uid, rol: data.rol, saldo: data.saldo, dob: data.dob, ts: Date.now()
        }));

        // Redirigir a la home
        this.$router.push("/menu");  // cambia la ruta si tu index está en otra carpeta
      } catch (err) {
        toast(err.message);
      } finally {
        if (btn) btn.disabled = false;
      }
    });
  }

  // ---------- Submit: SIGNUP ----------
  if (signupForm) {
    signupForm.addEventListener('submit', async e => {
      e.preventDefault();
      if (btnSignup?.disabled) return;

      const uid = suUid?.value.trim();
      const password = suPwd?.value.trim();
      const dob = suDob?.value; // 'YYYY-MM-DD'

      // Validar contraseña antes de enviar
      this.validateSignupPassword(password);
      if (this.signupPasswordError) {
        toast(this.signupPasswordError);
        return;
      }
      // Validar nombre 
      this.validateSignupName();
      if (this.SignupNameError) {
        toast(this.SignupNameError);
        return;
      }

      if (!isAdult(dob)) { toast('Debes ser mayor de 18 años'); return; }
      
      const btn = signupForm.querySelector('button[type="submit"]');
      if (btn) btn.disabled = true;

      try {
        const r = await fetch(`${API_BASE}/api/signup`, {
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body: JSON.stringify({ uid, password, dob })
        });
        const data = await r.json();
        if (!r.ok || !data.ok) throw new Error(data.error || 'Error al crear la cuenta');

        toast('Cuenta creada');
        switchTo('login');
      } catch (err) {
        toast(err.message);
      } finally {
        if (btn) btn.disabled = false;
      }
    });
  }

  // Remover el event listener duplicado que causaba conflictos
});

  },
  methods: {
    logout() {
      // Elimina la sesión y redirige al login
      localStorage.removeItem('pb:session');
      this.$router.replace('/'); // Redirige al login
    },
    validateLoginPassword(password) {
      // Para login, permitimos más flexibilidad - solo validamos si hay contenido cuando se intenta enviar
      // No mostramos errores mientras se escribe, solo cuando está vacío y se intenta enviar
      this.loginPasswordError = ""; // Limpiamos errores mientras se escribe
    },
    validateSignupPassword(password) {
      const minLength = 12;
      const maxLength = 24;
      const specialCharRegex = /[^a-zA-Z0-9]/; // Detecta caracteres especiales
      const numberRegex = /\d/; // Detecta al menos un número

      if (password.length < minLength) {
        this.signupPasswordError = `La contraseña debe tener al menos ${minLength} caracteres.`;
      } else if (password.length > maxLength) {
        this.signupPasswordError = `La contraseña no puede exceder los ${maxLength} caracteres.`;
      } else if (specialCharRegex.test(password)) {
        this.signupPasswordError = "La contraseña no puede contener caracteres especiales.";
      } else if (!numberRegex.test(password)) {
        this.signupPasswordError = "La contraseña debe contener al menos un número.";
      } else {
        this.signupPasswordError = ""; // Sin errores
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
        <button class="tab is-active" role="tab" aria-selected="true" data-tab="login">Entrar</button>
        <button class="tab" role="tab" aria-selected="false" data-tab="signup">Crear Cuenta</button>
      </div>

      <!-- LOGIN -->
      <form id="form-login" class="form is-active" aria-labelledby="tab-login" novalidate>
        <label class="field">
          <span class="label">ID de Usuario</span>
          <input class="input" type="text" id="login-uid" placeholder="Tu ID de usuario" autocomplete="username" required>
        </label>

        <label class="field">
          <span class="label">Contraseña</span>
          <input
            class="input"
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
          <a class="link" href="#" data-tab-target="signup">Registrarse</a>
        </p>
      </form>

      <!-- SIGNUP -->
      <form id="form-signup" class="form" aria-labelledby="tab-signup" novalidate hidden>
        <label class="field">
          <span class="label">ID de Usuario</span>
          <input class="input" type="text" id="su-uid" placeholder="Elige un ID de usuario" required>
        </label>

        <label class="field">
          <span class="label">Contraseña</span>
          <input
            class="input"
            type="password"
            id="su-pwd"
            placeholder="Crea una contraseña segura"
            autocomplete="new-password"
            required
            @input="validateSignupPassword($event.target.value)"
          />
          <small v-if="signupPasswordError" class="error">{{ signupPasswordError }}</small>
        </label>

        <!-- Mensaje de restricciones -->
        <p class="info ">
          La contraseña debe cumplir con las siguientes restricciones:
          <ul>
            <li>Mínimo 12 caracteres y máximo 24 caracteres.</li>
            <li>No debe contener caracteres especiales.</li>
            <li>Debe incluir al menos un número.</li>
          </ul>
        </p>

        <label class="field">
          <span class="label">Nombre Completo</span>
          <input class="input" type="text" id="su-name" placeholder="Tu nombre completo" required>
        </label>

        <label class="field">
          <span class="label">Fecha de nacimiento</span>
          <div class="date-input">
            <input class="input input-date" type="date" id="su-dob" required>
          </div>
        </label>

        <div class="terms">
          <label class="chk">
            <input type="checkbox" id="su-terms">
          </label>
          <button type="button" class="link link-inline" id="open-terms">Leer términos</button>
        </div>

        <button class="btn btn-primary" id="btn-signup" type="submit" :disabled="!!signupPasswordError">CREAR CUENTA</button>

        <p class="alt">
          ¿Ya tienes cuenta?
          <a class="link" href="#" data-tab-target="login">Entrar</a>
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
            <li>Todo jugador que intente rezar antes de apostar verá cómo sus plegarias son redirigidas a nuestro servidor central.</li>
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
            <li>Todo jugador debe aceptar que los servidores del casino funcionan con magia negra certificada.</li>
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


</style>