<script setup>
import { ref, computed } from 'vue'
import TrainView      from './TrainView.vue'
import RestView       from './RestView.vue'
import ExploreView    from './ExploreView.vue'
import TeamView       from './TeamView.vue'
import InventarioView   from './InventarioView.vue'
import CompañerosView  from './CompañerosView.vue'
import CombateView     from './CombateView.vue'
import PerfilView           from './PerfilView.vue'
import GuardarPartidaView  from './GuardarPartidaView.vue'

const props = defineProps({
  entrenador:           Object,
  equipo:               Array,
  capturados:           Array,
  inventario:           Object,
  ultimoDescanso:       Number,
  descansandoHasta:     Number,
  peDescanso:           Number,
  capturaCooldownHasta: Number,
  capturasDisponibles:  Number,
  partidaId:            Number,
  nombrePartida:        String,
})

const emit = defineEmits(['actualizar-pokemon', 'capturar-pokemon', 'actualizar-equipo', 'actualizar-capturas', 'iniciar-descanso', 'completar-descanso', 'agregar-material', 'usar-material', 'actualizar-nombre', 'guardar-partida', 'actualizar-hp'])

const vistaActual    = ref('hub')
const pokemonUid     = ref(null)
const sidebarAbierto = ref(true)

const pokemonSeleccionado = computed(() =>
  props.capturados.find(p => p.uid === pokemonUid.value) ?? null
)

function actualizarPokemon(datos) {
  emit('actualizar-pokemon', { uid: pokemonUid.value, datos })
}
</script>

