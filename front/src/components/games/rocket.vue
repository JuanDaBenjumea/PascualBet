<template>
  <div class="rocket-game-container">
    <!-- Header -->
    <header class="game-header">
      <h1 class="game-title">🚀 Cohete PascualBet</h1>
      <div class="user-actions">
        <div class="balance">Créditos: <strong>${{ credits }}</strong></div>
        <div class="balance">Apuesta: <strong class="danger-text">${{ betAmount }}</strong></div>
      </div>
      <button @click="goBack" class="btn-back">Volver</button>
    </header>

    <!-- Main Layout -->
    <div class="main-layout">
      <!-- Área del Juego (Gráfico) -->
      <div class="game-area-wrapper">
        <div class="game-area">
          <div class="multiplier-display" :class="{ 'crashed-text': gameState === 'crashed' }">
            <span v-if="gameState === 'running' || gameState === 'crashed'">{{ currentMultiplier.toFixed(2) }}x</span>
            <span v-if="gameState === 'waiting'">Esperando la siguiente ronda...</span>
            <span v-if="gameState === 'starting'">Despegando en {{ (countdown / 1000).toFixed(1) }}s</span>
          </div>
          <canvas ref="gameCanvas" width="800" height="450"></canvas>
        </div>

        <!-- Panel de Controles Inferior -->
        <div class="controls-panel">
          <div class="bet-controls">
            <button @click="decreaseBet" :disabled="isBettingLocked" class="btn control-btn">-</button>
            <div class="bet-display">
              <label>Apuesta</label>
              <input type="number" v-model.number="betAmount" :disabled="isBettingLocked" />
            </div>
            <button @click="increaseBet" :disabled="isBettingLocked" class="btn control-btn">+</button>
          </div>

          <div class="action-controls">
            <button 
              class="btn action-button"
              :class="buttonClass"
              @click="handleAction"
              :disabled="buttonDisabled"
            >
              {{ buttonText }}
            </button>
            <button @click="setMaxBet" :disabled="isBettingLocked" class="btn max-bet-btn">
              APUESTA MÁX
            </button>
          </div>

          <div class="auto-cashout-controls">
            <label>Auto Retirar</label>
            <input type="number" v-model.number="autoCashout" :disabled="isBettingLocked" placeholder="2.00x" />
          </div>
        </div>
      </div>

      <!-- Panel de Información Derecho -->
      <div class="info-panel">
        <h2 class="info-title">Resultados</h2>
        <div class="history-list">
          <div v-for="(result, index) in history" :key="index" class="history-item" :class="getHistoryClass(result)">
            {{ result.toFixed(2) }}x
          </div>
        </div>
        <div class="game-info">
          <div class="info-item">
            <span>Apuesta Mínima:</span>
            <strong>$1</strong>
          </div>
          <div class="info-item">
            <span>Apuesta Máxima:</span>
            <strong>$1000</strong>
          </div>
        </div>
        <div v-if="gameMessage" class="game-message" :class="messageClass">
          {{ gameMessage }}
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, reactive } from 'vue';
import { useRouter } from 'vue-router';

// --- State ---
const credits = ref(1000);
const betAmount = ref(10);
const betStep = 10;
const autoCashout = ref(2.0);
const gameState = ref('waiting'); // 'waiting', 'starting', 'running', 'crashed'
const currentMultiplier = ref(1.00);
const hasPlacedBet = ref(false);
const hasCashedOut = ref(false);
const lastGameResult = ref(null);
const history = ref([]);
const countdown = ref(5000);
const gameMessage = ref('');
const router = useRouter();

// --- Canvas & Animation ---
const gameCanvas = ref(null);
let ctx = null;
let animationFrameId = null;
const rocket = reactive({
  x: 60,
  y: 400,
  rotation: 0,
  trail: []
});
let gameStartTime = 0;
let crashPoint = 0;
let gameLoopInterval = null;

// --- UI Computed Properties ---
const buttonText = computed(() => {
  if (gameState.value === 'running') {
    return hasCashedOut.value ? `RETIRADO` : `RETIRAR @ ${currentMultiplier.value.toFixed(2)}x`;
  }
  if (hasPlacedBet.value) {
    return 'ESPERANDO RONDA';
  }
  return 'APOSTAR';
});

const buttonClass = computed(() => {
  if (gameState.value === 'running' && !hasCashedOut.value) return 'cashout-button';
  return 'bet-button';
});

