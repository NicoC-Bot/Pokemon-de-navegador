export function generarHabilidadesAscension(elemento, catalogo) {
  const pool = catalogo.filter(h => h.elemento === elemento)
  return [...pool].sort(() => Math.random() - 0.5).slice(0, 2)
}

export function obtenerHabilidadRareza(rareza, catalogo) {
  return catalogo.find(h => h.rareza === rareza) ?? null
}

export function resolverHabilidades(ascIds, rarezaId, catalogo) {
  return {
    asc:    (ascIds ?? []).map(id => catalogo.find(h => h.identificador === id)).filter(Boolean),
    rareza: rarezaId ? (catalogo.find(h => h.identificador === rarezaId) ?? null) : null,
  }
}
