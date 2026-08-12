const KEY = 'practica2_entrenamientos'

export async function registrarSesiones(partida_id, sesiones) {
  const lista = JSON.parse(localStorage.getItem(KEY) ?? '[]')
  for (const sesion of sesiones) {
    lista.push({ partida_id, ...sesion, fecha: Date.now() })
  }
  localStorage.setItem(KEY, JSON.stringify(lista))
  return { ok: true }
}