const buttonDisabled = computed(() => {
  const canBet = (gameState.value === 'waiting' || gameState.value === 'starting') && !hasPlacedBet.value;
  const canCashout = gameState.value === 'running' && hasPlacedBet.value && !hasCashedOut.value;
  return !canBet && !canCashout;
});

const isBettingLocked = computed(() => gameState.value !== 'waiting' || hasPlacedBet.value);

const messageClass = computed(() => {
  if (gameMessage.value.includes('Ganaste')) {
    return 'win-message';
  }
  if (gameMessage.value.includes('perdiste')) {
    return 'loss-message';
  }
  return '';
});

// --- Game Logic ---
function handleAction() {
  if (buttonDisabled.value) return;
  if (gameState.value === 'running') {
    cashOut(currentMultiplier.value);
  } else if (gameState.value === 'waiting' || gameState.value === 'starting') {
    if (credits.value < betAmount.value) return;
    credits.value -= betAmount.value;
    hasPlacedBet.value = true;
  }
}

function cashOut(multiplier) {
  if (!hasCashedOut.value) {
    hasCashedOut.value = true;
    const winnings = betAmount.value * (multiplier > 0 ? multiplier : 1);
    credits.value += winnings;
    gameMessage.value = `¡Ganaste ${winnings.toFixed(2)}!`;
  }
}

function getHistoryClass(result) {
  if (result >= 10) return 'history-high';
  if (result >= 2) return 'history-medium';
  return 'history-low';
}

function decreaseBet() {
  betAmount.value = Math.max(1, betAmount.value - betStep);
}

function increaseBet() {
  betAmount.value = Math.min(1000, betAmount.value + betStep);
}

function setMaxBet() {
  betAmount.value = 1000;
}

function startGame() {
  gameMessage.value = '';
  hasCashedOut.value = false;
  gameState.value = 'running';
  currentMultiplier.value = 1.00;
  gameStartTime = Date.now();
  
  // En un juego real, esto vendría del servidor.
  crashPoint = 1 + Math.pow(Math.random(), 4) * 20; // Crash entre 1x y 21x, con más probabilidad en valores bajos
  console.log(`Esta ronda terminará en ${crashPoint.toFixed(2)}x`);

  animationFrameId = requestAnimationFrame(gameLoop);
}

function gameLoop() {
  const elapsedTime = (Date.now() - gameStartTime) / 1000; // en segundos
  currentMultiplier.value = Math.pow(1.07, elapsedTime);

  if (hasPlacedBet.value && !hasCashedOut.value && autoCashout.value > 0 && currentMultiplier.value >= autoCashout.value) {
      cashOut(autoCashout.value);
  }

  if (currentMultiplier.value >= crashPoint) {
    endGame();
  } else {
    draw();
    animationFrameId = requestAnimationFrame(gameLoop);
  }
}

function endGame() {
  gameState.value = 'crashed';
  currentMultiplier.value = crashPoint;
  lastGameResult.value = crashPoint;

  // Añadir al historial
  history.value.unshift(crashPoint); // unshift para añadir al principio
  if (history.value.length > 20) history.value.pop(); // Mantener solo los últimos 20

  draw(); // Dibuja el estado final "crashed"
  cancelAnimationFrame(animationFrameId);

  if (hasPlacedBet.value && !hasCashedOut.value) {
      gameMessage.value = 'Perdiste tu apuesta.';
  }
}

function resetForNextRound() {
    hasPlacedBet.value = false;
    hasCashedOut.value = false;
    countdown.value = 5000; // Reiniciar la cuenta regresiva
    gameState.value = 'waiting'; // Cambiar a 'waiting' para el próximo ciclo
    gameMessage.value = ''; // Limpiar el mensaje para la siguiente ronda
}

function goBack() {
  router.push('/menu');
}

