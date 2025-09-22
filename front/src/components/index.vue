<script>



</script>



<template>
  <header class="site-header">
    <div class="container">
      <div class="brand">
        <span class="logo">Pascualbet</span>
        <span class="locale" id="current-locale">ES</span>
      </div>

      <nav class="user-actions">
        <div class="balance">
          Saldo: <strong id="balance" data-balance="0">$0</strong>
        </div>
        <button class="btn" id="btn-deposit" data-action="open-deposit">
          Depositar
        </button>
        <button
          class="btn btn-outline"
          id="btn-withdraw"
          data-action="open-withdraw"
        >
          Retirar
        </button>
        <div class="avatar-menu">
          <button
            class="avatar"
            id="avatar-button"
            aria-haspopup="menu"
            aria-expanded="false"
          >
            <span class="avatar-fallback" id="avatar-initials">PB</span>
          </button>
          <div class="menu" id="avatar-menu" hidden>
            <button class="menu-item" data-action="profile">Mi perfil</button>
            <button class="menu-item" data-action="history">Historial</button>
            <button
              class="menu-item destructive"
              id="btn-logout"
              data-action="logout"
            >
              Cerrar sesión
            </button>
          </div>
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
      ></button>
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
            <p class="card-text">
              Gira y gana. Configura tu apuesta y cruza los dedos.
            </p>
            <button class="btn play" data-action="play" data-game="ruleta">
              Jugar
            </button>
          </article>

          <article class="card game" data-game="blackjack">
            <h3 class="card-title">Blackjack</h3>
            <p class="card-text">
              Llega a 21 sin pasarte. ¿Pides o te plantas?
            </p>
            <button class="btn play" data-action="play" data-game="blackjack">
              Jugar
            </button>
          </article>

          <article class="card game" data-game="poker">
            <h3 class="card-title">Póker</h3>
            <p class="card-text">Arma la mejor mano y vence a la mesa.</p>
            <button class="btn play" data-action="play" data-game="poker">
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
  <div class="modal" id="modal-deposit" role="dialog" aria-modal="true" hidden>
    <div class="modal-content">
      <header class="modal-header">
        <h3>Depositar</h3>
        <button
          class="icon-btn"
          data-action="close-deposit"
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
          Confirmar
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Retiro -->
  <div class="modal" id="modal-withdraw" role="dialog" aria-modal="true" hidden>
    <div class="modal-content">
      <header class="modal-header">
        <h3>Retirar</h3>
        <button
          class="icon-btn"
          data-action="close-withdraw"
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

  <footer class="site-footer">
    <div class="container">
      <small
        >© <span id="year"></span> Pascualbet. Todos los derechos
        reservados.</small
      >
    </div>
  </footer>
</template>
