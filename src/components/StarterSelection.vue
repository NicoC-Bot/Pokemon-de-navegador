<script setup>
import { ref } from 'vue'
import { pokemonesWild } from '../data/pokemonesExploracion.js'

const props = defineProps({
  entrenador: Object,
})

const emit = defineEmits(['compañero-elegido'])

const pokemonElegido = ref(null)

function comenzarAventura() {
  emit('compañero-elegido', pokemonElegido.value)
}

function habsDeId(id) {
  return pokemonesWild.find(p => p.id === id)?.habilidades ?? []
}

const iniciales = [
  {
    id: 'embrix',
    nombre: 'Embrix',
    elemento: '🔥 Fuego',
    colorElemento: '#e63946',
    descripcion: 'Ágil y agresivo. Golpea fuerte desde el primer turno.',
    rareza: 'comun',
    habilidades: habsDeId('embrix'),
    stats: {
      HP: 40,
      Ataque: 45,
      Defensa: 30,
      Velocidad: 50,
      'Ataque Esp.': 25,
      'Defensa Esp.': 25,
    }
  },
  {
    id: 'aquell',
    nombre: 'Aquell',
    elemento: '💧 Agua',
    colorElemento: '#4895ef',
    descripcion: 'Resistente y constante. Difícil de derribar en combate.',
    rareza: 'comun',
    habilidades: habsDeId('aquell'),
    stats: {
      HP: 55,
      Ataque: 30,
      Defensa: 45,
      Velocidad: 30,
      'Ataque Esp.': 35,
      'Defensa Esp.': 40,
    }
  },
  {
    id: 'verdun',
    nombre: 'Verdún',
    elemento: '🌿 Planta',
    colorElemento: '#2dc653',
    descripcion: 'Equilibrado y paciente. Ideal para aprender a combatir.',
    rareza: 'comun',
    habilidades: habsDeId('verdun'),
    stats: {
      HP: 50,
      Ataque: 35,
      Defensa: 50,
      Velocidad: 25,
      'Ataque Esp.': 30,
      'Defensa Esp.': 35,
    }
  },
]
</script>

<template>
  <div class="starter-selection">

    <!-- Card del entrenador -->
    <div class="trainer-card" :style="{ borderColor: entrenador.clase.color }">
      <div class="trainer-header" :style="{ backgroundColor: entrenador.clase.color }">
        <span class="trainer-icono">🧢</span>
        <div>
          <h2>{{ entrenador.nombre }}</h2>
          <span class="trainer-clase">{{ entrenador.clase.label }}</span>
        </div>
      </div>

      <div class="trainer-stats">
        <div v-for="stat in entrenador.clase.stats" class="stat-fila">
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

    <!-- Pokémon iniciales -->
    <h3 class="titulo-iniciales">Elige tu Pokémon inicial</h3>
    <p class="subtitulo-iniciales">Este será el primero en acompañarte en tu aventura</p>

    <div class="iniciales-grid">
      <div
        v-for="pokemon in iniciales"
        class="pokemon-card"
        :style="{ borderColor: pokemon.colorElemento }"
      >
        <div class="pokemon-header" :style="{ backgroundColor: pokemon.colorElemento }">
          <span class="pokemon-nombre">{{ pokemon.nombre }}</span>
          <span class="pokemon-elemento">{{ pokemon.elemento }}</span>
        </div>

        <p class="pokemon-desc">{{ pokemon.descripcion }}</p>

        <div class="pokemon-stats">
          <div v-for="(valor, nombre) in pokemon.stats" class="pstat-fila">
            <span class="pstat-nombre">{{ nombre }}</span>
            <span class="pstat-valor">{{ valor }}</span>
          </div>
        </div>

        <button
          class="btn-elegir"
          :style="{ backgroundColor: pokemon.colorElemento }"
          @click="pokemonElegido = pokemon"
        >
          {{ pokemonElegido && pokemonElegido.id === pokemon.id ? '✓ Elegido' : 'Elegir a ' + pokemon.nombre }}
        </button>
      </div>
    </div>

    <div class="aventura-wrap">
      <button
        class="btn-aventura"
        :disabled="pokemonElegido === null"
        :class="{ activo: pokemonElegido !== null }"
        :style="pokemonElegido ? { backgroundColor: pokemonElegido.colorElemento } : {}"
        @click="comenzarAventura"
      >
        ¡Comenzar aventura!
      </button>
      <p v-if="pokemonElegido === null" class="aventura-hint">
        Elige un compañero para continuar
      </p>
    </div>

  </div>
</template>

<style scoped>
.starter-selection {
  max-width: 860px;
  margin: 48px auto;
  font-family: sans-serif;
  padding: 0 16px;
}

/* Card del entrenador */
.trainer-card {
  border: 2px solid #ccc;
  border-radius: 14px;
  overflow: hidden;
  margin-bottom: 48px;
}

.trainer-header {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 24px;
  color: white;
}

.trainer-icono {
  font-size: 2.5rem;
}

.trainer-header h2 {
  margin: 0;
  font-size: 1.6rem;
}

.trainer-clase {
  font-size: 0.95rem;
  opacity: 0.9;
}

.trainer-stats {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 6px;
  padding: 16px 24px;
}

.stat-fila {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 4px 8px;
  background: #f9f9f9;
  border-radius: 6px;
  font-size: 0.85rem;
}

.stat-nombre { color: #333; }
.stat-valor  { font-weight: bold; }
.positivo    { color: #2dc653; }
.negativo    { color: #e63946; }
.neutro      { color: #aaa; }

/* Títulos */
.titulo-iniciales {
  font-size: 1.4rem;
  text-align: center;
  margin-bottom: 4px;
}

.subtitulo-iniciales {
  text-align: center;
  color: #777;
  margin-bottom: 24px;
  font-size: 0.9rem;
}

/* Grid de iniciales */
.iniciales-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 20px;
}

.pokemon-card {
  border: 2px solid #ccc;
  border-radius: 14px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.pokemon-header {
  padding: 14px 16px;
  color: white;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pokemon-nombre {
  font-size: 1.3rem;
  font-weight: bold;
}

.pokemon-elemento {
  font-size: 0.85rem;
  opacity: 0.9;
}

.pokemon-desc {
  font-size: 0.82rem;
  color: #555;
  padding: 10px 14px;
  margin: 0;
}

.pokemon-stats {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 0 14px 10px;
  flex: 1;
}

.pstat-fila {
  display: flex;
  justify-content: space-between;
  font-size: 0.82rem;
  padding: 3px 6px;
  background: #f9f9f9;
  border-radius: 4px;
}

.pstat-nombre { color: #444; }
.pstat-valor  { font-weight: bold; color: #222; }

.btn-elegir {
  margin: 12px 14px 14px;
  padding: 10px;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 0.9rem;
  cursor: pointer;
  transition: filter 0.2s, transform 0.1s;
}

.btn-elegir:hover {
  filter: brightness(0.9);
  transform: scale(1.02);
}

.aventura-wrap {
  text-align: center;
  margin-top: 40px;
}

.btn-aventura {
  padding: 14px 48px;
  font-size: 1.1rem;
  font-weight: bold;
  color: white;
  border: none;
  border-radius: 12px;
  cursor: not-allowed;
  background-color: #ccc;
  transition: background-color 0.3s, transform 0.1s, filter 0.2s;
}

.btn-aventura.activo {
  cursor: pointer;
}

.btn-aventura.activo:hover {
  filter: brightness(0.9);
  transform: scale(1.02);
}

.aventura-hint {
  margin-top: 10px;
  color: #aaa;
  font-size: 0.88rem;
}
</style>
