<script setup>
import { ref, computed } from 'vue'
import { calcularGananciaEntrenamiento, xpParaNivel } from '../utils/calcularStats.js'
import { aplicarBono, calcularGananciaTotal, subirStatNivel } from '../utils/bonos.js'

const props = defineProps({
  pokemon:    Object,
  claseStats: Array,
})

const emit = defineEmits(['actualizar', 'volver'])

const stats      = ref({ ...props.pokemon.stats })
const nivel      = ref(props.pokemon.nivel)
const xp         = ref(props.pokemon.xp ?? 0)
const pe         = ref(props.pokemon.pe)
const haycambios = ref(false)
const confirmado = ref(false)
const subiNivel  = ref(false)
const contadores = ref(
  Object.fromEntries(Object.keys(props.pokemon.stats).map(k => [k, 0]))
)

const xpNecesaria        = computed(() => xpParaNivel(nivel.value))
const xpPorcentaje       = computed(() => Math.min(100, (xp.value / xpNecesaria.value) * 100))
const xpPendiente        = computed(() => Object.values(contadores.value).reduce((s, c) => s + c, 0) * ganancia())
const xpPorcentajeGhost  = computed(() => Math.min(100, ((xp.value + xpPendiente.value) / xpNecesaria.value) * 100))

function ganancia() {
  return calcularGananciaEntrenamiento(nivel.value)
}

function puedeEntrenar(valorStat) {
  return valorStat < 150 && pe.value >= ganancia()
}

function entrenar(nombreStat) {
  if (!puedeEntrenar(stats.value[nombreStat])) return
  confirmado.value = false
  stats.value[nombreStat] = Math.min(150, stats.value[nombreStat] + aplicarBono(ganancia(), obtenerBonus(nombreStat)))
  pe.value -= ganancia()
  contadores.value[nombreStat]++
  haycambios.value = true
}

function disminuir(nombreStat) {
  if (contadores.value[nombreStat] <= 0) return
  confirmado.value = false
  stats.value[nombreStat] -= aplicarBono(ganancia(), obtenerBonus(nombreStat))
  pe.value += ganancia()
  contadores.value[nombreStat]--
  haycambios.value = Object.values(contadores.value).some(c => c > 0)
}

function confirmar() {
  const base     = ganancia()
  const xpGanada = Object.values(contadores.value).reduce((s, c) => s + c, 0) * base
  let xpActual   = xp.value + xpGanada
  subiNivel.value = false

  while (xpActual >= xpParaNivel(nivel.value)) {
    xpActual -= xpParaNivel(nivel.value)
    nivel.value++
    for (const nombreStat in stats.value) {
      stats.value[nombreStat] = subirStatNivel(stats.value[nombreStat])
    }
    subiNivel.value = true
  }

  xp.value = xpActual

  const sesionEntrenamiento = {
    pokemon_uid:             props.pokemon.uid,
    pokemon_nombre:          props.pokemon.nombre,
    pe_inicial:              props.pokemon.pe,
    pe_gastado:              props.pokemon.pe - pe.value,
    pe_final:                pe.value,
    xp_ganada:               xpGanada,
    nivel_antes:             props.pokemon.nivel,
    nivel_despues:           nivel.value,
    cantidad_entrenamientos: Object.values(contadores.value).filter(c => c > 0).length,
    stats: Object.entries(contadores.value)
      .filter(([, c]) => c > 0)
      .map(([nombre, cantidad]) => ({
        stat_nombre:        nombre,
        cantidad_entrenada: cantidad,
        valor_antes:        props.pokemon.stats[nombre],
        valor_despues:      Math.min(150, props.pokemon.stats[nombre] + calcularGananciaTotal(base, cantidad * base, obtenerBonus(nombre))),
      })),
  }

  emit('actualizar', {
    stats:               { ...stats.value },
    pe:                  pe.value,
    nivel:               nivel.value,
    xp:                  xp.value,
    sesionEntrenamiento,
  })
  confirmado.value = true
  haycambios.value = false
  for (const k in contadores.value) {
    contadores.value[k] = 0
  }
}

