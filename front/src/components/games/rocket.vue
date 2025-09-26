<template>
  <div class="rocket-game-container">
    <!-- Panel de Controles Izquierdo -->
    <div class="controls-panel">
      <div class="control-group">
        <label>Bet Amount</label>
        <div class="input-group">
          <input type="number" v-model.number="betAmount" :disabled="hasPlacedBet" />
        </div>
      </div>

      <div class="control-group">
        <label>Auto Cashout</label>
        <div class="input-group">
          <input type="number" v-model.number="autoCashout" :disabled="hasPlacedBet" placeholder="2.00" />
        </div>
      </div>

      <button 
        class="action-button"
        :class="buttonClass"
        @click="handleAction"
        :disabled="buttonDisabled"
      >
        {{ buttonText }}
      </button>

      <div v-if="gameMessage" class="game-message" :class="messageClass">
        {{ gameMessage }}
      </div>

      <div v-if="lastGameResult" class="last-result">
        Crashed at {{ lastGameResult.toFixed(2) }}x
      </div>
    </div>

    <!-- Área del Juego (Gráfico) -->
    <div class="game-area">
      <div class="multiplier-display" :class="{ 'crashed-text': gameState === 'crashed' }">
        <span v-if="gameState === 'running' || gameState === 'crashed'">{{ currentMultiplier.toFixed(2) }}x</span>
        <span v-if="gameState === 'waiting'">Waiting for next round...</span>
        <span v-if="gameState === 'starting'">Starting in {{ (countdown / 1000).toFixed(1) }}s</span>
      </div>
      <canvas ref="gameCanvas" width="600" height="400"></canvas>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, watch } from 'vue';

// --- State ---
const betAmount = ref(10);
const autoCashout = ref(2.0);
const gameState = ref('waiting'); // 'waiting', 'starting', 'running', 'crashed'
const currentMultiplier = ref(1.00);
const hasPlacedBet = ref(false);
const hasCashedOut = ref(false);
const lastGameResult = ref(null);
const countdown = ref(5000);
const gameMessage = ref(''); // Para mostrar mensajes de ganar/perder

// --- Canvas & Animation ---
const gameCanvas = ref(null);
let ctx = null;
let animationFrameId = null;
let gameStartTime = 0;
let crashPoint = 0;
let gameLoopInterval = null;

// --- Computed Properties for UI ---
const buttonText = computed(() => {
  if (gameState.value === 'running') {
    return hasCashedOut.value ? `Cashed Out @${autoCashout.value}x` : `Cashout @ ${currentMultiplier.value.toFixed(2)}x`;
  }
  if (hasPlacedBet.value) {
    return 'Waiting for next round';
  }
  return 'Place Bet';
});

const buttonClass = computed(() => {
  if (gameState.value === 'running' && !hasCashedOut.value) return 'cashout-button';
  return 'bet-button';
});

const buttonDisabled = computed(() => {
  // Si el juego está en curso, el botón (para cashout) no debe estar deshabilitado
  if (gameState.value === 'running') {
    return hasCashedOut.value; // Deshabilítalo solo si ya se ha cobrado
  }
  // Si se está esperando o comenzando, deshabilítalo si ya se ha apostado
  if (gameState.value === 'waiting' || gameState.value === 'starting') {
    return hasPlacedBet.value;
  }
  // Deshabilítalo en cualquier otro estado (como 'crashed')
  return true;
});

const messageClass = computed(() => {
  if (gameMessage.value.includes('won')) {
    return 'win-message';
  }
  if (gameMessage.value.includes('lost')) {
    return 'loss-message';
  }
  return '';
});


// --- Game Logic ---
function handleAction() {
  if (gameState.value === 'running' && hasPlacedBet.value && !hasCashedOut.value) {
    // Manual Cashout
    cashOut(currentMultiplier.value);
  } else if (gameState.value === 'waiting' || gameState.value === 'starting') {
    // Place Bet
    hasPlacedBet.value = true;
  }
}

function cashOut(multiplier) {
  if (!hasCashedOut.value) {
    hasCashedOut.value = true;
    const winnings = betAmount.value * multiplier;
    gameMessage.value = `You won ${winnings.toFixed(2)}!`;
    console.log(`Cashed out! Winnings: ${winnings.toFixed(2)}`);
    // Aquí mostrarías una notificación de ganancia
  }
}

function startGame() {
  gameMessage.value = ''; // Limpiar mensaje al iniciar
  hasCashedOut.value = false; // Resetear estado de cashout
  gameState.value = 'running';
  currentMultiplier.value = 1.00;
  gameStartTime = Date.now();
  
  // En un juego real, esto vendría del servidor.
  // Generamos un punto de crash aleatorio con una distribución que favorece valores más bajos.
  // Aumentar el exponente (de 3 a 4) hace que los resultados bajos sean más probables.
  crashPoint = Math.pow(Math.random(), 4) * 50 + 1; 
  console.log(`This round will crash at ${crashPoint.toFixed(2)}x`);

  animationFrameId = requestAnimationFrame(gameLoop);
}

