<template>
  <div class="roulette-container">
    <!-- Header with theme styling -->
    <header class="game-header">
      <div class="container">
        <div class="brand">
          <h1 class="game-title">🎰 Ruleta PascualBet</h1>
        </div>
        <div class="user-actions">
          <div class="balance">
            Balance: <strong>${{ credits }}</strong>
          </div>
          <div class="balance">
            Apuesta: <strong style="color: var(--danger)">${{ totalBet }}</strong>
          </div>
        </div>
      </div>
    </header>

    <!-- Winner Banner -->
    <div 
      v-if="lastResult !== null && !spinning" 
      class="winner-banner animate-win-pulse"
    >
      <div class="winner-content">
        <div class="winner-label">🎲 NÚMERO GANADOR 🎲</div>
        <div class="winner-display">
          <div 
            class="winner-number"
            :class="getNumberColorClass(lastResult)"
          >
            {{ lastResult }}
          </div>
          <div class="winner-info">
            <div class="winner-type">{{ getNumberType(lastResult) }}</div>
            <div class="winner-details">{{ getNumberDetails(lastResult) }}</div>
          </div>
        </div>
        <div v-if="lastWin > 0" class="winner-prize">
          🏆 GANASTE ${{ lastWin }} 🏆
        </div>
        <div v-else class="winner-message">
          ¡Sigue intentando!
        </div>
      </div>
    </div>

    <div class="container">
      <!-- Main Game Area -->
      <div class="game-layout">
        
        <!-- Roulette Wheel Section -->
        <div class="wheel-section">
          <div class="card wheel-card">
            <div class="wheel-container">
              <canvas 
                ref="wheelCanvas" 
                width="320" 
                height="320" 
                class="roulette-wheel"
              ></canvas>
              
              <!-- Wheel Pointer -->
              <div class="wheel-pointer"></div>

              <!-- Ball -->
              <div 
                ref="ballElement"
                class="roulette-ball"
                :style="ballPosition"
              >
              </div>

              <!-- Result Highlight -->
              <div 
                v-if="resultHighlight.show"
                class="result-highlight animate-win-pulse"
                :style="resultHighlight.style"
              >
                <span class="result-number">{{ lastResult }}</span>
                <div class="result-arrow"></div>
              </div>

              <!-- Big Result Overlay -->
              <div 
                v-if="showBigResult"
                class="big-result-overlay"
              >
                <div class="big-result-content">
                  <div 
                    class="big-result-number animate-win-pulse"
                    :class="getNumberColorClass(lastResult)"
                  >
                    {{ lastResult }}
                  </div>
                  <div class="big-result-text">¡SALIÓ EL {{ lastResult }}!</div>
                  <div class="big-result-type">{{ getNumberType(lastResult) }}</div>
                  <div class="big-result-indicator">
                    🎯 ¡NÚMERO GANADOR! 🎯
                  </div>
                </div>
              </div>
            </div>
            
            <!-- Spin Button -->
            <div class="spin-section">
              <button 
                @click="spin" 
                :disabled="spinning || totalBet === 0"
                class="btn play spin-btn"
                :class="{ 'spinning': spinning }"
              >
                {{ spinning ? 'GIRANDO...' : 'GIRAR RULETA' }}
              </button>
            </div>
            
            <!-- Results Display -->
            <div v-if="lastResult !== null" class="results-panel">
              <div class="results-header">🏆 ÚLTIMO RESULTADO</div>
              <div class="results-display">
                <div 
                  class="result-circle"
                  :class="getNumberColorClass(lastResult)"
                >
                  {{ lastResult }}
                </div>
                <div class="result-info">
                  <div class="result-label">{{ getNumberType(lastResult) }}</div>
                  <div class="result-details">{{ getNumberDetails(lastResult) }}</div>
                </div>
              </div>
              <div class="results-outcome">
                <div v-if="lastWin > 0" class="win-message animate-win-pulse">
                  💰 ¡GANASTE ${{ lastWin }}! 💰
                </div>
                <div v-else class="lose-message">
                  💸 Suerte para la próxima
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Betting Table Section -->
        <div class="betting-section">
          <div class="card betting-table">
            <h2 class="h2">Mesa de Apuestas</h2>
            
            <!-- Number Grid -->
            <div class="numbers-grid">
              <div 
                v-for="number in numbers.slice(1)" 
                :key="number"
                @click="placeBet('number', number)"
                class="number-cell"
                :class="[
                  getNumberColorClass(number),
                  { 'winning-number': lastResult === number },
                  { 'has-bet': bets.numbers[number] > 0 }
                ]"
              >
                <span class="number-value">{{ number }}</span>
                <div v-if="bets.numbers[number] > 0" class="bet-chip">
                  ${{ bets.numbers[number] }}
                </div>
              </div>
            </div>

            <!-- Zero -->
            <div class="zero-section">
              <div 
                @click="placeBet('number', 0)"
                class="number-cell zero-cell"
                :class="{ 'winning-number': lastResult === 0, 'has-bet': bets.numbers[0] > 0 }"
              >
                <span class="number-value">0</span>
                <div v-if="bets.numbers[0] > 0" class="bet-chip">
                  ${{ bets.numbers[0] }}
                </div>
              </div>
            </div>

            <!-- Outside Bets -->
            <div class="outside-bets">
              <div 
                @click="placeBet('color', 'red')"
                class="bet-cell red-bet"
                :class="{ 'has-bet': bets.colors.red > 0 }"
              >
                <span>ROJO</span>
                <div v-if="bets.colors.red > 0" class="bet-chip">
                  ${{ bets.colors.red }}
                </div>
              </div>
              
              <div 
                @click="placeBet('color', 'black')"
                class="bet-cell black-bet"
                :class="{ 'has-bet': bets.colors.black > 0 }"
              >
                <span>NEGRO</span>
                <div v-if="bets.colors.black > 0" class="bet-chip">
                  ${{ bets.colors.black }}
                </div>
              </div>
              
              <div 
                @click="placeBet('parity', 'even')"
                class="bet-cell parity-bet"
                :class="{ 'has-bet': bets.parity.even > 0 }"
              >
                <span>PAR</span>
                <div v-if="bets.parity.even > 0" class="bet-chip">
                  ${{ bets.parity.even }}
                </div>
              </div>
              
              <div 
                @click="placeBet('parity', 'odd')"
                class="bet-cell parity-bet"
                :class="{ 'has-bet': bets.parity.odd > 0 }"
              >
                <span>IMPAR</span>
                <div v-if="bets.parity.odd > 0" class="bet-chip">
                  ${{ bets.parity.odd }}
                </div>
              </div>
            </div>

            <!-- Range Bets -->
            <div class="range-bets">
              <div 
                @click="placeBet('range', 'low')"
                class="bet-cell range-bet"
                :class="{ 'has-bet': bets.ranges.low > 0 }"
              >
                <span>1-18</span>
                <div v-if="bets.ranges.low > 0" class="bet-chip">
                  ${{ bets.ranges.low }}
                </div>
              </div>
              
              <div 
                @click="placeBet('range', 'high')"
                class="bet-cell range-bet"
                :class="{ 'has-bet': bets.ranges.high > 0 }"
              >
                <span>19-36</span>
                <div v-if="bets.ranges.high > 0" class="bet-chip">
                  ${{ bets.ranges.high }}
                </div>
              </div>
            </div>

            <!-- Bet Controls -->
            <div class="bet-controls">
              <div class="bet-amounts">
                <div class="muted">Valor de apuesta:</div>
                <div class="amount-buttons">
                  <button 
                    v-for="amount in betAmounts" 
                    :key="amount"
                    @click="currentBetAmount = amount"
                    class="btn-outline amount-btn"
                    :class="{ 'active': currentBetAmount === amount }"
                  >
                    ${{ amount }}
                  </button>
                </div>
              </div>
              
              <div class="action-buttons">
                <button 
                  @click="clearAllBets"
                  class="btn"
                  style="background: linear-gradient(180deg, var(--danger), #dc2626);"
                >
                  Limpiar Apuestas
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'Roulette',
  data() {
    return {
      credits: 1000,
      spinning: false,
      lastResult: null,
      lastWin: 0,
      currentBetAmount: 10,
      betAmounts: [5, 10, 25, 50, 100],
      numbers: Array.from({length: 37}, (_, i) => i), // 0-36
      redNumbers: [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36],
      bets: {
        numbers: {},
        colors: { red: 0, black: 0 },
        parity: { even: 0, odd: 0 },
        ranges: { low: 0, high: 0 }
      },
      wheelAngle: 0,
      ballAngle: 0,
      animationId: null,
      resultHighlight: {
        show: false,
        style: {}
      },
      showBigResult: false
    }
  },
  computed: {
    totalBet() {
      let total = 0;
      
      // Sum number bets
      for (let number in this.bets.numbers) {
        total += this.bets.numbers[number];
      }
      
      // Sum color bets
      total += this.bets.colors.red + this.bets.colors.black;
      
      // Sum parity bets
      total += this.bets.parity.even + this.bets.parity.odd;
      
      // Sum range bets
      total += this.bets.ranges.low + this.bets.ranges.high;
      
      return total;
    },
    
    ballPosition() {
      const centerX = 175; // Centro del canvas
      const centerY = 175;
      const radius = 140; // Radio donde se mueve la pelota
      
      const angleRad = (this.ballAngle * Math.PI) / 180;
      const x = centerX + Math.cos(angleRad) * radius - 8; // -8 para centrar la pelota
      const y = centerY + Math.sin(angleRad) * radius - 8;
      
      return {
        left: x + 'px',
        top: y + 'px'
      };
    }
  },
  watch: {
    wheelAngle() {
      this.drawWheel();
    },
    ballAngle() {
      // La posición de la pelota se actualiza automáticamente via computed property
    }
  },
  mounted() {
    this.initializeWheel();
    // Esperar a que el canvas esté renderizado antes de dibujar
    this.$nextTick(() => {
      setTimeout(() => {
        this.drawWheel();
      }, 100);
    });
  },
  methods: {
    initializeWheel() {
      // Initialize number bets object
      for (let i = 0; i <= 36; i++) {
        this.bets.numbers[i] = 0;
      }
    },
    
    getNumberColorClass(number) {
      if (number === 0) return 'green';
      return this.redNumbers.includes(number) ? 'red' : 'black';
    },
    
    getNumberType(number) {
      if (number === 0) return 'VERDE';
      return this.redNumbers.includes(number) ? 'ROJO' : 'NEGRO';
    },
    
    getNumberDetails(number) {
      if (number === 0) return 'CERO';
      
      let details = [];
      
      // Parity
      details.push(number % 2 === 0 ? 'PAR' : 'IMPAR');
      
      // Range
      if (number >= 1 && number <= 18) {
        details.push('1-18');
      } else if (number >= 19 && number <= 36) {
        details.push('19-36');
      }
      
      return details.join(', ');
    },
    
    placeBet(type, value) {
      if (this.spinning || this.credits < this.currentBetAmount) return;
      
      if (type === 'number') {
        this.bets.numbers[value] += this.currentBetAmount;
      } else if (type === 'color') {
        this.bets.colors[value] += this.currentBetAmount;
      } else if (type === 'parity') {
        this.bets.parity[value] += this.currentBetAmount;
      } else if (type === 'range') {
        this.bets.ranges[value] += this.currentBetAmount;
      }
      
      this.credits -= this.currentBetAmount;
    },
    
    clearAllBets() {
      // Reset all bets and refund credits
      let totalRefund = this.totalBet;
      
      // Clear number bets
      for (let number in this.bets.numbers) {
        this.bets.numbers[number] = 0;
      }
      
      // Clear color bets
      this.bets.colors = { red: 0, black: 0 };
      
      // Clear parity bets
      this.bets.parity = { even: 0, odd: 0 };
      
      // Clear range bets
      this.bets.ranges = { low: 0, high: 0 };
      
      // Refund credits
      this.credits += totalRefund;
    },
    
    spin() {
      if (this.spinning || this.totalBet === 0) return;
      
      this.spinning = true;
      this.showBigResult = false;
      this.resultHighlight.show = false;
      
      // Reset previous results visually
      this.lastResult = null;
      this.lastWin = 0;
      
      // Generate random result
      const result = Math.floor(Math.random() * 37); // 0-36
      
      this.animateWheelAndBall(result);
    },
    
    animateWheelAndBall(result) {
      const canvas = this.$refs.wheelCanvas;
      if (!canvas) return;
      
      // Calculate target angles
      const targetWheelAngle = this.wheelAngle + 1800 + Math.random() * 360; // Multiple spins
      const targetBallAngle = (result * (360/37)) + Math.random() * 10 - 5; // Some randomness
      
      const startTime = Date.now();
      const duration = 4000; // 4 seconds
      
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function (ease-out)
        const easeOut = 1 - Math.pow(1 - progress, 3);
        
        // Update angles
        this.wheelAngle = this.wheelAngle + (targetWheelAngle - this.wheelAngle) * easeOut;
        this.ballAngle = this.ballAngle + (targetBallAngle - this.ballAngle) * easeOut;
        
        if (progress < 1) {
          this.animationId = requestAnimationFrame(animate);
        } else {
          // Animation complete
          this.spinning = false;
          this.lastResult = result;
          this.calculateWinnings();
          this.showResultHighlight(result);
          this.showBigResult = true;
          
          // Hide big result after 3 seconds
          setTimeout(() => {
            this.showBigResult = false;
          }, 3000);
        }
      };
      
      this.animationId = requestAnimationFrame(animate);
    },
    
    showResultHighlight(result) {
      // Show highlight ring around winning number segment
      const canvas = this.$refs.wheelCanvas;
      if (!canvas) return;
      
      const segmentAngle = 360 / 37;
      const resultAngle = result * segmentAngle;
      
      // Calculate position for highlight
      const centerX = 160;
      const centerY = 160;
      const radius = 130;
      
      const angleRad = (resultAngle * Math.PI) / 180;
      const x = centerX + Math.cos(angleRad) * radius - 25; // -25 to center the highlight
      const y = centerY + Math.sin(angleRad) * radius - 25;
      
      this.resultHighlight = {
        show: true,
        style: {
          left: x + 'px',
          top: y + 'px'
        }
      };
      
      // Hide after 5 seconds
      setTimeout(() => {
        this.resultHighlight.show = false;
      }, 5000);
    },
    
    calculateWinnings() {
      let totalWin = 0;
      
      // Check number bets (35:1 payout)
      if (this.bets.numbers[this.lastResult] > 0) {
        totalWin += this.bets.numbers[this.lastResult] * 36; // Original bet + 35:1
      }
      
      // Check color bets (1:1 payout)
      if (this.lastResult !== 0) { // Zero doesn't count for color bets
        if (this.redNumbers.includes(this.lastResult) && this.bets.colors.red > 0) {
          totalWin += this.bets.colors.red * 2; // Original bet + 1:1
        } else if (!this.redNumbers.includes(this.lastResult) && this.bets.colors.black > 0) {
          totalWin += this.bets.colors.black * 2; // Original bet + 1:1
        }
      }
      
      // Check parity bets (1:1 payout)
      if (this.lastResult !== 0) { // Zero doesn't count for parity bets
        if (this.lastResult % 2 === 0 && this.bets.parity.even > 0) {
          totalWin += this.bets.parity.even * 2; // Original bet + 1:1
        } else if (this.lastResult % 2 !== 0 && this.bets.parity.odd > 0) {
          totalWin += this.bets.parity.odd * 2; // Original bet + 1:1
        }
      }
      
      // Check range bets (1:1 payout)
      if (this.lastResult >= 1 && this.lastResult <= 18 && this.bets.ranges.low > 0) {
        totalWin += this.bets.ranges.low * 2; // Original bet + 1:1
      } else if (this.lastResult >= 19 && this.lastResult <= 36 && this.bets.ranges.high > 0) {
        totalWin += this.bets.ranges.high * 2; // Original bet + 1:1
      }
      
      this.lastWin = totalWin;
      this.credits += totalWin;
      
      // Clear all bets after the spin (but don't refund - money was already spent)
      setTimeout(() => {
        this.clearBetsWithoutRefund();
      }, 1000);
    },
    
    clearBetsWithoutRefund() {
      // Clear number bets
      for (let number in this.bets.numbers) {
        this.bets.numbers[number] = 0;
      }
      
      // Clear color bets
      this.bets.colors = { red: 0, black: 0 };
      
      // Clear parity bets
      this.bets.parity = { even: 0, odd: 0 };
      
      // Clear range bets
      this.bets.ranges = { low: 0, high: 0 };
    },
    
    drawWheel() {
      const canvas = this.$refs.wheelCanvas;
      if (!canvas) return;
      
      const ctx = canvas.getContext('2d');
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const radius = 150;
      
      // Clear canvas
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Draw roulette wheel
      const segmentAngle = (2 * Math.PI) / 37; // 37 numbers (0-36)
      
      for (let i = 0; i < 37; i++) {
        const startAngle = i * segmentAngle + (this.wheelAngle * Math.PI / 180);
        const endAngle = (i + 1) * segmentAngle + (this.wheelAngle * Math.PI / 180);
        
        // Determine color
        let color;
        if (i === 0) {
          color = '#22c55e'; // Green for 0
        } else if (this.redNumbers.includes(i)) {
          color = '#dc2626'; // Red
        } else {
          color = '#1f2937'; // Black
        }
        
        // Draw segment
        ctx.beginPath();
        ctx.arc(centerX, centerY, radius, startAngle, endAngle);
        ctx.lineTo(centerX, centerY);
        ctx.fillStyle = color;
        ctx.fill();
        ctx.strokeStyle = '#fbbf24';
        ctx.lineWidth = 2;
        ctx.stroke();
        
        // Draw number
        const textAngle = startAngle + segmentAngle / 2;
        const textX = centerX + Math.cos(textAngle) * (radius * 0.8);
        const textY = centerY + Math.sin(textAngle) * (radius * 0.8);
        
        ctx.save();
        ctx.translate(textX, textY);
        ctx.rotate(textAngle + Math.PI / 2);
        ctx.font = 'bold 16px Arial';
        ctx.fillStyle = 'white';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(i.toString(), 0, 0);
        ctx.restore();
      }
      
      // Draw center circle
      ctx.beginPath();
      ctx.arc(centerX, centerY, 20, 0, 2 * Math.PI);
      ctx.fillStyle = '#fbbf24';
      ctx.fill();
      ctx.strokeStyle = '#1f2937';
      ctx.lineWidth = 3;
      ctx.stroke();
      
      // Draw outer rim
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
      ctx.strokeStyle = '#fbbf24';
      ctx.lineWidth = 5;
      ctx.stroke();
    }
  },
  beforeUnmount() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }
  }
};
</script>

