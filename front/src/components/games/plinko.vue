<template>
  <div class="plinko-game-container">
  <button @click="goBack" class="btn-back top-left" :disabled="isBettingLocked">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
        <path fill-rule="evenodd" d="M12 8a.5.5 0 0 1-.5.5H5.707l2.147 2.146a.5.5 0 0 1-.708.708l-3-3a.5.5 0 0 1 0-.708l3-3a.5.5 0 1 1 .708.708L5.707 7.5H11.5a.5.5 0 0 1 .5.5z"/>
      </svg>
      Volver al Menú
    </button>
    <div class="controls-panel">
      <div class="balance-bar left">
        <span class="balance-icon">💰</span>
        <span class="balance-label">Saldo:</span>
        <span class="balance-amount">$ {{ balance.toFixed(2) }}</span>
      </div>
      <!-- Selector de Modo -->
      <div class="control-group mode-selector">
        <button :class="{ active: gameMode === 'manual' }" @click="setGameMode('manual')" :disabled="isAutoBetting">Manual</button>
        <button :class="{ active: gameMode === 'auto' }" @click="setGameMode('auto')" :disabled="isAutoBetting">Auto</button>
      </div>

      <div class="control-group">
        <label>Bet Amount</label>
        <div class="input-group">
          <input type="number" v-model.number="betAmount" :disabled="isBettingLocked" />
        </div>
      </div>

      <div class="control-group">
        <label>Risk Level</label>
        <select v-model="riskLevel" :disabled="isBettingLocked">
          <option value="low">Low</option>
          <option value="medium">Medium</option>
          <option value="high">High</option>
        </select>
      </div>

      <div class="control-group">
        <label>Number of Balls</label>
        <select v-model.number="ballsPerBet" :disabled="isBettingLocked">
          <option v-for="n in 10" :key="n" :value="n">{{ n }}</option>
        </select>
      </div>

      <!-- Controles Modo Automático -->
      <div v-if="gameMode === 'auto'" class="control-group">
        <label>Number of Bets</label>
        <div class="input-group">
          <input type="number" v-model.number="numberOfBets" :disabled="isBettingLocked" placeholder="∞" />
        </div>
      </div>

      <button 
        class="action-button"
        :class="buttonClass"
        @click="handleAction"
        :disabled="isButtonDisabled || (isAutoBetting && gameMode === 'auto')"
      >
        <template v-if="isAutoBetting && gameMode === 'auto'">
          Auto-Bet en progreso...
        </template>
        <template v-else>
          {{ buttonText }}
        </template>
      </button>

      <div v-if="totalWinThisRound !== null" class="game-message" :class="totalWinThisRound > 0 ? 'win-message' : 'loss-message'">
        {{ totalWinThisRound > 0 ? `Total Win: ${totalWinThisRound.toFixed(2)}` : 'No luck this round!' }}
      </div>
    </div>

    <!-- Área del Juego (Tablero) -->
    <div class="game-area" ref="gameAreaRef">
      <svg :viewBox="`0 0 ${boardWidth} ${boardHeight}`" class="plinko-board">
        <!-- Pivotes (Pegs) -->
        <circle
          v-for="peg in pegs"
          :key="peg.id"
          :cx="peg.x"
          :cy="peg.y"
          :r="pegRadius"
          :class="['peg', { 'hit': hitPegs.has(peg.id) }]"
        />

        <!-- Cubos Multiplicadores -->
        <g v-for="(bucket, index) in buckets" :key="`bucket-${index}`">
          <rect
            :x="bucket.x"
            :y="bucket.y"
            :width="bucketWidth"
            :height="bucketHeight"
            :class="['bucket', `bucket-color-${bucket.color}`, { 'pressed': lastHitBucketIndex === index }]"
          />
          <text
            :x="bucket.x + bucketWidth / 2"
            :y="bucket.y + bucketHeight / 2 + 5"
            class="bucket-text"
          >
            {{ bucket.multiplier }}x
          </text>
        </g>

        <!-- Bola -->
        <circle
          v-if="ball.visible"
          :cx="ball.x"
          :cy="ball.y"
          :r="ballRadius"
          class="ball"
        />
      </svg>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed, watch, onMounted, onUnmounted } from "vue";
import { useRouter } from 'vue-router';
import { balance, updateBalance, syncBalance } from '../../store/balance.js';
import * as Tone from 'tone';

