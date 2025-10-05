<template>
  <div class="mines-game-container">
    <!-- Import Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700&family=Montserrat:wght@400;600&display=swap" rel="stylesheet">

    <!-- Encabezado del Juego -->
    <header class="game-header">
      <div class="header-container">
        <div class="brand">
          <h1 class="brand-title">PascualBet</h1>
        </div>
        <div class="game-info">
          <span class="game-subtitle">Buscaminas</span>
        </div>
        <div class="stats">
          <div class="stat-item">
            <span>Balance</span>
            <strong>${{ credits.toFixed(2) }}</strong>
          </div>
          <div class="stat-item bet-stat">
            <span>Apuesta</span>
            <strong>${{ betAmount > 0 ? betAmount.toFixed(2) : '0.00' }}</strong>
          </div>
        </div>
      </div>
    </header>

    <div class="game-content">
      <!-- Botón Volver (debajo del encabezado) -->
      <button @click="goBack" class="btn-back-below-header" :disabled="gameState !== 'betting'">⬅ Regresar</button>

      <div class="main-game-area">
        <!-- Panel de Controles Izquierdo -->
        <div class="controls-panel">
          <div class="control-group">
            <label>Bet Amount</label>
            <div class="input-group">
              <input type="number" v-model.number="betAmount" :disabled="gameState !== 'betting'" />
            </div>
          </div>
    
          <div class="control-group">
            <label>Grid Size</label>
            <select v-model.number="gridDimension" :disabled="gameState !== 'betting'">
              <option v-for="n in 7" :key="n" :value="n + 2">{{ n + 2 }}x{{ n + 2 }}</option>
            </select>
          </div>
    
          <div class="control-group">
            <label>Mines</label>
            <select v-model.number="numMines" :disabled="gameState !== 'betting'">
              <option v-for="n in maxMines" :key="n" :value="n">{{ n }}</option>
            </select>
          </div>
    
          <button v-if="gameState === 'betting'" class="action-button bet-button" @click="startGame">
            Bet
          </button>
          <div v-if="lastWinnings !== null" class="total-win-label">
            Total Win: {{ lastWinnings.toFixed(2) }}
          </div>
          <button v-if="gameState === 'playing'" class="action-button cashout-button" @click="cashout">
            Cashout ({{ currentMultiplier.toFixed(2) }}x)
          </button>
          <div v-if="gameState === 'busted'" class="game-over-message">
            <span v-if="isCashedOut" class="win-message-color">¡Has ganado!</span>
            <span v-else>¡Has perdido!</span>
            <button class="action-button bet-button" @click="resetGame">
              Jugar de nuevo
            </button>
          </div>
        </div>
    
        <!-- Grid del Juego -->
        <div class="game-grid" :style="gridStyle">
          <div
            v-for="(tile, index) in grid"
            :key="index"
            class="tile"
            :class="{
              revealed: tile.isRevealed,
              mine: (tile.isRevealed && tile.isMine) || (isCashedOut && tile.isMine),
              diamond: tile.isRevealed && !tile.isMine,
              'game-over': gameState === 'busted'
            }"
            @click="onTileClick(index)"
          >
            <div class="tile-content">
              <span v-if="tile.isRevealed && !tile.isMine">💎</span>
              <span v-if="(tile.isRevealed && tile.isMine) || (isCashedOut && tile.isMine)">💣</span>
            </div>
          </div>
        </div>
      </div>

      <!-- win-info-label ahora está debajo del botón Bet -->
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useRouter } from 'vue-router';
import * as Tone from 'tone';
// Importa el saldo global y las funciones de sincronización
import { balance, syncBalance } from '../../store/balance.js';

// --- State ---
const gridDimension = ref(5); // 5 for 5x5, 3 for 3x3, etc.
const betAmount = ref(10.00);
const numMines = ref(3);
const gameState = ref('betting'); // 'betting', 'playing', 'busted'
const isCashedOut = ref(false);
const diamondsFound = ref(0);
// Usar el saldo global reactivo
const { uid } = balance;
const credits = balance.credits;
const router = useRouter();
const lastWinnings = ref(null);
const currentBetId = ref(null); // Para guardar el id_sesion de la apuesta

// Ocultar el mensaje de ganancia si el usuario cambia la apuesta o parámetros
watch([betAmount, gridDimension, numMines], () => {
  if (gameState.value === 'betting') {
    lastWinnings.value = null;
  }
});

// --- Computed Properties ---
const GRID_SIZE = computed(() => gridDimension.value * gridDimension.value);
const grid = ref(initializeGrid());

const maxMines = computed(() => GRID_SIZE.value - 1);

const gridStyle = computed(() => ({
  gridTemplateColumns: `repeat(${gridDimension.value}, 1fr)`,
  gridTemplateRows: `repeat(${gridDimension.value}, 1fr)`,
}));

const currentMultiplier = computed(() => {
  if (diamondsFound.value === 0) return 1.0;
  const safeTiles = GRID_SIZE.value - numMines.value;
  let multiplier = 1.0;
  for (let i = 0; i < diamondsFound.value; i++) {
    multiplier *= (GRID_SIZE.value - i) / (safeTiles - i);
  }
  return multiplier * 0.95; // Simulación de un "house edge"
});

