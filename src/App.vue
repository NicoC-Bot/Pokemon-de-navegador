<script setup>
import { ref } from 'vue'
import TrainerCreate from './components/TrainerCreate.vue'
import StarterSelection from './components/StarterSelection.vue'

const entrenador = ref(null)

function recibirEntrenador(datos) {
  entrenador.value = datos
}
</script>

<template>
  <TrainerCreate v-if="entrenador === null" @entrenador-creado="recibirEntrenador" />
  <StarterSelection v-else :entrenador="entrenador" />
</template>