// --- Drawing on Canvas ---
function draw() {
  const width = gameCanvas.value.width;
  const height = gameCanvas.value.height; // 800x450

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  // Draw background and grid
  ctx.fillStyle = '#0a1929';
  ctx.fillRect(0, 0, width, height);
  drawGrid(width, height);

  if (gameState.value === 'waiting') {
    return; // No dibujar gráfico si no está en juego
  }

  // Calcular posición del cohete
  const elapsedTime = (Date.now() - gameStartTime) / 1000;
  const progress = Math.min(elapsedTime / 12, 1); // Normaliza el tiempo para la curva

  rocket.x = 60 + progress * (width - 120);
  rocket.y = height - 50 - Math.pow(progress, 2) * (height - 100);
  rocket.rotation = -Math.atan(2 * progress * (height - 100) / (width - 120));

  // Actualizar y dibujar estela
  updateTrail();
  drawTrail();

  if (gameState.value === 'crashed') {
    drawExplosion(rocket.x, rocket.y);
  } else {
    drawRocket();
  }
}

function drawGrid(width, height) {
  ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
  ctx.lineWidth = 1;
  for (let i = 0; i < width; i += 20) {
    ctx.beginPath();
    ctx.moveTo(i, 0);
    ctx.lineTo(i, height);
    ctx.stroke();
  }
  for (let i = 0; i < height; i += 20) {
    ctx.beginPath();
    ctx.moveTo(0, i);
    ctx.lineTo(width, i);
    ctx.stroke();
  }
}

function drawRocket() {
  ctx.save();
  ctx.translate(rocket.x, rocket.y);
  ctx.rotate(rocket.rotation);
  
  // Cuerpo del cohete
  ctx.fillStyle = '#d1d5db'; // Gris claro
  ctx.beginPath();
  ctx.moveTo(25, 0); // Punta
  ctx.lineTo(-15, 12); // Base derecha
  ctx.lineTo(-15, -12); // Base izquierda
  ctx.closePath();
  ctx.fill();

  // Aletas
  ctx.fillStyle = '#e63946'; // Rojo
  ctx.fillRect(-20, 12, 10, 5); // Aleta derecha
  ctx.fillRect(-20, -17, 10, 5); // Aleta izquierda

  ctx.restore();
}

function updateTrail() {
  rocket.trail.push({ x: rocket.x - 25, y: rocket.y, radius: 8, opacity: 1 });
  airplane.trail.forEach(p => {
    p.opacity -= 0.03;
    p.radius -= 0.15;
  });
  airplane.trail = airplane.trail.filter(p => p.opacity > 0 && p.radius > 0);
}

function drawTrail() {
  const trailGradient = ctx.createRadialGradient(0, 0, 0, 0, 0, 8);
  trailGradient.addColorStop(0, 'rgba(255, 220, 150, 0.8)');
  trailGradient.addColorStop(1, 'rgba(255, 100, 0, 0)');

  airplane.trail.forEach(p => {
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
    ctx.fillStyle = `rgba(255, 220, 150, ${p.opacity * 0.5})`;
    ctx.fill();
  });
}

function drawExplosion(x, y) {
  ctx.fillStyle = '#ff4d4d';
  ctx.font = 'bold 36px "Poppins", sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('💥', x, y);
}

// --- Lifecycle Hooks ---
onMounted(() => {
  ctx = gameCanvas.value.getContext('2d');
  draw();

  // Main game cycle manager
  gameLoopInterval = setInterval(() => {
    if (gameState.value === 'waiting' && hasPlacedBet.value) {
      gameState.value = 'starting'; // Inicia la cuenta regresiva
    } else if (gameState.value === 'starting') {
      countdown.value -= 100;
      if (countdown.value <= 0) {
        startGame();
      }
    } else if (gameState.value === 'crashed') {
      resetForNextRound();
    }
  }, 100);
});

onUnmounted(() => {
  cancelAnimationFrame(animationFrameId);
  clearInterval(gameLoopInterval);
});

</script>

<style scoped>
.rocket-game-container {
  background: radial-gradient(ellipse at bottom, #1b2735 0%, #090a0f 100%);
  color: #fff;
  min-height: 100vh;
  overflow: hidden;
  position: relative;
  font-family: 'Poppins', sans-serif;
}

/* Header */
.game-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
  background: rgba(0,0,0,0.2);
  border-bottom: 1px solid #223042;
}

.game-title {
  font-size: 1.5rem;
  font-weight: 700;
}