// Sonidos Mines (libertad creativa)
const diamondSynth = new Tone.PolySynth().toDestination();
diamondSynth.set({ volume: -10 });
const mineSynth = new Tone.MembraneSynth({
  pitchDecay: 0.02,
  octaves: 4,
  envelope: { attack: 0.001, decay: 0.2, sustain: 0, release: 0.1 },
  volume: -8
}).toDestination();
const cashoutSynth = new Tone.PolySynth().toDestination();
cashoutSynth.set({ volume: -8 });
const loseSynth = new Tone.MonoSynth({
  oscillator: { type: 'triangle' },
  envelope: { attack: 0.01, decay: 0.3, sustain: 0, release: 0.2 },
  volume: -12
}).toDestination();

// --- Methods ---
function goBack() {
  router.push('/menu');
}

function initializeGrid() {
  return Array.from({ length: GRID_SIZE.value }, (_, i) => ({
    id: i,
    isMine: false,
    isRevealed: false,
  }));
}

watch(gridDimension, () => {
  if (numMines.value >= GRID_SIZE.value) {
    numMines.value = GRID_SIZE.value - 1;
  }
  grid.value = initializeGrid();
});

function startGame() {
  if (betAmount.value <= 0) {
    alert("Please enter a bet amount greater than zero.");
    return;
  }
  gameState.value = 'playing';
  diamondsFound.value = 0;
  
  grid.value = initializeGrid();
  let minesPlaced = 0;
  while (minesPlaced < numMines.value) {
    const randomIndex = Math.floor(Math.random() * GRID_SIZE.value);
    if (!grid.value[randomIndex].isMine) {
      grid.value[randomIndex].isMine = true;
      minesPlaced++;
    }
  }
}

async function onTileClick(index) {
  if (gameState.value !== 'playing' || grid.value[index].isRevealed) {
    return;
  }

  const tile = grid.value[index];
  tile.isRevealed = true;

  if (tile.isMine) {
    // Sonido de explosión
    mineSynth.triggerAttackRelease('C2', '16n');
    gameState.value = 'busted';
    revealAllMines();

    // Finalizar la apuesta como PERDIDA en un solo paso
    await fetch('http://localhost:4000/api/bet/create', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ uid: uid.value, id_juego: 5, monto: betAmount.value, resultado: 'PERDIDO', multiplicador: 0 })
    });
    await syncBalance();

    // Sonido de perder
    setTimeout(() => loseSynth.triggerAttackRelease('C1', '8n'), 200);
  } else {
    // Sonido de diamante
    diamondSynth.triggerAttackRelease(['C5', 'E5', 'G5'], '16n');
    diamondsFound.value++;
  }
}

function revealAllMines() {
  grid.value.forEach(tile => {
    if (tile.isMine) {
      tile.isRevealed = true;
    }
  });
}

async function cashout() {
  if (gameState.value !== 'playing' || diamondsFound.value === 0) return;
  const winnings = betAmount.value * currentMultiplier.value;
  const multiplier = currentMultiplier.value;

  // Finalizar la apuesta como GANADA en un solo paso
  await fetch('http://localhost:4000/api/bet/create', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ uid: uid.value, id_juego: 5, monto: betAmount.value, resultado: 'GANADO', multiplicador: multiplier })
  });
  await syncBalance();

  // Sonido de cashout alegre
  cashoutSynth.triggerAttackRelease(['C6', 'E6', 'G6'], '8n');
  lastWinnings.value = winnings - betAmount.value; // Mostrar ganancia neta
  
  isCashedOut.value = true;
  gameState.value = 'busted'; // Reutilizamos el estado 'busted' para mostrar el tablero final
  diamondsFound.value = 0;
}

function resetGame() {
  gameState.value = 'betting';
  isCashedOut.value = false;
  grid.value = initializeGrid();
  // No borramos lastWinnings aquí
}
</script>

