<script setup>
import { ref } from 'vue'
import TrainView      from './TrainView.vue'
import RestView       from './RestView.vue'
import ExploreView    from './ExploreView.vue'
import TeamView       from './TeamView.vue'
import InventarioView   from './InventarioView.vue'
import CompañerosView  from './CompañerosView.vue'
import CombateView     from './CombateView.vue'
import PerfilView           from './PerfilView.vue'
import GuardarPartidaView  from './GuardarPartidaView.vue'

const props = defineProps({
  entrenador:           Object,
  equipo:               Array,
  capturados:           Array,
  inventario:           Object,
  ultimoDescanso:       Number,
  descansandoHasta:     Number,
  peDescanso:           Number,
  capturaCooldownHasta: Number,
  capturasDisponibles:  Number,
  partidaId:            Number,
  nombrePartida:        String,
})

const emit = defineEmits(['actualizar-pokemon', 'capturar-pokemon', 'actualizar-equipo', 'actualizar-capturas', 'iniciar-descanso', 'completar-descanso', 'agregar-material', 'usar-material', 'actualizar-nombre', 'guardar-partida', 'actualizar-hp'])

const vistaActual    = ref('hub')
const pokemonIndex   = ref(0)
const sidebarAbierto = ref(true)

function actualizarPokemon(index, datos) {
  emit('actualizar-pokemon', { index, datos })
}

function seleccionarParaEntrenar(index) {
  if (props.equipo[index] === undefined) return
  pokemonIndex.value = index
}
</script>

