<template>
  <div class="slot-machine card p-6 rounded-lg shadow-lg max-w-xl mx-auto my-8 flex flex-col items-center">
    <h2 class="title text-4xl font-bold text-center mb-2 text-primary tracking-widest uppercase">TRAGAMONEDAS</h2>
    <p class="subtitle text-md text-muted-foreground mb-8">¡Alinea símbolos para ganar!</p>

    <div class="reels flex justify-center gap-4 mb-8">
      <div v-for="(reel, index) in reels" :key="index"
           class="reel-container w-28 h-28 bg-secondary flex items-center justify-center rounded-md overflow-hidden"
           :style="{ transitionDuration: `${spinDurations[index]}s` }">
        <span class="text-6xl pixel-text" :style="{ transform: `translateY(${reelPositions[index]}px)` }">
          {{ symbols[reel] }}
        </span>
      </div>
    </div>

    <div class="controls flex flex-col items-center gap-4">
      <button @click="spin" :disabled="spinning || balance < bet"
              class="btn btn-primary text-2xl px-12 py-4">
        {{ spinning ? 'Girando...' : 'GIRAR' }}
      </button>
      <p class="text-xl text-muted-foreground mt-4">COSTO: <strong class="text-foreground">${{ bet }}</strong></p>
      <p class="text-lg text-muted-foreground mt-2">Saldo: <strong class="text-foreground">${{ balance }}</strong></p>
      <p v-if="message" class="message text-center text-lg mt-4"
         :class="{ 'text-success animate-win-pulse': message.includes('Ganaste'), 'text-danger animate-bust-shake': message.includes('Perdiste'), 'text-primary': !message.includes('Ganaste') && !message.includes('Perdiste') }">
        {{ message }}
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SlotMachine',
  data() {
    return {
      symbols: ['🍒', '🔔', '⭐', '🍋', '💎'], // Símbolos disponibles
      reels: [0, 1, 2], // Índices iniciales de los símbolos en cada carrete
      spinning: false,
      spinningReels: [false, false, false],
      balance: 100,
      bet: 10,
      message: '',
      spinDurations: [0, 0, 0],
      reelPositions: [0, 0, 0], // Posición Y inicial para los símbolos
    };
  },
  methods: {
    spin() {
      if (this.spinning || this.balance < this.bet) {
        this.message = this.balance < this.bet ? 'Saldo insuficiente para girar.' : '';
        return;
      }

      this.spinning = true;
      this.spinningReels = [true, true, true];
      this.message = '';
      this.balance -= this.bet;

      const finalResults = [];
      const baseSpinTime = 2000; // Tiempo base de giro en ms

      for (let i = 0; i < this.reels.length; i++) {
        const delay = i * 200; // Retraso escalonado para cada carrete
        this.spinDurations[i] = (baseSpinTime + delay) / 1000; // Convertir a segundos

        // Animación de "blur" al inicio del giro
        this.reelPositions[i] = 0; // Resetear la posición para el giro
        this.$set(this.spinningReels, i, true); // Activa el blur

        // Simula el giro rápido moviendo los símbolos
        let animationFrame;
        const startTime = Date.now();
        const animateSpin = () => {
          const elapsed = Date.now() - startTime;
          if (elapsed < (baseSpinTime + delay)) {
            // Mueve el símbolo para simular un giro rápido
            this.reels[i] = Math.floor(Math.random() * this.symbols.length);
            animationFrame = requestAnimationFrame(animateSpin);
          } else {
            cancelAnimationFrame(animationFrame);
          }
        };
        animationFrame = requestAnimationFrame(animateSpin);

        // Detener el carrete después de un tiempo
        setTimeout(() => {
          const resultIndex = Math.floor(Math.random() * this.symbols.length); // Elije un símbolo final
          finalResults[i] = resultIndex; // Guarda el índice del símbolo final para la comprobación
          this.reels[i] = resultIndex; // Asigna el símbolo final al carrete

          this.$set(this.spinningReels, i, false); // Desactiva el blur
          this.reelPositions[i] = 0; // Asegura que el símbolo final esté centrado

          // Si es el último carrete, comprueba la victoria
          if (i === this.reels.length - 1) {
            this.checkWin(finalResults);
          }
        }, baseSpinTime + delay);
      }
    },
    checkWin(results) {
      this.spinning = false;
      const allSame = results.every(val => val === results[0]);

      if (allSame) {
        const winAmount = this.bet * 10;
        this.balance += winAmount;
        this.message = `¡Ganaste $${winAmount}! 🎉`;
      } else {
        this.message = '¡Perdiste! Inténtalo de nuevo. 😢';
      }
    },
  },
};
</script>

<style scoped>
.pixel-text {
  text-shadow: 2px 2px 0px hsl(var(--primary-2)),
               4px 4px 0px rgba(0,0,0,0.3);
}

.reel-container {
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: inset 0 0 0 2px rgba(0,0,0,0.2);
}

.reel-container span {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  will-change: transform;
}

.btn.play {
  background: hsl(var(--primary)) !important;
  box-shadow: 0 4px 0 0 hsl(var(--primary-2)) !important;
  transform: translateY(0);
  transition: all 0.1s ease;
}

.btn.play:active {
  transform: translateY(2px);
  box-shadow: 0 2px 0 0 hsl(var(--primary-2)) !important;
}
</style>