// umbral: número mínimo que debe salir en el RNG (1-100) para que un Pokémon de esta rareza aparezca.
// Siempre aparece el Pokémon más raro al que llegaste con el roll.
// Si el roll no supera ningún umbral (1-35), se encuentra un material en su lugar.
//
// Fórmula de daño:
//   ratio = clamp(statAtaque / statDefensa, 0.5, 2.0)
//   base  = floor(potencia × (ratio × 0.3 + 0.1))
//   daño  = floor(base × random(0.85, 1.0))
// Crítico (10% prob): daño × 1.5
// 'fisico'   → usa Ataque del atacante vs Defensa del defensor
// 'especial' → usa 'Ataque Esp.' vs 'Defensa Esp.'
// 'estado'   → no hace daño; solo aplica su efecto
//
// Escala de potencia (ratio=1, stats promedio):
//   p.25 → ~10 daño (~21% HP)   — golpe básico, ~5 hits para KO
//   p.40 → ~16 daño (~33% HP)   — golpe estándar, ~3-4 hits
//   p.60 → ~24 daño (~50% HP)   — golpe fuerte, ~2-3 hits
//   p.85 → ~34 daño (~71% HP)   — golpe definitivo, ~2 hits
export const rarezas = [
  { id: 'comun',      label: 'Común',      umbral: 36, color: '#888888' },
  { id: 'pocoComun',  label: 'Poco común', umbral: 61, color: '#2d8c4e' },
  { id: 'raro',       label: 'Raro',       umbral: 79, color: '#1a6db5' },
  { id: 'muyRaro',    label: 'Muy raro',   umbral: 91, color: '#7b2fbe' },
  { id: 'legendario', label: 'Legendario', umbral: 98, color: '#c8970a' },
]