function obtenerBonus(nombreStat) {
  const stat = props.claseStats?.find(s => s.nombre === nombreStat)
  return stat ? stat.valor : 0
}

function volver() {
  emit('volver')
}
</script>

<template>
  <div class="train-view">
    <button class="btn-volver" @click="volver">← Volver</button>

    <!-- Header del Pokémon -->
    <div class="pokemon-header" :style="{ backgroundColor: pokemon.colorElemento, borderColor: pokemon.colorElemento }">
      <div class="pokemon-info">
        <span class="pokemon-nombre">{{ pokemon.nombre }}</span>
        <span class="pokemon-elemento">{{ pokemon.elemento }}</span>
      </div>
      <div class="pokemon-meta">
        <div class="meta-item">
          <span class="meta-label">Nivel</span>
          <span class="meta-valor">{{ nivel }}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">PE restantes</span>
          <span class="meta-valor" :class="{ 'pe-bajo': pe <= 20 }">{{ pe }}</span>
        </div>
        <div class="meta-item">
          <span class="meta-label">Ganancia actual</span>
          <span class="meta-valor">+{{ ganancia() }} por entrenamiento</span>
        </div>
      </div>
      <div class="xp-barra-wrap">
        <div class="xp-labels">
          <span>EXP</span>
          <div class="xp-labels-right">
            <span v-if="xpPendiente > 0" class="xp-pendiente">+{{ xpPendiente }} xp</span>
            <span>{{ xp }} / {{ xpNecesaria }}</span>
          </div>
        </div>
        <div class="xp-barra-fondo">
          <div class="xp-barra-ghost"   :style="{ width: xpPorcentajeGhost + '%' }"></div>
          <div class="xp-barra-relleno" :style="{ width: xpPorcentaje      + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Tabla de stats -->
    <div class="stats-tabla">

      <div class="fila-header">
        <span>Stat</span>
        <span>Valor actual</span>
        <span>Bono</span>
        <span>Tope</span>
        <span>Entrenamientos</span>
      </div>

      <div v-for="(valor, nombreStat) in stats" class="fila-stat">
        <span class="stat-nombre">{{ nombreStat }}</span>

        <div class="stat-barra-wrap">
          <div
            class="stat-barra"
            :style="{
              width: (valor / 150 * 100) + '%',
              backgroundColor: pokemon.colorElemento
            }"
          ></div>
          <span class="stat-valor">{{ valor }}</span>
        </div>

        <span
          class="stat-bonus"
          :class="obtenerBonus(nombreStat) > 0 ? 'positivo' : obtenerBonus(nombreStat) < 0 ? 'negativo' : 'neutro'"
        >
          {{ obtenerBonus(nombreStat) > 0 ? '+' + obtenerBonus(nombreStat) : obtenerBonus(nombreStat) === 0 ? '—' : obtenerBonus(nombreStat) }}%
        </span>

        <span class="stat-tope" :class="{ alcanzado: valor >= 150 }">150</span>

        <div class="acciones-stat">
          <button
            class="btn-disminuir"
            :disabled="contadores[nombreStat] === 0"
            @click="disminuir(nombreStat)"
          >−</button>
          <span class="stat-contador" :class="{ activo: contadores[nombreStat] > 0 }">
            {{ contadores[nombreStat] }}x
          </span>
          <button
            class="btn-entrenar"
            :disabled="!puedeEntrenar(valor)"
            :style="puedeEntrenar(valor) ? { backgroundColor: pokemon.colorElemento } : {}"
            @click="entrenar(nombreStat)"
          >
            {{ valor >= 150 ? 'Tope' : pe < ganancia() ? 'Sin PE' : '+' }}
          </button>
        </div>
      </div>

    </div>

    <p v-if="pe === 0 && !confirmado" class="aviso-pe">
      Este Pokémon ha agotado sus puntos de entrenamiento.
    </p>

    <Transition name="fade">
      <div v-if="confirmado" class="aviso-completado" :class="{ 'nivel-up': subiNivel }">
        <template v-if="subiNivel">⬆ ¡Subiste al nivel {{ nivel }}! Todos los stats +2</template>
        <template v-else>✓ ¡Entrenamiento completado!</template>
      </div>
    </Transition>

    <div class="acciones">
      <button
        class="btn-confirmar"
        :disabled="!haycambios"
        :style="haycambios ? { backgroundColor: pokemon.colorElemento } : {}"
        @click="confirmar"
      >
        Confirmar entrenamiento
      </button>
    </div>

  </div>
