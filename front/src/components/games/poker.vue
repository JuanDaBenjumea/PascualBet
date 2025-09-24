<template>
    <div class="poker-container">
      <!-- Header -->
      <header class="site-header">
        <div class="container">
          <div class="brand">
            <h1 class="game-title">🃏 Poker PascualBet 🃏</h1>
          </div>
          <div class="user-actions">
            <div class="balance">
              Créditos: <strong>${{ credits }}</strong>
            </div>
            <div class="bet-display">
              Apuesta: <strong class="danger-text">${{ currentBet }}</strong>
            </div>
          </div>
        </div>
      </header>
      
      <div class="container">
        <!-- Game Table -->
        <div class="game-table">
          <!-- Dealer Section -->
          <div class="dealer-section">
            <div class="player-label">
              <h3>🏛️ CASA</h3>
            </div>
            <div class="cards-container">
              <div 
                v-for="(card, index) in dealerHand" 
                :key="index"
                class="playing-card"
                :class="{ 
                  'card-hidden': !showDealerCards && index > 0,
                  'animate-deal-card': cardAnimation 
                }"
                :style="{ animationDelay: `${index * 0.1}s` }"
              >
                <div v-if="showDealerCards || index === 0" class="card-content">
                  <div class="card-suit" :class="getCardColor(card.suit)">{{ card.suit }}</div>
                  <div class="card-value">{{ card.value }}</div>
                </div>
                <div v-else class="card-back">🂠</div>
              </div>
            </div>
            <div v-if="showDealerCards && dealerHandValue > 0" class="hand-value">
              <span class="value-text">Valor: {{ dealerHandValue }}</span>
              <span class="hand-type">{{ dealerHandType }}</span>
            </div>
          </div>
          <!-- Player Section -->
          <div class="player-section">
            <div class="player-label">
              <h3>👤 TU MANO</h3>
            </div>
            <div class="cards-container">
              <div 
                v-for="(card, index) in playerHand" 
                :key="index"
                class="playing-card animate-deal-card"
                :style="{ animationDelay: `${index * 0.1}s` }"
              >
                <div class="card-content">
                  <div class="card-suit" :class="getCardColor(card.suit)">{{ card.suit }}</div>
                  <div class="card-value">{{ card.value }}</div>
                </div>
              </div>
            </div>
            <div v-if="playerHandValue > 0" class="hand-value">
              <span class="value-text">Valor: {{ playerHandValue }}</span>
              <span class="hand-type">{{ playerHandType }}</span>
            </div>
          </div>
          <!-- Game Status -->
          <div v-if="gameStatus" class="game-status">
            <div 
              class="status-message"
              :class="{
                'status-win': gameStatus.includes('GANAS'),
                'status-lose': gameStatus.includes('PIERDES'),
                'status-tie': gameStatus.includes('EMPATE')
              }"
            >
              {{ gameStatus }}
            </div>
            <div v-if="lastWin > 0" class="win-amount">
              ¡Ganaste ${{ lastWin }}!
            </div>
          </div>
          <!-- Game Controls -->
          <div class="game-controls">
            <!-- Bet Controls -->
            <div v-if="!gameStarted" class="bet-controls">
              <button 
                @click="decreaseBet"
                :disabled="currentBet <= minBet"
                class="control-btn decrease-btn"
              >
                -
              </button>
              <div class="bet-display">
                <span>Apuesta: ${{ currentBet }}</span>
              </div>
              <button 
                @click="increaseBet"
                :disabled="currentBet >= maxBet || currentBet + betStep > credits"
                class="control-btn increase-btn"
              >
                +
              </button>
            </div>
  
            <!-- Action Buttons -->
            <div class="action-controls">
              <button 
                v-if="!gameStarted"
                @click="startGame"
                :disabled="credits < currentBet"
                class="btn play-btn"
                :class="{ disabled: credits < currentBet }"
              >
                REPARTIR CARTAS
              </button>
  
              <template v-else-if="canPlay">
                <button 
                  @click="hit"
                  class="btn action-btn hit-btn"
                >
                  PEDIR CARTA
                </button>
                <button 
                  @click="stand"
                  class="btn action-btn stand-btn"
                >
                  PLANTARSE
                </button>
              </template>
  
              <button 
                v-if="gameStarted && !canPlay"
                @click="newGame"
                class="btn new-game-btn"
              >
                NUEVA PARTIDA
              </button>
            </div>
          </div>
        </div>
        <!-- Rules Card -->
        <div class="rules-card card">
          <h3 class="rules-title">📜 REGLAS DEL POKER</h3>
          <div class="rules-grid">
            <div class="rules-section">
              <h4 class="rules-subtitle">Jerarquía de Manos:</h4>
              <ul class="rules-list">
                <li>• <strong>Escalera Real:</strong> A, K, Q, J, 10 del mismo palo</li>
                <li>• <strong>Escalera de Color:</strong> 5 cartas consecutivas del mismo palo</li>
                <li>• <strong>Póker:</strong> 4 cartas del mismo valor</li>
                <li>• <strong>Full House:</strong> 3 + 2 cartas del mismo valor</li>
                <li>• <strong>Color:</strong> 5 cartas del mismo palo</li>
                <li>• <strong>Escalera:</strong> 5 cartas consecutivas</li>
                <li>• <strong>Trío:</strong> 3 cartas del mismo valor</li>
                <li>• <strong>Doble Par:</strong> 2 pares de cartas</li>
                <li>• <strong>Par:</strong> 2 cartas del mismo valor</li>
                <li>• <strong>Carta Alta:</strong> La carta más alta</li>
              </ul>
            </div>
            <div class="rules-section">
              <h4 class="rules-subtitle">Cómo Jugar:</h4>
              <ul class="rules-list">
                <li>• Haz tu apuesta antes de repartir</li>
                <li>• Se reparten 5 cartas a cada jugador</li>
                <li>• Puedes cambiar hasta 3 cartas</li>
                <li>• Gana la mejor mano de poker</li>
                <li>• Los pagos dependen de tu mano final</li>
              </ul>
            </div>
          </div>
        </div>
  
        <!-- Back Section -->
        <div class="back-section">
          <button @click="goBack" class="btn btn-outline">
            ← Volver al Menú
          </button>
        </div>
      </div>
    </div>
  </template>
  
  <script>
  export default {
    name: 'PokerGame',
    data() {
      return {
        credits: 1000,
        currentBet: 25,
        minBet: 10,
        maxBet: 200,
        betStep: 25,
        gameStarted: false,
        canPlay: false,
        showDealerCards: false,
        cardAnimation: false,
        gameStatus: '',
        lastWin: 0,
        
        deck: [],
        playerHand: [],
        dealerHand: [],
        
        suits: ['♠', '♥', '♦', '♣'],
        values: ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'],
        
        handTypes: {
          'royal_flush': { name: 'Escalera Real', multiplier: 250 },
          'straight_flush': { name: 'Escalera de Color', multiplier: 50 },
          'four_of_a_kind': { name: 'Póker', multiplier: 25 },
          'full_house': { name: 'Full House', multiplier: 9 },
          'flush': { name: 'Color', multiplier: 6 },
          'straight': { name: 'Escalera', multiplier: 4 },
          'three_of_a_kind': { name: 'Trío', multiplier: 3 },
          'two_pair': { name: 'Doble Par', multiplier: 2 },
          'pair': { name: 'Par', multiplier: 1 },
          'high_card': { name: 'Carta Alta', multiplier: 0 }
        }
      }
    },
    
    computed: {
      playerHandValue() {
        return this.getHandRank(this.playerHand);
      },
      
      dealerHandValue() {
        return this.getHandRank(this.dealerHand);
      },
      
      playerHandType() {
        const type = this.getHandType(this.playerHand);
        return this.handTypes[type].name;
      },
      
      dealerHandType() {
        const type = this.getHandType(this.dealerHand);
        return this.handTypes[type].name;
      }
    },
    
    methods: {
      createDeck() {
        this.deck = [];
        for (let suit of this.suits) {
          for (let value of this.values) {
            this.deck.push({ suit, value });
          }
        }
        this.shuffleDeck();
      },
      
      shuffleDeck() {
        for (let i = this.deck.length - 1; i > 0; i--) {
          const j = Math.floor(Math.random() * (i + 1));
          [this.deck[i], this.deck[j]] = [this.deck[j], this.deck[i]];
        }
      },
      
      dealCard() {
        return this.deck.pop();
      },
      
      startGame() {
        if (this.credits < this.currentBet) return;
        
        this.credits -= this.currentBet;
        this.gameStarted = true;
        this.canPlay = true;
        this.showDealerCards = false;
        this.gameStatus = '';
        this.lastWin = 0;
        this.cardAnimation = true;
        
        this.createDeck();
        this.playerHand = [];
        this.dealerHand = [];
        
        // Deal 5 cards to each player
        for (let i = 0; i < 5; i++) {
          this.playerHand.push(this.dealCard());
          this.dealerHand.push(this.dealCard());
        }
        
        setTimeout(() => {
          this.cardAnimation = false;
        }, 1000);
      },
      
      hit() {
        if (this.playerHand.length < 5) {
          this.playerHand.push(this.dealCard());
        }
        this.checkGame();
      },
      
      stand() {
        this.canPlay = false;
        this.showDealerCards = true;
        this.checkGame();
      },
      
      checkGame() {
        if (!this.canPlay) {
          const playerType = this.getHandType(this.playerHand);
          const dealerType = this.getHandType(this.dealerHand);
          const playerRank = this.getHandRank(this.playerHand);
          const dealerRank = this.getHandRank(this.dealerHand);
          
          if (playerRank > dealerRank) {
            this.gameStatus = '¡GANAS!';
            const multiplier = this.handTypes[playerType].multiplier;
            this.lastWin = this.currentBet * (multiplier + 1);
            this.credits += this.lastWin;
          } else if (playerRank < dealerRank) {
            this.gameStatus = 'PIERDES';
          } else {
            this.gameStatus = 'EMPATE';
            this.credits += this.currentBet; // Return bet
          }
        }
      },
      
      getCardColor(suit) {
        return ['♥', '♦'].includes(suit) ? 'text-red-500' : 'text-black';
      },
      
      getHandType(hand) {
        if (hand.length < 5) return 'high_card';
        
        const values = hand.map(card => this.getCardValue(card.value));
        const suits = hand.map(card => card.suit);
        const valueCounts = {};
        
        values.forEach(value => {
          valueCounts[value] = (valueCounts[value] || 0) + 1;
        });
        
        const counts = Object.values(valueCounts).sort((a, b) => b - a);
        const isFlush = suits.every(suit => suit === suits[0]);
        const sortedValues = values.sort((a, b) => a - b);
        const isStraight = this.isStraight(sortedValues);
        const isRoyal = sortedValues.join(',') === '1,10,11,12,13';
        
        if (isRoyal && isFlush) return 'royal_flush';
        if (isStraight && isFlush) return 'straight_flush';
        if (counts[0] === 4) return 'four_of_a_kind';
        if (counts[0] === 3 && counts[1] === 2) return 'full_house';
        if (isFlush) return 'flush';
        if (isStraight) return 'straight';
        if (counts[0] === 3) return 'three_of_a_kind';
        if (counts[0] === 2 && counts[1] === 2) return 'two_pair';
        if (counts[0] === 2) return 'pair';
        
        return 'high_card';
      },
      
      getHandRank(hand) {
        const type = this.getHandType(hand);
        const baseRank = Object.keys(this.handTypes).indexOf(type);
        return (Object.keys(this.handTypes).length - baseRank) * 1000;
      },
      
      getCardValue(value) {
        if (value === 'A') return 1; // Can also be 14 for high ace
        if (value === 'J') return 11;
        if (value === 'Q') return 12;
        if (value === 'K') return 13;
        return parseInt(value);
      },
      
      isStraight(sortedValues) {
        for (let i = 1; i < sortedValues.length; i++) {
          if (sortedValues[i] !== sortedValues[i-1] + 1) {
            return false;
          }
        }
        return true;
      },
      
      newGame() {
        this.gameStarted = false;
        this.canPlay = false;
        this.showDealerCards = false;
        this.gameStatus = '';
        this.playerHand = [];
        this.dealerHand = [];
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
      
      goBack() {
        this.$router.push('/menu');
      }
    }
  }
  </script>
  
<style scoped>
/* Tema principal usando CSS variables del globals.css */
.poker-container {
  background: var(--bg);
  color: var(--text);
  min-height: 100vh;
}

/* Header */
.game-title {
  font-size: 2rem;
  font-weight: bold;
  color: var(--primary);
  margin: 0;
}

.user-actions {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.balance, .bet-display {
  color: var(--muted);
  font-size: 1.1rem;
}

.danger-text {
  color: var(--destructive);
}

/* Game Table */
.game-table {
  background: linear-gradient(180deg, var(--card), var(--card-2));
  border: 2px solid var(--primary);
  border-radius: var(--radius);
  padding: 2rem;
  margin: 2rem 0;
  box-shadow: var(--shadow);
}

/* Player Sections */
.dealer-section, .player-section {
  margin-bottom: 2rem;
  text-align: center;
}

.player-label {
  margin-bottom: 1rem;
}

.player-label h3 {
  color: var(--primary);
  font-size: 1.5rem;
  font-weight: bold;
  margin: 0;
}

/* Cards */
.cards-container {
  display: flex;
  justify-content: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.playing-card {
  width: 4rem;
  height: 6rem;
  background: white;
  border: 2px solid var(--border);
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  box-shadow: 0 4px 12px rgba(0,0,0,0.25);
  transition: transform 0.2s ease;
  min-width: 64px;
  flex-shrink: 0;
}

.playing-card:hover {
  transform: translateY(-2px);
}

.card-content {
  text-align: center;
  color: #000;
}

.card-suit {
  font-size: 1.5rem;
  font-weight: bold;
  line-height: 1;
}

.card-value {
  font-size: 0.875rem;
  font-weight: bold;
  margin-top: 0.25rem;
}

.card-back {
  font-size: 2.5rem;
  color: var(--primary);
}

.card-hidden {
  background: linear-gradient(180deg, var(--primary), var(--primary-2));
  color: white;
}

/* Hand Values */
.hand-value {
  color: var(--muted);
  font-size: 1rem;
}

.value-text {
  margin-right: 0.5rem;
}

.hand-type {
  color: var(--primary);
  font-weight: 600;
}

/* Game Status */
.game-status {
  text-align: center;
  margin-bottom: 2rem;
}

.status-message {
  font-size: 1.5rem;
  font-weight: bold;
  padding: 0.75rem 2rem;
  border-radius: var(--radius);
  display: inline-block;
  margin-bottom: 0.5rem;
}

.status-win {
  background: var(--success);
  color: white;
  animation: win-pulse 1s infinite;
}

.status-lose {
  background: var(--destructive);
  color: white;
  animation: bust-shake 0.4s ease-in-out;
}

.status-tie {
  background: hsl(var(--accent));
  color: white;
}

.win-amount {
  color: var(--success);
  font-size: 1.25rem;
  font-weight: bold;
}

/* Game Controls */
.game-controls {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  align-items: center;
}

/* Bet Controls */
.bet-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: rgba(255,255,255,0.05);
  padding: 1rem;
  border-radius: 12px;
  border: 1px solid var(--border);
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
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.decrease-btn {
  background: var(--destructive);
  color: white;
}

.increase-btn {
  background: var(--success);
  color: white;
}

.control-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.control-btn:hover:not(:disabled) {
  transform: scale(1.05);
}

.bet-display {
  color: var(--text);
  font-weight: bold;
  font-size: 1.25rem;
  padding: 0 1rem;
}

/* Action Controls */
.action-controls {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  justify-content: center;
}

.btn {
  font-size: 1rem;
  padding: 0.75rem 2rem;
  border-radius: var(--radius);
  font-weight: 600;
  letter-spacing: 0.5px;
  transition: all 0.2s ease;
  min-width: 150px;
}

.play-btn {
  background: linear-gradient(180deg, var(--primary), hsl(var(--primary-2)));
  font-size: 1.25rem;
  padding: 1rem 2rem;
}

.action-btn {
  padding: 0.75rem 1.5rem;
}

.hit-btn {
  background: var(--success);
}

.stand-btn {
  background: var(--destructive);
}

.new-game-btn {
  background: linear-gradient(180deg, hsl(var(--accent)), #a855f7);
  font-size: 1.25rem;
  padding: 1rem 2rem;
}

/* Rules Card */
.rules-card {
  margin: 2rem 0;
}

.rules-title {
  color: var(--primary);
  font-size: 1.5rem;
  font-weight: bold;
  text-align: center;
  margin-bottom: 1.5rem;
}

.rules-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
}

.rules-section {
  text-align: left;
}

.rules-subtitle {
  color: var(--primary);
  font-weight: bold;
  margin-bottom: 1rem;
  font-size: 1.1rem;
}

.rules-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.rules-list li {
  margin-bottom: 0.5rem;
  color: var(--muted);
  line-height: 1.4;
}

.rules-list strong {
  color: var(--text);
}

/* Back Section */
.back-section {
  text-align: center;
  margin-top: 2rem;
}

/* Card Color Classes */
.text-red-500 {
  color: #ef4444;
}

.text-black {
  color: #000000;
}

/* Animations using globals.css */
.animate-deal-card {
  animation: deal-card 0.5s ease-out forwards;
}

/* Responsive */
@media (max-width: 768px) {
  .game-table {
    padding: 1rem;
  }
  
  .cards-container {
    gap: 0.5rem;
  }
  
  .playing-card {
    width: 3rem;
    height: 4.5rem;
  }
  
  .card-suit {
    font-size: 1.25rem;
  }
  
  .card-value {
    font-size: 0.75rem;
  }
  
  .rules-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .action-controls {
    flex-direction: column;
    width: 100%;
  }
  
  .btn {
    width: 100%;
  }
  
  .bet-controls {
    flex-wrap: wrap;
    justify-content: center;
  }
}

@media (max-width: 480px) {
  .container {
    padding: 0.5rem;
  }
  
  .game-title {
    font-size: 1.5rem;
  }
  
  .user-actions {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .status-message {
    font-size: 1.25rem;
    padding: 0.5rem 1rem;
  }
  
  .rules-title {
    font-size: 1.25rem;
  }
}
</style>