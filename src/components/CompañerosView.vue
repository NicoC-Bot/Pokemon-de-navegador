<script setup>
import { ref } from 'vue'
import { rarezas, materiales, habilidadesAscension, COSTO_ASCENSION } from '../data/pokemonesExploracion.js'

const props = defineProps({
  equipo:     Array,
  capturados: Array,
  inventario: Object,
})

const emit = defineEmits(['volver', 'usar-material'])

const materialesCurativos  = materiales.filter(m => m.tipo === 'curativo')
const materialesAscension  = materiales.filter(m => m.tipo === 'ascension')
const materialesElementales = materiales.filter(m => m.tipo === 'curativo-elemental')

function obtenerRareza(id) {
  return rarezas.find(r => r.id === id) ?? rarezas[0]
}

function materialDeElemento(elemento) {
  return materialesAscension.find(m => m.elemento === elemento)
}

function curaEfectiva(mat, pokemon) {
  return mat.elemento === pokemon.elemento ? mat.hpRecuperado : Math.floor(mat.hpRecuperado * 0.5)
}

function elementoCompatible(mat, pokemon) {
  return mat.elemento === pokemon.elemento
}

function elementalesConStock(pokemon) {
  return materialesElementales.filter(m => (props.inventario[m.id] ?? 0) > 0)
}

function maxHp(pokemon) {
  return pokemon.stats?.HP ?? pokemon.statsBase?.HP ?? pokemon.hpActual ?? 0
}

function hpPorcentaje(pokemon) {
  const max = maxHp(pokemon)
  if (!max) return 0
  return Math.min(100, ((pokemon.hpActual ?? max) / max) * 100)
}

function puedeAscender(pokemon) {
  const mat = materialDeElemento(pokemon.elemento)
  if (!mat) return false
  if ((pokemon.nivelAscension ?? 0) >= 2) return false
  return (props.inventario[mat.id] ?? 0) >= COSTO_ASCENSION
}

const expandidas            = ref({})
const seleccionados         = ref({})
const confirmandoSobrepaso  = ref({})

function toggleSeleccion(pokemon, mat) {
  const uid    = pokemon.uid
  const actual = seleccionados.value[uid] ?? {}
  confirmandoSobrepaso.value = { ...confirmandoSobrepaso.value, [uid]: false }
  if (actual[mat.id]) {
    const { [mat.id]: _, ...resto } = actual
    seleccionados.value = { ...seleccionados.value, [uid]: resto }
  } else {
    seleccionados.value = { ...seleccionados.value, [uid]: { ...actual, [mat.id]: 1 } }
  }
}

function aumentarCantidad(pokemon, mat) {
  const uid      = pokemon.uid
  const actual   = seleccionados.value[uid] ?? {}
  const cantActual = actual[mat.id] ?? 0
  if (cantActual >= (props.inventario[mat.id] ?? 0)) return
  seleccionados.value = { ...seleccionados.value, [uid]: { ...actual, [mat.id]: cantActual + 1 } }
}

function disminuirCantidad(pokemon, mat) {
  const uid      = pokemon.uid
  const actual   = seleccionados.value[uid] ?? {}
  const cantActual = actual[mat.id] ?? 0
  if (cantActual <= 1) {
    const { [mat.id]: _, ...resto } = actual
    seleccionados.value = { ...seleccionados.value, [uid]: resto }
  } else {
    seleccionados.value = { ...seleccionados.value, [uid]: { ...actual, [mat.id]: cantActual - 1 } }
  }
}

function cantidadSeleccionada(pokemon, mat) {
  return (seleccionados.value[pokemon.uid] ?? {})[mat.id] ?? 0
}

function estaSeleccionado(pokemon, mat) {
  return !!(seleccionados.value[pokemon.uid] ?? {})[mat.id]
}

function tieneSeleccion(pokemon) {
  const sel = seleccionados.value[pokemon.uid] ?? {}
  return Object.values(sel).some(c => c > 0)
}

function confirmarCuracion(pokemon) {
  if (sobrepasaHpMax(pokemon)) {
    confirmandoSobrepaso.value = { ...confirmandoSobrepaso.value, [pokemon.uid]: true }
    return
  }
  _ejecutarCuracion(pokemon)
}

function _ejecutarCuracion(pokemon) {
  const sel = seleccionados.value[pokemon.uid] ?? {}
  for (const [materialId, cantidad] of Object.entries(sel)) {
    if (cantidad > 0) emit('usar-material', { pokemonUid: pokemon.uid, materialId, cantidad })
  }
  seleccionados.value        = { ...seleccionados.value, [pokemon.uid]: {} }
  confirmandoSobrepaso.value = { ...confirmandoSobrepaso.value, [pokemon.uid]: false }
}

