<template>
  <div class="blackjack">
    <h1>🃏 Blackjack 🃏</h1>
    <div class="bet-section" v-if="!gameStarted">
      <h2>💰 Ingresa tu apuesta</h2>
      <input
        type="number"
        list="predefinedAmounts"
        v-model="betAmount"
        placeholder="Selecciona o ingresa una cantidad (mínimo: 10)"
        class="bet-input"
        @input="validateBetAmount"
      />
      <datalist id="predefinedAmounts">
        <option v-for="amount in predefinedAmounts" :key="amount" :value="amount">
          {{ amount }}
        </option>
      </datalist>
      <button @click="startGame" :disabled="betAmount < 10" class="bet-button">🎲 Repartir</button>
    </div>
    <div v-else class="table">
      <div class="dealer">
        <h2>Crupier</h2>
        <div class="cards">
          <div v-for="(card, index) in dealerCards" :key="'dealer-' + index" class="card">
            <span v-if="index === 0 && playerTurn">🂠</span>
            <span v-else>
              <span>{{ card.rank }}</span>
              <span class="suit">{{ card.suit }}</span>
            </span>
          </div>
        </div>
        <p>Puntuación: {{ playerTurn ? '?' : dealerScore }}</p>
      </div>
      <div class="player">
        <h2>Jugador</h2>
        <div class="cards">
          <div v-for="(card, index) in playerCards" :key="'player-' + index" class="card">
            <span>{{ card.rank }}</span>
            <span class="suit">{{ card.suit }}</span>
          </div>
        </div>
        <p>Puntuación: {{ playerScore }}</p>
        <p>💵 Apuesta: {{ betAmount }}</p>
      </div>
    </div>
    <div class="actions" v-if="playerTurn && gameStarted">
      <button @click="hit">➕ Pedir carta</button>
      <button @click="stand">✋ Plantarse</button>
    </div>
    <div v-if="gameOver" class="game-over">
      <h2>{{ resultMessage }}</h2>
      <button @click="resetGame">🔄 Jugar de nuevo</button>
    </div>
    <div class="manual">
      <h2>📖 Cómo Jugar</h2>
      <p><strong>Objetivo:</strong> Tu mano debe sumar un valor más cercano a 21 que la del crupier, sin pasarte de 21.</p>
      <h3>🃏 Valor de las Cartas</h3>
      <ul>
        <li>
          <span class="card">7♠</span> Cartas 2-10: Valen su número indicado.
          <div class="example">
            <p>Ejemplo:</p>
            <div class="card">7♠</div>
            <p>Esta carta vale 7 puntos.</p>
          </div>
        </li>
        <li>
          <span class="card">K♦</span> Figuras (J, Q, K): Valen 10 puntos cada una.
          <div class="example">
            <p>Ejemplo:</p>
            <div class="card">K♦</div>
            <p>Esta carta vale 10 puntos.</p>
          </div>
        </li>
        <li>
          <span class="card">A♥</span> As (A): Vale 1 u 11, lo que más te convenga.
          <div class="example">
            <p>Ejemplo:</p>
            <div class="card">A♥</div>
            <p>Esta carta puede valer 1 o 11 puntos según tu estrategia.</p>
          </div>
        </li>
      </ul>
      <h3>📜 Reglas Principales</h3>
      <ul>
        <li>
          Elige tu apuesta y pulsa <span class="button-example">REPARTIR</span>.
        </li>
        <li>
          Recibes 2 cartas. El crupier recibe 2, una de ellas boca abajo.
        </li>
        <li>
          Pulsa <span class="button-example">PEDIR</span> para recibir otra carta o pulsa <span class="button-example">PLANTARSE</span> para quedarte con tu mano actual.
        </li>
        <li>
          Si tu puntuación supera 21, pierdes automáticamente (Bust).
        </li>
        <li>
          El crupier está obligado a pedir cartas hasta que su mano sume 17 o más.
        </li>
        <li>
          Un Blackjack (un As y una carta de valor 10 en la mano inicial) paga 3 a 2 (1.5x tu apuesta).
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      deck: [],
      playerCards: [],
      dealerCards: [],
      playerTurn: true,
      gameOver: false,
      gameStarted: false,
      betAmount: 0,
      predefinedAmounts: [10, 20, 50, 100],
      resultMessage: "",
    };
  },
  computed: {
    playerScore() {
      return this.calculateScore(this.playerCards);
    },
    dealerScore() {
      return this.calculateScore(this.dealerCards);
    },
  },
  methods: {
    validateBetAmount() {
      if (this.betAmount < 10) {
        this.betAmount = 0; // Resetea si la cantidad es menor al mínimo
      }
    },
    startGame() {
      if (this.betAmount < 10) return; // Asegúrate de que la apuesta sea válida
      this.deck = this.createDeck();
      this.shuffleDeck(this.deck);
      this.playerCards = [this.drawCard(), this.drawCard()];
      this.dealerCards = [this.drawCard(), this.drawCard()];
      this.playerTurn = true;
      this.gameOver = false;
      this.gameStarted = true;
      this.resultMessage = "";
    },
    resetGame() {
      this.gameStarted = false;
      this.betAmount = 0;
      this.playerCards = [];
      this.dealerCards = [];
      this.resultMessage = "";
    },
    createDeck() {
      const suits = ["♠", "♥", "♦", "♣"];
      const ranks = [
        "2",
        "3",
        "4",
        "5",
        "6",
        "7",
        "8",
        "9",
        "10",
        "J",
        "Q",
        "K",
        "A",
      ];
      const deck = [];
      for (const suit of suits) {
        for (const rank of ranks) {
          deck.push({ suit, rank });
        }
      }
      return deck;
    },
    shuffleDeck(deck) {
      for (let i = deck.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [deck[i], deck[j]] = [deck[j], deck[i]];
      }
    },
    drawCard() {
      return this.deck.pop();
    },
    calculateScore(cards) {
      let score = 0;
      let aces = 0;
      for (const card of cards) {
        if (["J", "Q", "K"].includes(card.rank)) {
          score += 10;
        } else if (card.rank === "A") {
          aces += 1;
          score += 11;
        } else {
          score += parseInt(card.rank);
        }
      }
      while (score > 21 && aces > 0) {
        score -= 10;
        aces -= 1;
      }
      return score;
    },
    hit() {
      if (this.gameOver) return; // Evita que se pidan cartas si el juego ya terminó
      this.playerCards.push(this.drawCard());
      if (this.playerScore > 21) {
        this.endGame("¡Te pasaste! El crupier gana.");
      }
    },
    stand() {
      if (this.gameOver) return; // Evita que se interactúe si el juego ya terminó
      this.playerTurn = false;
      while (this.dealerScore < 17) {
        this.dealerCards.push(this.drawCard());
      }
      if (this.dealerScore > 21 || this.playerScore > this.dealerScore) {
        this.endGame("¡Ganaste!");
      } else if (this.playerScore < this.dealerScore) {
        this.endGame("El crupier gana.");
      } else {
        this.endGame("Es un empate.");
      }
    },
    endGame(message) {
      this.gameOver = true;
      this.resultMessage = message;
    },
  },
  mounted() {
    this.resetGame();
  },
};
</script>