function gameLoop() {
  const elapsedTime = (Date.now() - gameStartTime) / 1000; // en segundos
  // La curva de crecimiento del multiplicador
  currentMultiplier.value = Math.pow(1.05, elapsedTime);

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
  draw(); // Dibuja el estado final "crashed"
  cancelAnimationFrame(animationFrameId);

  if (hasPlacedBet.value && !hasCashedOut.value) {
      gameMessage.value = 'You lost your bet.';
      console.log('You lost your bet.');
      // Aquí mostrarías una notificación de pérdida
  }
}

function resetForNextRound() {
    hasPlacedBet.value = false;
    hasCashedOut.value = false;
    countdown.value = 5000; // Reiniciar la cuenta regresiva
    gameState.value = 'waiting';
    gameMessage.value = ''; // Limpiar el mensaje para la siguiente ronda
}

// --- Drawing on Canvas ---
function draw() {
  const width = gameCanvas.value.width;
  const height = gameCanvas.value.height;

  // Clear canvas
  ctx.clearRect(0, 0, width, height);

  // Draw background
  ctx.fillStyle = '#0f212e';
  ctx.fillRect(0, 0, width, height);

  if (gameState.value !== 'running' && gameState.value !== 'crashed') {
    return; // No dibujar gráfico si no está en juego
  }

  // Draw graph line
  ctx.beginPath();
  ctx.moveTo(0, height);
  ctx.lineWidth = 10;
  ctx.strokeStyle = '#f0b90b';

  const elapsedTime = (Date.now() - gameStartTime) / 1000;
  const currentX = Math.min(elapsedTime * 50, width); // Escala de tiempo a píxeles
  const currentY = height - Math.log(currentMultiplier.value) * 50; // Escala de multiplicador a píxeles (logarítmica)

  ctx.lineTo(currentX, Math.max(0, currentY));
  ctx.stroke();

  // Draw filled area under graph
  ctx.lineTo(currentX, height);
  ctx.lineTo(0, height);
  ctx.closePath();
  const gradient = ctx.createLinearGradient(0, 0, 0, height);
  gradient.addColorStop(0, 'rgba(240, 185, 11, 0.5)');
  gradient.addColorStop(1, 'rgba(240, 185, 11, 0)');
  ctx.fillStyle = gradient;
  ctx.fill();

  if (gameState.value === 'crashed') {
    // Draw explosion/crash effect
    ctx.fillStyle = 'rgba(255, 77, 77, 0.8)';
    ctx.beginPath();
    ctx.arc(currentX, currentY, 20, 0, Math.PI * 2);
    ctx.fill();
  }
}

// --- Lifecycle Hooks ---
onMounted(() => {
  ctx = gameCanvas.value.getContext('2d');
  draw();

  // Main game cycle manager
  gameLoopInterval = setInterval(() => {
    if (gameState.value === 'waiting') {
      gameState.value = 'starting';
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
  display: flex;
  gap: 2rem;
  padding: 2rem;
  background-color: #0f212e;
  color: #fff;
  font-family: Arial, sans-serif;
  border-radius: 8px;
  width: fit-content;
  margin: auto;
}

.controls-panel {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  background-color: #213743;
  padding: 1.5rem;
  border-radius: 8px;
  width: 250px;
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.control-group label {
  font-size: 0.9rem;
  color: #b0c4de;
}

.input-group input {
  background-color: #0f212e;
  border: 1px solid #3a4c5a;
  color: #fff;
  padding: 0.75rem;
  border-radius: 4px;
  width: 100%;
  box-sizing: border-box;
}

.action-button {
  width: 100%;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: background-color 0.2s;
}

.bet-button {
  background-color: #17a047;
  color: #fff;
}
.bet-button:hover:not(:disabled) {
  background-color: #1db954;
}

.cashout-button {
  background-color: #f0b90b;
  color: #111;
}
.cashout-button:hover:not(:disabled) {
  background-color: #f3c93e;
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.game-message {
  text-align: center;
  padding: 0.5rem;
  border-radius: 4px;
  font-weight: bold;
}

.win-message {
  background-color: rgba(23, 160, 71, 0.3);
  color: #17a047;
}

.loss-message {
  background-color: rgba(255, 77, 77, 0.3);
  color: #ff4d4d;
}

.last-result {
  text-align: center;
  font-size: 1rem;
  color: #ff4d4d;
  font-weight: bold;
  margin-top: 1rem;
}

.game-area {
  position: relative;
  width: 600px;
  height: 400px;
  background-color: #0f212e;
  border-radius: 8px;
  border: 1px solid #213743;
}

.multiplier-display {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 4rem;
  font-weight: bold;
  color: #fff;
  text-shadow: 2px 2px 8px rgba(0,0,0,0.5);
}

.multiplier-display.crashed-text {
  color: #ff4d4d;
}

canvas {
  display: block;
  width: 100%;
  height: 100%;
}
</style>