<style scoped>
/* Tema principal usando CSS variables */
.roulette-container {
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
}

/* Header */
.game-header {
  background: linear-gradient(180deg, var(--primary), #0a4a6b);
  border-bottom: 3px solid var(--border);
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
}

.brand {
  display: flex;
  align-items: center;
}

.game-title {
  font-size: 2rem;
  font-weight: bold;
  color: white;
  margin: 0;
}

.user-actions {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.balance {
  color: white;
  font-size: 1.1rem;
}

/* Winner Banner */
.winner-banner {
  background: linear-gradient(45deg, var(--warning), #f59e0b);
  border: 3px solid var(--border);
  border-radius: 12px;
  margin: 1rem;
  padding: 1rem;
  box-shadow: 0 8px 25px rgba(0,0,0,0.3);
}

.winner-content {
  text-align: center;
}

.winner-label {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--text);
  margin-bottom: 1rem;
}

.winner-display {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2rem;
  margin-bottom: 1rem;
}

.winner-number {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2.5rem;
  font-weight: bold;
  color: white;
  border: 4px solid white;
  box-shadow: 0 4px 15px rgba(0,0,0,0.4);
}

.winner-number.red {
  background: var(--danger);
}

.winner-number.black {
  background: #1f2937;
}

.winner-number.green {
  background: var(--success);
}

.winner-info {
  text-align: left;
}

.winner-type {
  font-size: 1.8rem;
  font-weight: bold;
  color: var(--text);
}

.winner-details {
  font-size: 1.2rem;
  color: var(--muted);
}

.winner-prize {
  font-size: 2rem;
  font-weight: bold;
  color: var(--success);
}

.winner-message {
  font-size: 1.5rem;
  color: var(--muted);
}

/* Game Layout */
.game-layout {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 2rem;
  padding: 2rem 0;
}

@media (max-width: 768px) {
  .game-layout {
    grid-template-columns: 1fr;
  }
}

/* Card styling */
.card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
}

/* Wheel Section */
.wheel-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-bottom: 2rem;
}

