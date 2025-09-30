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

// Creamos un estado reactivo para el saldo.
const state = reactive({
  credits: getInitialBalance(),
});

// Función para actualizar el saldo. Acepta montos positivos (ganancias) y negativos (pérdidas).
export const updateBalance = (amount) => {
  state.credits += amount;
  // Persistimos el cambio en localStorage para que no se pierda.
  const session = JSON.parse(localStorage.getItem('pb:session') || '{}');
  session.saldo = state.credits;
  localStorage.setItem('pb:session', JSON.stringify(session));
  try {
    // Persistimos el cambio en localStorage para que no se pierda.
    const session = JSON.parse(localStorage.getItem('pb:session') || '{}');
    session.saldo = state.credits;
    localStorage.setItem('pb:session', JSON.stringify(session));
  } catch (e) {
    console.error("Error al actualizar la sesión en localStorage:", e);
  }
};

// Exportamos las referencias reactivas para que los componentes puedan usarlas.
export const balance = toRefs(state);