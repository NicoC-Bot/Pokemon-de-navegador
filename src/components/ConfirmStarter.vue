<script setup>
const props = defineProps({
  entrenador: Object,
  compañero: Object,
})

const emit = defineEmits(['confirmar', 'volver'])

// Los stats del pokémon que también tienen bonificación del entrenador
const statsAplicables = ['HP', 'Ataque', 'Defensa', 'Velocidad', 'Ataque Esp.', 'Defensa Esp.']

function obtenerBonus(nombreStat) {
  const stat = props.entrenador.clase.stats.find(s => s.nombre === nombreStat)
  if (stat === undefined) {
    return 0
  }
  return stat.valor
}

function calcularFinal(nombreStat, valorBase) {
  const bonus = obtenerBonus(nombreStat)
  return Math.round(valorBase * (1 + bonus / 100))
}
</script>

<template>
  <div class="confirm-starter">
    <button class="btn-volver" @click="emit('volver')">← Volver a seleccionar</button>

    <h1>Tu compañero está listo</h1>
    <p class="subtitulo">
      Revisa cómo afecta tu clase <strong :style="{ color: entrenador.clase.color }">{{ entrenador.clase.label }}</strong> a los stats de {{ compañero.nombre }}
    </p>

    <div class="card" :style="{ borderColor: compañero.colorElemento }">

      <div class="card-header" :style="{ backgroundColor: compañero.colorElemento }">
        <span class="pokemon-nombre">{{ compañero.nombre }}</span>
        <span class="pokemon-elemento">{{ compañero.elemento }}</span>
      </div>

      <div class="stats-tabla">

        <div class="fila-header">
          <span>Stat</span>
          <span>Base</span>
          <span>Bono</span>
          <span>Final</span>
        </div>

        <div
          v-for="(valorBase, nombreStat) in compañero.stats"
          class="fila-stat"
        >
          <span class="stat-nombre">{{ nombreStat }}</span>
          <span class="stat-base">{{ valorBase }}</span>
          <span
            class="stat-bonus"
            :class="obtenerBonus(nombreStat) > 0 ? 'positivo' : obtenerBonus(nombreStat) < 0 ? 'negativo' : 'neutro'"
          >
            {{ obtenerBonus(nombreStat) > 0 ? '+' + obtenerBonus(nombreStat) : obtenerBonus(nombreStat) === 0 ? '—' : obtenerBonus(nombreStat) }}%
          </span>
          <span
            class="stat-final"
            :class="obtenerBonus(nombreStat) > 0 ? 'positivo' : obtenerBonus(nombreStat) < 0 ? 'negativo' : ''"
          >
            {{ calcularFinal(nombreStat, valorBase) }}
          </span>
        </div>

      </div>
    </div>

    <div class="acciones">
      <button
        class="btn-confirmar"
        :style="{ backgroundColor: compañero.colorElemento }"
        @click="emit('confirmar')"
      >
        Confirmar
      </button>
    </div>

  </div>
</template>

<style scoped>
.confirm-starter {
  max-width: 560px; /* ancho máximo de la pantalla de confirmación */
  margin: 48px auto; /* centra horizontalmente con margen vertical */
  font-family: sans-serif; /* fuente sin serif para todo el componente */
  padding: 0 16px; /* padding lateral para pantallas pequeñas */
}

h1 {
  font-size: 1.8rem; /* tamaño del título principal de confirmación */
  text-align: center; /* centra el título */
  margin-bottom: 8px; /* pequeño espacio bajo el título */
}

.subtitulo {
  text-align: center; /* centra el subtítulo descriptivo */
  color: #555; /* color gris medio del subtítulo */
  font-size: 0.95rem; /* tamaño del texto del subtítulo */
  margin-bottom: 32px; /* espacio bajo el subtítulo antes del card */
}

.card {
  border: 2px solid #ccc; /* borde del card del pokémon elegido */
  border-radius: 14px; /* esquinas redondeadas del card */
  overflow: hidden; /* recorta el header dentro del borde redondeado */
}

