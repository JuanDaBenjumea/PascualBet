import { createRouter, createWebHistory } from 'vue-router';
import index from '../components/index.vue';
import login from '../components/login.vue';
import SlotM from '../components/games/slotM.vue';

const routes = [
  {
    path: '/',
    component: login,
    beforeEnter: (to, from, next) => {
      const session = localStorage.getItem('pb:session');
      if (session) {
        next('/menu'); // Si hay sesión activa, redirige al menú
      } else {
        next(); // Permite el acceso al login
      }
    }
  },
  {
    path: '/menu',
    component: index,
    beforeEnter: (to, from, next) => {
      const session = localStorage.getItem('pb:session');
      if (!session) {
        next('/'); // Si no hay sesión, redirige al login
      } else {
        next(); // Permite el acceso al menú
      }
    }
  },
  { path: '/game', component: SlotM }
];

const router = createRouter({
  history: createWebHistory(),
  routes
});

export default router;