export const materiales = [
  // Curativos
  { id: 'baya',              nombre: 'Baya Dulce',          icono: '🍓', descripcion: 'Una baya silvestre. Restaura 15 HP.',                    tipo: 'curativo',  hpRecuperado: 15 },
  { id: 'hierba',            nombre: 'Hierba Medicinal',    icono: '🌿', descripcion: 'Hierba con propiedades curativas. Restaura 25 HP.',       tipo: 'curativo',  hpRecuperado: 25 },
  { id: 'nectar',            nombre: 'Néctar Silvestre',    icono: '🍯', descripcion: 'Néctar dulce y energizante. Restaura 20 HP.',             tipo: 'curativo',  hpRecuperado: 20 },
  { id: 'frutaMistica',      nombre: 'Fruta Mística',       icono: '🍇', descripcion: 'Fruta de propiedades extraordinarias. Restaura 40 HP.',   tipo: 'curativo',  hpRecuperado: 40 },
  // Generales
  { id: 'cristal',           nombre: 'Cristal de Tierra',   icono: '💎', descripcion: 'Un cristal opaco extraído del suelo.',                   tipo: 'general' },
  { id: 'agua',              nombre: 'Agua Pura',            icono: '💧', descripcion: 'Agua cristalina de un manantial cercano.',               tipo: 'general' },
  { id: 'piedra',            nombre: 'Piedra Brillante',    icono: '🪨', descripcion: 'Una piedra con un brillo inusual.',                      tipo: 'general' },
  // Ascensión — uno por elemento
  { id: 'brasaIgnia',        nombre: 'Brasa Ígnia',         icono: '🔥', descripcion: 'Una brasa que arde sin consumirse.',                     tipo: 'ascension',          elemento: '🔥 Fuego'     },
  { id: 'perlaMarina',       nombre: 'Perla Marina',        icono: '🫧', descripcion: 'Perla formada en las profundidades marinas.',            tipo: 'ascension',          elemento: '💧 Agua'      },
  { id: 'semillaAncestral',  nombre: 'Semilla Ancestral',   icono: '🌱', descripcion: 'Semilla que irradia vida en su interior.',               tipo: 'ascension',          elemento: '🌿 Planta'    },
  { id: 'rocaArcana',        nombre: 'Roca Arcana',         icono: '🗿', descripcion: 'Roca imbuida con energía telúrica.',                    tipo: 'ascension',          elemento: '🪨 Tierra'    },
  { id: 'chispaEstatica',    nombre: 'Chispa Estática',     icono: '⚡', descripcion: 'Chispa atrapada en un cristal eléctrico.',              tipo: 'ascension',          elemento: '⚡ Eléctrico' },
  { id: 'plumaEterea',       nombre: 'Pluma Etérea',        icono: '🪶', descripcion: 'Pluma que flota sin ningún apoyo.',                     tipo: 'ascension',          elemento: '🌀 Viento'    },
  { id: 'sombraCristalizada',nombre: 'Sombra Cristalizada', icono: '🌑', descripcion: 'Oscuridad solidificada en forma de cristal.',           tipo: 'ascension',          elemento: '🌑 Oscuro'    },
  { id: 'fragmentoSolar',    nombre: 'Fragmento Solar',     icono: '☀️', descripcion: 'Fragmento de luz pura solidificada.',                   tipo: 'ascension',          elemento: '✨ Luz'        },
  // Curativos elementales — uno por elemento, solo curan al elemento correspondiente
  { id: 'chileIgnio',        nombre: 'Chile Ígneo',         icono: '🌶️', descripcion: 'Picante y ardiente. Restaura 55 HP solo a Pokémon de Fuego.',           tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '🔥 Fuego'     },
  { id: 'bayaMarina',        nombre: 'Baya Marina',         icono: '🫐', descripcion: 'Jugosa baya de las costas. Restaura 55 HP solo a Pokémon de Agua.',       tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '💧 Agua'      },
  { id: 'kiwiSilvestre',     nombre: 'Kiwi Silvestre',      icono: '🥝', descripcion: 'Fruta de la selva profunda. Restaura 55 HP solo a Pokémon de Planta.',    tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '🌿 Planta'    },
  { id: 'raizArcana',        nombre: 'Raíz Arcana',         icono: '🍠', descripcion: 'Raíz de la tierra profunda. Restaura 55 HP solo a Pokémon de Tierra.',    tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '🪨 Tierra'    },
  { id: 'bayaElectra',       nombre: 'Baya Electra',        icono: '🍋', descripcion: 'Baya cargada de electricidad. Restaura 55 HP solo a Pokémon Eléctrico.',  tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '⚡ Eléctrico' },
  { id: 'vainaAerea',        nombre: 'Vaina Aérea',         icono: '🫛', descripcion: 'Vaina que flota en el viento. Restaura 55 HP solo a Pokémon de Viento.',  tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '🌀 Viento'    },
  { id: 'frutoSombrio',      nombre: 'Fruto Sombrío',       icono: '🫒', descripcion: 'Fruto que crece sin luz. Restaura 55 HP solo a Pokémon de Oscuro.',       tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '🌑 Oscuro'    },
  { id: 'frutaAurea',        nombre: 'Fruta Áurea',         icono: '🍊', descripcion: 'Fruta dorada que desprende luz propia. Restaura 55 HP solo a Pokémon de Luz.', tipo: 'curativo-elemental', hpRecuperado: 55, elemento: '✨ Luz'   },
]

export const COSTO_ASCENSION = 3

export const habilidadesAscension = [
  { nivel: 1, nombre: 'Habilidad Innata I',  descripcion: 'Habilidad por definir.' },
  { nivel: 2, nombre: 'Habilidad Innata II', descripcion: 'Habilidad por definir.' },
]

