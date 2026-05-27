// Aplica los bonos de la clase del entrenador a los stats base del Pokémon
function calcularStatsFinal(statsBase, claseStats) {
  const resultado = {}

  for (const nombreStat in statsBase) {
    const valorBase = statsBase[nombreStat]
    const statClase = claseStats.find(s => s.nombre === nombreStat)
    const bonus = statClase !== undefined ? statClase.valor : 0
    resultado[nombreStat] = Math.round(valorBase * (1 + bonus / 100))
  }

  return resultado
}

// Devuelve cuántos puntos gana un stat por entrenamiento según el nivel
function calcularGananciaEntrenamiento(nivel) {
  if (nivel <= 15) return 5
  if (nivel <= 35) return 3
  return 1
}

// Prepara un Pokémon recién elegido para el juego con todo lo necesario
function prepararPokemon(pokemon, clase) {
  const statsFinal = calcularStatsFinal(pokemon.stats, clase.stats)

  return {
    ...pokemon,
    uid:            Date.now() + '-' + Math.random(),
    rareza:         pokemon.rareza ?? 'comun',
    nivel:          1,
    xp:             0,
    pe:             100,
    hpActual:       statsFinal.HP,
    nivelAscension: 0,
    stats:          statsFinal,
    statsBase:      { ...pokemon.stats },
  }
}

function xpParaNivel(nivel) {
  return Math.floor(100 * Math.pow(nivel, 1.4))
}

export { calcularStatsFinal, calcularGananciaEntrenamiento, prepararPokemon, xpParaNivel }
