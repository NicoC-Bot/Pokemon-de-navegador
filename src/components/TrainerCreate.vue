<script setup>
import { ref } from 'vue'

const emit = defineEmits(['entrenador-creado'])

const nombre = ref('')
const claseElegida = ref(null)

const guiaStats = [
  { icono: '⚔️',  nombre: 'Ataque',         descripcion: 'Potencia de los golpes físicos del Pokémon.' },
  { icono: '🛡️',  nombre: 'Defensa',         descripcion: 'Resistencia ante golpes físicos recibidos.' },
  { icono: '❤️',  nombre: 'HP',              descripcion: 'Puntos de vida totales en combate.' },
  { icono: '💨',  nombre: 'Velocidad',        descripcion: 'Determina quién ataca primero en cada turno.' },
  { icono: '✨',  nombre: 'Ataque Esp.',      descripcion: 'Potencia de los ataques elementales y mágicos.' },
  { icono: '🔮',  nombre: 'Defensa Esp.',     descripcion: 'Resistencia ante ataques elementales recibidos.' },
  { icono: '💥',  nombre: 'Daño Físico',      descripcion: 'Multiplicador de daño al usar movimientos físicos.' },
  { icono: '🌀',  nombre: 'Daño Elemental',   descripcion: 'Multiplicador de daño al usar movimientos elementales.' },
  { icono: '🌫️',  nombre: 'Evasión',          descripcion: 'Probabilidad de esquivar ataques del rival.' },
]

