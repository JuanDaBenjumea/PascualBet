<script>
export default {
  data() {
    return {
      showLogoutModal: false, // Controla la visibilidad del modal de logout
      showDepositModal: false, // Controla la visibilidad del modal de depósito
      showWithdrawModal: false // Controla la visibilidad del modal de retiro
    };
  },
  methods: {
    openLogoutModal() {
      this.showLogoutModal = true; // Muestra el modal de logout
    },
    closeLogoutModal() {
      this.showLogoutModal = false; // Oculta el modal de logout
    },
    logout() {
      // Elimina la sesión y redirige al login
      localStorage.removeItem('pb:session');
      this.$router.replace('/'); // Redirige al login
    },
    openDepositModal() {
      this.showDepositModal = true; // Muestra el modal de depósito
    },
    closeDepositModal() {
      this.showDepositModal = false; // Oculta el modal de depósito
    },
    openWithdrawModal() {
      this.showWithdrawModal = true; // Muestra el modal de retiro
    },
    closeWithdrawModal() {
      this.showWithdrawModal = false; // Oculta el modal de retiro
    },
    tragaperras() {
        this.$router.push('/slot');
      },
      ruleta() {
        this.$router.push('/rulete');
      },
      poker() {
        this.$router.push('/poker');
      }
  }
};
</script>