</template>

<style scoped>
/* Contenedor principal de la vista; limita el ancho para no estirarse en pantallas grandes */
.train-view {
  padding: 32px;           /* espaciado interior de la vista de entrenamiento */
  font-family: sans-serif; /* fuente genérica sin serif para legibilidad */
  max-width: 700px;        /* limita el ancho máximo del contenedor */
}

/* ──────────────── HEADER DEL POKÉMON ──────────────── */

/* Tarjeta de cabecera; usa flex-wrap para que la barra de XP baje sola a una segunda línea */
.pokemon-header {
  border: 2px solid #ccc;          /* borde sólido gris claro del header */
  border-radius: 14px;             /* esquinas redondeadas del header */
  padding: 20px 24px 16px;         /* espaciado interior del header */
  display: flex;                   /* activa el modelo de caja flex */
  flex-wrap: wrap;                 /* permite que los hijos bajen a otra línea */
  justify-content: space-between;  /* separa los hijos hacia los extremos */
  align-items: center;             /* centra verticalmente los hijos */
  margin-bottom: 32px;             /* separa el header de la tabla de stats */
  gap: 16px;                       /* espacio entre los hijos del header */
  color: white;                    /* texto blanco sobre el fondo de color del elemento */
}

/* Nombre y elemento del pokémon, apilados verticalmente */
.pokemon-info {
  display: flex;          /* activa layout flex en la info del pokémon */
  flex-direction: column; /* apila nombre y elemento verticalmente */
  gap: 4px;               /* separación entre nombre y elemento */
}

/* Nombre grande destacado del pokémon */
.pokemon-nombre {
  font-size: 1.5rem;  /* tamaño grande para el nombre del pokémon */
  font-weight: bold;  /* texto en negrita para el nombre */
}

/* Tipo/elemento debajo del nombre, más pequeño */
.pokemon-elemento {
  font-size: 0.9rem; /* tamaño reducido para el tipo del pokémon */
  opacity: 0.85;     /* ligera transparencia para jerarquía visual */
}

/* Grupo de métricas (nivel, PE restantes, ganancia), en fila */
.pokemon-meta {
  display: flex; /* muestra las métricas en fila */
  gap: 24px;     /* espacio entre nivel, PE y ganancia */
}

/* Cada métrica: etiqueta arriba, valor abajo, centrados */
.meta-item {
  display: flex;          /* layout flex para etiqueta y valor */
  flex-direction: column; /* apila etiqueta sobre valor */
  align-items: center;    /* centra horizontalmente el contenido */
  gap: 2px;               /* separación mínima entre etiqueta y valor */
}

/* Etiqueta pequeña en mayúsculas sobre cada métrica */
.meta-label {
  font-size: 0.75rem;        /* tamaño pequeño para la etiqueta de métrica */
  opacity: 0.8;              /* semitransparente para menor jerarquía */
  text-transform: uppercase; /* convierte etiqueta a mayúsculas */
}

/* Valor numérico grande de cada métrica */
.meta-valor {
  font-size: 1.1rem;  /* tamaño destacado para el valor de métrica */
  font-weight: bold;  /* negrita para resaltar el valor */
}