const clases = [
  {
    id: 'fuego',
    label: '🔥 Fuego',
    color: '#e63946',
    // descripcion: 'Atacante físico puro. Alto daño directo, pero frágil y sin poder especial.',
    descripcion: 'Aumenta el ataque, velocidad y daño físico de tus Pokémon. Penaliza su defensa, ataque especial, daño elemental y evasión.',
    stats: [
      { nombre: 'Ataque',        valor: +20 },
      { nombre: 'Velocidad',     valor:  +5 },
      { nombre: 'Daño Físico',   valor: +20 },
      { nombre: 'Ataque Esp.',   valor: -10 },
      { nombre: 'Defensa',       valor: -15 },
      { nombre: 'Daño Elemental',valor: -10 },
      { nombre: 'Evasión',       valor:  -5 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'agua',
    label: '💧 Agua',
    color: '#4895ef',
    // descripcion: 'Tanque de vida. Se regenera constantemente en batalla, difícil de desgastar.',
    descripcion: 'Aumenta la vida, defensa especial, daño elemental y evasión de tus Pokémon. Penaliza su ataque, daño físico y velocidad.',
    stats: [
      { nombre: 'HP',            valor: +20 },
      { nombre: 'Defensa Esp.',  valor: +10 },
      { nombre: 'Daño Elemental',valor: +15 },
      { nombre: 'Evasión',       valor: +10 },
      { nombre: 'Ataque',        valor: -10 },
      { nombre: 'Daño Físico',   valor:  -5 },
      { nombre: 'Velocidad',     valor:  -5 },
      { nombre: 'Defensa',       valor:   0 },
      { nombre: 'Ataque Esp.',   valor:   0 },
    ]
  },
  {
    id: 'planta',
    label: '🌿 Planta',
    color: '#2dc653',
    // descripcion: 'Tanque de armadura. Reduce el daño recibido con su defensa física brutal.',
    descripcion: 'Maximiza la defensa de tus Pokémon y mejora levemente el daño elemental. Penaliza su velocidad, ataque especial y evasión.',
    stats: [
      { nombre: 'Defensa',       valor: +25 },
      { nombre: 'Daño Elemental',valor:  +5 },
      { nombre: 'Velocidad',     valor: -15 },
      { nombre: 'Ataque Esp.',   valor:  -5 },
      { nombre: 'Evasión',       valor:  -5 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Ataque',        valor:   0 },
      { nombre: 'Daño Físico',   valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'electro',
    label: '⚡ Eléctrico',
    color: '#f4d35e',
    // descripcion: 'Velocidad extrema. Siempre ataca primero, pero sus Pokémon son muy frágiles.',
    descripcion: 'Dispara la velocidad, daño físico y evasión de tus Pokémon, y mejora su ataque. Penaliza fuertemente su defensa y vida.',
    stats: [
      { nombre: 'Velocidad',     valor: +25 },
      { nombre: 'Ataque',        valor:  +5 },
      { nombre: 'Daño Físico',   valor: +15 },
      { nombre: 'Evasión',       valor: +25 },
      { nombre: 'Defensa',       valor: -15 },
      { nombre: 'HP',            valor: -10 },
      { nombre: 'Ataque Esp.',   valor:   0 },
      { nombre: 'Daño Elemental',valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'psiquico',
    label: '🧠 Psíquico',
    color: '#9b5de5',
    // descripcion: 'Especialista en ataques mágicos. Poderoso mentalmente, inútil en combate físico.',
    descripcion: 'Eleva el ataque especial, defensa especial, daño elemental y evasión de tus Pokémon. Penaliza fuertemente su ataque, defensa y daño físico.',
    stats: [
      { nombre: 'Ataque Esp.',   valor: +20 },
      { nombre: 'Defensa Esp.',  valor: +10 },
      { nombre: 'Daño Elemental',valor: +25 },
      { nombre: 'Evasión',       valor: +15 },
      { nombre: 'Ataque',        valor: -15 },
      { nombre: 'Defensa',       valor:  -5 },
      { nombre: 'Daño Físico',   valor: -20 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Velocidad',     valor:   0 },
    ]
  },
  {
    id: 'roca',
    label: '🛡️ Roca',
    color: '#8d6e63',
    // descripcion: 'Fortaleza física. Defensa y vida brutales, pero lento y sin poder especial.',
    descripcion: 'Maximiza la defensa y vida de tus Pokémon, y mejora su daño físico. Penaliza fuertemente su velocidad, evasión, ataque especial y daño elemental.',
    stats: [
      { nombre: 'Defensa',       valor: +25 },
      { nombre: 'HP',            valor: +10 },
      { nombre: 'Daño Físico',   valor: +10 },
      { nombre: 'Velocidad',     valor: -20 },
      { nombre: 'Ataque Esp.',   valor: -15 },
      { nombre: 'Daño Elemental',valor: -15 },
      { nombre: 'Evasión',       valor: -20 },
      { nombre: 'Ataque',        valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
]

function crearEntrenador() {
  if (nombre.value === '') {
    alert('Debes ingresar un nombre')
    return
  }
  if (claseElegida.value === null) {
    alert('Debes elegir una clase')
    return
  }

  emit('entrenador-creado', {
    nombre: nombre.value,
    clase: claseElegida.value,
  })
}
</script>

<template>
  <div class="crear-entrenador">
    <h1>Crea tu Entrenador</h1>

    <div class="campo-nombre">
      <label>Nombre del entrenador</label>
      <input v-model="nombre" type="text" placeholder="Ej: Ash" />
    </div>

    <div class="selector-clase">

      <!-- Columna izquierda: lista de clases -->
      <div class="lista-clases">
        <label>Elige tu clase</label>
        <div
          v-for="clase in clases"
          class="clase-item"
          :class="{ seleccionada: claseElegida && claseElegida.id === clase.id }"
          :style="claseElegida && claseElegida.id === clase.id ? { borderColor: clase.color, color: clase.color } : {}"
          @click="claseElegida = clase"
        >
          {{ clase.label }}
        </div>
      </div>

      <!-- Panel derecho: detalle de la clase elegida -->
      <Transition name="detalle">
        <div
          v-if="claseElegida"
          class="detalle-clase"
          :style="{ borderColor: claseElegida.color }"
        >
          <h2 :style="{ color: claseElegida.color }">{{ claseElegida.label }}</h2>
          <p class="clase-desc">{{ claseElegida.descripcion }}</p>

          <div class="stats">
            <div v-for="stat in claseElegida.stats" class="stat-fila">
              <span class="stat-nombre">{{ stat.nombre }}</span>
              <span
                class="stat-valor"
                :class="stat.valor > 0 ? 'positivo' : stat.valor < 0 ? 'negativo' : 'neutro'"
              >
                {{ stat.valor > 0 ? '+' + stat.valor : stat.valor === 0 ? '—' : stat.valor }}%
              </span>
            </div>
          </div>
        </div>

        <div v-else class="detalle-vacio">
          <span>👈 Selecciona una clase para ver sus estadísticas</span>
        </div>
      </Transition>

    </div>

    <!-- Guía de stats -->
    <div class="guia-stats">
      <h3>¿Qué significa cada stat?</h3>
      <div class="guia-grid">
        <div v-for="guia in guiaStats" class="guia-card">
          <span class="guia-icono">{{ guia.icono }}</span>
          <div>
            <span class="guia-nombre">{{ guia.nombre }}</span>
            <span class="guia-desc">{{ guia.descripcion }}</span>
          </div>
        </div>
      </div>
    </div>

    <button
      @click="crearEntrenador"
      :style="claseElegida ? { backgroundColor: claseElegida.color } : {}"
    >
      ¡Comenzar aventura!
    </button>
  </div>
</template>

<style scoped>
.crear-entrenador {
  max-width: 760px;
  margin: 48px auto;
  font-family: sans-serif;
  padding: 0 16px;
}

h1 {
  font-size: 2rem;
  text-align: center;
  margin-bottom: 28px;
}

.campo-nombre {
  margin-bottom: 28px;
}

label {
  display: block;
  font-weight: bold;
  margin-bottom: 8px;
}

input {
  width: 100%;
  padding: 10px;
  font-size: 1rem;
  border: 2px solid #ccc;
  border-radius: 8px;
  box-sizing: border-box;
}

.selector-clase {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  min-height: 300px;
}

.lista-clases {
  display: flex;
  flex-direction: column;
  gap: 8px;
  min-width: 170px;
}

.clase-item {
  padding: 10px 14px;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
  transition: border-color 0.2s, color 0.2s, background-color 0.2s;
}

.clase-item:hover {
  background-color: #f5f5f5;
}

.clase-item.seleccionada {
  background-color: #fafafa;
}

.detalle-clase {
  flex: 1;
  border: 2px solid #ccc;
  border-radius: 12px;
  padding: 20px 24px;
}

.detalle-vacio {
  flex: 1;
  border: 2px dashed #ccc;
  border-radius: 12px;
  padding: 20px 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #aaa;
  font-size: 0.95rem;
}

h2 {
  margin: 0 0 8px 0;
  font-size: 1.4rem;
}

.clase-desc {
  color: #555;
  margin: 0 0 16px 0;
  font-size: 0.9rem;
}

.stats {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.stat-fila {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 8px;
  background: #f9f9f9;
  border-radius: 6px;
  font-size: 0.9rem;
}

.stat-nombre { color: #333; }
.stat-valor  { font-weight: bold; }
.positivo    { color: #2dc653; }
.negativo    { color: #e63946; }
.neutro      { color: #aaa; }

/* Guía de stats */
.guia-stats {
  margin-top: 40px;
}

.guia-stats h3 {
  font-size: 1rem;
  font-weight: bold;
  margin-bottom: 12px;
  color: #444;
}

.guia-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
}

.guia-card {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  background: #f9f9f9;
  border: 1px solid #e0e0e0;
  border-radius: 10px;
  padding: 10px 12px;
}

.guia-icono {
  font-size: 1.4rem;
  line-height: 1;
  flex-shrink: 0;
}

.guia-card div {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.guia-nombre {
  font-weight: bold;
  font-size: 0.85rem;
  color: #222;
}

.guia-desc {
  font-size: 0.78rem;
  color: #666;
}

/* Botón */
button {
  display: block;
  margin: 28px auto 0;
  padding: 12px 40px;
  font-size: 1rem;
  background-color: #555;
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: background-color 0.3s, transform 0.1s;
}

button:hover {
  filter: brightness(0.9);
  transform: scale(1.02);
}

.detalle-enter-active,
.detalle-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}

.detalle-enter-from,
.detalle-leave-to {
  opacity: 0;
  transform: translateX(12px);
}
</style>
