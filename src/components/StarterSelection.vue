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
  max-width: 860px; /* ancho máximo del contenedor de selección */
  margin: 48px auto; /* centra horizontalmente con margen vertical */
  font-family: sans-serif; /* fuente sin serif para todo el componente */
  padding: 0 16px; /* padding lateral para pantallas pequeñas */
}

/* Card del entrenador */
.trainer-card {
  border: 2px solid #ccc; /* borde gris del card del entrenador */
  border-radius: 14px; /* esquinas redondeadas del card */
  overflow: hidden; /* recorta el header dentro del borde redondeado */
  margin-bottom: 48px; /* espacio bajo el card antes de los iniciales */
}

.trainer-header {
  display: flex; /* alinea icono y nombre en fila */
  align-items: center; /* centra verticalmente icono y texto */
  gap: 16px; /* espacio entre icono y datos del entrenador */
  padding: 16px 24px; /* relleno interno del encabezado */
  color: white; /* texto blanco sobre el fondo de color de clase */
}

.trainer-icono {
  font-size: 2.5rem; /* tamaño del emoji del entrenador */
}

.trainer-header h2 {
  margin: 0; /* elimina el margen por defecto del h2 */
  font-size: 1.6rem; /* tamaño del nombre del entrenador */
}

.trainer-clase {
  font-size: 0.95rem; /* tamaño del label de clase del entrenador */
  opacity: 0.9; /* leve transparencia en el label de clase */
}

.trainer-stats {
  display: grid; /* rejilla para organizar las filas de stats */
  grid-template-columns: 1fr 1fr 1fr; /* tres columnas iguales de stats */
  gap: 6px; /* espacio entre filas de stats */
  padding: 16px 24px; /* relleno interno de la sección de stats */
}

.stat-fila {
  display: flex; /* nombre y valor del stat en fila */
  justify-content: space-between; /* empuja nombre a la izq. y valor a la der. */
  align-items: center; /* alinea verticalmente nombre y valor */
  padding: 4px 8px; /* relleno interno de cada fila de stat */
  background: #f9f9f9; /* fondo gris muy claro de la fila */
  border-radius: 6px; /* esquinas redondeadas de la fila */
  font-size: 0.85rem; /* tamaño del texto de stats del entrenador */
}

.stat-nombre { color: #333; } /* color oscuro del nombre del stat */
.stat-valor  { font-weight: bold; } /* valor del stat en negrita */
.positivo    { color: #2dc653; } /* stat positivo en verde */
.negativo    { color: #e63946; } /* stat negativo en rojo */
.neutro      { color: #aaa; } /* stat sin modificador en gris */

/* Títulos */
.titulo-iniciales {
  font-size: 1.4rem; /* tamaño del título de selección de pokémon */
  text-align: center; /* centra el título */
  margin-bottom: 4px; /* pequeño espacio bajo el título */
}

.subtitulo-iniciales {
  text-align: center; /* centra el subtítulo */
  color: #777; /* color gris del texto del subtítulo */
  margin-bottom: 24px; /* espacio bajo el subtítulo antes del grid */
  font-size: 0.9rem; /* tamaño del texto del subtítulo */
}

/* Grid de iniciales */
.iniciales-grid {
  display: grid; /* rejilla para las tres tarjetas de pokémon */
  grid-template-columns: 1fr 1fr 1fr; /* tres columnas iguales para los pokémones */
  gap: 20px; /* espacio entre tarjetas de pokémon */
}

.pokemon-card {
  border: 2px solid #ccc; /* borde gris del card de pokémon */
  border-radius: 14px; /* esquinas redondeadas del card */
  overflow: hidden; /* recorta el header dentro del borde redondeado */
  display: flex; /* organiza las secciones del card en columna */
  flex-direction: column; /* apila secciones del card verticalmente */
}

.pokemon-header {
  padding: 14px 16px; /* relleno del encabezado del pokémon */
  color: white; /* texto blanco sobre el fondo de color */
  display: flex; /* apila nombre y tipo del pokémon */
  flex-direction: column; /* orienta nombre y tipo verticalmente */
  gap: 2px; /* mínimo espacio entre nombre y tipo */
}

.pokemon-nombre {
  font-size: 1.3rem; /* tamaño del nombre del pokémon */
  font-weight: bold; /* nombre del pokémon en negrita */
}

.pokemon-elemento {
  font-size: 0.85rem; /* tamaño del texto de tipo o elemento */
  opacity: 0.9; /* leve transparencia en el tipo del pokémon */
}

.pokemon-desc {
  font-size: 0.82rem; /* tamaño de la descripción del pokémon */
  color: #555; /* color gris oscuro de la descripción */
  padding: 10px 14px; /* relleno de la descripción */
  margin: 0; /* elimina el margen por defecto del párrafo */
}

.pokemon-stats {
  display: flex; /* apila las filas de stats en columna */
  flex-direction: column; /* orienta las filas verticalmente */
  gap: 4px; /* espacio entre filas de stats del pokémon */
  padding: 0 14px 10px; /* relleno lateral e inferior de los stats */
  flex: 1; /* ocupa el espacio restante del card */
}

.pstat-fila {
  display: flex; /* nombre y valor en fila */
  justify-content: space-between; /* empuja nombre a izq. y valor a der. */
  font-size: 0.82rem; /* tamaño del texto de stats del pokémon */
  padding: 3px 6px; /* relleno interno de la fila de stat */
  background: #f9f9f9; /* fondo gris muy claro de la fila */
  border-radius: 4px; /* esquinas redondeadas de la fila */
}

.pstat-nombre { color: #444; } /* color del nombre de stat del pokémon */
.pstat-valor  { font-weight: bold; color: #222; } /* valor en negrita y color oscuro */

.btn-elegir {
  margin: 12px 14px 14px; /* margen exterior del botón de selección */
  padding: 10px; /* relleno interno del botón */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde visible en el botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  font-size: 0.9rem; /* tamaño del texto del botón */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  transition: filter 0.2s, transform 0.1s; /* animación suave al hacer hover */
}

.btn-elegir:hover {
  filter: brightness(0.9); /* oscurece levemente el botón al hover */
  transform: scale(1.02); /* agranda levemente el botón al hover */
}

.aventura-wrap {
  text-align: center; /* centra el botón y el mensaje de pista */
  margin-top: 40px; /* espacio superior del bloque de inicio */
}

.btn-aventura {
  padding: 14px 48px; /* relleno generoso del botón principal */
  font-size: 1.1rem; /* tamaño del texto del botón de aventura */
  font-weight: bold; /* texto del botón en negrita */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde en el botón */
  border-radius: 12px; /* esquinas muy redondeadas del botón */
  cursor: not-allowed; /* cursor de prohibido cuando está deshabilitado */
  background-color: #ccc; /* fondo gris cuando no hay pokémon elegido */
  transition: background-color 0.3s, transform 0.1s, filter 0.2s; /* transiciones suaves de estado */
}

.btn-aventura.activo {
  cursor: pointer; /* cursor de mano cuando hay pokémon elegido */
}

.btn-aventura.activo:hover {
  filter: brightness(0.9); /* oscurece el botón activo al hacer hover */
  transform: scale(1.02); /* agranda levemente el botón activo al hover */
}

.aventura-hint {
  margin-top: 10px; /* espacio sobre el texto de pista */
  color: #aaa; /* color gris claro del mensaje de pista */
  font-size: 0.88rem; /* tamaño pequeño del texto de pista */
}
</style>