function aceptarSobrepaso(pokemon) {
  _ejecutarCuracion(pokemon)
}

function cancelarSobrepaso(pokemon) {
  confirmandoSobrepaso.value = { ...confirmandoSobrepaso.value, [pokemon.uid]: false }
}

function totalCura(pokemon) {
  const sel = seleccionados.value[pokemon.uid] ?? {}
  return Object.entries(sel).reduce((total, [materialId, cantidad]) => {
    const mat = materiales.find(m => m.id === materialId)
    if (!mat) return total
    const cura = mat.tipo === 'curativo-elemental'
      ? (mat.elemento === pokemon.elemento ? mat.hpRecuperado : Math.floor(mat.hpRecuperado * 0.5))
      : mat.hpRecuperado
    return total + (cura * cantidad)
  }, 0)
}

function sobrepasaHpMax(pokemon) {
  const max = maxHp(pokemon)
  if (!max) return false
  const hpActual = pokemon.hpActual ?? max
  return tieneSeleccion(pokemon) && (hpActual + totalCura(pokemon)) > max
}

function toggleHabilidad(pokemonUid, habId) {
  const key = pokemonUid + '-' + habId
  expandidas.value[key] = !expandidas.value[key]
}

function estaExpandida(pokemonUid, habId) {
  return !!expandidas.value[pokemonUid + '-' + habId]
}

function curar(pokemon, material) {
  emit('usar-material', { pokemonUid: pokemon.uid, materialId: material.id, cantidad: 1 })
}

function ascender(pokemon) {
  const mat = materialDeElemento(pokemon.elemento)
  if (!mat) return
  emit('usar-material', { pokemonUid: pokemon.uid, materialId: mat.id, cantidad: COSTO_ASCENSION })
}
</script>

