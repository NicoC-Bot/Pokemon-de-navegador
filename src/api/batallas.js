const BASE = import.meta.env.VITE_API_BASE ?? '/api'

export async function registrarBatalla({ partida_id, estado, resultado, turnos_totales, participantes, turnos }) {
  const res = await fetch(`${BASE}/batallas.php`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ partida_id, estado, resultado, turnos_totales, participantes, turnos }),
  })
  if (!res.ok) throw new Error('Error al registrar batalla')
  return res.json()
}
