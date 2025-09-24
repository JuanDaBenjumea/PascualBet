<template>
  <div class="slot-machine-container">
    <!-- Header with theme styling -->
    <header class="game-header">
      <div class="container">
        <div class="brand">
          <h1 class="game-title">🎰 Tragamonedas PascualBet 🎰</h1>
        </div>
        <div class="user-actions">
          <div class="balance">
            Créditos: <strong>${{ credits }}</strong>
          </div>
          <div class="balance">
            Apuesta: <strong class="danger-text">${{ currentBet }}</strong>
          </div>
        </div>
      </div>
    </header>

    <!-- Winner Banner -->
    <div 
      v-if="lastWin > 0" 
      class="winner-banner animate-win-pulse"
    >
      <div class="winner-content">
        <div class="winner-label">🎰 ¡JACKPOT! 🎰</div>
        <div class="winner-display">
          <div class="winner-prize">
            💰 ¡GANASTE ${{ lastWin }}! 💰
          </div>
          <div class="winner-combo">{{ winMessage }}</div>
        </div>
      </div>
    </div>

    <div class="container">
      <!-- Main Game Area -->
      <div class="game-layout">
        
        <!-- Slot Machine Section -->
        <div class="machine-section">
          <div class="card machine-card">
            <div class="machine-frame">
              <!-- Screen with Canvas -->
              <div class="screen-container">
                <canvas 
                  ref="slotCanvas" 
                  width="800" 
                  height="200" 
                  class="slot-screen"
                ></canvas>
              </div>
              
              <!-- Paylines Indicator -->
              <div class="payline-indicator">
                <div class="payline-badge">
                  LÍNEA DE PAGO
                </div>
              </div>

              <!-- Spin Controls -->
              <div class="controls-section">
                <!-- Bet Controls -->
                <div class="bet-controls">
                  <button 
                    @click="decreaseBet"
                    :disabled="spinning || currentBet <= minBet"
                    class="btn control-btn decrease-btn"
                    :class="{ 'disabled': spinning || currentBet <= minBet }"
                  >
                    -
                  </button>
                  <div class="bet-display">
                    Apuesta: <strong>${{ currentBet }}</strong>
                  </div>
                  <button 
                    @click="increaseBet"
                    :disabled="spinning || currentBet >= maxBet || currentBet + betStep > credits"
                    class="btn control-btn increase-btn"
                    :class="{ 'disabled': spinning || currentBet >= maxBet || currentBet + betStep > credits }"
                  >
                    +
                  </button>
                </div>

                <!-- Action Buttons -->
                <div class="action-controls">
                  <button 
                    @click="spin"
                    :disabled="spinning || credits < currentBet"
                    class="btn play spin-btn"
                    :class="{ 'spinning': spinning, 'disabled': credits < currentBet }"
                  >
                    {{ spinning ? 'GIRANDO...' : 'GIRAR' }}
                  </button>
                  
                  <button 
                    @click="maxBet"
                    :disabled="spinning || credits < 100"
                    class="btn max-bet-btn"
                    :class="{ 'disabled': spinning || credits < 100 }"
                  >
                    APUESTA MÁX
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Paytable Section -->
        <div class="paytable-section">
          <div class="card paytable-card">
            <h2 class="h2 paytable-title">TABLA DE PAGOS</h2>
            <div class="paytable-grid">
              <div v-for="(payout, combo) in paytable" :key="combo" class="payout-item">
                <div class="combo-symbols">{{ combo }}</div>
                <div class="payout-multiplier">{{ payout }}x</div>
              </div>
            </div>
            
            <!-- Game Info -->
            <div class="game-info">
              <div class="info-item">
                <span class="muted">Apuesta mínima:</span>
                <strong>${{ minBet }}</strong>
              </div>
              <div class="info-item">
                <span class="muted">Apuesta máxima:</span>
                <strong>${{ maxBet }}</strong>
              </div>
              <div class="info-item">
                <span class="muted">Pago por par:</span>
                <strong>0.5x</strong>
              </div>
            </div>
            
            <!-- Back Button -->
            <div class="back-section">
              <button 
                @click="goBack"
                class="btn btn-outline"
              >
                Volver al Menú
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SlotMachine',
  data() {
    return {
      credits: 1000,
      currentBet: 10,
      minBet: 5,
      maxBet: 100,
      betStep: 5,
      spinning: false,
      lastWin: 0,
      winMessage: '',
      reels: ['🍒', '🍊', '🍋'],
      symbols: ['🍒', '🍊', '🍋', '🍇', '⭐', '💎', '🔔', '7️⃣'],
      paytable: {
        '🍒 🍒 🍒': 10,
        '🍊 🍊 🍊': 15,
        '🍋 🍋 🍋': 20,
        '🍇 🍇 🍇': 25,
        '⭐ ⭐ ⭐': 50,
        '💎 💎 💎': 100,
        '🔔 🔔 🔔': 200,
        '7️⃣ 7️⃣ 7️⃣': 777
      },
      animationId: null,
      spinStartTime: 0,
      spinDuration: 3000,
      reelAnimations: [0, 0, 0],
      targetSymbols: ['🍒', '🍊', '🍋'],
      allReelSymbols: [
        [], [], [] // Arrays to hold all symbols for each reel during animation
      ]
    }
  },
  
  mounted() {
    this.initializeCanvas();
    this.randomizeReels();
    this.drawSlotMachine();
  },

  beforeUnmount() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }
  },

  methods: {
    initializeCanvas() {
      const canvas = this.$refs.slotCanvas;
      if (!canvas) return;
      
      const ctx = canvas.getContext('2d');
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      
      // Initialize reel symbol arrays
      for (let i = 0; i < 3; i++) {
        this.allReelSymbols[i] = [];
        for (let j = 0; j < 20; j++) {
          this.allReelSymbols[i].push(
            this.symbols[Math.floor(Math.random() * this.symbols.length)]
          );
        }
      }
    },

    randomizeReels() {
      this.reels = [
        this.symbols[Math.floor(Math.random() * this.symbols.length)],
        this.symbols[Math.floor(Math.random() * this.symbols.length)],
        this.symbols[Math.floor(Math.random() * this.symbols.length)]
      ];
    },

    drawSlotMachine() {
      const canvas = this.$refs.slotCanvas;
      if (!canvas) return;
      
      const ctx = canvas.getContext('2d');
      const width = canvas.width;
      const height = canvas.height;
      
      // Get CSS variables
      const computedStyle = getComputedStyle(document.documentElement);
      const cardColor = computedStyle.getPropertyValue('--card-2').trim() || '#141c27';
      const borderColor = computedStyle.getPropertyValue('--border').trim() || '#1f2a37';
      const primaryColor = computedStyle.getPropertyValue('--primary').trim() || '#0ea5e9';
      
      // Clear canvas
      ctx.fillStyle = `hsl(${cardColor})`;
      ctx.fillRect(0, 0, width, height);
      
      // Draw reel backgrounds
      const reelWidth = 160;
      const reelHeight = 160;
      const spacing = 40;
      const startX = (width - (3 * reelWidth + 2 * spacing)) / 2;
      const startY = (height - reelHeight) / 2;
      
      for (let i = 0; i < 3; i++) {
        const x = startX + i * (reelWidth + spacing);
        const y = startY;
        
        // Draw reel frame
        ctx.fillStyle = `hsl(${primaryColor})`;
        ctx.fillRect(x - 4, y - 4, reelWidth + 8, reelHeight + 8);
        
        // Draw reel background
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(x, y, reelWidth, reelHeight);
        
        // Draw reel border
        ctx.strokeStyle = `hsl(${borderColor})`;
        ctx.lineWidth = 3;
        ctx.strokeRect(x, y, reelWidth, reelHeight);
        
        // Draw symbols
        this.drawReel(ctx, i, x, y, reelWidth, reelHeight);
      }
      
      // Draw center payline
      ctx.strokeStyle = `hsl(${computedStyle.getPropertyValue('--danger').trim() || '#ef4444'})`;
      ctx.lineWidth = 4;
      ctx.setLineDash([10, 5]);
      ctx.beginPath();
      ctx.moveTo(20, height / 2);
      ctx.lineTo(width - 20, height / 2);
      ctx.stroke();
      ctx.setLineDash([]);
    },

    drawReel(ctx, reelIndex, x, y, width, height) {
      const centerY = y + height / 2;
      
      if (this.spinning) {
        // Draw spinning animation with random symbols
        const animationOffset = this.reelAnimations[reelIndex];
        const symbolHeight = 60;
        
        // Draw multiple symbols for spinning effect
        for (let i = -3; i <= 4; i++) {
          const symbolY = centerY + (i * symbolHeight) + animationOffset;
          if (symbolY > y - 50 && symbolY < y + height + 50) {
            // Use random symbols from the reel array during spinning
            const symbolIndex = Math.abs((i + Math.floor(animationOffset / 60) + 20)) % this.allReelSymbols[reelIndex].length;
            const symbol = this.allReelSymbols[reelIndex][symbolIndex];
            this.drawSymbol(ctx, symbol, x + width / 2, symbolY);
          }
        }
        
        // Draw masks to hide symbols outside reel
        const cardColor = getComputedStyle(document.documentElement).getPropertyValue('--card-2').trim() || '#141c27';
        ctx.fillStyle = `hsl(${cardColor})`;
        ctx.fillRect(x - 4, y - 60, width + 8, 60); // Top mask
        ctx.fillRect(x - 4, y + height, width + 8, 60); // Bottom mask
        
      } else {
        // Draw final result symbol
        this.drawSymbol(ctx, this.reels[reelIndex], x + width / 2, centerY);
      }
    },

    drawSymbol(ctx, symbol, x, y) {
      ctx.font = '72px Arial';
      ctx.fillStyle = '#000000';
      ctx.fillText(symbol, x, y);
    },

    animateReels() {
      if (!this.spinning) return;
      
      const elapsed = Date.now() - this.spinStartTime;
      const progress = Math.min(elapsed / this.spinDuration, 1);
      
      // Different speeds for each reel
      const speeds = [25, 30, 35];
      
      for (let i = 0; i < 3; i++) {
        const stopTime = 0.5 + (i * 0.2); // Reels stop at different times
        
        if (progress < stopTime) {
          // Still spinning
          this.reelAnimations[i] -= speeds[i];
          if (this.reelAnimations[i] <= -60) {
            this.reelAnimations[i] += 60;
          }
        } else {
          // Stop with easing
          const stopProgress = Math.min((progress - stopTime) / 0.3, 1);
          const easing = 1 - Math.pow(1 - stopProgress, 3); // Ease out
          const targetOffset = 0; // Final position
          this.reelAnimations[i] = targetOffset + (-60 * (1 - easing));
          
          // Ensure we end exactly at 0
          if (stopProgress >= 1) {
            this.reelAnimations[i] = 0;
          }
        }
      }
      
      this.drawSlotMachine();
      
      if (progress < 1) {
        this.animationId = requestAnimationFrame(() => this.animateReels());
      } else {
        // Animation finished - set final symbols
        this.spinning = false;
        this.reelAnimations = [0, 0, 0];
        this.reels = [...this.targetSymbols];
        this.drawSlotMachine();
        this.checkWin();
      }
    },

    spin() {
      if (this.spinning || this.credits < this.currentBet) return;

      this.spinning = true;
      this.credits -= this.currentBet;
      this.lastWin = 0;
      this.winMessage = '';

      // Set target symbols (final result)
      this.targetSymbols = [
        this.symbols[Math.floor(Math.random() * this.symbols.length)],
        this.symbols[Math.floor(Math.random() * this.symbols.length)],
        this.symbols[Math.floor(Math.random() * this.symbols.length)]
      ];

      // Regenerate random symbols for animation
      for (let i = 0; i < 3; i++) {
        this.allReelSymbols[i] = [];
        for (let j = 0; j < 20; j++) {
          this.allReelSymbols[i].push(
            this.symbols[Math.floor(Math.random() * this.symbols.length)]
          );
        }
      }

      // Start animation
      this.spinStartTime = Date.now();
      this.reelAnimations = [0, 0, 0];
      this.animateReels();
    },

    checkWin() {
      const combination = this.reels.join(' ');
      const payout = this.paytable[combination];

      if (payout) {
        this.lastWin = this.currentBet * payout;
        this.credits += this.lastWin;
        this.winMessage = `¡${combination}!`;
      } else {
        // Check for any two matching symbols (smaller payout)
        const counts = {};
        this.reels.forEach(symbol => {
          counts[symbol] = (counts[symbol] || 0) + 1;
        });

        const pairs = Object.entries(counts).filter(([symbol, count]) => count >= 2);
        if (pairs.length > 0) {
          this.lastWin = Math.floor(this.currentBet * 0.5);
          this.credits += this.lastWin;
          this.winMessage = '¡Par ganador!';
        }
      }
    },

    increaseBet() {
      if (this.currentBet + this.betStep <= this.maxBet && this.currentBet + this.betStep <= this.credits) {
        this.currentBet += this.betStep;
      }
    },

    decreaseBet() {
      if (this.currentBet - this.betStep >= this.minBet) {
        this.currentBet -= this.betStep;
      }
    },

    maxBet() {
      this.currentBet = Math.min(this.maxBet, this.credits);
    },

    goBack() {
      this.$router.push('/menu');
    }
  }
}
</script>

