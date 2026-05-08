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

    <button class="btn-volver" @click="emit('volver')">← Volver</button>

  </div>
</template>

<style scoped>
.inventario-view {
  padding: 28px 32px;
  font-family: sans-serif;
  max-width: 520px;
}

h2 {
  font-size: 1.4rem;
  margin-bottom: 4px;
}

.subtitulo {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 20px;
}

.capacidad {
  margin-bottom: 20px;
}

.capacidad-texto {
  display: flex;
  justify-content: space-between;
  font-size: 0.85rem;
  color: #555;
  margin-bottom: 6px;
}

.capacidad-texto .lleno {
  color: #e63946;
  font-weight: bold;
}

.barra-fondo {
  height: 8px;
  background: #eee;
  border-radius: 4px;
  overflow: hidden;
}

.barra-relleno {
  height: 100%;
  background: #2d8c4e;
  border-radius: 4px;
  transition: width 0.3s;
}

.barra-relleno.llena { background: #e63946; }

.vacio {
  color: #aaa;
  font-size: 0.88rem;
  text-align: center;
  padding: 32px 0;
}

.materiales-lista {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 24px;
}

.mat-fila {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 12px 16px;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  transition: border-color 0.2s;
}

.mat-fila:not(.inactivo) { border-color: #b0d4be; }

.mat-fila.inactivo { opacity: 0.45; }

.mat-icono { font-size: 1.8rem; flex-shrink: 0; }

.mat-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
  flex: 1;
  min-width: 0;
}

.mat-nombre { font-weight: bold; font-size: 0.95rem; color: #fff; }
.mat-desc   { font-size: 0.8rem; color: #666; }

.mat-cantidad {
  font-size: 1.2rem;
  font-weight: bold;
  color: #222;
  min-width: 32px;
  text-align: right;
}

.btn-volver {
  padding: 8px 18px;
  background: white;
  border: 2px solid #ccc;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.88rem;
  color: #555;
  transition: border-color 0.2s;
}

.btn-volver:hover { border-color: #888; color: #222; }
</style>