// --- Funciones de Lógica y Probabilidad (integradas desde plinko-logic.js) ---

/**
 * Calcula el coeficiente binomial "n choose k".
 * C(n, k) = n! / (k! * (n - k)!)
 * @param {number} n - Número total de ensayos (filas_estacas).
 * @param {number} k - Número de éxitos (desvíos a la izquierda).
 * @returns {number} El coeficiente binomial.
 */
function binomialCoefficient(n, k) {
  if (k < 0 || k > n) {
    return 0;
  }
  if (k === 0 || k === n) {
    return 1;
  }
  if (k > n / 2) {
    k = n - k;
  }
  let res = 1;
  for (let i = 1; i <= k; i++) {
    res = res * (n - i + 1) / i;
  }
  return res;
}

/**
 * Calcula la distribución de probabilidad binomial para cada casilla final.
 * @param {number} filas_estacas - El número de filas de estacas.
 * @param {number} probabilidad_desvio_izq (p) - La probabilidad de que la bola se desvíe a la izquierda.
 * @returns {number[]} Un array con la probabilidad de caer en cada una de las `filas_estacas + 1` casillas.
 */
function calculateBinomialProbabilities(filas_estacas, probabilidad_desvio_izq) {
  const num_casillas = filas_estacas + 1;
  const probabilities = new Array(num_casillas).fill(0);
  const p = probabilidad_desvio_izq;

  for (let k = 0; k < num_casillas; k++) {
    // k = número de desvíos a la izquierda
    const combinations = binomialCoefficient(filas_estacas, k);
    const probability = combinations * Math.pow(p, k) * Math.pow(1 - p, filas_estacas - k);
    probabilities[k] = probability;
  }

  return probabilities;
}

/**
 * Simula una gran cantidad de caídas de bolas para verificar la distribución de probabilidad.
 * @param {number} num_simulations - El número de caídas a simular (e.g., 10,000).
 * @param {number} filas_estacas - El número de filas de estacas.
 * @param {number} probabilidad_desvio_izq (p) - La probabilidad de desvío a la izquierda.
 * @returns {number[]} Un array con la frecuencia relativa de caída en cada casilla.
 */
function simulateLargeScale(num_simulations, filas_estacas, probabilidad_desvio_izq) {
  const num_casillas = filas_estacas + 1;
  const counts = new Array(num_casillas).fill(0);

  for (let i = 0; i < num_simulations; i++) {
    let left_moves = 0;
    for (let j = 0; j < filas_estacas; j++) {
      if (Math.random() < probabilidad_desvio_izq) {
        left_moves++;
      }
    }
    counts[left_moves]++;
  }

  return counts.map(count => count / num_simulations);
}

/**
 * Ajusta los multiplicadores para alcanzar un Retorno Esperado (ER) específico.
 * Los multiplicadores son inversamente proporcionales a la probabilidad de la casilla.
 * @param {number[]} probabilities - El array de probabilidades para cada casilla.
 * @param {number} targetER - El Retorno Esperado deseado (e.g., 0.95 para 95%).
 * @param {number[] | null} baseMultipliers - Multiplicadores base para dar forma a la curva (opcional).
 * @returns {number[]} Un array de multiplicadores ajustados.
 */
function adjustMultipliersForER(probabilities, targetER, baseMultipliers = null) {
  const num_casillas = probabilities.length;
  let multipliers = new Array(num_casillas);

  if (baseMultipliers) {
    // Usa una curva base si se proporciona (para riesgos 'low' y 'high')
    const mid = Math.floor(num_casillas / 2);
    for (let i = 0; i < num_casillas; i++) {
      const distFromMid = Math.abs(i - mid);
      multipliers[i] = baseMultipliers[distFromMid] || baseMultipliers[baseMultipliers.length - 1];
    }
  } else {
    // Genera multiplicadores inversamente proporcionales a la probabilidad
    const totalProb = probabilities.reduce((sum, p) => sum + (p > 0 ? 1 / p : 0), 0);
    for (let i = 0; i < num_casillas; i++) {
      multipliers[i] = (probabilities[i] > 0) ? (1 / probabilities[i]) / totalProb * num_casillas : 0;
    }
  }

  // Calcula el ER actual con los multiplicadores generados
  const currentER = probabilities.reduce((sum, prob, i) => sum + prob * multipliers[i], 0);

  // Si el ER actual es 0, no se puede escalar. Devuelve los multiplicadores base.
  if (currentER === 0) {
    return multipliers.map(m => parseFloat(m.toFixed(2)));
  }

  // Escala todos los multiplicadores para que coincidan con el ER objetivo
  const scaleFactor = targetER / currentER;
  const finalMultipliers = multipliers.map(m => m * scaleFactor);

  // Redondea a 2 decimales para la visualización
  return finalMultipliers.map(m => parseFloat(m.toFixed(2)));
}

