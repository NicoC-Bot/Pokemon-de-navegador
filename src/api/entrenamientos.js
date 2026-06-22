const BASE = import.meta.env.VITE_API_BASE ?? '/api'

export async function registrarSesiones(partida_id, sesiones) {
  const res = await fetch(`${BASE}/entrenamientos.php`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ partida_id, sesiones }),
  })
  if (!res.ok) throw new Error('Error al registrar sesiones de entrenamiento')
  return res.json()
}