.user-actions {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.balance {
  font-size: 1rem;
}

.danger-text {
  color: #ff4d4d;
}

.btn-back {
  padding: 0.5rem 1rem;
  background-color: #3a4c5a;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 600;
  transition: background-color 0.2s;
}
.btn-back:hover {
  background-color: #4f6a7e;
}

/* Layout */
.main-layout {
  display: grid;
  grid-template-columns: 3fr 1fr;
  gap: 2rem;
  padding: 2rem;
  height: calc(100vh - 70px); /* Ajustar altura */
}

.game-area-wrapper {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.game-area {
  position: relative;
  flex-grow: 1;
  background-color: #000;
  border-radius: 8px;
  border: 2px solid #4a5568;
  overflow: hidden;
  box-shadow: inset 0 0 15px rgba(74, 85, 104, 0.5);
}

.multiplier-display {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 6rem;
  font-weight: 700;
  color: #fff;
  text-shadow: 2px 2px 8px rgba(0,0,0,0.5);
  z-index: 10;
}

.multiplier-display.crashed-text {
  color: #ff4d4d;
}

/* Controls Panel */
.controls-panel {
  background: #1a202c;
  border-radius: 8px;
  padding: 1rem;
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  align-items: center;
  gap: 1rem;
}

.bet-controls {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: #2d3748;
  border-radius: 8px;
  padding: 0.5rem;
}

.control-btn {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  font-size: 1.5rem;
  font-weight: 700;
  background: #4a5568;
  border: none;
  color: white;
}

.bet-display {
  flex-grow: 1;
  text-align: center;
}
.bet-display label {
  font-size: 0.8rem;
  color: #a0aec0;
  display: block;
}
.bet-display input {
  background: transparent;
  border: none;
  color: white;
  font-size: 1.2rem;
  font-weight: 700;
  text-align: center;
  width: 100%;
}

.action-controls {
  display: flex;
  gap: 1rem;
}

.action-button, .max-bet-btn {
  flex-grow: 1;
  padding: 1rem;
  font-size: 1.2rem;
  font-weight: 700;
  border-radius: 8px;
  border: none;
  color: white;
  text-shadow: 0 0 5px rgba(0,0,0,0.5);
}

.action-button.bet-button {
  background: linear-gradient(180deg, #22c55e, #16a34a);
  box-shadow: 0 0 20px #22c55e;
}

.action-button.cashout-button {
  background: linear-gradient(180deg, #facc15, #eab308);
  color: #1a202c;
  box-shadow: 0 0 20px #facc15;
}

.max-bet-btn {
  background: linear-gradient(180deg, #a78bfa, #7c3aed);
  box-shadow: 0 0 20px #8b5cf6;
}

.auto-cashout-controls {
  text-align: center;
}
.auto-cashout-controls label {
  font-size: 0.8rem;
  color: #a0aec0;
}
.auto-cashout-controls input {
  background: #2d3748;
  border: 1px solid #4a5568;
  border-radius: 8px;
  color: white;
  padding: 0.5rem;
  width: 80px;
  text-align: center;
  margin-left: 0.5rem;
}

/* Info Panel */
.info-panel {
  background: #1a202c;
  border-radius: 8px;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.info-title {
  text-align: center;
  font-size: 1.2rem;
  font-weight: 700;
  color: #a0aec0;
  border-bottom: 1px solid #2d3748;
  padding-bottom: 1rem;
}

.history-list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

.history-item {
  padding: 0.3rem 0.6rem;
  border-radius: 4px;
  font-weight: bold;
  font-size: 0.9rem;
  transition: transform 0.2s;
}
.history-item:hover {
  transform: scale(1.1);
}

.history-low { background-color: #4f6a7e; color: #fff; }
.history-medium { background-color: #17a047; color: #fff; box-shadow: 0 0 10px #17a047; }
.history-high { background-color: #e63946; color: #fff; box-shadow: 0 0 10px #e63946; }

.game-info {
  margin-top: auto;
  background: #0f172a;
  border-radius: 8px;
  padding: 1rem;
}
.info-item {
  display: flex;
  justify-content: space-between;
  font-size: 0.9rem;
  padding: 0.25rem 0;
}
.info-item span { color: #a0aec0; }

.game-message { text-align: center; padding: 0.5rem; border-radius: 4px; font-weight: bold; }
.win-message { background-color: rgba(23, 160, 71, 0.2); color: #22c55e; }
.loss-message { background-color: rgba(255, 77, 77, 0.2); color: #ff4d4d; }

/* General Button Styles */
.btn:disabled { opacity: 0.5; cursor: not-allowed; box-shadow: none; }
.btn:hover:not(:disabled) { filter: brightness(1.2); }

canvas {
  display: block;
  width: 100%;
  height: 100%;
}
</style>