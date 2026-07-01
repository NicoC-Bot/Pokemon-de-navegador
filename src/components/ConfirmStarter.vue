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
  max-width: 560px;
  margin: 48px auto;
  font-family: sans-serif;
  padding: 0 16px;
}

h1 {
  font-size: 1.8rem;
  text-align: center;
  margin-bottom: 8px;
}

.subtitulo {
  text-align: center;
  color: #555;
  font-size: 0.95rem;
  margin-bottom: 32px;
}

.card {
  border: 2px solid #ccc;
  border-radius: 14px;
  overflow: hidden;
}

.card-header {
  padding: 16px 24px;
  color: white;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.pokemon-nombre {
  font-size: 1.5rem;
  font-weight: bold;
}

.pokemon-elemento {
  font-size: 0.9rem;
  opacity: 0.9;
}

.stats-tabla {
  padding: 16px 20px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.fila-header {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  font-size: 0.8rem;
  font-weight: bold;
  color: #999;
  padding: 0 8px;
  text-transform: uppercase;
}

.fila-stat {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  align-items: center;
  padding: 6px 8px;
  background: #f9f9f9;
  border-radius: 6px;
  font-size: 0.9rem;
}

.stat-nombre { color: #333; }
.stat-base   { color: #666; }
.stat-bonus  { font-weight: bold; }
.stat-final  { font-weight: bold; color: #222; }

.positivo { color: #2dc653; }
.negativo { color: #e63946; }
.neutro   { color: #aaa; }

.acciones {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 32px;
}

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

.btn-confirmar {
  padding: 12px 48px;
  font-size: 1rem;
  font-weight: bold;
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  transition: filter 0.2s, transform 0.1s;
}

.btn-confirmar:hover {
  filter: brightness(0.9);
  transform: scale(1.02);
}
</style>
