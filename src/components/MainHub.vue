<script setup>
import { ref } from 'vue'
import TrainView from './TrainView.vue'
import RestView  from './RestView.vue'

const props = defineProps({
  entrenador:       Object,
  equipo:           Array,
  ultimoDescanso:   String,
  descansandoHasta: Number,
  peDescanso:       Number,
})

const emit = defineEmits(['actualizar-pokemon', 'iniciar-descanso', 'completar-descanso'])

const vistaActual = ref('hub')

function actualizarPokemon(index, datos) {
  emit('actualizar-pokemon', { index, datos })
}
</script>

<template>
  <div class="hub">

    <!-- Sidebar izquierda -->
    <aside class="sidebar">

      <div class="trainer-card" :style="{ borderColor: entrenador.clase.color }">
        <div class="trainer-header" :style="{ backgroundColor: entrenador.clase.color }">
          <span class="trainer-icono">🧢</span>
          <div>
            <h2>{{ entrenador.nombre }}</h2>
            <span class="trainer-clase">{{ entrenador.clase.label }}</span>
          </div>
        </div>
      </div>

      <div class="equipo">
        <h3>Equipo</h3>
        <div class="slots">
          <div
            v-for="(slot, index) in 6"
            class="slot"
            :class="{ ocupado: equipo[index] !== undefined }"
          >
            <span v-if="equipo[index]" class="slot-nombre">{{ equipo[index].nombre }}</span>
            <span v-else class="slot-vacio">—</span>
          </div>
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
        </div>
      </div>

      <!-- Vista: Entrenar -->
      <div v-else-if="vistaActual === 'entrenar'">
        <TrainView
          :pokemon="equipo[0]"
          :clase-stats="entrenador.clase.stats"
          @actualizar="datos => actualizarPokemon(0, datos)"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Explorar (próximamente) -->
      <div v-else-if="vistaActual === 'explorar'" class="proximamente">
        <button class="btn-volver" @click="vistaActual = 'hub'">← Volver</button>
        <p>🔍 Explorar — próximamente</p>
      </div>

      <!-- Vista: Equipo (próximamente) -->
      <div v-else-if="vistaActual === 'equipo'" class="proximamente">
        <button class="btn-volver" @click="vistaActual = 'hub'">← Volver</button>
        <p>📋 Equipo — próximamente</p>
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

    </main>

  </div>
</template>

<style scoped>
.hub {
  display: flex;
  min-height: 100vh;
  font-family: sans-serif;
}

.sidebar {
  width: 240px;
  min-height: 100vh;
  background: #f4f4f4;
  border-right: 1px solid #e0e0e0;
  padding: 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 24px;
  flex-shrink: 0;
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

.equipo h3 {
  font-size: 0.9rem;
  font-weight: bold;
  color: #666;
  text-transform: uppercase;
  margin-bottom: 10px;
}

.slots {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.slot {
  padding: 8px 12px;
  border: 2px dashed #ccc;
  border-radius: 8px;
  font-size: 0.85rem;
  color: #aaa;
  text-align: center;
  transition: border-color 0.2s;
}

.slot.ocupado {
  border-style: solid;
  border-color: #888;
  color: #222;
}

.slot-nombre { font-weight: bold; }

.contenido {
  flex: 1;
  padding: 48px 40px;
}

.bienvenida { margin-bottom: 48px; }

.bienvenida h1 {
  font-size: 2rem;
  margin-bottom: 6px;
}

.bienvenida p {
  color: #666;
  font-size: 1rem;
}

.acciones {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20px;
}

.accion-card {
  border: 2px solid #e0e0e0;
  border-radius: 14px;
  padding: 28px 24px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.accion-card:hover {
  border-color: #aaa;
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

.accion-icono { font-size: 2rem; }

.accion-card h2 {
  font-size: 1.2rem;
  margin: 0;
}

.accion-card p {
  font-size: 0.88rem;
  color: #666;
  margin: 0;
  flex: 1;
}

.accion-card button {
  margin-top: 12px;
  padding: 10px;
  background: #222;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: background 0.2s;
}

.accion-card button:hover { background: #444; }

.btn-volver {
  margin-bottom: 24px;
  padding: 8px 16px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover {
  border-color: #888;
  color: #222;
}

.proximamente {
  color: #aaa;
  font-size: 1rem;
}
</style>