<template>
  <header class="site-header">
    <div class="container">
      <div class="brand">
        <span class=""><img src="/img/Logo_PascualBet.png" alt="Logo" class="avatar"/></span>
      </div>

      <nav class="user-actions">
        <div class="balance">
          Saldo: <strong id="balance" data-balance="0">$0</strong>
        </div>
        <button class="btn" id="btn-deposit" data-action="open-deposit" aria-haspopup="menu"
            aria-expanded="false"
            @click="openDepositModal">
          Depositar
        </button>
        <button @click="openWithdrawModal" >
          Retirar
        </button>
        <div class="avatar-menu">
          <button
            class="avatar"
            id="avatar-button"
            aria-haspopup="menu"
            aria-expanded="false"
            @click="openLogoutModal"
          >
            <span class="avatar-fallback" id="avatar-initials">
              <img src="https://cdn2.iconfinder.com/data/icons/pixel-characters-v2/100/avatar-09-512.png" alt="">
            </span>
          </button>
        </div>
      </nav>
    </div>
  </header>

  <main class="container">
    <!-- Tabs -->
    <section class="tabs" role="tablist" aria-label="Secciones">
      <button
        class="tab is-active"
        role="tab"
        aria-selected="true"
        data-tab="casino"
      ></button>
      <button
        class="tab"
        role="tab"
        aria-selected="false"
        data-tab="apuestas"
      >
    </button>
      <button
        class="tab"
        role="tab"
        aria-selected="false"
        data-tab="slots"
      ></button>
      <button
        class="tab"
        role="tab"
        aria-selected="false"
        data-tab="admin"
        id="tab-admin"
        hidden
      ></button>
    </section>

    <!-- Paneles -->
    <section class="tab-panels">
      <!-- Casino -->
      <div class="tab-panel is-active" id="panel-casino" role="tabpanel">
        <h2 class="h2">Casino</h2>
        <div class="cards-grid">
          <article class="card game" data-game="ruleta">
            <h3 class="card-title">Ruleta</h3>
            <img src="https://png.pngtree.com/png-clipart/20241009/original/pngtree-roulette-game-in-pixel-art-style-png-image_16249811.png" alt="" >
            <p class="card-text">
              Gira y gana. Configura tu apuesta y cruza los dedos.
            </p>
            <button class="btn play" @click="ruleta">
              Jugar
            </button>
          </article>

          <article class="card game" data-game="blackjack">
            <h3 class="card-title">tragamonedas</h3>
            <img src="https://i.redd.it/8iwvfxxg2efe1.png" alt="" srcset="">
            <p class="card-text">
              nose usted ya sabra, tu apuesta tu perder
            </p>
            <button class="btn play" @click="tragaperras">
              Jugar
            </button>
          </article>

          <article class="card game" data-game="poker">
            <h3 class="card-title">Póker</h3>
            <img src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTYWJWVbDcT413-oX0ekFgFcRqdCH_8tTVzKg&s" alt="" srcset="">
            <p class="card-text">Arma la mejor mano y vence a la mesa.</p>
            <button class="btn play" @click="tragaperras">
              Jugar
            </button>
          </article>
        </div>
      </div>

      <!-- Apuestas -->
      <div class="tab-panel" id="panel-apuestas" role="tabpanel" hidden>
        <h2 class="h2">Apuestas Deportivas</h2>
        <div class="list">
          <div class="list-item">
            <div>
              <strong>Fútbol</strong>
              <div class="muted">Barcelona vs. Madrid — 20:00</div>
            </div>
            <button class="btn" data-action="bet" data-match-id="m1">
              Apostar
            </button>
          </div>
          <div class="list-item">
            <div>
              <strong>Tennis</strong>
              <div class="muted">Semifinal — 18:30</div>
            </div>
            <button class="btn" data-action="bet" data-match-id="m2">
              Apostar
            </button>
          </div>
        </div>
      </div>

      <!-- Slots -->
      <div class="tab-panel" id="panel-slots" role="tabpanel" hidden>
        <h2 class="h2">Slots</h2>
        <div class="cards-grid">
          <article class="card slot" data-game="slot-classic">
            <h3 class="card-title">Slot Clásico</h3>
            <p class="card-text">
              Siete, cerezas y BAR. La clásica de siempre.
            </p>
            <button
              class="btn play"
              data-action="play"
              data-game="slot-classic"
            >
              Girar
            </button>

          </article>

          <article class="card slot" data-game="slot-egypt">
            <h3 class="card-title">Tesoros de Egipto</h3>
            <p class="card-text">Explora las pirámides en busca de premios.</p>
            <button class="btn play" data-action="play" data-game="slot-egypt">
              Girar
            </button>
          </article>
        </div>
      </div>

      <!-- Admin (visible solo si role=admin) -->
      <div class="tab-panel" id="panel-admin" role="tabpanel" hidden>
        <h2 class="h2">Panel de Administración</h2>
        <div class="cards-grid">
          <article class="card">
            <h3 class="card-title">Usuarios</h3>
            <p class="card-text">Gestión básica de usuarios y saldos.</p>
            <button class="btn" data-action="open-admin-users">Abrir</button>
          </article>
          <article class="card">
            <h3 class="card-title">Transacciones</h3>
            <p class="card-text">Revisión de depósitos y retiros.</p>
            <button class="btn" data-action="open-admin-tx">Abrir</button>
          </article>
        </div>
      </div>
    </section>
  </main>

  <!-- Modal Depósito -->
  <div class="modal" id="modal-deposit" v-if="showDepositModal" role="dialog" aria-modal="true">
    <div class="modal-content">
      <header class="modal-header">
        <h3>Depositar</h3>
        <button
          class="icon-btn"
          @click="closeDepositModal"
          aria-label="Cerrar"
        >
          ✕
        </button>
      </header>
      <div class="modal-body">
        <label class="field">
          <span>Monto</span>
          <input
            type="number"
            id="deposit-amount"
            min="0"
            step="1000"
            placeholder="0"
          />
        </label>
        <button class="btn" id="confirm-deposit" data-action="confirm-deposit">
          <a href="https://www.youtube.com/watch?v=xvFZjo5PgG0&list=RDxvFZjo5PgG0&start_radio=1" target="_blank">confirmar</a>
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Retiro -->
  <div class="modal" id="modal-withdraw" v-if="showWithdrawModal" role="dialog" aria-modal="true">
    <div class="modal-content">
      <header class="modal-header">
        <h3>Retirar</h3>
        <button
          class="icon-btn"
          @click="closeWithdrawModal"
          aria-label="Cerrar"
        >
          ✕
        </button>
      </header>
      <div class="modal-body">
        <label class="field">
          <span>Monto</span>
          <input
            type="number"
            id="withdraw-amount"
            min="0"
            step="1000"
            placeholder="0"
          />
        </label>
        <button
          class="btn btn-outline"
          id="confirm-withdraw"
          data-action="confirm-withdraw"
        >
          Confirmar
        </button>
      </div>
    </div>
  </div>

  <!-- Modal para cerrar sesión -->
  <div class="modal" id="logout-modal" v-if="showLogoutModal" role="dialog" aria-modal="true">
    <div class="modal-content">
      <header class="modal-header">
        <h3>¿Deseas cerrar sesión?</h3>
        <button class="icon-btn" @click="closeLogoutModal" aria-label="Cerrar">✕</button>
      </header>
      <div class="modal-body">
        <p>Al cerrar sesión, todavia no alcanzaras el objetivo de ser millonario</p>
        <img src="https://i.redd.it/iu0ms6q9sit71.jpg" alt="">
        <button class="btn destructive" @click="logout">Cerrar sesión</button>
      </div>
    </div>
  </div>

  <footer class="site-footer">
    <div class="container">
      <small
        >© <span id="year"></span> Pascualbet. Todos los derechos
        reservados.</small>
    </div>
  </footer>