<template>
  <div class="compañeros-view">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <h2>Compañeros</h2>
    <p class="subtitulo">Cuida y usa materiales con tus Pokémon.</p>

    <div v-if="capturados.length === 0" class="vacio">
      Aún no tienes ningún compañero.
    </div>

    <div class="grid">
      <div
        v-for="pokemon in capturados"
        :key="pokemon.uid"
        class="pokemon-card"
        :style="{ borderColor: pokemon.colorElemento }"
      >
        <!-- Header -->
        <div class="card-header" :style="{ backgroundColor: pokemon.colorElemento }">
          <div class="card-info">
            <span class="card-nombre">{{ pokemon.nombre }}</span>
            <span class="card-elemento">{{ pokemon.elemento }}</span>
          </div>
          <div class="card-badges">
            <span class="nivel-badge">Nv. {{ pokemon.nivel }}</span>
            <span class="ascension-badge">✦ {{ pokemon.nivelAscension ?? 0 }} / 2</span>
            <span class="rareza-badge" :style="{ backgroundColor: obtenerRareza(pokemon.rareza).color }">
              {{ obtenerRareza(pokemon.rareza).label }}
            </span>
          </div>
        </div>

        <div class="card-body">

          <!-- HP -->
          <div class="seccion">
            <div class="seccion-titulo">Salud</div>
            <div class="hp-labels">
              <span>HP</span>
              <span :class="{ 'hp-bajo': (pokemon.hpActual ?? maxHp(pokemon)) <= Math.floor(maxHp(pokemon) * 0.25) }">
                {{ pokemon.hpActual ?? maxHp(pokemon) }} / {{ maxHp(pokemon) || '?' }}
              </span>
            </div>
            <div class="barra-fondo">
              <div
                class="barra-relleno"
                :style="{ width: hpPorcentaje(pokemon) + '%', backgroundColor: pokemon.colorElemento }"
              ></div>
            </div>

            <div class="curativos">
              <div class="seccion-curativos-label">Curación normal</div>
              <div v-for="mat in materialesCurativos" :key="mat.id" class="item-curar-wrap">
                <button
                  class="btn-curar"
                  :class="{ seleccionado: estaSeleccionado(pokemon, mat) }"
                  :disabled="(inventario[mat.id] ?? 0) === 0 || (pokemon.hpActual ?? maxHp(pokemon)) >= maxHp(pokemon)"
                  @click="toggleSeleccion(pokemon, mat)"
                >
                  {{ mat.icono }} +{{ mat.hpRecuperado }} <span class="mat-count">({{ inventario[mat.id] ?? 0 }})</span>
                </button>
                <div v-if="estaSeleccionado(pokemon, mat)" class="cantidad-controles">
                  <button class="btn-cantidad" @click="disminuirCantidad(pokemon, mat)">−</button>
                  <span class="cantidad-valor">{{ cantidadSeleccionada(pokemon, mat) }}</span>
                  <button class="btn-cantidad" :disabled="cantidadSeleccionada(pokemon, mat) >= (inventario[mat.id] ?? 0)" @click="aumentarCantidad(pokemon, mat)">+</button>
                </div>
              </div>
            </div>

            <div v-if="elementalesConStock(pokemon).length > 0" class="curativos-elementales">
              <div class="seccion-curativos-label">Curación elemental</div>
              <div v-for="mat in elementalesConStock(pokemon)" :key="mat.id" class="item-curar-wrap">
                <button
                  class="btn-curar btn-elemental"
                  :class="{ incompatible: !elementoCompatible(mat, pokemon), seleccionado: estaSeleccionado(pokemon, mat) }"
                  :style="elementoCompatible(mat, pokemon) ? { borderColor: pokemon.colorElemento, color: pokemon.colorElemento } : {}"
                  :disabled="(pokemon.hpActual ?? maxHp(pokemon)) >= maxHp(pokemon)"
                  @click="toggleSeleccion(pokemon, mat)"
                >
                  {{ mat.icono }} +{{ curaEfectiva(mat, pokemon) }}
                  <span v-if="!elementoCompatible(mat, pokemon)" class="reduccion-texto">-50%</span>
                  <span class="mat-count">({{ inventario[mat.id] ?? 0 }})</span>
                </button>
                <div v-if="estaSeleccionado(pokemon, mat)" class="cantidad-controles">
                  <button class="btn-cantidad" @click="disminuirCantidad(pokemon, mat)">−</button>
                  <span class="cantidad-valor">{{ cantidadSeleccionada(pokemon, mat) }}</span>
                  <button class="btn-cantidad" :disabled="cantidadSeleccionada(pokemon, mat) >= (inventario[mat.id] ?? 0)" @click="aumentarCantidad(pokemon, mat)">+</button>
                </div>
              </div>
            </div>

            <button
              class="btn-confirmar-cura"
              :disabled="!tieneSeleccion(pokemon) || confirmandoSobrepaso[pokemon.uid]"
              @click="confirmarCuracion(pokemon)"
            >
              Confirmar curación
              <span v-if="tieneSeleccion(pokemon)" class="cura-total">+{{ totalCura(pokemon) }} HP</span>
            </button>

            <p v-if="sobrepasaHpMax(pokemon) && !confirmandoSobrepaso[pokemon.uid]" class="aviso-sobrepasa">
              ⚠ La curación sobrepasa la vida máxima del compañero.
            </p>

            <div v-if="confirmandoSobrepaso[pokemon.uid]" class="card-advertencia">
              <p class="advertencia-mensaje">
                ⚠ La curación total (+{{ totalCura(pokemon) }} HP) superará el máximo de {{ maxHp(pokemon) }} HP. ¿Confirmar de todas formas?
              </p>
              <div class="advertencia-acciones">
                <button class="btn-advertencia-si" @click="aceptarSobrepaso(pokemon)">Sí, curar</button>
                <button class="btn-advertencia-no" @click="cancelarSobrepaso(pokemon)">No, cancelar</button>
              </div>
            </div>
          </div>

          <!-- Ascensión -->
          <div class="seccion">
            <div class="seccion-titulo">Ascensión</div>

            <div class="habilidades">
              <div
                v-for="hab in habilidadesAscension"
                :key="hab.nivel"
                class="habilidad"
                :class="{ desbloqueada: (pokemon.nivelAscension ?? 0) >= hab.nivel }"
              >
                <span class="hab-icono">{{ (pokemon.nivelAscension ?? 0) >= hab.nivel ? '✦' : '○' }}</span>
                <div class="hab-info">
                  <span class="hab-nombre">{{ hab.nombre }}</span>
                  <span class="hab-desc">{{ hab.descripcion }}</span>
                </div>
              </div>
            </div>

            <div v-if="(pokemon.nivelAscension ?? 0) < 2" class="ascension-accion">
              <div v-if="materialDeElemento(pokemon.elemento)" class="mat-requerido">
                <span>{{ materialDeElemento(pokemon.elemento).icono }} {{ materialDeElemento(pokemon.elemento).nombre }}</span>
                <span class="mat-disponible" :class="{ insuficiente: (inventario[materialDeElemento(pokemon.elemento).id] ?? 0) < COSTO_ASCENSION }">
                  {{ inventario[materialDeElemento(pokemon.elemento).id] ?? 0 }} / {{ COSTO_ASCENSION }}
                </span>
              </div>
              <button
                class="btn-ascender"
                :style="puedeAscender(pokemon) ? { backgroundColor: pokemon.colorElemento } : {}"
                :disabled="!puedeAscender(pokemon)"
                @click="ascender(pokemon)"
              >
                Ascender
              </button>
            </div>
            <div v-else class="ascension-completa">✦ Ascensión completa</div>
          </div>

          <!-- Habilidades de combate -->
          <div class="seccion">
            <div class="seccion-titulo">Habilidades de combate</div>

            <div v-if="pokemon.habilidades && pokemon.habilidades.length" class="habs-combate">
              <div v-for="hab in pokemon.habilidades" :key="hab.id" class="hab-combate">
                <button
                  class="hab-header"
                  :style="{ borderColor: pokemon.colorElemento }"
                  @click="toggleHabilidad(pokemon.uid, hab.id)"
                >
                  <div class="hab-meta">
                    <span class="hab-nombre-combate">{{ hab.nombre }}</span>
                    <span class="hab-tipo" :class="'tipo-' + hab.tipo">{{ hab.tipo }}</span>
                    <span v-if="hab.potencia" class="hab-potencia">p.{{ hab.potencia }}</span>
                  </div>
                  <span class="hab-chevron">{{ estaExpandida(pokemon.uid, hab.id) ? '▲' : '▼' }}</span>
                </button>
                <div v-if="estaExpandida(pokemon.uid, hab.id)" class="hab-descripcion">
                  {{ hab.descripcion }}
                </div>
              </div>
            </div>
            <div v-else class="sin-habilidades">Sin habilidades de combate.</div>
          </div>

        </div>
      </div>
    </div>


  </div>
