import { reactive, toRefs } from 'vue';

/**
 * Obtiene el saldo inicial desde la sesión guardada en localStorage.
 */
const getInitialBalance = () => {
  const session = localStorage.getItem('pb:session');
  if (session) {
    try {
      const parsedSession = JSON.parse(session);
      // Nos aseguramos de que el saldo sea un número. Si no, devolvemos 0.
      return Number(parsedSession.saldo) || 0;
    } catch (e) {
      console.error("Error al parsear la sesión de localStorage:", e);
      return 0;
    }
  }
  return 0;
};

// Función para obtener la sesión parseada de forma segura
const getSession = () => {
  const session = localStorage.getItem('pb:session');
  try {
    return session ? JSON.parse(session) : {};
  } catch (e) {
    return {};
  }
};

// Creamos un estado reactivo para los datos de la sesión del usuario.
const state = reactive({
  credits: getInitialBalance(),
  uid: getSession().uid || '',
  rol: getSession().rol || 'Usuario' // Añadimos el rol al estado
});

// Nueva función para sincronizar saldo desde la base de datos
export const syncBalance = async () => {
  const session = localStorage.getItem('pb:session');
  if (!session) return;
  const { uid } = JSON.parse(session);
  try {
    const r = await fetch(`http://localhost:4000/api/user/info/${uid}`);
    const data = await r.json();
    if (data.ok && data.info) {
      state.credits = Number(data.info.saldo_actual) || 0;
      // Actualiza también el saldo en localStorage
      const newSession = { ...JSON.parse(session), saldo: state.credits };
      localStorage.setItem('pb:session', JSON.stringify(newSession));
    }
  } catch (e) {
    console.error("Error al sincronizar saldo:", e);
  }
};

export const setSession = (session) => {
  // Actualiza el estado reactivo con los datos del nuevo usuario
  state.uid = session.uid;
  state.rol = session.rol; // Guardamos el rol en el estado
  state.credits = Number(session.saldo) || 0;
  localStorage.setItem('pb:session', JSON.stringify(session));
};

// Función para actualizar el saldo. Acepta montos positivos (ganancias) y negativos (pérdidas).
export const updateBalance = (amount) => {
  state.credits += amount;
  // Persistimos el cambio en localStorage para que no se pierda.
  const session = JSON.parse(localStorage.getItem('pb:session') || '{}');
  session.saldo = state.credits;
  localStorage.setItem('pb:session', JSON.stringify(session));
};

// Exportamos las referencias reactivas para que los componentes puedan usarlas.
export const balance = toRefs(state);