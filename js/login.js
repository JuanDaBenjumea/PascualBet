// login.js (adaptado con redirección a index.html al loguear)
document.addEventListener('DOMContentLoaded', () => {
  // ---------- Tabs ----------
  const tabButtons = document.querySelectorAll('.tab');
  const loginForm  = document.getElementById('form-login');
  const signupForm = document.getElementById('form-signup');

  function switchTo(tab) {
    tabButtons.forEach(b => b.classList.toggle('is-active', b.dataset.tab === tab));
    const showLogin  = tab === 'login';
    if (loginForm)  { loginForm.hidden  = !showLogin;  loginForm.classList.toggle('is-active', showLogin); }
    if (signupForm) { signupForm.hidden =  showLogin;  signupForm.classList.toggle('is-active', !showLogin); }
  }
  tabButtons.forEach(b => b.addEventListener('click', () => switchTo(b.dataset.tab)));
  document.querySelectorAll('[data-tab-target]').forEach(a => {
    a.addEventListener('click', e => { e.preventDefault(); switchTo(a.dataset.tabTarget); });
  });

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
    setTimeout(() => t.style.opacity = '0', 1600);
  }

  // ---------- Submit: LOGIN ----------
  const loginUid = document.getElementById('login-uid');
  const loginPwd = document.getElementById('login-pwd');

  if (loginForm) {
    loginForm.addEventListener('submit', async e => {
      e.preventDefault();
      const uid = loginUid?.value.trim();
      const password = loginPwd?.value.trim();
      if (!uid || !password) { toast('Completa ID y contraseña'); return; }

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
        window.location.href = 'index.html'; // cambia la ruta si tu index está en otra carpeta
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
});
