const BASE = import.meta.env.VITE_API_BASE ?? '/api'

export async function obtenerPartidas() {
  const res = await fetch(`${BASE}/partidas.php`)
  if (!res.ok) throw new Error('Error al obtener partidas')
  return res.json()
}

export async function obtenerPartidaCompleta(id) {
  const res = await fetch(`${BASE}/partidas.php?id=${id}`)
  if (!res.ok) throw new Error('Error al cargar partida')
  return res.json()
}

export async function guardarPartida(nombre, estado, pokemon, inventario) {
  const res = await fetch(`${BASE}/partidas.php`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ nombre, estado, pokemon, inventario }),
  })
  if (!res.ok) throw new Error('Error al guardar partida')
  return res.json()
}

export async function actualizarPartida(id, nombre, estado, pokemon, inventario) {
  const res = await fetch(`${BASE}/partidas.php`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id, nombre, estado, pokemon, inventario }),
  })
  if (!res.ok) throw new Error('Error al actualizar partida')
  return res.json()
}

export async function eliminarPartida(id) {
  const res = await fetch(`${BASE}/partidas.php`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id }),
  })
  if (!res.ok) throw new Error('Error al eliminar partida')
  return res.json()
}