<style scoped>
.blackjack {
  text-align: center;
  font-family: Arial, sans-serif;
  background-color: #001f3f; /* Azul oscuro */
  color: #ffffff; /* Blanco */
  padding: 20px;
}
.bet-section {
  margin-bottom: 20px;
}
.bet-input {
  padding: 10px;
  font-size: 16px;
  border: 2px solid #ffffff;
  border-radius: 4px;
  background-color: #003366; /* Azul más claro */
  color: #ffffff;
}
.bet-button {
  margin-top: 10px;
  padding: 10px 20px;
  font-size: 16px;
  background-color: #ffffff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  color: #001f3f;
}
.bet-button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}
.table {
  display: flex;
  justify-content: space-around;
  margin: 20px 0;
  background-color: #003366; /* Azul más claro para simular una mesa */
  border-radius: 15px;
  padding: 20px;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.5); /* Sombra para dar profundidad */
}
.cards {
  display: flex;
  justify-content: center;
  margin: 10px 0;
}
.card {
  border: 2px solid #ffffff; /* Blanco */
  border-radius: 4px;
  padding: 5px;
  margin: 5px;
  width: 60px;
  height: 80px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  background-color: #001f3f; /* Azul oscuro */
  box-shadow: 2px 2px 0px #ffffff; /* Sombra blanca */
}
.card .suit {
  font-size: 20px;
  color: #ffffff; /* Blanco */
}
.actions button {
  margin: 5px;
  padding: 10px 20px;
  font-size: 14px;
  background-color: #ffffff; /* Blanco */
  border: none;
  border-radius: 4px;
  cursor: pointer;
  box-shadow: 2px 2px 0px #001f3f; /* Sombra azul oscuro */
  color: #001f3f; /* Texto azul oscuro */
}
.actions button:hover {
  background-color: #f0f0f0; /* Blanco más claro */
}
.game-over {
  margin-top: 20px;
}
.manual {
  margin-top: 30px;
  text-align: left;
  font-size: 14px;
  background: #003366; /* Azul más claro */
  color: #ffffff; /* Blanco */
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.5);
}
.example {
  margin-top: 10px;
  background: #001f3f; /* Azul oscuro */
  padding: 10px;
  border-radius: 4px;
  color: #ffffff; /* Blanco */
}
.button-example {
  background: #ffffff; /* Blanco */
  padding: 5px 10px;
  border-radius: 4px;
  font-weight: bold;
  color: #001f3f; /* Azul oscuro */
}
</style>