<style scoped>
.mines-game-container {
  padding: 8rem 2rem 2rem 2rem; /* Espacio para el header fijo */
  background-color: #0a1929;
  color: #fff;
  font-family: 'Montserrat', sans-serif;
  min-height: 100vh;
  justify-content: center;
  align-items: flex-start;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.game-content {
  text-align: left;
}

/* Header */
.game-header {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  background: linear-gradient(180deg, #1f2937, #121212);
  border-bottom: 1px solid #2a3a50;
  padding: 1rem 2rem;
  box-shadow: 0 4px 15px rgba(0,0,0,0.3);
  z-index: 100;
}

.header-container {
  display: flex;
  justify-content: space-between;
  align-items: center;
  max-width: 1400px;
  margin: 0 auto;
}

.brand-title {
  font-family: 'Playfair Display', serif;
  font-size: 2rem;
  color: #d4af37;
  text-shadow: 0 0 10px rgba(212, 175, 55, 0.4);
  margin: 0;
}

.game-info {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
}

.game-subtitle {
  font-family: 'Montserrat', sans-serif;
  font-size: 1.2rem;
  font-weight: 600;
  color: #e0e0e0;
}

.stats {
  display: flex;
  gap: 1rem;
}

.stat-item {
  background: rgba(0,0,0,0.3);
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1px solid #2a3a50;
  font-size: 0.9rem;
  color: #a0aec0;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.stat-item strong {
  color: #ffffff;
  font-size: 1.1rem;
}

.stat-item.bet-stat strong {
  color: #f0b90b;
}

.btn-back-below-header {
  margin-bottom: 1.5rem; /* Espacio entre el botón y la sección de apuestas */
  background: linear-gradient(45deg, #f0b90b, #d4af37, #b8860b);
  color: white;
  border: none;
  border-radius: 20px;
  padding: 0.6rem 1.2rem;
  font-family: 'Montserrat', sans-serif;
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 15px rgba(212, 175, 55, 0.3);
}

.btn-back-below-header:hover {
  box-shadow: 0 0 20px rgba(212, 175, 55, 0.7);
  transform: translateY(-1px);
}

.btn-back-below-header:disabled {
  background: #333;
  color: #666;
  cursor: not-allowed;
  box-shadow: none;
  transform: none;
}

.main-game-area {
  display: flex;
  gap: 2rem;
  justify-content: center;
}

.controls-panel {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  background-color: #1a2c38;
  padding: 1.5rem;
  border-radius: 8px;
  width: 250px;
  border: 1px solid #22c55e;
  box-shadow: 0 0 20px rgba(34, 197, 94, 0.2);
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.control-group label {
  font-size: 0.9rem;
  color: #b0c4de;
  font-weight: 600;
}

.input-group {
  display: flex;
}

.input-group input, select {
  background-color: #0f212e;
  border: 1px solid #22c55e;
  color: #fff;
  padding: 0.75rem;
  border-radius: 4px;
  width: 100%;
  transition: all 0.2s ease;
}

input:focus, select:focus {
  outline: none;
  box-shadow: 0 0 10px rgba(34, 197, 94, 0.5);
  border-color: #4ade80;
}

.action-button {
  width: 100%;
  padding: 0.75rem;
  border: none;
  border-radius: 6px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s ease;
}

.bet-button {
  background-color: #22c55e;
  color: #fff;
  box-shadow: 0 0 15px rgba(34, 197, 94, 0.3);
}
.bet-button:hover {
  background-color: #4ade80;
  transform: translateY(-2px);
}

.cashout-button {
  background-color: #38bdf8;
  color: #0f212e;
  box-shadow: 0 0 15px rgba(56, 189, 248, 0.3);
}
.cashout-button:hover {
  background-color: #7dd3fc;
  transform: translateY(-2px);
}

.game-over-message {
  text-align: center;
  color: #f87171;
  font-weight: bold;
}
.win-message-color {
  color: #22c55e;
}
.game-over-message .action-button {
  margin-top: 1rem;
}

.game-grid {
  display: grid;
  gap: 10px;
  width: 600px;
  height: 600px;
  background-color: #1a2c38;
  padding: 1rem;
  border-radius: 12px;
  border: 1px solid #22c55e;
  box-shadow: 0 0 30px rgba(34, 197, 94, 0.15), inset 0 0 20px rgba(0,0,0,0.4);
}

.tile {
  background-color: #2f4553; /* Color base del cuadro */
  border-radius: 8px; /* Bordes suaves */
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  transition: all 0.2s ease;
  position: relative;
  overflow: hidden;
  border: 1px solid transparent;
}

.tile:not(.revealed):hover {
  border-color: #38bdf8;
  box-shadow: 0 0 15px rgba(56, 189, 248, 0.4);
  transform: scale(1.05);
}

.tile.revealed {
  cursor: default;
  background-color: #0f212e; /* Fondo revelado */
  border-color: #475569;
}

.tile.game-over:not(.revealed) {
  opacity: 0.5;
  cursor: not-allowed;
}

.tile-content {
  font-size: 2rem;
  animation: appear 0.4s ease-out;
  text-shadow: 0 0 10px currentColor;
}

.tile.mine .tile-content {
  animation: explode 0.3s forwards;
  color: #f87171;
}

.tile.diamond .tile-content {
  color: #38bdf8;
}

@keyframes appear {
  from {
    transform: scale(0.5);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

@keyframes explode {
  0% { transform: scale(0.5); opacity: 0; }
  70% { transform: scale(1.2); opacity: 1; }
  100% { transform: scale(1); opacity: 1; }
}

/* Deshabilitar estilos */
button:disabled, input:disabled, select:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  box-shadow: none;
  transform: none;
}

button:disabled:hover {
  background-color: initial; /* Evita cambio de color en hover cuando está deshabilitado */
  transform: none;
}

.total-win-label {
  margin: 0.7rem 0 0.7rem 0;
  background: #18222e;
  color: #22c55e;
  font-size: 1.1rem;
  font-weight: 600;
  border-radius: 8px;
  padding: 0.6rem 0;
  text-align: center;
  letter-spacing: 1px;
  user-select: none;
  width: 100%;
  box-shadow: none;
  border: none;
}
</style>