<template>
  <div class="hub">

    <!-- Sidebar izquierda -->
    <button class="sidebar-toggle" @click="sidebarAbierto = !sidebarAbierto">
      {{ sidebarAbierto ? '◀' : '▶' }}
    </button>

    <aside class="sidebar" :class="{ colapsado: !sidebarAbierto }">

      <div class="trainer-card" :style="{ borderColor: entrenador.clase.color }">
        <div class="trainer-header" :style="{ backgroundColor: entrenador.clase.color }">
          <span class="trainer-icono">🧢</span>
          <div>
            <h2>{{ entrenador.nombre }}</h2>
            <span class="trainer-clase">{{ entrenador.clase.label }}</span>
          </div>
        </div>
      </div>

      <div class="sidebar-bonos">
        <h3>Bonos de clase</h3>
        <div v-for="stat in entrenador.clase.stats" :key="stat.nombre" class="bono-fila">
          <span class="bono-nombre">{{ stat.nombre }}</span>
          <span class="bono-valor" :class="stat.valor > 0 ? 'positivo' : stat.valor < 0 ? 'negativo' : 'neutro'">
            {{ stat.valor > 0 ? '+' + stat.valor : stat.valor === 0 ? '—' : stat.valor }}%
          </span>
        </div>
      </div>

      <div class="sidebar-conteo">
        <div class="conteo-item">
          <span class="conteo-num">{{ capturados.length }}</span>
          <span class="conteo-label">Capturados</span>
        </div>
        <div class="conteo-item">
          <span class="conteo-num">{{ equipo.length }}</span>
          <span class="conteo-label">En equipo</span>
        </div>
      </div>

    </aside>

    <!-- Contenido principal -->
    <main class="contenido">

      <!-- Vista: Hub principal -->
      <div v-if="vistaActual === 'hub'">
        <div class="bienvenida">
          <h1>¡Bienvenido, {{ entrenador.nombre }}!</h1>
          <p>Tu aventura comienza. ¿Qué harás hoy?</p>
        </div>

        <div class="acciones">
          <div class="accion-card">
            <span class="accion-icono">🔍</span>
            <h2>Explorar</h2>
            <p>Busca Pokémon salvajes y amplía tu equipo.</p>
            <button @click="vistaActual = 'explorar'">Explorar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">💪</span>
            <h2>Entrenar</h2>
            <p>Fortalece los stats de tu equipo actual.</p>
            <button @click="vistaActual = 'entrenar'">Entrenar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">📋</span>
            <h2>Equipo</h2>
            <p>Gestiona y revisa los Pokémon de tu equipo.</p>
            <button @click="vistaActual = 'equipo'">Ver equipo</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🌙</span>
            <h2>Descansar</h2>
            <p>Recupera los PE de tu equipo. Un descanso por día.</p>
            <button @click="vistaActual = 'descanso'">Descansar</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🎒</span>
            <h2>Inventario</h2>
            <p>Revisa los materiales que has recogido en tus exploraciones.</p>
            <button @click="vistaActual = 'inventario'">Ver inventario</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">🤝</span>
            <h2>Compañeros</h2>
            <p>Cuida y usa materiales con tus Pokémon.</p>
            <button @click="vistaActual = 'compañeros'">Ver compañeros</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">⚔️</span>
            <h2>Combate</h2>
            <p>Enfrenta a tus Pokémon en duelos uno a uno.</p>
            <button @click="vistaActual = 'combate'">Ir a combate</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">👤</span>
            <h2>Perfil</h2>
            <p>Consulta tus datos, clase y bonos de entrenador.</p>
            <button @click="vistaActual = 'perfil'">Ver perfil</button>
          </div>

          <div class="accion-card">
            <span class="accion-icono">💾</span>
            <h2>Guardar partida</h2>
            <p>Guarda tu progreso actual para continuar más tarde.</p>
            <button @click="vistaActual = 'guardar'">Guardar</button>
          </div>
        </div>
      </div>

      <!-- Vista: Entrenar -->
      <div v-else-if="vistaActual === 'entrenar'">

        <div v-if="!pokemonSeleccionado" class="seleccion-entrenar">
          <button class="btn-volver" @click="vistaActual = 'hub'">← Volver</button>
          <p class="sel-titulo">¿Quién va a entrenar?</p>
          <button
            v-for="poke in capturados"
            :key="poke.uid"
            class="sel-btn"
            :disabled="poke.pe === 0"
            :style="{ borderColor: poke.colorElemento }"
            @click="pokemonUid = poke.uid"
          >
            <strong>{{ poke.nombre }}</strong> · Nv.{{ poke.nivel }}
            <span :style="{ color: poke.pe <= 20 ? '#e63946' : '#555' }">
              · PE: {{ poke.pe === 0 ? 'Sin PE' : poke.pe }}
            </span>
          </button>
        </div>

        <TrainView
          v-else
          :key="pokemonUid"
          :pokemon="pokemonSeleccionado"
          :clase-stats="entrenador.clase.stats"
          @actualizar="actualizarPokemon"
          @volver="pokemonUid = null"
        />

      </div>

      <!-- Vista: Explorar -->
      <div v-else-if="vistaActual === 'explorar'">
        <ExploreView
          :captura-cooldown-hasta="capturaCooldownHasta"
          :capturas-disponibles="capturasDisponibles"
          @volver="vistaActual = 'hub'"
          @capturar="pokemon => emit('capturar-pokemon', pokemon)"
          @actualizar-capturas="datos => emit('actualizar-capturas', datos)"
          @agregar-material="material => emit('agregar-material', material)"
        />
      </div>

      <!-- Vista: Equipo -->
      <div v-else-if="vistaActual === 'equipo'">
        <TeamView
          :equipo="equipo"
          :capturados="capturados"
          @actualizar-equipo="nuevoEquipo => emit('actualizar-equipo', nuevoEquipo)"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Descanso -->
      <div v-else-if="vistaActual === 'descanso'">
        <RestView
          :ultimo-descanso="ultimoDescanso"
          :descansando-hasta="descansandoHasta"
          :pe-descanso="peDescanso"
          @iniciar-descanso="datos => emit('iniciar-descanso', datos)"
          @completar-descanso="emit('completar-descanso')"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Inventario -->
      <div v-else-if="vistaActual === 'inventario'">
        <InventarioView
          :inventario="inventario"
          @volver="vistaActual = 'hub'"
        />
      </div>

      <!-- Vista: Compañeros -->
      <div v-else-if="vistaActual === 'compañeros'">
        <CompañerosView
          :equipo="equipo"
          :capturados="capturados"
          :inventario="inventario"
          @volver="vistaActual = 'hub'"
          @usar-material="datos => emit('usar-material', datos)"
        />
      </div>

      <!-- Vista: Combate -->
      <div v-else-if="vistaActual === 'combate'">
        <CombateView
          :entrenador="entrenador"
          :equipo="equipo"
          :capturados="capturados"
          :partida-id="partidaId"
          @volver="vistaActual = 'hub'"
          @actualizar-hp="emit('actualizar-hp', $event)"
        />
      </div>

      <!-- Vista: Perfil -->
      <div v-else-if="vistaActual === 'perfil'">
        <PerfilView
          :entrenador="entrenador"
          :capturados="capturados"
          :partida-id="partidaId"
          @volver="vistaActual = 'hub'"
          @actualizar-nombre="nombre => emit('actualizar-nombre', nombre)"
        />
      </div>

      <!-- Vista: Guardar partida -->
      <div v-else-if="vistaActual === 'guardar'">
        <GuardarPartidaView
          :entrenador="entrenador"
          :partida-id="partidaId"
          :nombre-partida="nombrePartida"
          @volver="vistaActual = 'hub'"
          @guardar-partida="datos => emit('guardar-partida', datos)"
        />
      </div>

    </main>

  </div>