export default {
  name: "Plinko",
  setup() {
    const { uid } = balance;

    function goBack() {
      router.push('/menu');
    }

    // --- Configuración del Tablero ---
    const gameAreaRef = ref(null);
    const filas_estacas = ref(12); // Parámetro de entrada: Número de filas de estacas
    const boardWidth = ref(500);
    const boardHeight = ref(550);
    const pegRadius = 8;
    const ballRadius = 10;
    const bucketHeight = 30;
    
    // --- Estado del Juego ---
    const gameMode = ref('manual'); // 'manual', 'auto'
    const router = useRouter();
    const betAmount = ref(10);
    const riskLevel = ref("medium"); // 'low', 'medium', 'high'
    const ballsPerBet = ref(1);
    const numberOfBets = ref(10); // Para modo auto
    
    const gameState = ref("betting"); // 'betting', 'dropping'
    const isAutoBetting = ref(false);
    const betsPlayed = ref(0);
    const totalWinThisRound = ref(null);
  // El saldo ahora viene del store centralizado
    
    const ball = reactive({
      id: 0,
      x: boardWidth.value / 2,
      y: 20,
      vx: 0,
      vy: 0,
      visible: false,
    });

    const hitPegs = reactive(new Set());
    const lastHitBucketIndex = ref(null);
    // --- Lógica de Probabilidad y Multiplicadores ---
    const probabilidad_desvio_izq = computed(() => {
      // El riesgo ajusta la probabilidad de desvío
      if (riskLevel.value === 'low') return 0.45; // Ligero sesgo al centro
      if (riskLevel.value === 'high') return 0.55; // Ligero sesgo a los extremos
      return 0.5; // Riesgo medio, sin sesgo
    });

    const probabilidades = computed(() => calculateBinomialProbabilities(filas_estacas.value, probabilidad_desvio_izq.value));
    const num_casillas = computed(() => filas_estacas.value + 1);

    // --- Lógica de la Interfaz ---

    const isBettingLocked = computed(() => gameState.value === 'dropping' || isAutoBetting.value);

    const buttonText = computed(() => {
      if (isAutoBetting.value) return `Stop Auto (${betsPlayed.value}/${numberOfBets.value || '∞'})`;
      if (gameState.value === 'dropping') return 'Dropping...';
      if (gameMode.value === 'auto') return 'Start Auto-Bet';
      return 'Place Bet';
    });

    const buttonClass = computed(() => {
      if (isAutoBetting.value) return 'stop-button';
      return 'bet-button';
    });

    const isButtonDisabled = computed(() => {
      if (gameMode.value === 'manual' && gameState.value === 'dropping') return true;
      return false;
    });

    function setGameMode(mode) {
      if (!isAutoBetting.value) {
        gameMode.value = mode;
      }
    }

    // Sonido de click para la salida de la bola
    const clickSynth = new Tone.NoiseSynth({ volume: -26 }).toDestination();

    // Clase para reproducir una nota con Tone.js
    class Note {
      constructor(note) {
        this.synth = new Tone.PolySynth().toDestination();
        this.synth.set({ volume: -6 });
        this.note = note;
      }
      play() {
        return this.synth.triggerAttackRelease(
          this.note,
          "32n",
          Tone.context.currentTime
        );
      }
    }
    // Notas asociadas a cada bucket/pivote
    const notesArr = [
      "C#5", "C5", "B5", "A#5", "A5", "G#4", "G4", "F#4",
      "F4", "F#4", "G4", "G#4", "A5", "A#5", "B5", "C5", "C#5"
    ].map((note) => new Note(note));

    // Sonido plano, corto y bajo para los buckets centrales
    const flatSynth = new Tone.NoiseSynth({
      volume: -28,
      envelope: { attack: 0.001, decay: 0.05, sustain: 0, release: 0.01 }
    }).toDestination();
    // Filtro para hacerlo más "plano"
    const flatFilter = new Tone.Filter(800, "lowpass").toDestination();
    flatSynth.connect(flatFilter);

    // Sonido audible para los buckets centrales si no suena nada
    const fallbackSynth = new Tone.PolySynth().toDestination();

    // Sonido fuerte y claro para los buckets centrales
    const centralSynth = new Tone.PolySynth().toDestination();
    centralSynth.set({ volume: -10 });

    // Sonido especial para los extremos (0 y 16): acorde mayor brillante
    const edgeSynth = new Tone.PolySynth().toDestination();
    edgeSynth.set({ volume: -8 });

    // Buckets centrales (planos): índices 5 a 10
    const bucketSounds = [
      // Extremo izquierdo
      () => edgeSynth.triggerAttackRelease(["C5", "E5", "G5"], '8n'),
      () => bellSynth.triggerAttackRelease('G4', '16n'),
      () => marimbaSynth.triggerAttackRelease('A4', '16n'),
      () => marimbaSynth.triggerAttackRelease('C5', '16n'),
      () => marimbaSynth.triggerAttackRelease('E5', '16n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      () => centralSynth.triggerAttackRelease('C5', '8n'),
      // ...resto igual...
      () => marimbaSynth.triggerAttackRelease('E5', '16n'),
      () => marimbaSynth.triggerAttackRelease('C5', '16n'),
      () => marimbaSynth.triggerAttackRelease('A4', '16n'),
      () => bellSynth.triggerAttackRelease('G4', '16n'),
      // Extremo derecho
      () => edgeSynth.triggerAttackRelease(["C5", "E5", "G5"], '8n'),
    ];

    // Descontar la apuesta al apostar (solo para manual y para cada ronda en auto)
    function handleAction() {
      if (isAutoBetting.value) {
        stopAutoBetting();
      } else if (gameMode.value === 'manual') {
        if (balance.credits.value >= betAmount.value * ballsPerBet.value) {
          startManualDrop();
        }
      } else if (gameMode.value === 'auto') {
        startAutoBetting(); // La validación de saldo se hace en el loop
      }
    }

    // En modo auto, descuenta la apuesta antes de cada ronda
    async function autoBetLoop() {
      if (!isAutoBetting.value) return;
      if (numberOfBets.value > 0 && betsPlayed.value >= numberOfBets.value) {
        stopAutoBetting();
        return;
      }
      const totalCost = betAmount.value * ballsPerBet.value;
      if (balance.credits.value >= totalCost) {
        await playRound();
        betsPlayed.value++;
        setTimeout(autoBetLoop, 500);
      } else {
        alert("Saldo insuficiente para continuar el auto-bet.");
        stopAutoBetting();
      }
    }

    // --- Geometría del Tablero (Computadas) ---
    const pegs = computed(() => {
      const pegArray = [];
      const rows = filas_estacas.value;
      const verticalSpacing = (boardHeight.value - bucketHeight - 80) / rows;
      const horizontalSpacing = boardWidth.value / (rows + 2); // Espaciado horizontal basado en el número de filas

      for (let row = 0; row < rows; row++) {
        const numPegsInRow = row + 1;
        const y = 60 + row * verticalSpacing;
        const startX = (boardWidth.value - (numPegsInRow - 1) * horizontalSpacing) / 2;
        for (let col = 0; col < numPegsInRow; col++) {
          const x = startX + col * horizontalSpacing;
          pegArray.push({ x, y, id: `${row}-${col}` });
        }
      }
      return pegArray;
    });


    const bucketWidth = computed(() => boardWidth.value / num_casillas.value);

    const buckets = computed(() => {
      // Ajusta los multiplicadores para un ER del 95%
      const baseMultipliers = { 
        low:    [1.1, 1, 1.2, 1.5, 3],   // Riesgo bajo: premios consistentes y bajos.
        medium: [0.5, 1.1, 2, 5, 15],  // Riesgo medio: equilibrio.
        high:   [0.3, 0.5, 3, 10, 30]    // Riesgo alto: alta volatilidad.
      };
      const adjustedMultipliers = adjustMultipliersForER(
        probabilidades.value, 
        0.95, // ER del 95%
        baseMultipliers[riskLevel.value] || null // Pasa multiplicadores base para 'low' y 'high'
      );

      const bWidth = bucketWidth.value;

      const colors = {
        low:    ['green', 'blue', 'yellow'],
        medium: ['green', 'blue', 'yellow'],
        high:   ['red', 'green', 'blue', 'yellow'],
      };

      return adjustedMultipliers.map((m, i) => ({
        x: i * bWidth,
        y: boardHeight.value - bucketHeight,
        multiplier: m,
        color: colors[riskLevel.value][i % colors[riskLevel.value].length]
      }));
    });


    // --- Lógica de Animación y Juego ---
    let animationFrameId = null;

    async function startManualDrop() {
      if (gameState.value === 'dropping') return;
      await playRound();
    }

    function startAutoBetting() {
      isAutoBetting.value = true;
      betsPlayed.value = 0;
      autoBetLoop();
    }

    function stopAutoBetting() {
      isAutoBetting.value = false;
    }

    async function playRound() {
      const totalCost = betAmount.value * ballsPerBet.value;
      if (totalCost <= 0) {
        alert("Please place a valid bet.");
        return;
      }

      if (balance.credits.value < totalCost) {
        alert("Saldo insuficiente.");
        return;
      }

      gameState.value = 'dropping';
      totalWinThisRound.value = 0;
      clickSynth.triggerAttackRelease('8n');

      try {
        for (let i = 0; i < ballsPerBet.value; i++) {
          const { win, multiplier } = await dropSingleBall(i);
          const resultado = win > 0 ? 'GANADO' : 'PERDIDO';

          try {
            await fetch('http://localhost:4000/api/bet/create', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ uid: uid.value, id_juego: 4, monto: betAmount.value, resultado, multiplicador })
            });
            await syncBalance();
          } catch (error) {
            console.error("Error communicating with the server during bet:", error);
          }

          if (ballsPerBet.value > 1 && i < ballsPerBet.value - 1) {
            await new Promise(resolve => setTimeout(resolve, 200));
          }
        }
      } catch (error) {
        console.error("An error occurred during the Plinko round:", error);
      } finally {
        gameState.value = 'betting';
        setTimeout(() => {
          totalWinThisRound.value = null;
        }, 3000);
      }
    }

    function animate(resolve, startTime) {
      const elapsedTime = Date.now() - startTime;
      if (elapsedTime > 10000) { // 10 segundos de tiempo de espera
        console.warn(`La bola de Plinko ${ball.id} ha superado el tiempo de espera y ha sido eliminada.`);
        ball.visible = false;
        resolve({ win: 0, multiplier: 0 }); // Resuelve como una pérdida
        return; // Detiene el bucle de animación
      }

      // Comprobar si ha llegado al fondo ANTES de la siguiente animación
      if (ball.y > boardHeight.value - bucketHeight - ballRadius) {
        ball.visible = false;

        const bucketIndex = Math.floor(ball.x / bucketWidth.value);
        const winningBucket = buckets.value[bucketIndex];

        // Animar el cubo ganador
        lastHitBucketIndex.value = bucketIndex;
        setTimeout(() => {
          if (lastHitBucketIndex.value === bucketIndex) lastHitBucketIndex.value = null;
        }, 500);

        if (winningBucket) {
          const winAmount = betAmount.value * winningBucket.multiplier;
          totalWinThisRound.value += winAmount;
          resolve({ win: winAmount, multiplier: winningBucket.multiplier });
        } else {
          resolve({ win: 0, multiplier: 0 }); // Cayó fuera
        }
        return; // Detener el bucle de animación
      }

      // Aplicar gravedad
      ball.vy += 0.15;

      // Actualizar posición
      ball.x += ball.vx;
      ball.y += ball.vy;

      // Detección de colisión con pivotes
      for (const peg of pegs.value) {
        const dx = ball.x - peg.x;
        const dy = ball.y - peg.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < ballRadius + pegRadius) {
          if (!hitPegs.has(peg.id)) {
            hitPegs.add(peg.id);
            setTimeout(() => hitPegs.delete(peg.id), 300);
            
            const bucketIdx = Math.round(peg.x / bucketWidth.value);
            if (notesArr[bucketIdx]) notesArr[bucketIdx].play();
          }
          
          ball.vy *= -0.4;
          ball.vx = (dx / distance) * 2.5 + (Math.random() - 0.5);
        }
      }

      // Detección de colisión con paredes
      if (ball.x < ballRadius || ball.x > boardWidth.value - ballRadius) {
        ball.vx *= -0.8;
      }

      animationFrameId = requestAnimationFrame(() => animate(resolve, startTime));
    }

    function dropSingleBall(id) {
      return new Promise(resolve => {
        const startTime = Date.now();
        hitPegs.clear();
        ball.id = id;
        ball.x = boardWidth.value / 2 + (Math.random() - 0.5) * 10;
        ball.y = 20;
        ball.vx = 0;
        ball.vy = 0;
        ball.visible = true;

        // Cancelar cualquier frame de animación anterior para evitar bucles fantasma
        if (animationFrameId) {
          cancelAnimationFrame(animationFrameId);
        }
        
        animate(resolve, startTime);
      });
    }

    watch(riskLevel, () => {
      totalWinThisRound.value = null;
    });

    // --- Lógica de Redimensionamiento ---
    let resizeObserver = null;

    onMounted(() => {
      if (gameAreaRef.value) {
        resizeObserver = new ResizeObserver(entries => {
          for (const entry of entries) {

            const { width, height } = entry.contentRect;
            boardWidth.value = width;
            boardHeight.value = height;
          }
        });
        resizeObserver.observe(gameAreaRef.value);
      }
    });

    onUnmounted(() => {
      if (resizeObserver && gameAreaRef.value) {
        resizeObserver.unobserve(gameAreaRef.value);
      }
      if (animationFrameId) {
        cancelAnimationFrame(animationFrameId);
      }
    });

    return {
      gameMode,
      betAmount,
      riskLevel,
      gameState,
      totalWinThisRound,
      buttonText,
      boardWidth,
      boardHeight,
      pegs,
      pegRadius,
      buckets,
      bucketWidth,
      bucketHeight,
      ball,
      ballRadius,
      setGameMode,
      isBettingLocked,
      isAutoBetting,
      ballsPerBet,
      numberOfBets,
      betsPlayed,
      buttonClass,
      isButtonDisabled,
      goBack,
      gameAreaRef,
      hitPegs,
      lastHitBucketIndex,
  balance: computed(() => balance.credits.value),
      handleAction,
    };
  },
};
</script>

