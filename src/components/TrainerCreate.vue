<script setup>
import { ref } from 'vue'

const emit = defineEmits(['entrenador-creado', 'volver'])

const nombre = ref('')
const claseElegida = ref(null)

const guiaStats = [
  { icono: '⚔️',  nombre: 'Ataque',         descripcion: 'Potencia de los golpes físicos del Pokémon.' },
  { icono: '🛡️',  nombre: 'Defensa',         descripcion: 'Resistencia ante golpes físicos recibidos.' },
  { icono: '❤️',  nombre: 'HP',              descripcion: 'Puntos de vida totales en combate.' },
  { icono: '💨',  nombre: 'Velocidad',        descripcion: 'Determina quién ataca primero en cada turno.' },
  { icono: '✨',  nombre: 'Ataque Esp.',      descripcion: 'Potencia de los ataques elementales y mágicos.' },
  { icono: '🔮',  nombre: 'Defensa Esp.',     descripcion: 'Resistencia ante ataques elementales recibidos.' },
  { icono: '💥',  nombre: 'Daño Físico',      descripcion: 'Multiplicador de daño al usar movimientos físicos.' },
  { icono: '🌀',  nombre: 'Daño Elemental',   descripcion: 'Multiplicador de daño al usar movimientos elementales.' },
  { icono: '🌫️',  nombre: 'Evasión',          descripcion: 'Probabilidad de esquivar ataques del rival.' },
]