.card-header {
  padding: 16px 24px; /* relleno del encabezado del card */
  color: white; /* texto blanco sobre el fondo de color del pokémon */
  display: flex; /* apila nombre y tipo del pokémon */
  flex-direction: column; /* orienta nombre y tipo verticalmente */
  gap: 2px; /* mínimo espacio entre nombre y tipo */
}

.pokemon-nombre {
  font-size: 1.5rem; /* tamaño del nombre del pokémon elegido */
  font-weight: bold; /* nombre en negrita */
}

.pokemon-elemento {
  font-size: 0.9rem; /* tamaño del tipo o elemento del pokémon */
  opacity: 0.9; /* leve transparencia en el tipo */
}

.stats-tabla {
  padding: 16px 20px; /* relleno de la tabla de stats */
  display: flex; /* apila filas de stats en columna */
  flex-direction: column; /* orienta las filas verticalmente */
  gap: 6px; /* espacio entre filas de stats */
}

.fila-header {
  display: grid; /* rejilla de cuatro columnas para los encabezados */
  grid-template-columns: 2fr 1fr 1fr 1fr; /* columna de nombre más ancha que valores */
  font-size: 0.8rem; /* tamaño pequeño de los encabezados */
  font-weight: bold; /* encabezados en negrita */
  color: #999; /* color gris claro de los encabezados */
  padding: 0 8px; /* relleno lateral de la fila encabezado */
  text-transform: uppercase; /* encabezados en mayúsculas */
}

.fila-stat {
  display: grid; /* rejilla para las columnas de cada stat */
  grid-template-columns: 2fr 1fr 1fr 1fr; /* misma proporción que el encabezado */
  align-items: center; /* alinea verticalmente el contenido de las celdas */
  padding: 6px 8px; /* relleno interno de cada fila de stat */
  background: #f9f9f9; /* fondo gris claro de cada fila */
  border-radius: 6px; /* esquinas redondeadas de la fila */
  font-size: 0.9rem; /* tamaño del texto de la fila */
}

.stat-nombre { color: #333; } /* color oscuro del nombre de stat */
.stat-base   { color: #666; } /* color gris del valor base del stat */
.stat-bonus  { font-weight: bold; } /* bono del entrenador en negrita */
.stat-final  { font-weight: bold; color: #222; } /* valor final en negrita y oscuro */

.positivo { color: #2dc653; } /* bono positivo en verde */
.negativo { color: #e63946; } /* bono negativo en rojo */
.neutro   { color: #aaa; } /* stat sin bono en gris */

.acciones {
  display: flex; /* alinea el botón de confirmación en fila */
  justify-content: center; /* centra el botón de confirmación */
  gap: 12px; /* espacio entre posibles botones de acción */
  margin-top: 32px; /* espacio sobre la fila de acciones */
}

.btn-volver {
  display: block; /* permite usar margin auto para centrar */
  margin: 0 auto 20px; /* centra el botón y agrega espacio inferior */
  padding: 8px 18px; /* relleno del botón de volver */
  background: white; /* fondo blanco del botón */
  border: 2px solid #ccc; /* borde gris del botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  font-size: 0.88rem; /* tamaño del texto del botón */
  color: #555; /* color gris del texto del botón */
  transition: border-color 0.2s, color 0.2s; /* animación suave al hacer hover */
}

.btn-volver:hover { border-color: #888; color: #222; } /* oscurece borde y texto al hover */

.btn-confirmar {
  padding: 12px 48px; /* relleno generoso del botón confirmar */
  font-size: 1rem; /* tamaño del texto del botón */
  font-weight: bold; /* texto del botón en negrita */
  color: white; /* texto blanco del botón */
  border: none; /* sin borde en el botón */
  border-radius: 10px; /* esquinas redondeadas del botón */
  cursor: pointer; /* cursor de mano en el botón */
  transition: filter 0.2s, transform 0.1s; /* animación suave al hacer hover */
}

.btn-confirmar:hover {
  filter: brightness(0.9); /* oscurece el botón al hacer hover */
  transform: scale(1.02); /* agranda levemente el botón al hover */
}
</style>