export const pokemonesWild = [
  {
    id: 'embrix',
    nombre: 'Embrix',
    elemento: '🔥 Fuego',
    colorElemento: '#e63946',
    descripcion: 'Ágil y agresivo. Golpea fuerte desde el primer turno.',
    rareza: 'comun',
    stats: { HP: 40, Ataque: 45, Defensa: 30, Velocidad: 50, 'Ataque Esp.': 25, 'Defensa Esp.': 32 },
    habilidades: [
      {
        id: 'ascua',
        nombre: 'Ascua',
        tipo: 'fisico',
        potencia: 30,
        precision: 100,
        descripcion: 'Golpe de fuego rápido. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'llamarada',
        nombre: 'Llamarada',
        tipo: 'fisico',
        potencia: 65,
        precision: 80,
        descripcion: 'Explosión de fuego intensa. 40% de quemar al rival y reducir su Ataque un 20% por 2 turnos.',
        efecto: { tipo: 'quemadura', stat: 'Ataque', reduccion: 20, turnos: 2, probabilidad: 40, acumulable: false },
      },
    ],
  },
  {
    id: 'aquell',
    nombre: 'Aquell',
    elemento: '💧 Agua',
    colorElemento: '#4895ef',
    descripcion: 'Resistente y constante. Difícil de derribar en combate.',
    rareza: 'comun',
    stats: { HP: 62, Ataque: 30, Defensa: 45, Velocidad: 30, 'Ataque Esp.': 35, 'Defensa Esp.': 40 },
    habilidades: [
      {
        id: 'burbuja',
        nombre: 'Burbuja',
        tipo: 'especial',
        potencia: 25,
        precision: 100,
        descripcion: 'Disparo de burbujas de agua. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'torrente',
        nombre: 'Torrente',
        tipo: 'especial',
        potencia: 55,
        precision: 90,
        descripcion: 'Chorro potente de agua. Si Aquell tiene ≤50% HP, la potencia sube a 65.',
        efecto: { tipo: 'condicion-hp', umbral: 0.5, potenciaBonus: 10 },
      },
    ],
  },
  {
    id: 'verdun',
    nombre: 'Verdún',
    elemento: '🌿 Planta',
    colorElemento: '#2dc653',
    descripcion: 'Equilibrado y paciente. Ideal para aprender a combatir.',
    rareza: 'comun',
    stats: { HP: 60, Ataque: 42, Defensa: 50, Velocidad: 25, 'Ataque Esp.': 30, 'Defensa Esp.': 35 },
    habilidades: [
      {
        id: 'latigo-cepa',
        nombre: 'Látigo Cepa',
        tipo: 'fisico',
        potencia: 48,
        precision: 100,
        descripcion: 'Golpe con una cepa vegetal. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'regeneracion',
        nombre: 'Regeneración',
        tipo: 'estado',
        potencia: null,
        precision: null,
        descripcion: 'Recupera el 30% del HP máximo propio. Cooldown: 2 turnos.',
        efecto: { tipo: 'regeneracion', porcentaje: 30, cooldown: 2 },
      },
    ],
  },
  {
    id: 'petrix',
    nombre: 'Petrix',
    elemento: '🪨 Tierra',
    colorElemento: '#a0784a',
    descripcion: 'Sólido como una roca. Su defensa es difícil de atravesar.',
    rareza: 'pocoComun',
    stats: { HP: 65, Ataque: 40, Defensa: 60, Velocidad: 20, 'Ataque Esp.': 20, 'Defensa Esp.': 45 },
    habilidades: [
      {
        id: 'golpe-roca',
        nombre: 'Golpe Rocoso',
        tipo: 'fisico',
        potencia: 35,
        precision: 100,
        descripcion: 'Impacto directo con una roca afilada. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'terremoto',
        nombre: 'Terremoto',
        tipo: 'fisico',
        potencia: 70,
        precision: 85,
        descripcion: 'Sacudida violenta del suelo. 35% de reducir la Velocidad del rival un 25% por 2 turnos.',
        efecto: { tipo: 'debuff', stat: 'Velocidad', reduccion: 25, turnos: 2, probabilidad: 35, acumulable: false },
      },
    ],
  },
  {
    id: 'voltin',
    nombre: 'Voltín',
    elemento: '⚡ Eléctrico',
    colorElemento: '#f4c430',
    descripcion: 'Veloz y descargador. Ataca antes de que el rival reaccione.',
    rareza: 'raro',
    stats: { HP: 35, Ataque: 55, Defensa: 25, Velocidad: 65, 'Ataque Esp.': 45, 'Defensa Esp.': 28 },
    habilidades: [
      {
        id: 'chispazo',
        nombre: 'Chispazo',
        tipo: 'fisico',
        potencia: 30,
        precision: 100,
        descripcion: 'Descarga eléctrica rápida. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'descarga',
        nombre: 'Descarga',
        tipo: 'especial',
        potencia: 55,
        precision: 90,
        descripcion: 'Ráfaga eléctrica intensa. 40% de paralizar al rival, reduciendo su Velocidad un 30% por 2 turnos.',
        efecto: { tipo: 'paralisis', stat: 'Velocidad', reduccion: 30, turnos: 2, probabilidad: 40, acumulable: false },
      },
    ],
  },
  {
    id: 'zefiro',
    nombre: 'Zéfiro',
    elemento: '🌀 Viento',
    colorElemento: '#48cae4',
    descripcion: 'Esquivo e impredecible. Rara vez recibe un golpe directo.',
    rareza: 'raro',
    stats: { HP: 40, Ataque: 35, Defensa: 30, Velocidad: 55, 'Ataque Esp.': 40, 'Defensa Esp.': 30 },
    habilidades: [
      {
        id: 'rafaga',
        nombre: 'Ráfaga',
        tipo: 'especial',
        potencia: 30,
        precision: 100,
        descripcion: 'Golpe de viento ligero. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'vendaval',
        nombre: 'Vendaval',
        tipo: 'especial',
        potencia: 60,
        precision: 75,
        descripcion: 'Ráfaga cortante e impredecible. 25% de esquivar el siguiente ataque recibido este turno.',
        efecto: { tipo: 'esquiva', probabilidad: 25, acumulable: false },
      },
    ],
  },
  {
    id: 'noctis',
    nombre: 'Noctis',
    elemento: '🌑 Oscuro',
    colorElemento: '#5a3e8a',
    descripcion: 'Surgido de las sombras. Equilibrado y letal en combate.',
    rareza: 'muyRaro',
    stats: { HP: 50, Ataque: 55, Defensa: 40, Velocidad: 50, 'Ataque Esp.': 48, 'Defensa Esp.': 35 },
    habilidades: [
      {
        id: 'zarpazo',
        nombre: 'Zarpazo',
        tipo: 'fisico',
        potencia: 35,
        precision: 100,
        descripcion: 'Golpe oscuro veloz. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'sombra-cruel',
        nombre: 'Sombra Cruel',
        tipo: 'especial',
        potencia: 65,
        precision: 85,
        descripcion: 'Ataque de energía oscura. 30% de acumular debuff en Ataque Esp. rival (−3% por stack, máx. 3 stacks, 2 turnos).',
        efecto: { tipo: 'debuff', stat: 'Ataque Esp.', reduccion: 3, turnos: 2, probabilidad: 30, acumulable: true, stacksMax: 3 },
      },
    ],
  },
  {
    id: 'solaris',
    nombre: 'Solaris',
    elemento: '✨ Luz',
    colorElemento: '#f7b731',
    descripcion: 'Un ser de pura energía luminosa. Extremadamente difícil de encontrar.',
    rareza: 'legendario',
    stats: { HP: 60, Ataque: 60, Defensa: 50, Velocidad: 55, 'Ataque Esp.': 53, 'Defensa Esp.': 50 },
    habilidades: [
      {
        id: 'destello',
        nombre: 'Destello',
        tipo: 'especial',
        potencia: 35,
        precision: 100,
        descripcion: 'Ráfaga de luz pura. Sin efectos adicionales.',
        efecto: null,
      },
      {
        id: 'rayo-solar',
        nombre: 'Rayo Solar',
        tipo: 'especial',
        potencia: 80,
        precision: 85,
        descripcion: 'Concentración de energía solar. 40% de acumular debuff en Defensa Esp. rival (−4% por stack, máx. 3 stacks, 2 turnos).',
        efecto: { tipo: 'debuff', stat: 'Defensa Esp.', reduccion: 4, turnos: 2, probabilidad: 40, acumulable: true, stacksMax: 3 },
      },
    ],
  },
]