const clases = [
  {
    id: 'fuego',
    label: '🔥 Fuego',
    color: '#e63946',
    // descripcion: 'Atacante físico puro. Alto daño directo, pero frágil y sin poder especial.',
    descripcion: 'Aumenta el ataque, velocidad y daño físico de tus Pokémon. Penaliza su defensa, ataque especial, daño elemental y evasión.',
    stats: [
      { nombre: 'Ataque',        valor: +20 },
      { nombre: 'Velocidad',     valor:  +5 },
      { nombre: 'Daño Físico',   valor: +20 },
      { nombre: 'Ataque Esp.',   valor: -10 },
      { nombre: 'Defensa',       valor: -15 },
      { nombre: 'Daño Elemental',valor: -10 },
      { nombre: 'Evasión',       valor:  -5 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'agua',
    label: '💧 Agua',
    color: '#4895ef',
    // descripcion: 'Tanque de vida. Se regenera constantemente en batalla, difícil de desgastar.',
    descripcion: 'Aumenta la vida, defensa especial, daño elemental y evasión de tus Pokémon. Penaliza su ataque, daño físico y velocidad.',
    stats: [
      { nombre: 'HP',            valor: +20 },
      { nombre: 'Defensa Esp.',  valor: +10 },
      { nombre: 'Daño Elemental',valor: +15 },
      { nombre: 'Evasión',       valor: +10 },
      { nombre: 'Ataque',        valor: -10 },
      { nombre: 'Daño Físico',   valor:  -5 },
      { nombre: 'Velocidad',     valor:  -5 },
      { nombre: 'Defensa',       valor:   0 },
      { nombre: 'Ataque Esp.',   valor:   0 },
    ]
  },
  {
    id: 'planta',
    label: '🌿 Planta',
    color: '#2dc653',
    // descripcion: 'Tanque de armadura. Reduce el daño recibido con su defensa física brutal.',
    descripcion: 'Maximiza la defensa de tus Pokémon y mejora levemente el daño elemental. Penaliza su velocidad, ataque especial y evasión.',
    stats: [
      { nombre: 'Defensa',       valor: +25 },
      { nombre: 'Daño Elemental',valor:  +5 },
      { nombre: 'Velocidad',     valor: -15 },
      { nombre: 'Ataque Esp.',   valor:  -5 },
      { nombre: 'Evasión',       valor:  -5 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Ataque',        valor:   0 },
      { nombre: 'Daño Físico',   valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'electro',
    label: '⚡ Eléctrico',
    color: '#f4d35e',
    // descripcion: 'Velocidad extrema. Siempre ataca primero, pero sus Pokémon son muy frágiles.',
    descripcion: 'Dispara la velocidad, daño físico y evasión de tus Pokémon, y mejora su ataque. Penaliza fuertemente su defensa y vida.',
    stats: [
      { nombre: 'Velocidad',     valor: +25 },
      { nombre: 'Ataque',        valor:  +5 },
      { nombre: 'Daño Físico',   valor: +15 },
      { nombre: 'Evasión',       valor: +25 },
      { nombre: 'Defensa',       valor: -15 },
      { nombre: 'HP',            valor: -10 },
      { nombre: 'Ataque Esp.',   valor:   0 },
      { nombre: 'Daño Elemental',valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
  {
    id: 'psiquico',
    label: '🧠 Psíquico',
    color: '#9b5de5',
    // descripcion: 'Especialista en ataques mágicos. Poderoso mentalmente, inútil en combate físico.',
    descripcion: 'Eleva el ataque especial, defensa especial, daño elemental y evasión de tus Pokémon. Penaliza fuertemente su ataque, defensa y daño físico.',
    stats: [
      { nombre: 'Ataque Esp.',   valor: +20 },
      { nombre: 'Defensa Esp.',  valor: +10 },
      { nombre: 'Daño Elemental',valor: +25 },
      { nombre: 'Evasión',       valor: +15 },
      { nombre: 'Ataque',        valor: -15 },
      { nombre: 'Defensa',       valor:  -5 },
      { nombre: 'Daño Físico',   valor: -20 },
      { nombre: 'HP',            valor:   0 },
      { nombre: 'Velocidad',     valor:   0 },
    ]
  },
  {
    id: 'roca',
    label: '🛡️ Roca',
    color: '#8d6e63',
    // descripcion: 'Fortaleza física. Defensa y vida brutales, pero lento y sin poder especial.',
    descripcion: 'Maximiza la defensa y vida de tus Pokémon, y mejora su daño físico. Penaliza fuertemente su velocidad, evasión, ataque especial y daño elemental.',
    stats: [
      { nombre: 'Defensa',       valor: +25 },
      { nombre: 'HP',            valor: +10 },
      { nombre: 'Daño Físico',   valor: +10 },
      { nombre: 'Velocidad',     valor: -20 },
      { nombre: 'Ataque Esp.',   valor: -15 },
      { nombre: 'Daño Elemental',valor: -15 },
      { nombre: 'Evasión',       valor: -20 },
      { nombre: 'Ataque',        valor:   0 },
      { nombre: 'Defensa Esp.',  valor:   0 },
    ]
  },
]

function crearEntrenador() {
  if (nombre.value === '') {
    alert('Debes ingresar un nombre')
    return
  }
  if (claseElegida.value === null) {
    alert('Debes elegir una clase')
    return
  }

  emit('entrenador-creado', {
    nombre: nombre.value,
    clase: claseElegida.value,
  })
}
</script>

<template>
  <div class="crear-entrenador">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>
    <h1>Crea tu Entrenador</h1>

    <div class="campo-nombre">
      <label>Nombre del entrenador</label>
      <input v-model="nombre" type="text" placeholder="Ej: Ash" />
    </div>

    <div class="selector-clase">

      <!-- Columna izquierda: lista de clases -->
      <div class="lista-clases">
        <label>Elige tu clase</label>
        <div
          v-for="clase in clases"
          class="clase-item"
          :class="{ seleccionada: claseElegida && claseElegida.id === clase.id }"
          :style="claseElegida && claseElegida.id === clase.id ? { borderColor: clase.color, color: clase.color } : {}"
          @click="claseElegida = clase"
        >
          {{ clase.label }}
        </div>
      </div>

      <!-- Panel derecho: detalle de la clase elegida -->
      <Transition name="detalle">
        <div
          v-if="claseElegida"
          class="detalle-clase"
          :style="{ borderColor: claseElegida.color }"
        >
          <h2 :style="{ color: claseElegida.color }">{{ claseElegida.label }}</h2>
          <p class="clase-desc">{{ claseElegida.descripcion }}</p>

          <div class="stats">
            <div v-for="stat in claseElegida.stats" class="stat-fila">
              <span class="stat-nombre">{{ stat.nombre }}</span>
              <span
                class="stat-valor"
                :class="stat.valor > 0 ? 'positivo' : stat.valor < 0 ? 'negativo' : 'neutro'"
              >
                {{ stat.valor > 0 ? '+' + stat.valor : stat.valor === 0 ? '—' : stat.valor }}%
              </span>
            </div>
          </div>
        </div>

        <div v-else class="detalle-vacio">
          <span>👈 Selecciona una clase para ver sus estadísticas</span>
        </div>
      </Transition>

    </div>

    <!-- Guía de stats -->
    <div class="guia-stats">
      <h3>¿Qué significa cada stat?</h3>
      <div class="guia-grid">
        <div v-for="guia in guiaStats" class="guia-card">
          <span class="guia-icono">{{ guia.icono }}</span>
          <div>
            <span class="guia-nombre">{{ guia.nombre }}</span>
            <span class="guia-desc">{{ guia.descripcion }}</span>
          </div>
        </div>
      </div>
    </div>

    <button
      class="btn-elegir"
      :style="claseElegida ? { backgroundColor: claseElegida.color } : {}"
      @click="crearEntrenador"
    >
      Elegir compañero
    </button>
  </div>
</template>

<style scoped>
.crear-entrenador {
  max-width: 760px; /* ancho máximo del formulario de creación */
  margin: 48px auto; /* centrado horizontal con espacio superior */
  font-family: sans-serif; /* tipografía base del componente */
  padding: 0 16px; /* margen lateral para pantallas pequeñas */
}

h1 {
  font-size: 2rem; /* tamaño del título principal de la pantalla */
  text-align: center; /* centra el título horizontalmente */
  margin-bottom: 28px; /* separación del título al siguiente bloque */
}

.campo-nombre {
  margin-bottom: 28px; /* separación del campo nombre al selector de clase */
}

label {
  display: block; /* ocupa toda la línea para el texto de etiqueta */
  font-weight: bold; /* negrita para destacar la etiqueta del campo */
  margin-bottom: 8px; /* espacio entre la etiqueta y el input */
}

input {
  width: 100%; /* el input ocupa todo el ancho disponible */
  padding: 10px; /* espacio interno del campo de texto */
  font-size: 1rem; /* tamaño de fuente estándar en el input */
  border: 2px solid #ccc; /* borde gris claro del campo de nombre */
  border-radius: 8px; /* esquinas redondeadas del input */
  box-sizing: border-box; /* el padding no desborda el ancho declarado */
}

.selector-clase {
  display: flex; /* lista y panel derecho en fila horizontal */
  gap: 20px; /* separación entre lista de clases y detalle */
  align-items: flex-start; /* alinea lista y panel al borde superior */
  min-height: 300px; /* altura mínima para no colapsar sin selección */
}

.lista-clases {
  display: flex; /* items de clase apilados en columna */
  flex-direction: column; /* apila verticalmente los items de clase */
  gap: 8px; /* separación entre cada opción de clase */
  min-width: 170px; /* ancho mínimo de la columna de clases */
}

.clase-item {
  padding: 10px 14px; /* espacio interno de cada botón de clase */
  border: 2px solid #ccc; /* borde por defecto de cada opción de clase */
  border-radius: 8px; /* esquinas redondeadas del item de clase */
  cursor: pointer; /* cursor de mano al pasar sobre la clase */
  font-weight: bold; /* nombre de la clase en negrita */
  transition: border-color 0.2s, color 0.2s, background-color 0.2s; /* transición suave al seleccionar o hacer hover */
}

.clase-item:hover {
  background-color: #f5f5f5; /* fondo claro al pasar el cursor por encima */
}

.clase-item.seleccionada {
  background-color: #fafafa; /* fondo sutil de la clase actualmente elegida */
}

.detalle-clase {
  flex: 1; /* el panel de detalle ocupa el espacio restante */
  border: 2px solid #ccc; /* borde del panel de estadísticas de la clase */
  border-radius: 12px; /* esquinas redondeadas del panel de detalle */
  padding: 20px 24px; /* espacio interno del panel de estadísticas */
}

.detalle-vacio {
  flex: 1; /* ocupa el mismo espacio que el panel con datos */
  border: 2px dashed #ccc; /* borde discontinuo cuando no hay clase elegida */
  border-radius: 12px; /* esquinas redondeadas del panel vacío */
  padding: 20px 24px; /* espacio interno del mensaje de selección */
  display: flex; /* centra el mensaje de instrucción */
  align-items: center; /* centrado vertical del texto de ayuda */
  justify-content: center; /* centrado horizontal del texto de ayuda */
  color: #aaa; /* color gris claro del texto de instrucción */
  font-size: 0.95rem; /* tamaño del texto de instrucción vacía */
}

h2 {
  margin: 0 0 8px 0; /* sin margen superior, separación inferior al párrafo */
  font-size: 1.4rem; /* tamaño del nombre de la clase seleccionada */
}

.clase-desc {
  color: #555; /* color del texto descriptivo de la clase */
  margin: 0 0 16px 0; /* separación de la descripción a las estadísticas */
  font-size: 0.9rem; /* tamaño reducido del texto descriptivo */
}

.stats {
  display: flex; /* lista de stats en disposición de columna */
  flex-direction: column; /* apila filas de stats una bajo otra */
  gap: 6px; /* separación entre cada fila de estadística */
}

.stat-fila {
  display: flex; /* nombre y valor del stat en fila horizontal */
  justify-content: space-between; /* nombre a la izquierda, valor a la derecha */
  align-items: center; /* alinea verticalmente nombre y valor del stat */
  padding: 4px 8px; /* espacio interno de cada fila de stat */
  background: #f9f9f9; /* fondo claro de cada fila de estadística */
  border-radius: 6px; /* esquinas suavizadas de la fila de stat */
  font-size: 0.9rem; /* tamaño de fuente de cada fila de stat */
}

.stat-nombre { color: #333; } /* color oscuro del nombre de la estadística */
.stat-valor  { font-weight: bold; } /* valor en negrita para destacarlo */
.positivo    { color: #2dc653; } /* verde para bonificaciones positivas */
.negativo    { color: #e63946; } /* rojo para penalizaciones de stat */
.neutro      { color: #aaa; } /* gris para stats sin modificación */

/* Guía de stats */
.guia-stats {
  margin-top: 40px; /* separación de la guía al selector de clase */
}

.guia-stats h3 {
  font-size: 1rem; /* tamaño del título de la sección guía */
  font-weight: bold; /* negrita del título de la guía de stats */
  margin-bottom: 12px; /* separación del título a las tarjetas de guía */
  color: #444; /* color del título de la sección guía */
}

.guia-grid {
  display: grid; /* tarjetas de guía en cuadrícula */
  grid-template-columns: 1fr 1fr 1fr; /* tres columnas iguales para las tarjetas */
  gap: 10px; /* separación entre tarjetas de guía */
}

.guia-card {
  display: flex; /* ícono y texto en fila dentro de la tarjeta */
  align-items: flex-start; /* alinea ícono y texto al borde superior */
  gap: 10px; /* separación entre ícono y descripción del stat */
  background: #f9f9f9; /* fondo claro de cada tarjeta de guía */
  border: 1px solid #e0e0e0; /* borde sutil de cada tarjeta de guía */
  border-radius: 10px; /* esquinas redondeadas de la tarjeta de guía */
  padding: 10px 12px; /* espacio interno de la tarjeta de guía */
}

.guia-icono {
  font-size: 1.4rem; /* tamaño del emoji de cada stat en la guía */
  line-height: 1; /* evita espacio extra bajo el emoji */
  flex-shrink: 0; /* el ícono no se encoge al reducir el ancho */
}

.guia-card div {
  display: flex; /* nombre y descripción apilados en columna */
  flex-direction: column; /* coloca nombre arriba y descripción abajo */
  gap: 2px; /* mínima separación entre nombre y descripción */
}

.guia-nombre {
  font-weight: bold; /* nombre del stat en negrita */
  font-size: 0.85rem; /* tamaño del nombre del stat en la guía */
  color: #222; /* color oscuro del nombre del stat */
}

.guia-desc {
  font-size: 0.78rem; /* tamaño pequeño del texto descriptivo del stat */
  color: #666; /* color gris de la descripción del stat */
}

/* Botones */
.btn-volver {
  display: block; /* el botón ocupa su propia línea */
  margin: 0 auto 20px; /* centrado con separación inferior */
  padding: 8px 18px; /* espacio interno del botón volver */
  background: white; /* fondo blanco del botón volver */
  border: 2px solid #ccc; /* borde gris claro del botón volver */
  border-radius: 8px; /* esquinas redondeadas del botón volver */
  cursor: pointer; /* cursor de mano sobre el botón */
  font-size: 0.88rem; /* tamaño de fuente del botón volver */
  color: #555; /* color gris del texto del botón volver */
  transition: border-color 0.2s, color 0.2s; /* transición suave al hacer hover */
}

.btn-volver:hover {
  border-color: #888; /* oscurece el borde al pasar el cursor */
  color: #222; /* oscurece el texto al hacer hover */
}

.btn-elegir {
  display: block; /* el botón ocupa su propia línea */
  margin: 28px auto 0; /* centrado con separación superior */
  padding: 12px 40px; /* espacio interno amplio del botón principal */
  font-size: 1rem; /* tamaño de fuente del botón elegir */
  background-color: #555; /* color gris base hasta elegir una clase */
  color: white; /* texto blanco sobre el fondo del botón */
  border: none; /* sin borde para el botón de acción principal */
  border-radius: 10px; /* esquinas redondeadas del botón elegir */
  cursor: pointer; /* cursor de mano sobre el botón */
  transition: background-color 0.3s, transform 0.1s; /* transición de color y escala */
}

.btn-elegir:hover {
  filter: brightness(0.9); /* oscurece el color de clase al hacer hover */
  transform: scale(1.02); /* agranda ligeramente el botón al pasar el cursor */
}

.detalle-enter-active,
.detalle-leave-active {
  transition: opacity 0.25s ease, transform 0.25s ease; /* duración de animación de entrada y salida del panel */
}

.detalle-enter-from,
.detalle-leave-to {
  opacity: 0; /* panel invisible al iniciar entrada o salida */
  transform: translateX(12px); /* desplazamiento lateral al animar el panel */
}
</style>