.roulette-wheel {
  border: 4px solid var(--warning);
  border-radius: 50%;
  box-shadow: 0 8px 25px rgba(0,0,0,0.3);
}

.wheel-pointer {
  position: absolute;
  top: -10px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 15px solid transparent;
  border-right: 15px solid transparent;
  border-top: 25px solid var(--warning);
  z-index: 10;
}

.roulette-ball {
  position: absolute;
  width: 16px;
  height: 16px;
  background: radial-gradient(circle at 30% 30%, white, silver);
  border-radius: 50%;
  z-index: 5;
  box-shadow: 2px 2px 5px rgba(0,0,0,0.5);
}

/* Result Highlight */
.result-highlight {
  position: absolute;
  width: 50px;
  height: 50px;
  border: 4px solid var(--warning);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0,0,0,0.8);
  z-index: 8;
}

.result-number {
  color: white;
  font-weight: bold;
  font-size: 1.2rem;
}

.result-arrow {
  position: absolute;
  bottom: -12px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 8px solid transparent;
  border-right: 8px solid transparent;
  border-top: 12px solid var(--warning);
}

/* Big Result Overlay */
.big-result-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.9);
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  z-index: 15;
}

.big-result-content {
  text-align: center;
  color: white;
}

.big-result-number {
  width: 120px;
  height: 120px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 3rem;
  font-weight: bold;
  margin: 0 auto 1rem;
  border: 6px solid white;
}