/* Cambia el color del PE cuando queda poco (aviso visual) */
.pe-bajo {
  color: #ffe0e0; /* color rosa para indicar PE bajo */
}

/* ──────────────── BARRA DE XP ──────────────── */

/* Ocupa el ancho completo del header para quedar en su propia fila (flex-wrap) */
.xp-barra-wrap {
  width: 100%;      /* ocupa todo el ancho del header */
  flex-basis: 100%; /* fuerza una línea propia en el flex-wrap */
}

/* Fila de etiquetas sobre la barra: "EXP" a la izquierda, datos a la derecha */
.xp-labels {
  display: flex;                   /* coloca las etiquetas en fila */
  justify-content: space-between;  /* "EXP" a la izquierda, datos a la derecha */
  font-size: 0.72rem;              /* tamaño pequeño para etiquetas de XP */
  opacity: 0.85;                   /* semitransparente sobre el fondo de color */
  margin-bottom: 4px;              /* separa etiquetas de la barra XP */
}

/* Agrupa el texto de ganancia pendiente (+X xp) y el contador actual/total */
.xp-labels-right {
  display: flex;       /* agrupa pendiente y contador en fila */
  align-items: center; /* centra verticalmente los textos */
  gap: 8px;            /* espacio entre pendiente y contador */
}

/* Texto que muestra la XP que se ganará al confirmar el entrenamiento */
.xp-pendiente {
  font-size: 0.72rem; /* tamaño igual al resto de etiquetas XP */
  opacity: 0.75;      /* más tenue para mostrar que es estimado */
}

/* Fondo de la barra; position: relative para que las barras absolutas se posicionen dentro */
.xp-barra-fondo {
  position: relative;               /* contexto de posición para barras absolutas */
  height: 6px;                      /* altura delgada de la barra de XP */
  background: rgba(255,255,255,0.25); /* fondo blanco semitransparente del carril */
  border-radius: 4px;               /* esquinas redondeadas del carril */
  overflow: hidden;                 /* recorta las barras internas al borde */
}

/* Barra fantasma: muestra hasta dónde llegará la XP al confirmar; queda detrás de la barra real */
.xp-barra-ghost {
  position: absolute;                 /* se posiciona dentro del fondo de barra */
  top: 0;                             /* pega la barra al borde superior */
  left: 0;                            /* pega la barra al borde izquierdo */
  height: 100%;                       /* ocupa toda la altura del fondo */
  background: rgba(255,255,255,0.45); /* blanco semitransparente de la barra fantasma */
  border-radius: 4px;                 /* esquinas redondeadas de la barra fantasma */
  transition: width 0.3s ease;        /* animación suave al cambiar xp pendiente */
}

/* Barra de XP actual; encima de la fantasma gracias a z-index: 1 */
.xp-barra-relleno {
  position: absolute;                 /* se posiciona dentro del fondo de barra */
  top: 0;                             /* pega la barra al borde superior */
  left: 0;                            /* pega la barra al borde izquierdo */
  height: 100%;                       /* ocupa toda la altura del fondo */
  background: rgba(255,255,255,0.85); /* blanco casi opaco para la XP actual */
  border-radius: 4px;                 /* esquinas redondeadas de la barra real */
  transition: width 0.4s ease;        /* animación al ganar o perder XP */
  z-index: 1;                         /* queda encima de la barra fantasma */
}

/* ──────────────── TABLA DE STATS ──────────────── */

/* Contenedor de todas las filas, apiladas verticalmente */
.stats-tabla {
  display: flex;          /* contenedor flex de las filas */
  flex-direction: column; /* apila las filas de stats verticalmente */
  gap: 8px;               /* espacio entre filas de cada stat */
}

