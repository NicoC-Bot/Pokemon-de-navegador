const KEY = 'practica2_batallas'

export async function registrarBatalla({ partida_id, estado, resultado, turnos_totales }) {
  const lista = JSON.parse(localStorage.getItem(KEY) ?? '[]')
  lista.push({ partida_id, estado, resultado, turnos_totales, fecha: Date.now() })
  localStorage.setItem(KEY, JSON.stringify(lista))
  return { ok: true }
}