<style scoped>
/* Tema principal usando CSS variables del globals.css */
.slot-machine-container {
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
}

/* Header */
.game-header {
  background: linear-gradient(180deg, var(--primary), var(--primary-2));
  border-bottom: 1px solid var(--border);
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

.danger-text {
  color: var(--danger);
}

/* Winner Banner */
.winner-banner {
  background: linear-gradient(45deg, var(--success), #16a34a);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  margin: 1rem;
  padding: 1rem;
  box-shadow: var(--shadow);
}

.winner-content {
  text-align: center;
}

.winner-label {
  font-size: 1.5rem;
  font-weight: bold;
  color: var(--text);
  margin-bottom: 0.5rem;
}

.winner-display {
  color: var(--text);
}

.winner-prize {
  font-size: 2rem;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.winner-combo {
  font-size: 1.2rem;
  color: var(--muted);
}

/* Game Layout */
.game-layout {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
  padding: 2rem 0;
}

@media (max-width: 1024px) {
  .game-layout {
    grid-template-columns: 1fr;
  }
}

/* Card styling using globals.css classes */
.card {
  background: var(--card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 1.5rem;
  box-shadow: var(--shadow);
}

/* Machine Section */
.machine-section {
  display: flex;
  justify-content: center;
}

.machine-card {
  background: linear-gradient(180deg, var(--primary), var(--primary-2));
  border: 3px solid var(--border);
  border-radius: var(--radius);
  padding: 2rem;
  max-width: 900px;
  width: 100%;
}

.machine-frame {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Screen */
.screen-container {
  background: var(--bg);
  border: 2px solid var(--border);
  border-radius: 12px;
  padding: 1.5rem;
  display: flex;
  justify-content: center;
}

.slot-screen {
  background: var(--card-2);
  border: 1px solid var(--border);
  border-radius: 8px;
  max-width: 100%;
}

/* Payline */
.payline-indicator {
  display: flex;
  justify-content: center;
}

.payline-badge {
  background: var(--danger);
  color: var(--text);
  padding: 0.5rem 1.5rem;
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.9rem;
}

/* Controls */
.controls-section {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  align-items: center;
}

.bet-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: rgba(255,255,255,0.1);
  padding: 1rem;
  border-radius: 12px;
  border: 1px solid rgba(255,255,255,0.2);
}

.control-btn {
  width: 50px;
  height: 50px;
  border-radius: 50%;
  font-size: 1.5rem;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
}

.decrease-btn {
  background: var(--danger);
}

.increase-btn {
  background: var(--success);
}

.bet-display {
  color: white;
  font-weight: bold;
  font-size: 1.25rem;
  padding: 0 1rem;
}

.action-controls {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.spin-btn {
  font-size: 1.5rem;
  padding: 1rem 3rem;
  border-radius: var(--radius);
  min-width: 200px;
}

.spin-btn.spinning {
  animation: pulse 1s infinite;
}

.max-bet-btn {
  background: linear-gradient(180deg, #a855f7, #9333ea);
  font-size: 1rem;
  padding: 1rem 1.5rem;
}

/* Button disabled state */
.btn.disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn.disabled:hover {
  transform: none;
  filter: none;
}

/* Paytable Section */
.paytable-card {
  background: var(--card);
}

.paytable-title {
  color: var(--primary);
  text-align: center;
  margin-bottom: 1.5rem;
}

.paytable-grid {
  display: grid;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.payout-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  background: var(--card-2);
  border: 1px solid var(--border);
  border-radius: 8px;
  transition: all 0.2s ease;
}

.payout-item:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(14,165,233,0.15);
  border-color: var(--primary);
}

.combo-symbols {
  font-size: 1.2rem;
  font-weight: 500;
}

.payout-multiplier {
  color: var(--success);
  font-weight: bold;
  font-size: 1.1rem;
}

/* Game Info */
.game-info {
  background: var(--bg-soft);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: 1rem;
  margin-bottom: 1.5rem;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.25rem 0;
}

.info-item:not(:last-child) {
  border-bottom: 1px solid var(--border);
  padding-bottom: 0.5rem;
  margin-bottom: 0.5rem;
}

/* Back Section */
.back-section {
  text-align: center;
}

/* Animations using globals.css */
.animate-win-pulse {
  animation: win-pulse 1s infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

/* Responsive */
@media (max-width: 768px) {
  .machine-card {
    padding: 1rem;
  }
  
  .slot-screen {
    width: 100%;
    max-width: 600px;
  }
  
  .controls-section {
    gap: 0.75rem;
  }
  
  .bet-controls {
    flex-wrap: wrap;
    justify-content: center;
  }
  
  .action-controls {
    flex-direction: column;
    width: 100%;
  }
  
  .spin-btn {
    min-width: auto;
    width: 100%;
  }
}

@media (max-width: 480px) {
  .game-title {
    font-size: 1.5rem;
  }
  
  .user-actions {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .winner-prize {
    font-size: 1.5rem;
  }
  
  .container {
    padding: 0.5rem;
  }
}
</style>