</template>

<style scoped>
.compañeros-view {
  padding: 28px 32px; /* espaciado interno general de la vista */
  font-family: sans-serif; /* tipografía sin serifa para toda la vista */
}

h2 { font-size: 1.4rem; /* tamaño del título principal de la sección */ margin-bottom: 4px; /* separación mínima bajo el título */ }

.subtitulo {
  color: #666; /* color gris medio del subtítulo descriptivo */
  font-size: 0.9rem; /* tamaño ligeramente reducido del subtítulo */
  margin-bottom: 20px; /* espacio bajo el subtítulo antes del contenido */
}

.vacio {
  color: #aaa; /* color gris claro del mensaje de lista vacía */
  font-size: 0.88rem; /* texto ligeramente reducido del mensaje vacío */
  text-align: center; /* centra el mensaje cuando no hay compañeros */
  padding: 32px 0; /* espaciado vertical amplio del mensaje vacío */
}

.grid {
  display: grid; /* activa la disposición en grilla para las tarjetas */
  grid-template-columns: 1fr 1fr; /* dos columnas iguales para las tarjetas */
  gap: 14px; /* separación entre tarjetas de la grilla */
  margin-bottom: 24px; /* margen inferior de la grilla del equipo */
}

.pokemon-card {
  border: 2px solid #ccc; /* borde de la tarjeta, sobreescrito por color del elemento */
  border-radius: 12px; /* esquinas redondeadas de la tarjeta */
  overflow: hidden; /* recorta el contenido a los bordes redondeados */
}

/* Header */
.card-header {
  display: flex; /* encabezado con disposición flexible en fila */
  justify-content: space-between; /* nombre y badges en extremos opuestos */
  align-items: flex-start; /* alinea los grupos al tope del encabezado */
  padding: 10px 12px; /* espaciado interno del encabezado de la tarjeta */
  color: white; /* texto blanco sobre el fondo de color del elemento */
  gap: 6px; /* separación entre el nombre y los badges */
}

.card-info { display: flex; /* apila nombre y elemento con flex */ flex-direction: column; /* nombre sobre tipo elemental */ gap: 2px; /* separación mínima entre nombre y tipo */ min-width: 0; /* permite que el texto se recorte */ }
.card-nombre  { font-weight: bold; /* nombre del Pokémon en negrita */ font-size: 0.95rem; /* tamaño ligeramente reducido del nombre */ }
.card-elemento { font-size: 0.75rem; /* texto pequeño del tipo elemental */ opacity: 0.85; /* tipo ligeramente transparente bajo el nombre */ }

.card-badges {
  display: flex; /* agrupa los badges con flex */
  flex-direction: column; /* badges apilados verticalmente */
  align-items: flex-end; /* badges alineados al borde derecho */
  gap: 3px; /* separación entre los badges del encabezado */
  flex-shrink: 0; /* badges no se comprimen al reducir espacio */
}

.nivel-badge,
.ascension-badge,
.rareza-badge {
  font-size: 0.65rem; /* texto muy pequeño dentro de los badges */
  font-weight: bold; /* texto en negrita dentro de los badges */
  padding: 2px 6px; /* relleno compacto para los badges */
  border-radius: 20px; /* forma de píldora para los badges */
  white-space: nowrap; /* evita que el texto del badge se parta */
  color: white; /* texto blanco sobre el fondo del badge */
}

