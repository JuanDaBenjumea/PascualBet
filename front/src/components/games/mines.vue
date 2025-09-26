<template>
  <div class="mines-game-container">
    <!-- Panel de Controles Izquierdo -->
    <div class="controls-panel">
      <div class="control-group">
        <label>Bet Amount</label>
        <div class="input-group">
          <input type="number" v-model.number="betAmount" :disabled="gameState !== 'betting'" />
          <button @click="halfBet" :disabled="gameState !== 'betting'">½</button>
          <button @click="doubleBet" :disabled="gameState !== 'betting'">2×</button>
          <button @click="maxBet" :disabled="gameState !== 'betting'">Max</button>
        </div>
      </div>

      <div class="control-group">
        <label>Grid Size</label>
        <select v-model.number="gridDimension" :disabled="gameState !== 'betting'" @change="onGridSizeChange">
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
      <button v-if="gameState === 'playing'" class="action-button cashout-button" @click="cashout">
        Cashout ({{ currentMultiplier.toFixed(2) }}x)
      </button>
       <div v-if="gameState === 'busted'" class="game-over-message">
        ¡Has perdido!
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
          mine: tile.isRevealed && tile.isMine,
          diamond: tile.isRevealed && !tile.isMine,
          'game-over': gameState === 'busted'
        }"
        @click="onTileClick(index)"
      >
        <div class="tile-content">
          <span v-if="tile.isRevealed && !tile.isMine">💎</span>
          <span v-if="tile.isRevealed && tile.isMine">💣</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';

// --- State ---
const gridDimension = ref(5); // 5 for 5x5, 3 for 3x3, etc.
const betAmount = ref(0.00);
const numMines = ref(3);
const gameState = ref('betting'); // 'betting', 'playing', 'busted'
const diamondsFound = ref(0);

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

// --- Methods ---
function initializeGrid() {
  return Array.from({ length: GRID_SIZE.value }, (_, i) => ({
    id: i,
    isMine: false,
    isRevealed: false,
  }));
}

function onGridSizeChange() {
  if (numMines.value >= GRID_SIZE.value) {
    numMines.value = GRID_SIZE.value - 1;
  }
  grid.value = initializeGrid();
}

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

function onTileClick(index) {
  if (gameState.value !== 'playing' || grid.value[index].isRevealed) {
    return;
  }

  const tile = grid.value[index];
  tile.isRevealed = true;

  if (tile.isMine) {
    gameState.value = 'busted';
    revealAllMines();
  } else {
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

function cashout() {
    if (gameState.value !== 'playing' || diamondsFound.value === 0) return;
    const winnings = betAmount.value * currentMultiplier.value;
    alert(`¡Has ganado! Winnings: ${winnings.toFixed(2)}`);
    resetGame();
}

function resetGame() {
    gameState.value = 'betting';
    grid.value = initializeGrid();
}

// Control button methods
function halfBet() {
  betAmount.value = Math.max(0, betAmount.value / 2);
}

function doubleBet() {
  betAmount.value *= 2;
}

function maxBet() {
  betAmount.value = 1000; 
}
</script>

<style scoped>
.mines-game-container {
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

.input-group {
  display: flex;
}

.input-group input {
  flex-grow: 1;
  background-color: #0f212e;
  border: 1px solid #3a4c5a;
  color: #fff;
  padding: 0.5rem;
  border-radius: 4px 0 0 4px;
  width: 50%;
}

.input-group button {
  background-color: #3a4c5a;
  border: 1px solid #3a4c5a;
  border-left: none;
  color: #fff;
  cursor: pointer;
  padding: 0.5rem 0.75rem;
}

.input-group button:last-child {
  border-radius: 0 4px 4px 0;
}

select {
  background-color: #0f212e;
  border: 1px solid #3a4c5a;
  color: #fff;
  padding: 0.5rem;
  border-radius: 4px;
  width: 100%;
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
.bet-button:hover {
  background-color: #1db954;
}

.cashout-button {
  background-color: #f0b90b;
  color: #111;
}
.cashout-button:hover {
  background-color: #f3c93e;
}

.game-over-message {
  text-align: center;
  color: #ff4d4d;
  font-weight: bold;
}
.game-over-message .action-button {
  margin-top: 1rem;
}

.game-grid {
  display: grid;
  gap: 8px;
  width: 500px;
  height: 500px;
}

.tile {
  background-color: #2f4553;
  border-radius: 5px;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  transition: background-color 0.2s, transform 0.2s;
}

.tile:not(.revealed):hover {
  background-color: #3a5669;
  transform: scale(1.05);
}

.tile.revealed {
  cursor: default;
  background-color: #1a2c38;
}

.tile.game-over:not(.revealed) {
  opacity: 0.5;
}

.tile-content {
  font-size: 2rem;
  animation: appear 0.3s ease-in-out;
}

.tile.mine .tile-content {
  animation: explode 0.3s forwards;
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
}
</style>