</template>

<style scoped>
.hub {
  display: flex; /* layout horizontal de sidebar y contenido */
  height: 100vh; /* ocupa toda la altura de la ventana */
  overflow: hidden; /* evita scroll en el contenedor raíz */
  font-family: sans-serif; /* tipografía base sin serifas */
}

.sidebar {
  width: 240px; /* ancho fijo del panel lateral */
  height: 100%; /* sidebar ocupa toda la altura del hub */
  overflow: hidden; /* oculta contenido al colapsar la sidebar */
  background: #1e2a3a; /* fondo azul oscuro del panel */
  border-right: 1px solid #2c3e52; /* borde que separa sidebar del contenido */
  padding: 52px 16px 24px; /* espacio interno; extra arriba para el toggle */
  display: flex; /* apila secciones internas verticalmente */
  flex-direction: column; /* organiza hijos de la sidebar en columna */
  gap: 24px; /* separación entre secciones de la sidebar */
  flex-shrink: 0; /* impide que la sidebar se comprima */
  transition: width 0.25s ease, padding 0.25s ease; /* animación suave al colapsar */
}

.sidebar.colapsado {
  width: 0; /* sidebar completamente oculta al colapsar */
  padding: 0; /* elimina espacio interno al colapsar */
  border-right: none; /* quita el borde derecho al colapsar */
}

.sidebar.colapsado .trainer-card,
.sidebar.colapsado .equipo {
  display: none; /* oculta tarjeta y equipo al colapsar */
}

.sidebar-toggle {
  position: fixed; /* fija el botón independiente del scroll */
  top: 16px; /* separado del borde superior de la ventana */
  left: 8px; /* pegado al borde izquierdo de la pantalla */
  z-index: 100; /* se dibuja sobre el resto del contenido */
  background: #1e2a3a; /* coincide con el color de la sidebar */
  border: 1px solid #2c3e52; /* borde sutil del botón toggle */
  border-radius: 6px; /* esquinas levemente redondeadas */
  cursor: pointer; /* muestra mano al pasar sobre el botón */
  font-size: 0.75rem; /* ícono de flecha pequeño */
  padding: 4px 7px; /* espacio interno compacto del botón */
  color: #8aaabb; /* color azulado del ícono de flecha */
}

.sidebar-toggle:hover {
  background: #243447; /* fondo ligeramente más claro al pasar el cursor */
}

.trainer-card {
  border: 2px solid #ccc; /* borde base de la tarjeta del entrenador */
  border-radius: 12px; /* esquinas bien redondeadas de la tarjeta */
  overflow: hidden; /* recorta el header coloreado a los bordes */
}

.trainer-header {
  display: flex; /* alinea ícono y nombre del entrenador horizontalmente */
  align-items: center; /* centrado vertical del ícono y texto */
  gap: 10px; /* separación entre ícono y nombre del entrenador */
  padding: 12px 14px; /* espacio interno del encabezado de la tarjeta */
  color: white; /* texto blanco sobre fondo de color de clase */
}

.trainer-icono { font-size: 1.8rem; } /* tamaño grande del emoji del entrenador */

.trainer-header h2 {
  margin: 0; /* elimina margen por defecto del h2 */
  font-size: 1rem; /* nombre del entrenador en tamaño normal */
}

.trainer-clase {
  font-size: 0.8rem; /* etiqueta de clase más pequeña que el nombre */
  opacity: 0.9; /* ligeramente transparente para jerarquía visual */
}