/* Encabezado de la tabla; mismas columnas que las filas para alinear */
.fila-header {
  display: grid;                                       /* alinea los encabezados en columnas */
  grid-template-columns: 1.5fr 3fr 0.7fr 0.5fr 1.6fr; /* proporciones de columnas del encabezado */
  font-size: 0.78rem;                                  /* tamaño pequeño para el encabezado */
  font-weight: bold;                                   /* negrita para los títulos de columna */
  color: #999;                                         /* gris neutro para los encabezados */
  text-transform: uppercase;                           /* convierte los títulos a mayúsculas */
  padding: 0 8px;                                      /* alinea el encabezado con las filas */
}

/* Fila de cada stat: nombre | barra | bono | tope | botones */
.fila-stat {
  display: grid;                                       /* alinea las celdas del stat en columnas */
  grid-template-columns: 1.5fr 3fr 0.7fr 0.5fr 1.6fr; /* mismas proporciones que el encabezado */
  align-items: center;                                 /* centra verticalmente cada celda */
  gap: 12px;                                           /* espacio entre columnas de la fila */
  padding: 10px 8px;                                   /* espaciado interior de la fila */
  background: #f9f9f9;                                 /* fondo gris muy claro para cada fila */
  border-radius: 8px;                                  /* esquinas redondeadas de la fila */
}

/* Nombre del stat en negrita */
.stat-nombre {
  font-size: 0.9rem;  /* tamaño estándar para el nombre del stat */
  color: #333;        /* color oscuro para el nombre del stat */
  font-weight: bold;  /* negrita para destacar el nombre */
}

/* Porcentaje de bono de clase, centrado en su columna */
.stat-bonus {
  font-size: 0.82rem; /* tamaño reducido para el porcentaje de bono */
  font-weight: bold;  /* negrita para destacar el bono */
  text-align: center; /* centra el bono en su columna */
}