.big-result-text {
  font-size: 1.5rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.big-result-type {
  font-size: 1.2rem;
  margin-bottom: 1rem;
}

.big-result-indicator {
  font-size: 1.8rem;
  font-weight: bold;
}

/* Spin Button */
.spin-section {
  text-align: center;
  margin-bottom: 2rem;
}

.spin-btn {
  font-size: 1.2rem;
  padding: 1rem 2rem;
  background: linear-gradient(180deg, var(--danger), #b91c1c);
  border: none;
  border-radius: 8px;
  color: white;
  font-weight: bold;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

.spin-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0,0,0,0.3);
}

.spin-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.spin-btn.spinning {
  animation: pulse 1s infinite;
}

/* Results Panel */
.results-panel {
  background: linear-gradient(45deg, var(--warning), #f59e0b);
  border-radius: 12px;
  padding: 1.5rem;
  color: var(--text);
}

.results-header {
  text-align: center;
  font-size: 1.5rem;
  font-weight: bold;
  margin-bottom: 1rem;
}

.results-display {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 1rem;
}

.result-circle {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.8rem;
  font-weight: bold;
  color: white;
  border: 3px solid white;
}

.result-info {
  text-align: left;
}

.result-label {
  font-size: 1.3rem;
  font-weight: bold;
}

.result-details {
  font-size: 1rem;
  opacity: 0.8;
}

.results-outcome {
  text-align: center;
}

.win-message {
  color: var(--success);
  font-size: 1.4rem;
  font-weight: bold;
}

.lose-message {
  color: var(--muted);
  font-size: 1.2rem;
}

/* Betting Table */
.h2 {
  font-size: 1.5rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 1.5rem;
  color: var(--text);
}

/* Numbers Grid */
.numbers-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.number-cell {
  position: relative;
  background: var(--primary);
  color: white;
  padding: 1rem;
  text-align: center;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: bold;
  border: 2px solid transparent;
}

.number-cell:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 15px rgba(0,0,0,0.3);
}

.number-cell.red {
  background: var(--danger);
}

.number-cell.black {
  background: #1f2937;
}

.number-cell.green {
  background: var(--success);
}

.number-cell.winning-number {
  border-color: var(--warning);
  box-shadow: 0 0 20px var(--warning);
  animation: pulse 1s infinite;
}

.number-cell.has-bet {
  border-color: var(--warning);
  box-shadow: 0 0 10px var(--warning);
}

.number-value {
  font-size: 1.2rem;
}

.bet-chip {
  position: absolute;
  top: -8px;
  right: -8px;
  background: var(--warning);
  color: var(--text);
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
  font-weight: bold;
  border: 2px solid white;
}

/* Zero Section */
.zero-section {
  display: flex;
  justify-content: center;
  margin-bottom: 1.5rem;
}

.zero-cell {
  width: 80px;
}

/* Outside Bets */
.outside-bets {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.bet-cell {
  position: relative;
  padding: 1rem;
  text-align: center;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: bold;
  color: white;
  border: 2px solid transparent;
}

.bet-cell:hover {
  transform: scale(1.02);
  box-shadow: 0 4px 15px rgba(0,0,0,0.3);
}

.bet-cell.has-bet {
  border-color: var(--warning);
  box-shadow: 0 0 10px var(--warning);
}

.red-bet {
  background: var(--danger);
}

.black-bet {
  background: #1f2937;
}

.parity-bet {
  background: var(--primary);
}

/* Range Bets */
.range-bets {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.range-bet {
  background: var(--secondary);
}

/* Bet Controls */
.bet-controls {
  padding-top: 1.5rem;
  border-top: 1px solid var(--border);
}

.bet-amounts {
  margin-bottom: 1rem;
}

.muted {
  font-size: 0.9rem;
  color: var(--muted);
  margin-bottom: 0.5rem;
}

.amount-buttons {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
  justify-content: center;
}

.btn-outline {
  background: transparent;
  border: 2px solid var(--primary);
  color: var(--primary);
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: bold;
}

.btn-outline:hover {
  background: var(--primary);
  color: white;
}

.btn-outline.active {
  background: var(--primary);
  color: white;
}

.amount-btn {
  font-size: 0.9rem;
}

.action-buttons {
  text-align: center;
}

.btn {
  background: var(--primary);
  color: white;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s ease;
}

.btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}

/* Animations */
@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

@keyframes win-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

.animate-win-pulse {
  animation: win-pulse 0.8s ease-in-out infinite;
}

@keyframes flash {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}

.animate-flash {
  animation: flash 0.3s ease-in-out 5;
}
</style>