.sidebar-bonos h3 {
  font-size: 0.9rem; /* encabezado de sección de bonos pequeño */
  font-weight: bold; /* título de bonos en negrita */
  color: #8aaabb; /* tono azulado del título de sección */
  text-transform: uppercase; /* título de bonos en mayúsculas */
  margin-bottom: 10px; /* separación del título a las filas de bonos */
}

.bono-fila {
  display: flex; /* coloca nombre y valor del bono en la misma fila */
  justify-content: space-between; /* nombre a la izquierda, valor a la derecha */
  align-items: center; /* alineación vertical de los elementos */
  font-size: 0.82rem; /* texto pequeño de cada fila de bono */
  padding: 3px 0; /* separación vertical mínima entre bonos */
}

.bono-nombre {
  color: #c8d8e4; /* color claro para el nombre del stat */
}

.bono-valor {
  font-weight: bold; /* valor del bono en negrita */
}

.positivo { color: #2dc653; } /* verde para bonos de stat positivos */
.negativo { color: #e63946; } /* rojo para bonos de stat negativos */
.neutro   { color: #bbb; } /* gris para bonos de stat neutros */

.sidebar-conteo {
  display: grid; /* distribución en cuadrícula para los contadores */
  grid-template-columns: 1fr 1fr; /* dos columnas iguales de conteo */
  gap: 8px; /* separación entre los bloques de conteo */
}

.conteo-item {
  display: flex; /* apila número y etiqueta verticalmente */
  flex-direction: column; /* organiza número y etiqueta en columna */
  align-items: center; /* centra horizontalmente número y etiqueta */
  background: #243447; /* fondo azul oscuro del bloque contador */
  border-radius: 8px; /* esquinas redondeadas del bloque */
  padding: 10px 6px; /* espacio interno del bloque de conteo */
  gap: 4px; /* separación entre número y etiqueta */
}

.conteo-num {
  font-size: 1.4rem; /* número de capturas o equipo en tamaño grande */
  font-weight: bold; /* número en negrita */
  color: #e8f0f6; /* número en color claro */
}

.conteo-label {
  font-size: 0.72rem; /* etiqueta muy pequeña bajo el número */
  color: #8aaabb; /* tono azulado de la etiqueta */
  text-transform: uppercase; /* etiqueta en mayúsculas */
  text-align: center; /* texto centrado dentro del bloque */
}

.slot.seleccionado {
  border-color: #222; /* borde oscuro al seleccionar slot */
  background: #e8e8e8; /* fondo gris claro del slot seleccionado */
  box-shadow: inset 0 0 0 1px #222; /* sombra interna que refuerza el borde */
}

.slot-nombre { font-weight: bold; } /* nombre del pokémon en negrita */

.contenido {
  flex: 1; /* área de contenido ocupa espacio restante del hub */
  min-height: 0; /* permite scroll interno en el área de contenido */
  padding: 28px 32px; /* espacio interno del área de contenido */
  overflow-y: auto; /* scroll vertical cuando el contenido desborda */
}

.bienvenida { margin-bottom: 24px; } /* separación entre bienvenida y acciones */

.bienvenida h1 {
  font-size: 1.6rem; /* título de bienvenida en tamaño grande */
  margin-bottom: 4px; /* separación mínima al subtítulo */
}

.bienvenida p {
  color: #666; /* texto descriptivo de bienvenida en gris */
  font-size: 0.9rem; /* párrafo de bienvenida ligeramente reducido */
}

.acciones {
  display: grid; /* grilla de tarjetas de acciones del hub */
  grid-template-columns: 1fr 1fr 1fr; /* tres columnas iguales de acciones */
  gap: 14px; /* separación entre tarjetas de acción */
}

.accion-card {
  border: 2px solid #e0e0e0; /* borde suave de cada tarjeta de acción */
  border-radius: 14px; /* esquinas muy redondeadas de la tarjeta */
  padding: 18px 16px; /* espacio interno de cada tarjeta */
  display: flex; /* organiza contenido de la tarjeta verticalmente */
  flex-direction: column; /* apila ícono, título, descripción y botón */
  gap: 6px; /* separación entre elementos internos de la tarjeta */
  transition: border-color 0.2s, box-shadow 0.2s; /* animación de hover suave */
}

.accion-card:hover {
  border-color: #aaa; /* borde más oscuro al pasar el cursor */
  box-shadow: 0 4px 12px rgba(0,0,0,0.08); /* sombra sutil al hacer hover */
}

.accion-icono { font-size: 1.6rem; } /* emoji de acción en tamaño grande */

.accion-card h2 {
  font-size: 1rem; /* título de la acción en tamaño normal */
  margin: 0; /* elimina margen por defecto del h2 */
}

.accion-card p {
  font-size: 0.82rem; /* descripción pequeña de la acción */
  color: #666; /* texto descriptivo de acción en gris */
  margin: 0; /* elimina margen por defecto del párrafo */
  flex: 1; /* descripción empuja el botón al fondo de la tarjeta */
}

.accion-card button {
  margin-top: 8px; /* separación del botón respecto a la descripción */
  padding: 8px; /* espacio interno del botón de acción */
  background: #222; /* fondo oscuro del botón */
  color: white; /* texto blanco del botón */
  border: none; /* elimina el borde nativo del botón */
  border-radius: 8px; /* esquinas redondeadas del botón */
  font-size: 0.85rem; /* texto del botón ligeramente reducido */
  cursor: pointer; /* muestra mano al pasar sobre el botón */
  transition: background 0.2s; /* cambio de fondo animado al hover */
}

.accion-card button:hover { background: #444; } /* fondo más claro al pasar el cursor */

.btn-volver {
  display: block; /* permite usar margin auto para centrar el botón */
  margin: 0 auto 20px; /* centrado horizontal con separación abajo */
  padding: 8px 18px; /* espacio interno del botón de volver */
  background: white; /* fondo blanco del botón */
  border: 2px solid #ccc; /* borde gris del botón de volver */
  border-radius: 8px; /* esquinas redondeadas del botón */
  cursor: pointer; /* muestra mano al pasar sobre el botón */
  font-size: 0.88rem; /* texto ligeramente reducido */
  color: #555; /* texto gris oscuro del botón */
  transition: border-color 0.2s, color 0.2s; /* animación de hover suave */
}

.btn-volver:hover { border-color: #888; /* borde más oscuro al hover */ color: #222; /* texto más oscuro al hover */ }

.proximamente {
  color: #aaa; /* texto gris para función no implementada */
  font-size: 1rem; /* tamaño normal del mensaje pendiente */
}

/* ── Selección de pokémon para entrenar ── */

/* Contenedor de la lista de selección */
.seleccion-entrenar {
  padding: 32px; /* espacio interno generoso */
  max-width: 500px; /* limita el ancho para no estirarse */
}

/* Encabezado de la pantalla de selección */
.sel-titulo {
  font-size: 1.1rem; /* tamaño ligeramente mayor al cuerpo */
  font-weight: bold; /* destacado */
  color: #333; /* texto oscuro */
  margin-bottom: 16px; /* separa del primer botón */
}

/* Botón de fila por cada pokémon capturado */
.sel-btn {
  display: block; /* ocupa toda la fila */
  width: 100%; /* ancho completo del contenedor */
  margin-bottom: 10px; /* separación entre botones */
  padding: 12px 16px; /* espacio interno cómodo */
  background: white; /* fondo blanco base */
  border: 2px solid #ccc; /* borde por defecto (se reemplaza inline por color del elemento) */
  border-radius: 8px; /* esquinas redondeadas */
  cursor: pointer; /* cursor de mano */
  text-align: left; /* texto alineado a la izquierda */
  color: #333; /* texto oscuro sobre fondo blanco del botón */
  font-size: 0.9rem; /* tamaño de texto del botón */
  transition: box-shadow 0.15s; /* animación suave al hacer hover */
}

/* Sombra suave al pasar el cursor por un botón habilitado */
.sel-btn:not(:disabled):hover {
  box-shadow: 0 3px 10px rgba(0,0,0,0.1); /* sombra discreta de elevación */
}

/* Botón deshabilitado cuando el pokémon no tiene PE o no está en el equipo */
.sel-btn:disabled {
  opacity: 0.45; /* semitransparente para indicar inactividad */
  cursor: not-allowed; /* cursor de bloqueo */
}

/* Etiqueta que indica que el pokémon no está en el equipo activo */
.fuera-equipo {
  color: #aaa; /* gris para no llamar la atención */
  font-size: 0.8rem; /* más pequeño que el texto principal */
}
</style>