<template>
  <div class="hub">

    <!-- Sidebar izquierda -->
    <button class="sidebar-toggle" @click="sidebarAbierto = !sidebarAbierto">
      {{ sidebarAbierto ? '◀' : '▶' }}
    </button>

    <aside class="sidebar" :class="{ colapsado: !sidebarAbierto }">

      <div class="trainer-card" :style="{ borderColor: entrenador.clase.color }">
        <div class="trainer-header" :style="{ backgroundColor: entrenador.clase.color }">
          <span class="trainer-icono">🧢</span>
          <div>
            <h2>{{ entrenador.nombre }}</h2>
            <span class="trainer-clase">{{ entrenador.clase.label }}</span>
          </div>
        </div>
      </div>

      <div class="sidebar-bonos">
        <h3>Bonos de clase</h3>
        <div v-for="stat in entrenador.clase.stats" :key="stat.nombre" class="bono-fila">
          <span class="bono-nombre">{{ stat.nombre }}</span>
          <span class="bono-valor" :class="stat.valor > 0 ? 'positivo' : stat.valor < 0 ? 'negativo' : 'neutro'">
            {{ stat.valor > 0 ? '+' + stat.valor : stat.valor === 0 ? '—' : stat.valor }}%
          </span>
        </div>
      </div>

      <div class="sidebar-conteo">
        <div class="conteo-item">
          <span class="conteo-num">{{ capturados.length }}</span>
          <span class="conteo-label">Capturados</span>
        </div>
        <div class="conteo-item">
          <span class="conteo-num">{{ equipo.length }}</span>
          <span class="conteo-label">En equipo</span>
        </div>
      </div>

    </aside>

    <!-- Contenido principal -->
    <main class="contenido">

      <!-- Vista: Hub principal -->
      <div v-if="vistaActual === 'hub'">
        <div class="bienvenida">
          <h1>¡Bienvenido, {{ entrenador.nombre }}!</h1>
          <p>Tu aventura comienza. ¿Qué harás hoy?</p>
        </div>

        <div class="acciones">
          <div class="accion-card">
            <span class="accion-icono">🔍</span>
            <h2>Explorar</h2>
            <p>Busca Pokémon salvajes y amplía tu equipo.</p>
            <button @click="vistaActual = 'explorar'">Explorar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">💪</span>
            <h2>Entrenar</h2>
            <p>Fortalece los stats de tu equipo actual.</p>
            <button @click="vistaActual = 'entrenar'">Entrenar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">📋</span>
            <h2>Equipo</h2>
            <p>Gestiona y revisa los Pokémon de tu equipo.</p>
            <button @click="vistaActual = 'equipo'">Ver equipo</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🌙</span>
            <h2>Descansar</h2>
            <p>Recupera los PE de tu equipo. Un descanso por día.</p>
            <button @click="vistaActual = 'descanso'">Descansar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🎒</span>
            <h2>Inventario</h2>
            <p>Revisa los materiales que has recogido en tus exploraciones.</p>
            <button @click="vistaActual = 'inventario'">Ver inventario</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🤝</span>
            <h2>Compañeros</h2>
            <p>Cuida y usa materiales con tus Pokémon.</p>
            <button @click="vistaActual = 'compañeros'">Ver compañeros</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">⚔️</span>
            <h2>Combate</h2>
            <p>Enfrenta a tus Pokémon en duelos uno a uno.</p>
            <button @click="vistaActual = 'combate'">Ir a combate</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">👤</span>
            <h2>Perfil</h2>
            <p>Consulta tus datos, clase y bonos de entrenador.</p>
            <button @click="vistaActual = 'perfil'">Ver perfil</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">💾</span>
            <h2>Guardar partida</h2>
            <p>Guarda tu progreso actual para continuar más tarde.</p>
            <button @click="vistaActual = 'guardar'">Guardar</button>
          </div>
        </div>
      </div>

      <!-- Vista: Entrenar -->
      <div v-else-if="vistaActual === 'entrenar'">
        <TrainView
          :key="pokemonIndex"
          :pokemon="equipo[pokemonIndex]"
          :clase-stats="entrenador.clase.stats"
          @actualizar="datos => actualizarPokemon(pokemonIndex, datos)"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Explorar -->
      <div v-else-if="vistaActual === 'explorar'">
        <ExploreView
          :captura-cooldown-hasta="capturaCooldownHasta"
          :capturas-disponibles="capturasDisponibles"
          @volver="vistaActual = 'hub'"
          @capturar="pokemon => emit('capturar-pokemon', pokemon)"
          @actualizar-capturas="datos => emit('actualizar-capturas', datos)"
          @agregar-material="material => emit('agregar-material', material)"
        />
      </div>

      <!-- Vista: Equipo -->
      <div v-else-if="vistaActual === 'equipo'">
        <TeamView
          :equipo="equipo"
          :capturados="capturados"
          @actualizar-equipo="nuevoEquipo => emit('actualizar-equipo', nuevoEquipo)"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Descanso -->
      <div v-else-if="vistaActual === 'descanso'">
        <RestView
          :ultimo-descanso="ultimoDescanso"
          :descansando-hasta="descansandoHasta"
          :pe-descanso="peDescanso"
          @iniciar-descanso="datos => emit('iniciar-descanso', datos)"
          @completar-descanso="emit('completar-descanso')"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Inventario -->
      <div v-else-if="vistaActual === 'inventario'">
        <InventarioView
          :inventario="inventario"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Compañeros -->
      <div v-else-if="vistaActual === 'compañeros'">
        <CompañerosView
          :equipo="equipo"
          :capturados="capturados"
          :inventario="inventario"
          @volver="vistaActual = 'hub'"
          @usar-material="datos => emit('usar-material', datos)"
        />
      </div>

      <!-- Vista: Combate -->
      <div v-else-if="vistaActual === 'combate'">
        <CombateView
          :entrenador="entrenador"
          :equipo="equipo"
          :capturados="capturados"
          :partida-id="partidaId"
          @volver="vistaActual = 'hub'"
          @actualizar-hp="emit('actualizar-hp', $event)"
        />
      </div>

      <!-- Vista: Perfil -->
      <div v-else-if="vistaActual === 'perfil'">
        <PerfilView
          :entrenador="entrenador"
          :capturados="capturados"
          :partida-id="partidaId"
          @volver="vistaActual = 'hub'"
          @actualizar-nombre="nombre => emit('actualizar-nombre', nombre)"
        />
      </div>

      <!-- Vista: Guardar partida -->
      <div v-else-if="vistaActual === 'guardar'">
        <GuardarPartidaView
          :entrenador="entrenador"
          :partida-id="partidaId"
          :nombre-partida="nombrePartida"
          @volver="vistaActual = 'hub'"
          @guardar-partida="datos => emit('guardar-partida', datos)"
        />
      </div>

    </main>

  </div>