/* Verde para bono positivo */
.positivo { color: #2dc653; /* verde para bono positivo de clase */ }
/* Rojo para bono negativo */
.negativo { color: #e63946; /* rojo para bono negativo de clase */ }
/* Gris para sin bono */
.neutro   { color: #bbb;    /* gris para stat sin bono de clase */ }

/* Contenedor de la barra de progreso del stat y su valor numérico */
.stat-barra-wrap {
  display: flex;       /* muestra barra y valor en fila */
  align-items: center; /* centra verticalmente barra y número */
  gap: 10px;           /* espacio entre la barra y el valor */
}

/* Barra de progreso del stat; el color se inyecta por binding inline */
.stat-barra {
  height: 8px;               /* altura de la barra de progreso del stat */
  border-radius: 4px;        /* esquinas redondeadas de la barra */
  flex: 1;                   /* la barra ocupa el espacio disponible */
  transition: width 0.3s ease; /* animación al cambiar el valor del stat */
}

/* Valor numérico del stat a la derecha de la barra */
.stat-valor {
  font-size: 0.9rem;  /* tamaño estándar para el número del stat */
  font-weight: bold;  /* negrita para el valor numérico */
  min-width: 28px;    /* ancho mínimo para alinear los números */
  text-align: right;  /* alinea el número a la derecha */
}

/* Texto "150" indicando el tope máximo del stat */
.stat-tope {
  font-size: 0.8rem;  /* tamaño pequeño para el indicador de tope */
  color: #aaa;        /* gris claro cuando el stat no ha llegado al tope */
  text-align: center; /* centra el valor tope en su columna */
}

/* El tope se vuelve verde cuando el stat llegó a 150 */
.stat-tope.alcanzado {
  color: #2dc653;    /* verde al alcanzar el tope máximo */
  font-weight: bold; /* negrita al llegar al tope */
}

/* Grupo de botones [−] contador [+] para cada stat */
.acciones-stat {
  display: flex;       /* alinea botones y contador en fila */
  align-items: center; /* centra verticalmente los botones */
  gap: 6px;            /* espacio entre botón, contador y botón */
}

/* Botón para revertir un punto de entrenamiento */
.btn-disminuir {
  width: 28px;                   /* ancho fijo del botón disminuir */
  height: 28px;                  /* alto fijo del botón disminuir */
  font-size: 1rem;               /* tamaño del símbolo menos */
  line-height: 1;                /* alinea el símbolo verticalmente */
  color: #555;                   /* color gris oscuro del símbolo */
  background: white;             /* fondo blanco del botón disminuir */
  border: 2px solid #ccc;        /* borde gris claro del botón disminuir */
  border-radius: 6px;            /* esquinas redondeadas del botón */
  cursor: pointer;               /* cursor de mano al pasar sobre el botón */
  transition: border-color 0.2s; /* animación del borde al hacer hover */
  flex-shrink: 0;                /* impide que el botón se encoja en flex */
}

/* El botón disminuir se pone rojo al hacer hover si está activo */
.btn-disminuir:not(:disabled):hover {
  border-color: #e63946; /* borde rojo al hover del botón activo */
  color: #e63946;        /* texto rojo al hover para indicar eliminación */
}

/* Estado deshabilitado cuando no hay entrenamientos que revertir */
.btn-disminuir:disabled {
  cursor: not-allowed; /* cursor prohibido cuando no hay nada que revertir */
  opacity: 0.35;       /* muy transparente cuando está deshabilitado */
}

/* Contador de entrenamientos aplicados al stat (ej: "2x") */
.stat-contador {
  font-size: 0.82rem; /* tamaño reducido del contador de entrenamientos */
  font-weight: bold;  /* negrita para el contador */
  color: #bbb;        /* gris claro cuando el contador está en cero */
  min-width: 22px;    /* ancho mínimo para evitar saltos de layout */
  text-align: center; /* centra el número en su espacio */
}

/* El contador se oscurece cuando hay al menos un entrenamiento aplicado */
.stat-contador.activo {
  color: #444; /* oscurece el contador cuando hay entrenamientos */
}

/* Botón principal de entrenar un stat; el color se inyecta por binding inline */
.btn-entrenar {
  padding: 6px 10px;        /* espaciado interior del botón entrenar */
  font-size: 0.9rem;        /* tamaño del texto del botón */
  font-weight: bold;        /* negrita para el signo más */
  color: white;             /* texto blanco sobre el color del elemento */
  border: none;             /* sin borde en el botón entrenar */
  border-radius: 6px;       /* esquinas redondeadas del botón */
  cursor: pointer;          /* cursor de mano al pasar sobre el botón */
  background-color: #ccc;   /* gris por defecto antes de inyectar color */
  transition: filter 0.2s;  /* animación de brillo al hacer hover */
  flex-shrink: 0;           /* impide que el botón se encoja en flex */
}

/* Oscurece ligeramente al hover para dar feedback visual */
.btn-entrenar:not(:disabled):hover {
  filter: brightness(0.9); /* oscurece el botón entrenar al hover */
}

/* Estado deshabilitado cuando no hay PE o el stat ya está en tope */
.btn-entrenar:disabled {
  cursor: not-allowed; /* cursor prohibido cuando no se puede entrenar */
  opacity: 0.6;        /* semitransparente cuando está deshabilitado */
}

/* ──────────────── AVISOS Y CONFIRMACIÓN ──────────────── */

/* Mensaje que aparece cuando el pokémon agotó todos sus PE */
.aviso-pe {
  margin-top: 24px;   /* separa el aviso de la tabla de stats */
  text-align: center; /* centra el texto del aviso de PE */
  color: #e63946;     /* rojo para indicar alerta de PE agotados */
  font-size: 0.9rem;  /* tamaño estándar del aviso */
}

/* Banner verde que confirma el entrenamiento completado exitosamente */
.aviso-completado {
  margin-top: 24px;          /* separa el banner de la tabla de stats */
  padding: 14px 20px;        /* espaciado interior del banner */
  background: #edfff3;       /* verde muy claro para fondo del banner */
  border: 2px solid #2dc653; /* borde verde para el banner de éxito */
  border-radius: 10px;       /* esquinas redondeadas del banner */
  color: #1a9e3f;            /* verde oscuro para el texto de éxito */
  font-weight: bold;         /* negrita para el mensaje de confirmación */
  font-size: 0.95rem;        /* tamaño casi normal del mensaje */
  text-align: center;        /* centra el texto del banner */
}

/* Variante dorada del banner cuando además se subió de nivel */
.aviso-completado.nivel-up {
  background: #fff8e0;   /* amarillo muy claro para banner de subida de nivel */
  border-color: #f4c430; /* dorado para borde de subida de nivel */
  color: #a07800;        /* dorado oscuro para texto de subida de nivel */
}

/* Duración de la transición de entrada/salida del banner */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s, transform 0.3s; /* anima opacidad y posición al entrar/salir */
}

/* El banner aparece desde arriba y desaparece hacia arriba */
.fade-enter-from,
.fade-leave-to {
  opacity: 0;               /* invisible al inicio/fin de la transición */
  transform: translateY(-6px); /* desplazado hacia arriba al entrar/salir */
}

/* ──────────────── BOTONES DE ACCIÓN ──────────────── */

/* Centra el botón "Confirmar entrenamiento" horizontalmente */
.acciones {
  display: flex;           /* centra el botón confirmar */
  justify-content: center; /* alinea el botón al centro horizontal */
  align-items: center;     /* centra verticalmente en el contenedor */
  margin-top: 32px;        /* separa los botones de la sección anterior */
}

/* Botón para volver al hub, centrado y discreto */
.btn-volver {
  display: block;                            /* cambia a bloque para usar margin auto */
  margin: 0 auto 20px;                       /* centra el botón y lo separa abajo */
  padding: 8px 18px;                         /* espaciado interior del botón volver */
  background: white;                         /* fondo blanco del botón volver */
  border: 2px solid #ccc;                    /* borde gris claro del botón volver */
  border-radius: 8px;                        /* esquinas redondeadas del botón volver */
  cursor: pointer;                           /* cursor de mano sobre el botón */
  font-size: 0.88rem;                        /* tamaño ligeramente reducido del texto */
  color: #555;                               /* gris oscuro para el texto volver */
  transition: border-color 0.2s, color 0.2s; /* animación de borde y color al hover */
}

/* El borde y texto del botón volver se oscurecen al hover */
.btn-volver:hover { border-color: #888; color: #222; }

/* Botón principal para confirmar todos los entrenamientos de la sesión */
.btn-confirmar {
  padding: 10px 28px;                       /* espaciado generoso del botón confirmar */
  font-size: 0.95rem;                       /* tamaño casi normal del texto */
  font-weight: bold;                        /* negrita para el botón principal */
  color: white;                             /* texto blanco sobre el color del elemento */
  border: none;                             /* sin borde en el botón confirmar */
  border-radius: 8px;                       /* esquinas redondeadas del botón */
  cursor: pointer;                          /* cursor de mano sobre el botón */
  background: #ccc;                         /* gris por defecto antes de inyectar color */
  transition: filter 0.2s, transform 0.1s; /* animación de brillo y escala al hover */
}

/* Oscurece y agranda levemente el botón confirmar al hacer hover */
.btn-confirmar:not(:disabled):hover {
  filter: brightness(0.9); /* oscurece el botón al hover */
  transform: scale(1.02);  /* agranda levemente al hacer hover */
}

/* Estado deshabilitado cuando no hay cambios pendientes por confirmar */
.btn-confirmar:disabled {
  cursor: not-allowed; /* cursor prohibido sin cambios pendientes */
  opacity: 0.6;        /* semitransparente cuando está deshabilitado */
}
</style>
