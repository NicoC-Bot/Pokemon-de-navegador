const KEY = 'practica2_partidas'
const KEY_BATALLAS = 'practica2_batallas'

function cargar() {
  try { return JSON.parse(localStorage.getItem(KEY) ?? '[]') } catch { return [] }
}

function persistir(lista) {
  localStorage.setItem(KEY, JSON.stringify(lista))
}

function isoLocal(ts) {
  return new Date(ts).toISOString().slice(0, 19).replace('T', ' ')
}

export async function obtenerPartidas(pagina = 1) {
  const lista = cargar()
  const limite = 10
  const total = lista.length
  const paginas = Math.max(1, Math.ceil(total / limite))
  const offset = (pagina - 1) * limite
  const slice = lista
    .slice()
    .sort((a, b) => b.creada_en - a.creada_en)
    .slice(offset, offset + limite)
    .map(p => ({
      id: p.id,
      nombre: p.nombre,
      creada_en: isoLocal(p.creada_en),
      entrenador_nombre: p.estado.entrenador_nombre,
      clase_id: p.estado.clase_id,
    }))
  return { partidas: slice, total, pagina, paginas }
}

export async function obtenerPartidaCompleta(id) {
  const lista = cargar()
  const p = lista.find(p => p.id === Number(id))
  if (!p) throw new Error('Partida no encontrada')
  return { ...p, creada_en: isoLocal(p.creada_en) }
}

export async function guardarPartida(nombre, estado, pokemon, inventario) {
  const lista = cargar()
  const id = Date.now()
  lista.push({ id, nombre, creada_en: id, estado, pokemon, inventario })
  persistir(lista)
  return { id }
}

export async function actualizarPartida(id, nombre, estado, pokemon, inventario) {
  const lista = cargar()
  const idx = lista.findIndex(p => p.id === Number(id))
  if (idx === -1) throw new Error('Partida no encontrada')
  lista[idx] = { ...lista[idx], nombre, estado, pokemon, inventario }
  persistir(lista)
  return { ok: true }
}

export async function obtenerEstadisticas(id) {
  const batallas = JSON.parse(localStorage.getItem(KEY_BATALLAS) ?? '[]')
    .filter(b => b.partida_id === Number(id))
  const total     = batallas.length
  const victorias = batallas.filter(b => b.resultado === 'victoria').length
  const derrotas  = batallas.filter(b => b.resultado === 'derrota').length
  const huidas    = batallas.filter(b => b.estado === 'abandono').length
  const turnos    = batallas.map(b => b.turnos_totales).filter(Boolean)
  const promedio  = turnos.length
    ? Math.round(turnos.reduce((a, b) => a + b, 0) / turnos.length * 10) / 10
    : null
  return { total_batallas: total, victorias, derrotas, huidas, turnos_promedio: promedio }
}

export async function eliminarPartida(id) {
  persistir(cargar().filter(p => p.id !== Number(id)))
  return { ok: true }
}
