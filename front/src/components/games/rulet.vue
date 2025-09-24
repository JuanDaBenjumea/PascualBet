<template>
  <div class="roulette-game bg-green-900 min-h-screen p-4">
    <div class="max-w-6xl mx-auto">
      <!-- Header -->
      <div class="text-center mb-6">
        <h1 class="text-4xl font-bold text-yellow-400 mb-2">🎰 Ruleta PascualBet 🎰</h1>
        <div class="bg-black rounded-lg p-4 inline-block">
          <p class="text-white text-xl">Créditos: <span class="text-green-400 font-bold">${{ credits }}</span></p>
          <p class="text-white text-lg">Apuesta Total: <span class="text-red-400 font-bold">${{ totalBet }}</span></p>
        </div>
      </div>

      <!-- Roulette Wheel -->
      <div class="flex flex-col lg:flex-row gap-6">
        <div class="lg:w-1/3">
          <div class="relative">
            <canvas 
              ref="wheelCanvas" 
              width="350" 
              height="350" 
              class="border-4 border-yellow-400 rounded-full shadow-lg mx-auto block bg-gray-800"
              style="display: block; max-width: 100%;"
            ></canvas>
            
            <!-- Wheel Pointer -->
            <div class="absolute top-2 left-1/2 transform -translate-x-1/2 z-10">
              <div class="w-0 h-0 border-l-[15px] border-r-[15px] border-b-[30px] border-l-transparent border-r-transparent border-b-yellow-400 drop-shadow-lg"></div>
            </div>
            
            <!-- Spin Button -->
            <div class="text-center mt-4">
              <button 
                @click="spin" 
                :disabled="spinning || totalBet === 0"
                class="px-8 py-4 bg-gradient-to-r from-red-500 to-red-700 text-white font-bold text-xl rounded-full shadow-lg hover:from-red-600 hover:to-red-800 disabled:opacity-50 disabled:cursor-not-allowed transform hover:scale-105 transition-all"
              >
                {{ spinning ? 'GIRANDO...' : 'GIRAR RULETA' }}
              </button>
            </div>
            
            <!-- Results Display -->
            <div v-if="lastResult !== null" class="text-center mt-4 bg-black rounded-lg p-4">
              <p class="text-yellow-400 text-lg font-bold mb-2">ÚLTIMO RESULTADO:</p>
              <div class="flex items-center justify-center gap-2">
                <div 
                  class="w-8 h-8 rounded-full flex items-center justify-center text-white font-bold text-sm"
                  :class="getNumberColor(lastResult)"
                >
                  {{ lastResult }}
                </div>
                <span class="text-white">{{ getNumberType(lastResult) }}</span>
              </div>
              <p v-if="lastWin > 0" class="text-green-400 font-bold text-xl mt-2">¡GANASTE ${{ lastWin }}!</p>
              <p v-else class="text-red-400 font-bold text-xl mt-2">Suerte para la próxima</p>
            </div>
          </div>
        </div>

        <!-- Betting Table -->
        <div class="lg:w-2/3">
          <div class="bg-green-800 rounded-lg p-4 border-4 border-yellow-400">
            <!-- Number Grid -->
            <div class="grid grid-cols-3 gap-1 mb-4">
              <div 
                v-for="number in numbers.slice(1)" 
                :key="number"
                @click="placeBet('number', number)"
                class="bet-cell cursor-pointer transition-all hover:scale-105"
                :class="getNumberColor(number)"
              >
                <div class="w-full h-12 flex items-center justify-center text-white font-bold relative">
                  {{ number }}
                  <div v-if="bets.numbers[number] > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.numbers[number] }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Zero -->
            <div class="mb-4">
              <div 
                @click="placeBet('number', 0)"
                class="bet-cell bg-green-600 hover:bg-green-500 cursor-pointer transition-all hover:scale-105 w-full"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold text-xl relative">
                  0
                  <div v-if="bets.numbers[0] > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.numbers[0] }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Outside Bets -->
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-2 mb-4">
              <div 
                @click="placeBet('color', 'red')"
                class="bet-cell bg-red-600 hover:bg-red-500 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  ROJO
                  <div v-if="bets.colors.red > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.colors.red }}
                  </div>
                </div>
              </div>
              
              <div 
                @click="placeBet('color', 'black')"
                class="bet-cell bg-black hover:bg-gray-800 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  NEGRO
                  <div v-if="bets.colors.black > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.colors.black }}
                  </div>
                </div>
              </div>
              
              <div 
                @click="placeBet('parity', 'even')"
                class="bet-cell bg-blue-600 hover:bg-blue-500 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  PAR
                  <div v-if="bets.parity.even > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.parity.even }}
                  </div>
                </div>
              </div>
              
              <div 
                @click="placeBet('parity', 'odd')"
                class="bet-cell bg-purple-600 hover:bg-purple-500 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  IMPAR
                  <div v-if="bets.parity.odd > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.parity.odd }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Range Bets -->
            <div class="grid grid-cols-2 gap-2 mb-4">
              <div 
                @click="placeBet('range', 'low')"
                class="bet-cell bg-orange-600 hover:bg-orange-500 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  1-18
                  <div v-if="bets.ranges.low > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.ranges.low }}
                  </div>
                </div>
              </div>
              
              <div 
                @click="placeBet('range', 'high')"
                class="bet-cell bg-orange-600 hover:bg-orange-500 cursor-pointer transition-all hover:scale-105"
              >
                <div class="h-12 flex items-center justify-center text-white font-bold relative">
                  19-36
                  <div v-if="bets.ranges.high > 0" class="absolute -top-1 -right-1 bg-yellow-400 text-black text-xs rounded-full w-5 h-5 flex items-center justify-center">
                    ${{ bets.ranges.high }}
                  </div>
                </div>
              </div>
            </div>

            <!-- Bet Controls -->
            <div class="flex flex-wrap gap-2 justify-center items-center mb-4">
              <div class="text-white font-bold">Valor de apuesta:</div>
              <div class="flex gap-1">
                <button 
                  v-for="amount in betAmounts" 
                  :key="amount"
                  @click="currentBetAmount = amount"
                  :class="currentBetAmount === amount ? 'bg-yellow-400 text-black' : 'bg-gray-600 text-white'"
                  class="px-3 py-1 rounded font-bold hover:scale-105 transition-all"
                >
                  ${{ amount }}
                </button>
              </div>
            </div>

            <div class="flex gap-2 justify-center">
              <button 
                @click="clearAllBets"
                class="px-4 py-2 bg-red-600 text-white font-bold rounded hover:bg-red-700 transition-all"
              >
                Limpiar Apuestas
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
      animationId: null
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
    }
  },
  watch: {
    wheelAngle() {
      this.drawWheel();
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
    
    getNumberColor(number) {
      if (number === 0) return 'bg-green-600';
      return this.redNumbers.includes(number) ? 'bg-red-600' : 'bg-black';
    },
    
    getNumberType(number) {
      if (number === 0) return 'VERDE';
      return this.redNumbers.includes(number) ? 'ROJO' : 'NEGRO';
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
      if (this.spinning) return;
      
      // Refund all bets
      this.credits += this.totalBet;
      
      // Reset bets
      for (let i = 0; i <= 36; i++) {
        this.bets.numbers[i] = 0;
      }
      this.bets.colors = { red: 0, black: 0 };
      this.bets.parity = { even: 0, odd: 0 };
      this.bets.ranges = { low: 0, high: 0 };
    },
    
    spin() {
      if (this.spinning || this.totalBet === 0) return;
      
      this.spinning = true;
      this.lastWin = 0;
      
      // Generate random result
      const result = Math.floor(Math.random() * 37);
      
      // Calculate winning angle
      const anglePerNumber = 360 / 37;
      const targetAngle = 360 - (result * anglePerNumber);
      const spins = 5 + Math.random() * 3; // 5-8 full spins
      const finalAngle = this.wheelAngle + (spins * 360) + targetAngle;
      
      this.animateWheel(finalAngle, () => {
        this.lastResult = result;
        this.calculateWinnings(result);
        this.spinning = false;
        
        // Reset bets after spin
        this.initializeWheel();
        this.bets.colors = { red: 0, black: 0 };
        this.bets.parity = { even: 0, odd: 0 };
        this.bets.ranges = { low: 0, high: 0 };
      });
    },
    
    animateWheel(targetAngle, callback) {
      const startAngle = this.wheelAngle;
      const angleDifference = targetAngle - startAngle;
      const duration = 3000; // 3 seconds
      const startTime = Date.now();
      
      const animate = () => {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function (ease-out)
        const easeOut = 1 - Math.pow(1 - progress, 3);
        
        this.wheelAngle = startAngle + (angleDifference * easeOut);
        this.drawWheel();
        
        if (progress < 1) {
          this.animationId = requestAnimationFrame(animate);
        } else {
          callback();
        }
      };
      
      animate();
    },
    
    calculateWinnings(result) {
      let winnings = 0;
      
      // Check number bet
      if (this.bets.numbers[result] > 0) {
        winnings += this.bets.numbers[result] * 36; // 35:1 payout + original bet
      }
      
      // Check color bets
      if (result !== 0) {
        const isRed = this.redNumbers.includes(result);
        if (isRed && this.bets.colors.red > 0) {
          winnings += this.bets.colors.red * 2; // 1:1 payout + original bet
        } else if (!isRed && this.bets.colors.black > 0) {
          winnings += this.bets.colors.black * 2; // 1:1 payout + original bet
        }
      }
      
      // Check parity bets
      if (result !== 0) {
        const isEven = result % 2 === 0;
        if (isEven && this.bets.parity.even > 0) {
          winnings += this.bets.parity.even * 2; // 1:1 payout + original bet
        } else if (!isEven && this.bets.parity.odd > 0) {
          winnings += this.bets.parity.odd * 2; // 1:1 payout + original bet
        }
      }
      
      // Check range bets
      if (result >= 1 && result <= 18 && this.bets.ranges.low > 0) {
        winnings += this.bets.ranges.low * 2; // 1:1 payout + original bet
      } else if (result >= 19 && result <= 36 && this.bets.ranges.high > 0) {
        winnings += this.bets.ranges.high * 2; // 1:1 payout + original bet
      }
      
      this.lastWin = winnings;
      this.credits += winnings;
    },
    
    drawWheel() {
      const canvas = this.$refs.wheelCanvas;
      if (!canvas) {
        console.log('Canvas no encontrado');
        return;
      }
      
      const ctx = canvas.getContext('2d');
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;
      const radius = 160;
      
      console.log('Dibujando ruleta...', { centerX, centerY, radius });
      
      // Clear canvas
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      // Draw outer circle first
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius + 5, 0, 2 * Math.PI);
      ctx.fillStyle = '#fbbf24';
      ctx.fill();
      
      // Save context for rotation
      ctx.save();
      ctx.translate(centerX, centerY);
      ctx.rotate((this.wheelAngle * Math.PI) / 180);
      
      // Draw wheel segments
      const anglePerSegment = (2 * Math.PI) / 37;
      
      for (let i = 0; i < 37; i++) {
        const startAngle = i * anglePerSegment;
        const endAngle = (i + 1) * anglePerSegment;
        const number = (37 - i) % 37; // Reverse order for proper rotation
        
        // Draw segment
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, radius, startAngle, endAngle);
        ctx.closePath();
        
        // Set color
        if (number === 0) {
          ctx.fillStyle = '#059669'; // Green for 0
        } else if (this.redNumbers.includes(number)) {
          ctx.fillStyle = '#dc2626'; // Red
        } else {
          ctx.fillStyle = '#000000'; // Black
        }
        
        ctx.fill();
        ctx.strokeStyle = '#fbbf24'; // Gold border
        ctx.lineWidth = 1;
        ctx.stroke();
        
        // Draw number
        ctx.save();
        ctx.rotate(startAngle + anglePerSegment / 2);
        ctx.translate(radius * 0.75, 0);
        ctx.rotate(Math.PI / 2);
        
        ctx.fillStyle = '#ffffff';
        ctx.font = 'bold 12px Arial';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(number.toString(), 0, 0);
        
        ctx.restore();
      }
      
      // Draw center circle
      ctx.beginPath();
      ctx.arc(0, 0, 15, 0, 2 * Math.PI);
      ctx.fillStyle = '#fbbf24';
      ctx.fill();
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 2;
      ctx.stroke();
      
      // Restore context
      ctx.restore();
      
      console.log('Ruleta dibujada exitosamente');
    }
  },
  
  beforeUnmount() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }
  }
}
</script>

<style scoped>
.bet-cell {
  border: 2px solid #fbbf24;
  border-radius: 4px;
  transition: all 0.3s ease;
}

.bet-cell:hover {
  border-color: #f59e0b;
  box-shadow: 0 4px 8px rgba(251, 191, 36, 0.3);
}

.roulette-game {
  background: linear-gradient(135deg, #1f2937 0%, #065f46 50%, #1f2937 100%);
  min-height: 100vh;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-track {
  background: #374151;
}

::-webkit-scrollbar-thumb {
  background: #fbbf24;
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background: #f59e0b;
}
</style>