<style scoped>
.plinko-game-container {
  position: fixed;
  top: 10;
  left: 0;
  width: 100vw;
  height: 100vh;
  display: flex;
  gap: 2rem;
  justify-content: center;
  align-items: center;
  padding: 2rem;
  background: #1D1E22;
  color: #fff;
  box-sizing: border-box;
}


.btn-back {
  position: absolute;
  top: 1.5rem;
  left: 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 1.2rem;
  background: linear-gradient(145deg, #3a4c5a, #213743);
  color: #e0e0e0;
  border: 1px solid #4f6a7e;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  font-size: 0.9rem;
  z-index: 20;
  transition: all 0.2s ease-in-out;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
}
.btn-back:hover {
  background: linear-gradient(145deg, #4f6a7e, #3a4c5a);
  transform: translateY(-2px);
  box-shadow: 0 6px 15px rgba(0, 0, 0, 0.4);
  color: #fff;
}

.btn-back.top-left {
  position: absolute;
  top: 18px;
  left: 18px;
  z-index: 30;
  background: #22313f;
  color: #fff;
  border: none;
  border-radius: 8px;
  padding: 8px 18px;
  font-weight: bold;
  font-size: 1rem;
  box-shadow: 0 2px 8px #0002;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: background 0.2s, transform 0.1s;
}
.btn-back.top-left:hover {
  background: #1abc9c;
  color: #22313f;
  transform: translateY(-2px) scale(1.04);
}

.controls-panel {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  background: linear-gradient(180deg, #1f2c39, #0f1a24); /* Degradado sutil */
  padding: 2rem;
  border-radius: 16px; /* Bordes más redondeados */
  width: 280px;
  flex-shrink: 0; /* Evita que el panel se encoja */
  min-height: 450px; /* Altura mínima para el modo manual */
  transition: min-height 0.3s ease; /* Transición suave */
  border: 1px solid #3a4c5a;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4); /* Sombra para profundidad */
  font-family: 'Poppins', sans-serif; /* Fuente moderna */
}

.balance-bar.left {
  justify-content: flex-start;
  margin: 0 0 18px 0;
  padding: 10px 18px;
  font-size: 1.1rem;
  border-radius: 10px;
  background: linear-gradient(90deg, #232526 0%, #414345 100%);
  box-shadow: 0 2px 8px #0002;
}

.mode-selector {
  display: flex;
  background-color: #0f212e;
  border-radius: 4px;
  padding: 4px;
}
.mode-selector button {
  flex: 1;
  padding: 0.5rem;
  border: none;
  background-color: transparent;
  color: #b0c4de;
  font-weight: 600;
  cursor: pointer;
}
.mode-selector button.active {
  background-color: #3a4c5a;
  color: #fff;
  border-radius: 4px;
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.control-group label {
  font-size: 0.9rem;
  font-weight: 600; /* Títulos en negrita */
  color: #b0c4de;
}

.input-group input, select {
  background-color: #0a1016;
  border: 1px solid #00d4ff; /* Borde cian */
  color: #fff;
  padding: 0.75rem;
  border-radius: 8px; /* Bordes más redondeados */
  width: 100%;
  box-sizing: border-box;
  font-family: 'Poppins', sans-serif;
  transition: all 0.2s ease;
}

.input-group input:focus, select:focus {
  outline: none;
  box-shadow: 0 0 10px rgba(0, 212, 255, 0.5); /* Resplandor al enfocar */
  border-color: #33eaff;
}

.action-button {
  width: 100%;
  padding: 0.75rem;
  border: none;
  border-radius: 4px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.2s ease;
  text-transform: uppercase;
}

.bet-button {
  background-color: #17a047;
  color: #fff;
  box-shadow: 0 0 15px rgba(23, 160, 71, 0.4);
}
.bet-button:hover:not(:disabled) {
  background-color: #1db954;
  transform: translateY(-2px);
  box-shadow: 0 0 25px rgba(29, 185, 84, 0.7); /* Efecto glow */
}

.stop-button {
  background-color: #ef4444;
  color: #fff;
  box-shadow: 0 0 15px rgba(239, 68, 68, 0.4);
}
.stop-button:hover:not(:disabled) {
  background-color: #dc2626;
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

.game-area {
  flex-grow: 1; /* Ocupa el espacio restante */
  height: 100%;
  background-color: #1A1A21; /* Color solicitado */
  border-radius: 8px;

  border: 1px solid #213743;
  display: flex;
  align-items: center;
  justify-content: center;
}

.plinko-board {
  width: 100%;
  height: 100%;
}


.peg {
  fill: #fff; /* Adjust peg color */
  stroke: #3a4c5a; /* Add a dark stroke for definition */
  stroke-width: 0.2;
  transition: fill 0.3s ease, transform 0.1s ease, filter 0.1s ease; /* Add transition for hover effect */
}
.peg.hit {
  fill: #ffffff;
  filter: drop-shadow(0 0 8px rgba(255, 255, 255, 1)); /* Brillo más intenso */
  transform: scale(1.01); /* Movimiento reducido al 1% */
  transition: fill 0.05s ease, filter 0.05s ease, transform 0.05s ease;
}


.ball {
  fill: #ff4d4d; /* Adjust ball color */
  stroke: #fff;
  stroke-width: 0.2;
  /* Add a subtle glow effect */
  filter: drop-shadow(0 0 5px rgba(255, 77, 77, 0.7));
}


.bucket {
  stroke: #213743;
  stroke-width: 1;
  transform-origin: bottom center; /* Asegura que la animación se vea correcta */
}

.bucket.pressed {
  animation: press-bucket 0.5s ease-out;
}

@keyframes press-bucket {
  0%, 100% {
    transform: scaleY(1);
    filter: brightness(1);
  }
  50% {
    transform: scaleY(0.75); /* Aumenté la profundidad de la presión */
    filter: brightness(1.6); /* Aumenté el brillo */
  }
}


.bucket-color-yellow { fill: #bfa600; } /* amarillo oscuro */
.bucket-color-blue { fill: #225a8c; }   /* azul oscuro */
.bucket-color-green { fill: #11682d; }  /* verde oscuro */
.bucket-color-red { fill: #a02a2a; }    /* rojo oscuro */

.bucket-text {
  fill: #fff;
  font-size: 14px;
  font-weight: bold;
  text-anchor: middle;
  pointer-events: none;
}

/* Hover effect for pegs */
.peg:hover {
  fill: #f0b90b; /* Change color on hover */
  cursor: pointer; /* Change cursor to indicate interactivity */
}



</style>