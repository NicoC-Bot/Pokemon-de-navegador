# Conceptos usados en el proyecto

## JavaScript

### Tipos de datos (primitivos)
```js
let nombre = "Embrix"      // string
let vida = 40              // number
let activo = true          // boolean
let vacio = null           // null
let noDefinido = undefined // undefined
```

### Operadores
```js
// Matemáticos
10 + 5   // 15
10 - 5   // 5
10 * 2   // 20
10 / 2   // 5

// Comparación
5 === 5   // true (igual valor Y tipo)
5 !== 3   // true (diferente)
5 > 3     // true

// Lógicos
true && false  // false (ambos deben ser true)
true || false  // true (basta uno)
!true          // false (negación)
```

### Condiciones
```js
if (vida === 0) {
  console.log("Debilitado")
} else if (vida < 10) {
  console.log("Poca vida")
} else {
  console.log("Bien")
}
```

### Arrays y sus métodos
```js
let equipo = ["Embrix", "Aquell", "Verdún"]

equipo.push("Solaris")               // agrega al final
equipo.find(p => p === "Aquell")     // devuelve el primer elemento que cumple la condición
equipo.filter(p => p !== "Embrix")   // devuelve array sin los que cumplen la condición
equipo.some(p => p === "Solaris")    // true si al menos uno cumple
equipo[0]                            // accede por índice → "Embrix"
```

### Objetos
```js
let pokemon = {
  nombre: "Embrix",
  hp: 40,
  stats: { Ataque: 45, Defensa: 30 }
}

pokemon.nombre        // "Embrix"
pokemon.stats.Ataque  // 45
```

### Spread operator
```js
// Copia un objeto y opcionalmente reemplaza/agrega propiedades
const copia = { ...pokemon, hp: 99 }
// copia.hp = 99, pero pokemon.hp sigue siendo 40

// Con null/undefined como valor → se copia normal
const a = { vida: null }
const b = { ...a }  // { vida: null } ✅

// Spread directo de null/undefined → objeto vacío
const c = { ...null }  // {}
```

---

## Vue 3

### `ref()` — datos reactivos
```js
const vida = ref(40)

vida.value        // leer el valor (en el script)
vida.value = 30   // modificarlo

// En el template, Vue lo desenvuelve solo:
// {{ vida }}  →  muestra 40
```

### `computed()` — valor calculado automáticamente
```js
const porcentajeHP = computed(() => {
  return (vida.value / vidaMax.value) * 100
})
// Se recalcula solo cuando vida o vidaMax cambian
```

### Directivas en el template
```html
<!-- v-if / v-else-if / v-else -->
<p v-if="vida === 0">Debilitado</p>
<p v-else-if="vida < 10">Poca vida</p>
<p v-else>Sano</p>

<!-- v-for (recorrer listas) -->
<div v-for="pokemon in equipo">{{ pokemon.nombre }}</div>

<!-- v-for con índice -->
<div v-for="(pokemon, index) in equipo">{{ index }}: {{ pokemon.nombre }}</div>

<!-- @click (eventos) -->
<button @click="atacar()">Atacar</button>

<!-- :style y :class (binding dinámico) -->
<div :style="{ backgroundColor: pokemon.color }">...</div>
<div :class="{ activo: estaActivo }">...</div>
```

### Componentes, props y emits
```js
// Hijo recibe datos del padre con props
const props = defineProps({ pokemon: Object, nivel: Number })

// Hijo envía datos al padre con emits
const emit = defineEmits(['actualizar', 'volver'])
emit('actualizar', { hp: 30 })

// Padre escucha con @
// <HijoComponent @actualizar="miFuncion" />
```
