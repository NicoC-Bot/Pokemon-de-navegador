/**
 * Proyecta los próximos `n` turnos desde el estado actual de los gauges ATB.
 * Retorna un array de { nombre, equipo }.
 */
export function proyectarCola({ gaugeA, velA, nombreA, gaugeB, velB, nombreB, n = 10 }) {
  const slots = []
  let gA = gaugeA, gB = gaugeB
  for (let tick = 0; slots.length < n && tick < 1000; tick++) {
    gA += velA; gB += velB
    if (gA >= 100 && gB >= 100) {
      if (velA >= velB) {
        slots.push({ nombre: nombreA, equipo: 'jugador' }); gA -= 100
        if (slots.length < n) { slots.push({ nombre: nombreB, equipo: 'oponente' }); gB -= 100 }
      } else {
        slots.push({ nombre: nombreB, equipo: 'oponente' }); gB -= 100
        if (slots.length < n) { slots.push({ nombre: nombreA, equipo: 'jugador' }); gA -= 100 }
      }
    } else if (gA >= 100) {
      slots.push({ nombre: nombreA, equipo: 'jugador' }); gA -= 100
    } else if (gB >= 100) {
      slots.push({ nombre: nombreB, equipo: 'oponente' }); gB -= 100
    }
  }
  return slots.slice(0, n)
}

/**
 * Avanza la simulación ATB hasta que el equipo indicado actúa y consume ese turno.
 * Retorna los nuevos { gaugeA, gaugeB }.
 */
export function consumirTurno({ gaugeA, velA, gaugeB, velB, equipo }) {
  if (equipo === 'jugador'  && gaugeA >= 100) return { gaugeA: gaugeA - 100, gaugeB }
  if (equipo === 'oponente' && gaugeB >= 100) return { gaugeA, gaugeB: gaugeB - 100 }
  let gA = gaugeA, gB = gaugeB
  for (let i = 0; i < 1000; i++) {
    gA += velA; gB += velB
    if (gA >= 100 && gB >= 100) {
      if (velA >= velB) {
        if (equipo === 'jugador')  return { gaugeA: gA - 100, gaugeB: gB }
        return { gaugeA: gA, gaugeB: gB - 100 }
      } else {
        if (equipo === 'oponente') return { gaugeA: gA, gaugeB: gB - 100 }
        return { gaugeA: gA - 100, gaugeB: gB }
      }
    } else if (gA >= 100) {
      if (equipo === 'jugador') return { gaugeA: gA - 100, gaugeB: gB }
      gA -= 100
    } else if (gB >= 100) {
      if (equipo === 'oponente') return { gaugeA: gA, gaugeB: gB - 100 }
      gB -= 100
    }
  }
  return { gaugeA: gA, gaugeB: gB }
}

/**
 * Calcula el gauge inicial de un Pokémon que entra en combate.
 * Se basa en qué tanto habría acumulado, en proporción a lo que el rival ya tiene,
 * ajustado por la diferencia de velocidades.
 *
 * Ejemplo: rival lleva 80 de gauge y el entrante es el doble de rápido → arranca en 99.
 *          rival lleva 80 y el entrante es la mitad de rápido → arranca en 40.
 */
export function gaugeAlEntrar(velEntrante, velRival, gaugeRival) {
  if (velRival <= 0 || gaugeRival <= 0) return 0
  return Math.min(99, Math.floor(gaugeRival * velEntrante / velRival))
}