.nivel-badge     { background: rgba(0,0,0,0.25); /* fondo semitransparente oscuro del badge de nivel */ }
.ascension-badge { background: rgba(0,0,0,0.2); /* fondo semitransparente oscuro del badge de ascensión */ }

/* Body */
.card-body {
  padding: 10px 12px; /* espaciado interno del cuerpo de la tarjeta */
  display: flex; /* organiza las secciones con flex */
  flex-direction: column; /* secciones apiladas verticalmente */
  gap: 12px; /* separación entre secciones del cuerpo */
}

.seccion { display: flex; /* contenedor flex para cada sección */ flex-direction: column; /* elementos de la sección en columna */ gap: 6px; /* separación entre elementos de cada sección */ }

.seccion-titulo {
  font-size: 0.72rem; /* texto pequeño para el título de sección */
  font-weight: bold; /* título de sección en negrita */
  text-transform: uppercase; /* título de sección en mayúsculas */
  color: #999; /* color gris claro del título de sección */
}

/* HP */
.hp-labels {
  display: flex; /* etiquetas de HP en fila */
  justify-content: space-between; /* "HP" a la izquierda, valor a la derecha */
  font-size: 0.75rem; /* texto pequeño de las etiquetas de HP */
  color: #555; /* color gris oscuro de las etiquetas */
}