</template>

<style scoped>
.hub {
  display: flex;
  height: 100vh;
  overflow: hidden;
  font-family: sans-serif;
}

.sidebar {
  width: 240px;
  height: 100%;
  overflow: hidden;
  background: #1e2a3a;
  border-right: 1px solid #2c3e52;
  padding: 52px 16px 24px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  flex-shrink: 0;
  transition: width 0.25s ease, padding 0.25s ease;
}

.sidebar.colapsado {
  width: 0;
  padding: 0;
  border-right: none;
}

.sidebar.colapsado .trainer-card,
.sidebar.colapsado .equipo {
  display: none;
}

.sidebar-toggle {
  position: fixed;
  top: 16px;
  left: 8px;
  z-index: 100;
  background: #1e2a3a;
  border: 1px solid #2c3e52;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.75rem;
  padding: 4px 7px;
  color: #8aaabb;
}

.sidebar-toggle:hover {
  background: #243447;
}

.trainer-card {
  border: 2px solid #ccc;
  border-radius: 12px;
  overflow: hidden;
}

.trainer-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  color: white;
}

.trainer-icono { font-size: 1.8rem; }

.trainer-header h2 {
  margin: 0;
  font-size: 1rem;
}

.trainer-clase {
  font-size: 0.8rem;
  opacity: 0.9;
}

.sidebar-bonos h3 {
  font-size: 0.9rem;
  font-weight: bold;
  color: #8aaabb;
  text-transform: uppercase;
  margin-bottom: 10px;
}

.bono-fila {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.82rem;
  padding: 3px 0;
}

.bono-nombre {
  color: #c8d8e4;
}

.bono-valor {
  font-weight: bold;
}

.positivo { color: #2dc653; }
.negativo { color: #e63946; }
.neutro   { color: #bbb; }

.sidebar-conteo {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}

.conteo-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: #243447;
  border-radius: 8px;
  padding: 10px 6px;
  gap: 4px;
}

.conteo-num {
  font-size: 1.4rem;
  font-weight: bold;
  color: #e8f0f6;
}

.conteo-label {
  font-size: 0.72rem;
  color: #8aaabb;
  text-transform: uppercase;
  text-align: center;
}

.slot.seleccionado {
  border-color: #222;
  background: #e8e8e8;
  box-shadow: inset 0 0 0 1px #222;
}

.slot-nombre { font-weight: bold; }

.contenido {
  flex: 1;
  padding: 28px 32px;
  overflow-y: auto;
  height: 100%;
}

.bienvenida { margin-bottom: 24px; }

.bienvenida h1 {
  font-size: 1.6rem;
  margin-bottom: 4px;
}

.bienvenida p {
  color: #666;
  font-size: 0.9rem;
}

.acciones {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 14px;
}

.accion-card {
  border: 2px solid #e0e0e0;
  border-radius: 14px;
  padding: 18px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.accion-card:hover {
  border-color: #aaa;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

.accion-icono { font-size: 1.6rem; }

.accion-card h2 {
  font-size: 1rem;
  margin: 0;
}

.accion-card p {
  font-size: 0.82rem;
  color: #666;
  margin: 0;
  flex: 1;
}

.accion-card button {
  margin-top: 8px;
  padding: 8px;
  background: #222;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.85rem;
  cursor: pointer;
  transition: background 0.2s;
}

.accion-card button:hover { background: #444; }

.btn-volver {
  display: block;
  margin: 0 auto 20px;
  padding: 8px 18px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #555;
  transition: border-color 0.2s, color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }

.proximamente {
  color: #aaa;
  font-size: 1rem;
}
</style>
