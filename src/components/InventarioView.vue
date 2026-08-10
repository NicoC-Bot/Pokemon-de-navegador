<script setup>
import { computed } from 'vue'
import { materiales } from '../data/pokemonesExploracion.js'

const props = defineProps({
  inventario: Object,
})

const emit = defineEmits(['volver'])

const INVENTARIO_MAX = 2000

const total = computed(() =>
  Object.values(props.inventario).reduce((s, n) => s + n, 0)
)

const porcentaje = computed(() => Math.min(100, (total.value / INVENTARIO_MAX) * 100))
</script>

<template>
  <div class="inventario-view">
    <button class="btn-volver" @click="emit('volver')">← Volver</button>

    <h2>Inventario</h2>
    <p class="subtitulo">Materiales recogidos durante tus exploraciones.</p>

    <div class="capacidad">
      <div class="capacidad-texto">
        <span>Capacidad</span>
        <span :class="{ lleno: total >= INVENTARIO_MAX }">{{ total }} / {{ INVENTARIO_MAX }}</span>
      </div>
      <div class="barra-fondo">
        <div class="barra-relleno" :style="{ width: porcentaje + '%' }" :class="{ llena: total >= INVENTARIO_MAX }"></div>
      </div>
    </div>

    <div v-if="total === 0" class="vacio">
      Tu inventario está vacío. Recoge materiales al explorar.
    </div>

    <div class="materiales-lista">
      <div
        v-for="mat in materiales"
        :key="mat.id"
        class="mat-fila"
        :class="{ inactivo: (inventario[mat.id] ?? 0) === 0 }"
      >
        <span class="mat-icono">{{ mat.icono }}</span>
        <div class="mat-info">
          <span class="mat-nombre">{{ mat.nombre }}</span>
          <span class="mat-desc">{{ mat.descripcion }}</span>
        </div>
        <span class="mat-cantidad">{{ inventario[mat.id] ?? 0 }}</span>
      </div>
    </div>


  </div>
</template>

<style scoped>
.inventario-view {
  padding: 28px 32px; /* espacio interno del panel de inventario */
  font-family: sans-serif; /* tipografía base sin serifas */
  max-width: 520px; /* ancho máximo de la vista del inventario */
}

h2 {
  font-size: 1.4rem; /* título de la sección inventario */
  margin-bottom: 4px; /* separación mínima al subtítulo */
}

.subtitulo {
  color: #666; /* texto descriptivo en gris */
  font-size: 0.9rem; /* subtítulo ligeramente reducido */
  margin-bottom: 20px; /* separación al bloque de capacidad */
}

.capacidad {
  margin-bottom: 20px; /* separación entre capacidad y la lista */
}

.capacidad-texto {
  display: flex; /* coloca etiqueta y número en la misma fila */
  justify-content: space-between; /* etiqueta a la izquierda, número a la derecha */
  font-size: 0.85rem; /* texto pequeño del indicador de capacidad */
  color: #555; /* color gris oscuro del texto de capacidad */
  margin-bottom: 6px; /* separación entre texto y barra */
}

.capacidad-texto .lleno {
  color: #e63946; /* alerta roja cuando el inventario está lleno */
  font-weight: bold; /* número en negrita cuando está lleno */
}

.barra-fondo {
  height: 8px; /* altura del contenedor de la barra de capacidad */
  background: #eee; /* fondo gris claro de la barra vacía */
  border-radius: 4px; /* esquinas redondeadas de la barra */
  overflow: hidden; /* recorta el relleno a los bordes redondeados */
}

.barra-relleno {
  height: 100%; /* relleno ocupa toda la altura de la barra */
  background: #2d8c4e; /* color verde del relleno de capacidad */
  border-radius: 4px; /* esquinas redondeadas del relleno */
  transition: width 0.3s; /* animación al cambiar la cantidad del inventario */
}

.barra-relleno.llena { background: #e63946; } /* relleno rojo cuando el inventario está lleno */

.vacio {
  color: #aaa; /* texto gris cuando no hay materiales */
  font-size: 0.88rem; /* mensaje de inventario vacío en tamaño pequeño */
  text-align: center; /* mensaje centrado en la vista */
  padding: 32px 0; /* espacio vertical para el mensaje de vacío */
}

.materiales-lista {
  display: flex; /* apila las filas de materiales verticalmente */
  flex-direction: column; /* organiza los materiales en columna */
  gap: 8px; /* separación entre filas de materiales */
  margin-bottom: 24px; /* separación al pie de la lista */
}

.mat-fila {
  display: flex; /* alinea ícono, info y cantidad en fila */
  align-items: center; /* centrado vertical de los elementos */
  gap: 14px; /* separación entre ícono, nombre y cantidad */
  padding: 12px 16px; /* espacio interno de cada fila de material */
  border: 2px solid #e0e0e0; /* borde por defecto de la fila */
  border-radius: 10px; /* esquinas redondeadas de la fila */
  transition: border-color 0.2s; /* animación al activar el material */
}

.mat-fila:not(.inactivo) { border-color: #b0d4be; } /* borde verde claro cuando hay cantidad */

.mat-fila.inactivo { opacity: 0.45; } /* fila semitransparente cuando la cantidad es cero */

.mat-icono { font-size: 1.8rem; /* emoji del material en tamaño grande */ flex-shrink: 0; /* el ícono no se comprime al ajustar el ancho */ }

.mat-info {
  display: flex; /* apila nombre y descripción verticalmente */
  flex-direction: column; /* organiza nombre y descripción en columna */
  gap: 2px; /* separación mínima entre nombre y descripción */
  flex: 1; /* bloque de info ocupa espacio restante de la fila */
  min-width: 0; /* permite que el texto se trunque correctamente */
}

.mat-nombre { font-weight: bold; /* nombre del material en negrita */ font-size: 0.95rem; /* nombre del material en tamaño casi normal */ color: #fff; /* nombre del material en blanco */ }
.mat-desc   { font-size: 0.8rem; /* descripción del material más pequeña */ color: #666; /* descripción en gris */ }

.mat-cantidad {
  font-size: 1.2rem; /* cantidad del material en tamaño grande */
  font-weight: bold; /* cantidad en negrita */
  color: #fff; /* cantidad en blanco */
  min-width: 32px; /* ancho mínimo para alinear números */
  text-align: right; /* cantidad alineada a la derecha */
}

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
</style>