.hp-bajo { color: #e63946; /* color rojo cuando el HP está muy bajo */ font-weight: bold; /* valor de HP bajo resaltado en negrita */ }

.barra-fondo {
  height: 6px; /* altura delgada de la barra de HP */
  background: #eee; /* fondo gris claro de la barra vacía */
  border-radius: 4px; /* extremos redondeados de la barra */
  overflow: hidden; /* recorta el relleno a los bordes de la barra */
}

.barra-relleno {
  height: 100%; /* relleno ocupa toda la altura de la barra */
  border-radius: 4px; /* extremos redondeados del relleno de HP */
  transition: width 0.3s; /* animación suave al cambiar el HP */
}

/* Botones curar */
.curativos {
  display: flex; /* botones curativos en fila */
  flex-wrap: wrap; /* botones se envuelven si no caben */
  gap: 4px; /* separación entre botones curativos */
  margin-top: 2px; /* pequeño margen sobre los botones curativos */
}

.btn-curar {
  padding: 4px 8px; /* relleno compacto del botón de curar */
  font-size: 0.72rem; /* texto pequeño del botón de curar */
  font-weight: bold; /* texto en negrita del botón de curar */
  border: 2px solid #2dc653; /* borde verde del botón de curación normal */
  border-radius: 6px; /* esquinas redondeadas del botón de curar */
  background: white; /* fondo blanco del botón sin seleccionar */
  color: #1a9e3f; /* texto verde oscuro del botón de curar */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  transition: background 0.15s; /* transición suave del fondo al hacer hover */
}

.btn-curar:not(:disabled):hover { background: #edfff3; /* fondo verde muy claro al hacer hover */ }

.btn-curar:disabled {
  cursor: not-allowed; /* cursor de prohibido cuando está deshabilitado */
  opacity: 0.35; /* botón muy transparente al estar deshabilitado */
  border-color: #ddd; /* borde gris cuando no hay ítem disponible */
  color: #999; /* texto gris cuando el botón está deshabilitado */
}

.mat-count { opacity: 0.7; /* cantidad disponible ligeramente transparente */ }

.seccion-curativos-label {
  width: 100%; /* etiqueta ocupa todo el ancho disponible */
  font-size: 0.65rem; /* texto muy pequeño de la etiqueta de sección */
  font-weight: bold; /* etiqueta de sección en negrita */
  text-transform: uppercase; /* etiqueta de sección en mayúsculas */
  color: #aaa; /* color gris muy claro de la etiqueta */
  margin-bottom: 2px; /* separación mínima bajo la etiqueta */
}

/* Alimento elemental */
.curativos-elementales {
  display: flex; /* botones elementales en fila */
  flex-wrap: wrap; /* botones elementales se envuelven si no caben */
  gap: 4px; /* separación entre botones de curación elemental */
  margin-top: 6px; /* margen superior de la sección de curación elemental */
}

.btn-elemental {
  border-color: #aaa; /* borde gris para comida elemental sin compatibilidad */
  color: #555; /* texto gris del botón elemental neutro */
  background: #fafafa; /* fondo casi blanco del botón elemental */
}

.btn-elemental:not(:disabled):hover { background: #f0f0f0; /* fondo gris claro al hacer hover en botón elemental */ }

.btn-curar.seleccionado {
  background: #edfff3; /* fondo verde claro al seleccionar el ítem */
  border-color: #1a9e3f; /* borde verde oscuro al estar seleccionado */
  color: #1a9e3f; /* texto verde oscuro cuando el ítem está seleccionado */
}

.item-curar-wrap {
  display: flex; /* agrupa botón y controles de cantidad */
  flex-direction: column; /* controles de cantidad bajo el botón */
  gap: 3px; /* separación entre botón y controles de cantidad */
}

.cantidad-controles {
  display: flex; /* controles de cantidad en fila */
  align-items: center; /* botones y valor alineados verticalmente */
  gap: 6px; /* separación entre botones y valor de cantidad */
  padding-left: 4px; /* sangría izquierda de los controles */
}

.btn-cantidad {
  width: 22px; /* ancho fijo del botón de cantidad */
  height: 22px; /* alto fijo del botón de cantidad */
  font-size: 0.9rem; /* tamaño del símbolo más/menos */
  line-height: 1; /* altura de línea ajustada al ícono */
  border: 1px solid #ccc; /* borde gris claro del botón de cantidad */
  border-radius: 4px; /* esquinas ligeramente redondeadas */
  background: white; /* fondo blanco del botón de cantidad */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  color: #555; /* color gris oscuro del símbolo del botón */
}

.btn-cantidad:disabled {
  opacity: 0.35; /* botón de cantidad muy transparente al deshabilitarse */
  cursor: not-allowed; /* cursor de prohibido en botón deshabilitado */
}

.cantidad-valor {
  font-size: 0.8rem; /* tamaño del número de cantidad seleccionada */
  font-weight: bold; /* número de cantidad en negrita */
  color: #333; /* color oscuro del número de cantidad */
  min-width: 16px; /* ancho mínimo para no desplazar los botones */
  text-align: center; /* número de cantidad centrado */
}

.btn-confirmar-cura {
  width: 100%; /* botón de confirmar ocupa todo el ancho */
  padding: 7px; /* relleno del botón de confirmación de curación */
  margin-top: 8px; /* margen superior del botón de confirmar */
  font-size: 0.8rem; /* tamaño del texto del botón */
  font-weight: bold; /* texto en negrita del botón de confirmar */
  border: none; /* sin borde en el botón de confirmar */
  border-radius: 6px; /* esquinas redondeadas del botón */
  background: #2dc653; /* fondo verde del botón de confirmar curación */
  color: white; /* texto blanco sobre el fondo verde */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  transition: filter 0.15s; /* transición suave del brillo al hacer hover */
}

.btn-confirmar-cura:not(:disabled):hover { filter: brightness(0.9); /* oscurece el botón al hacer hover */ }

.btn-confirmar-cura:disabled {
  background: #ccc; /* fondo gris cuando no hay curación seleccionada */
  cursor: not-allowed; /* cursor de prohibido cuando no hay selección */
}

.cura-total {
  font-size: 0.75rem; /* texto pequeño del indicador de HP total a curar */
  opacity: 0.85; /* indicador de total ligeramente transparente */
  margin-left: 4px; /* separación izquierda del total respecto al texto */
}

.aviso-sobrepasa {
  font-size: 0.72rem; /* texto pequeño del aviso de sobrepaso de HP */
  color: #e6a817; /* color amarillo de advertencia por sobrepaso */
  margin-top: 4px; /* separación superior del aviso */
}

.card-advertencia {
  background: #fff8e0; /* fondo amarillo claro del panel de advertencia */
  border: 1px solid #f4c430; /* borde amarillo del panel de advertencia */
  border-radius: 6px; /* esquinas redondeadas del panel de advertencia */
  padding: 8px 10px; /* relleno interno del panel de advertencia */
  font-size: 0.78rem; /* texto pequeño del panel de advertencia */
  color: #a07800; /* color dorado oscuro del texto de advertencia */
  margin-top: 6px; /* separación superior del panel de advertencia */
}

.btn-elemental.incompatible {
  border-color: #ddd; /* borde gris para alimento de elemento incompatible */
  color: #999; /* texto gris cuando el alimento no es compatible */
  opacity: 0.8; /* botón ligeramente transparente si es incompatible */
}

.reduccion-texto {
  font-size: 0.65rem; /* texto muy pequeño del indicador de reducción */
  color: #e63946; /* color rojo del texto de penalización -50% */
  font-weight: normal; /* texto sin negrita para el indicador de reducción */
  margin-left: 2px; /* separación izquierda del texto de reducción */
}

/* Habilidades */
.habilidades { display: flex; /* lista de habilidades en flex */ flex-direction: column; /* habilidades apiladas verticalmente */ gap: 5px; /* separación entre habilidades de ascensión */ }

.habilidad {
  display: flex; /* ícono y texto de habilidad en fila */
  align-items: flex-start; /* ícono alineado arriba con el texto */
  gap: 6px; /* separación entre ícono e información de habilidad */
  opacity: 0.4; /* habilidad bloqueada muy transparente */
}

.habilidad.desbloqueada { opacity: 1; /* habilidad desbloqueada completamente visible */ }

.hab-icono { font-size: 0.8rem; /* tamaño del ícono de habilidad */ margin-top: 2px; /* pequeño margen para alinear ícono con texto */ flex-shrink: 0; /* ícono no se comprime al reducir espacio */ }

.hab-info { display: flex; /* nombre y descripción de habilidad en flex */ flex-direction: column; /* nombre sobre descripción en columna */ gap: 1px; /* separación mínima entre nombre y descripción */ }
.hab-nombre { font-size: 0.78rem; /* tamaño del nombre de la habilidad */ font-weight: bold; /* nombre de habilidad en negrita */ color: #222; /* color oscuro del nombre de habilidad */ }
.hab-desc   { font-size: 0.7rem; /* texto muy pequeño de la descripción */ color: #888; /* color gris de la descripción de habilidad */ }

/* Ascensión acción */
.ascension-accion { display: flex; /* acción de ascensión en flex */ flex-direction: column; /* material y botón apilados verticalmente */ gap: 5px; /* separación entre material requerido y botón */ }

.mat-requerido {
  display: flex; /* nombre e indicador de cantidad en fila */
  justify-content: space-between; /* nombre a la izquierda, cantidad a la derecha */
  align-items: center; /* nombre y cantidad alineados verticalmente */
  font-size: 0.75rem; /* texto pequeño del material requerido */
  color: #555; /* color gris del texto del material */
  padding: 4px 8px; /* relleno interno de la fila del material */
  background: #f9f9f9; /* fondo gris muy claro de la fila del material */
  border-radius: 6px; /* esquinas redondeadas de la fila del material */
}

.mat-disponible { font-weight: bold; /* cantidad disponible en negrita */ color: #2dc653; /* color verde cuando se tiene suficiente material */ }
.mat-disponible.insuficiente { color: #e63946; /* color rojo cuando no hay suficiente material */ }

.btn-ascender {
  width: 100%; /* botón de ascender ocupa todo el ancho */
  padding: 7px; /* relleno del botón de ascender */
  font-size: 0.8rem; /* tamaño del texto del botón */
  font-weight: bold; /* texto en negrita del botón de ascender */
  color: white; /* texto blanco del botón de ascender */
  border: none; /* sin borde en el botón de ascender */
  border-radius: 8px; /* esquinas redondeadas del botón de ascender */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  background: #ccc; /* fondo gris cuando no se puede ascender */
  transition: filter 0.2s; /* transición suave del brillo al hacer hover */
}

.btn-ascender:not(:disabled):hover { filter: brightness(0.9); /* oscurece el botón de ascender al hacer hover */ }
.btn-ascender:disabled { cursor: not-allowed; /* cursor de prohibido cuando no se puede ascender */ opacity: 0.5; /* botón de ascender semitransparente si está bloqueado */ }

.ascension-completa {
  text-align: center; /* texto de ascensión completa centrado */
  font-size: 0.78rem; /* texto pequeño del estado de ascensión completa */
  font-weight: bold; /* texto en negrita del estado final */
  color: #c8970a; /* color dorado del mensaje de ascensión completa */
  padding: 4px; /* relleno mínimo del mensaje de ascensión completa */
}

/* Habilidades de combate */
.habs-combate { display: flex; /* lista de habilidades de combate en flex */ flex-direction: column; /* habilidades de combate apiladas */ gap: 5px; /* separación entre habilidades de combate */ }

.hab-combate { display: flex; /* cabecera y descripción de habilidad en flex */ flex-direction: column; /* cabecera sobre descripción en columna */ }

.hab-header {
  display: flex; /* meta e indicador de expansión en fila */
  justify-content: space-between; /* nombre a la izquierda, flecha a la derecha */
  align-items: center; /* contenido del encabezado alineado verticalmente */
  padding: 5px 8px; /* relleno interno del encabezado de habilidad */
  background: #f9f9f9; /* fondo gris muy claro del encabezado */
  border: 1.5px solid #ddd; /* borde gris claro del encabezado de habilidad */
  border-radius: 6px; /* esquinas redondeadas del encabezado */
  cursor: pointer; /* cursor de mano para expandir/colapsar */
  text-align: left; /* texto del encabezado alineado a la izquierda */
  width: 100%; /* encabezado ocupa todo el ancho disponible */
  transition: background 0.15s; /* transición suave del fondo al hacer hover */
}

.hab-header:hover { background: #f0f0f0; /* fondo gris claro al hacer hover en el encabezado */ }

.hab-meta { display: flex; /* nombre, tipo y potencia en fila */ align-items: center; /* elementos meta alineados verticalmente */ gap: 5px; /* separación entre elementos meta */ flex-wrap: wrap; /* elementos meta se envuelven si no caben */ }

.hab-nombre-combate { font-size: 0.78rem; /* tamaño del nombre de habilidad de combate */ font-weight: bold; /* nombre de habilidad en negrita */ color: #222; /* color oscuro del nombre de habilidad */ }

.hab-tipo {
  font-size: 0.62rem; /* texto muy pequeño del tipo de habilidad */
  font-weight: bold; /* tipo de habilidad en negrita */
  padding: 1px 5px; /* relleno compacto del badge de tipo */
  border-radius: 10px; /* badge de tipo con forma de píldora */
  color: white; /* texto blanco sobre el badge de tipo */
}

.tipo-fisico   { background: #a0784a; /* fondo marrón para habilidades físicas */ }
.tipo-especial { background: #1a6db5; /* fondo azul para habilidades especiales */ }
.tipo-estado   { background: #2d8c4e; /* fondo verde para habilidades de estado */ }

.hab-potencia {
  font-size: 0.65rem; /* texto muy pequeño del valor de potencia */
  color: #888; /* color gris del indicador de potencia */
  margin-left: 2px; /* separación izquierda del valor de potencia */
}

.hab-chevron { font-size: 0.6rem; /* tamaño pequeño del ícono de flecha */ color: #aaa; /* color gris claro del ícono de expansión */ flex-shrink: 0; /* flecha no se comprime al reducir espacio */ }

.hab-descripcion {
  font-size: 0.72rem; /* texto pequeño de la descripción de habilidad */
  color: #555; /* color gris oscuro de la descripción */
  padding: 6px 8px; /* relleno interno de la descripción */
  background: #fafafa; /* fondo casi blanco de la descripción */
  border: 1.5px solid #eee; /* borde gris muy claro de la descripción */
  border-top: none; /* sin borde superior para unirse al encabezado */
  border-radius: 0 0 6px 6px; /* solo esquinas inferiores redondeadas */
}

.sin-habilidades { font-size: 0.75rem; /* texto pequeño del aviso sin habilidades */ color: #aaa; /* color gris claro del aviso sin habilidades */ }

.advertencia-mensaje {
  font-size: 0.78rem; /* texto pequeño del mensaje de advertencia */
  color: #a07800; /* color dorado oscuro del mensaje de advertencia */
  margin: 0 0 8px; /* margen inferior antes de los botones de acción */
  line-height: 1.4; /* altura de línea cómoda para el texto */
}

.advertencia-acciones {
  display: flex; /* botones de advertencia en fila */
  gap: 8px; /* separación entre botones de advertencia */
}

.btn-advertencia-si,
.btn-advertencia-no {
  flex: 1; /* cada botón ocupa la mitad del espacio disponible */
  padding: 6px 0; /* relleno vertical de los botones de advertencia */
  font-size: 0.78rem; /* tamaño del texto de los botones */
  font-weight: bold; /* texto en negrita de los botones de advertencia */
  border: none; /* sin borde en los botones de advertencia */
  border-radius: 6px; /* esquinas redondeadas de los botones */
  cursor: pointer; /* cursor de mano en los botones de advertencia */
  transition: filter 0.15s; /* transición suave del brillo al hacer hover */
}

.btn-advertencia-si  { background: #2dc653; /* fondo verde del botón de confirmar curación */ color: white; /* texto blanco del botón de confirmar */ }
.btn-advertencia-no  { background: #eee;    /* fondo gris claro del botón de cancelar */ color: #555;  /* texto gris del botón de cancelar */ }
.btn-advertencia-si:hover  { filter: brightness(0.9); /* oscurece el botón de confirmar al hacer hover */ }
.btn-advertencia-no:hover  { filter: brightness(0.95); /* oscurece ligeramente el botón de cancelar al hacer hover */ }

/* Volver */
.btn-volver {
  display: block; /* botón volver como bloque para usar margen auto */
  margin: 0 auto 20px; /* centra el botón y agrega margen inferior */
  padding: 8px 18px; /* relleno del botón de volver */
  background: white; /* fondo blanco del botón de volver */
  border: 2px solid #ccc; /* borde gris del botón de volver */
  border-radius: 8px; /* esquinas redondeadas del botón de volver */
  cursor: pointer; /* cursor de mano al pasar sobre el botón */
  font-size: 0.88rem; /* tamaño del texto del botón de volver */
  color: #555; /* color gris del texto del botón de volver */
  transition: border-color 0.2s, color 0.2s; /* transición de borde y color al hacer hover */
}

.btn-volver:hover { border-color: #888; /* borde más oscuro al hacer hover en volver */ color: #222; /* texto más oscuro al hacer hover en volver */ }
</style>