</template>

<style scoped>
.site-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 30px 20px;
  background-color: #1a1a2e; /* Color de fondo del header */
  color: #fff; /* Color del texto */
}

.brand {
  display: flex;
  align-items: center;
  gap: 10px;
}

.logo img {
  width: 120px; /* Ajusta el tamaño del logo */
  height: 100%; /* Mantén la proporción de la imagen */
  object-fit: contain; /* Asegura que la imagen no se recorte */
}

.user-actions {
  display: flex;
  align-items: center;
  gap: 15px; /* Espaciado entre los elementos */
}

.balance {
  font-size: 14px;
}

.avatar-menu {
  position: relative;
}

.avatar {
  width: 100%;
  height: 90px;
  border-radius: 50%;
  background-color: #223042; /* Fondo del avatar */
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff; /* Color del texto "PB" */
  font-weight: bold;
  cursor: pointer;
}

.avatar-menu .menu {
  position: absolute;
  top: 100px; /* Ajusta la posición del menú desplegable */
  right: 0;
  background-color: #1a1a2e;
  border: 1px solid #223042;
  border-radius: 5px;
  padding: 10px;
  display: none; /* Oculta el menú por defecto */
}

.avatar-menu .menu-item {
  color: #fff;
  padding: 0px 10px;
  cursor: pointer;
}

.avatar-menu .menu-item.destructive {
  color: #ff4d4d; /* Color para acciones destructivas */
}

.avatar-menu:hover .menu {
  display: block; /* Muestra el menú al pasar el mouse */
}

.avatar-fallback {
  width: 80px; /* Ajusta el tamaño del contenedor */
  height: 80px; /* Asegúrate de que el alto sea igual al ancho */
  border-radius: 50%; /* Hace que el borde sea completamente circular */
  overflow: hidden; /* Oculta cualquier contenido que exceda el contenedor */
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid #223042; /* Opcional: agrega un borde */
}

.avatar-fallback img {
  width: 100%; /* La imagen ocupará el 100% del ancho del contenedor */
  height: 100%; /* La imagen ocupará el 100% de la altura del contenedor */
  object-fit: cover; /* Asegura que la imagen se ajuste correctamente dentro del contenedor */
}

.avatar-fallback img {
  width: 80%; 
  height: 80%; /* La imagen ocupará el 100% de la altura del contenedor */
  object-fit: cover; 
}

.modal {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  background-color: #1a1a2e;
  color: #fff;
  border: 1px solid #223042;
  border-radius: 10px;
  padding: 20px;
  z-index: 1000;
  width: 600px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.35);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.modal-body {
  margin-top: 10px;
}



.btn.destructive {
  background-color: #ff4d4d;
  color: #fff;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;
}

.btn.destructive:hover {
  background-color: #e63939;
}
</style>
