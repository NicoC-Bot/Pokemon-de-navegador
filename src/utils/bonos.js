export function aplicarBono(valor, bono) {
  return Math.max(1, Math.round(valor * (1 + bono / 100)))
}

export function calcularGananciaTotal(valorBase, totalEntrenamiento, bono) {
  const puntos = totalEntrenamiento / valorBase
  return puntos * aplicarBono(valorBase, bono)
}

export function subirStatNivel(valorStat) {
  if (valorStat >= 150) return valorStat
  return Math.min(150, valorStat + 2)
}
