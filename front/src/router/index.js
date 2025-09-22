import { createRouter, createWebHistory } from 'vue-router'
import index from '../components/index.vue'
import login from '../components/login.vue'

const routes = [
  { path: '/', component: login },
  {path: '/a', component: index}
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
