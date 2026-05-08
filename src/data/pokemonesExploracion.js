// umbral: número mínimo que debe salir en el RNG (1-100) para que un Pokémon de esta rareza aparezca.
// Siempre aparece el Pokémon más raro al que llegaste con el roll.
// Si el roll no supera ningún umbral (1-35), se encuentra un material en su lugar.
export const rarezas = [
  { id: 'comun',      label: 'Común',      umbral: 36, color: '#888888' },
  { id: 'pocoComun',  label: 'Poco común', umbral: 61, color: '#2d8c4e' },
  { id: 'raro',       label: 'Raro',       umbral: 79, color: '#1a6db5' },
  { id: 'muyRaro',    label: 'Muy raro',   umbral: 91, color: '#7b2fbe' },
  { id: 'legendario', label: 'Legendario', umbral: 98, color: '#c8970a' },
]

export const materiales = [
  { id: 'baya',    nombre: 'Baya Dulce',       icono: '🍓', descripcion: 'Una baya silvestre. Podría tener algún uso.' },
  { id: 'hierba',  nombre: 'Hierba Medicinal',  icono: '🌿', descripcion: 'Hierba fresca con propiedades curativas.' },
  { id: 'cristal', nombre: 'Cristal de Tierra', icono: '💎', descripcion: 'Un cristal opaco extraído del suelo.' },
  { id: 'agua',    nombre: 'Agua Pura',          icono: '💧', descripcion: 'Agua cristalina de un manantial cercano.' },
  { id: 'piedra',  nombre: 'Piedra Brillante',  icono: '🪨', descripcion: 'Una piedra con un brillo inusual.' },
]

export const pokemonesWild = [
  {
    id: 'embrix',
    nombre: 'Embrix',
    elemento: '🔥 Fuego',
    colorElemento: '#e63946',
    descripcion: 'Ágil y agresivo. Golpea fuerte desde el primer turno.',
    rareza: 'comun',
    stats: { HP: 40, Ataque: 45, Defensa: 30, Velocidad: 50, 'Ataque Esp.': 25, 'Defensa Esp.': 25 },
  },
  {
    id: 'aquell',
    nombre: 'Aquell',
    elemento: '💧 Agua',
    colorElemento: '#4895ef',
    descripcion: 'Resistente y constante. Difícil de derribar en combate.',
    rareza: 'comun',
    stats: { HP: 55, Ataque: 30, Defensa: 45, Velocidad: 30, 'Ataque Esp.': 35, 'Defensa Esp.': 40 },
  },
  {
    id: 'verdun',
    nombre: 'Verdún',
    elemento: '🌿 Planta',
    colorElemento: '#2dc653',
    descripcion: 'Equilibrado y paciente. Ideal para aprender a combatir.',
    rareza: 'comun',
    stats: { HP: 50, Ataque: 35, Defensa: 50, Velocidad: 25, 'Ataque Esp.': 30, 'Defensa Esp.': 35 },
  },
  {
    id: 'petrix',
    nombre: 'Petrix',
    elemento: '🪨 Tierra',
    colorElemento: '#a0784a',
    descripcion: 'Sólido como una roca. Su defensa es difícil de atravesar.',
    rareza: 'pocoComun',
    stats: { HP: 50, Ataque: 40, Defensa: 60, Velocidad: 20, 'Ataque Esp.': 20, 'Defensa Esp.': 45 },
  },
  {
    id: 'voltin',
    nombre: 'Voltín',
    elemento: '⚡ Eléctrico',
    colorElemento: '#f4c430',
    descripcion: 'Veloz y descargador. Ataca antes de que el rival reaccione.',
    rareza: 'raro',
    stats: { HP: 35, Ataque: 55, Defensa: 25, Velocidad: 65, 'Ataque Esp.': 45, 'Defensa Esp.': 20 },
  },
  {
    id: 'zefiro',
    nombre: 'Zéfiro',
    elemento: '🌀 Viento',
    colorElemento: '#48cae4',
    descripcion: 'Esquivo e impredecible. Rara vez recibe un golpe directo.',
    rareza: 'raro',
    stats: { HP: 40, Ataque: 35, Defensa: 30, Velocidad: 55, 'Ataque Esp.': 40, 'Defensa Esp.': 30 },
  },
  {
    id: 'noctis',
    nombre: 'Noctis',
    elemento: '🌑 Oscuro',
    colorElemento: '#5a3e8a',
    descripcion: 'Surgido de las sombras. Equilibrado y letal en combate.',
    rareza: 'muyRaro',
    stats: { HP: 50, Ataque: 55, Defensa: 40, Velocidad: 50, 'Ataque Esp.': 55, 'Defensa Esp.': 35 },
  },
  {
    id: 'solaris',
    nombre: 'Solaris',
    elemento: '✨ Luz',
    colorElemento: '#f7b731',
    descripcion: 'Un ser de pura energía luminosa. Extremadamente difícil de encontrar.',
    rareza: 'legendario',
    stats: { HP: 60, Ataque: 60, Defensa: 50, Velocidad: 55, 'Ataque Esp.': 60, 'Defensa Esp.': 50 },
  },
]
