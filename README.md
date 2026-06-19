# Practica 2 — Juego de Entrenadores

Proyecto de juego tipo Pokémon construido con Vue 3 y Vite. Incluye sistema de combate, exploración, entrenamiento, inventario y gestión de equipo.

---

## Tecnologías usadas

| Herramienta | Versión | Para qué |
|---|---|---|
| Vue | ^3.5.32 | Interfaz visual en componentes |
| Vite | ^8.0.4 | Servidor local y compilación |
| Node.js | Requerido | Ejecutar las herramientas de desarrollo |
| npm | Incluido con Node.js | Gestión de dependencias |
| PHP | Incluido con XAMPP | API para la base de datos |
| MySQL | Incluido con XAMPP | Base de datos de partidas |
| Apache | Incluido con XAMPP | Servidor para PHP en producción |

---

## Requisitos previos

- [Node.js](https://nodejs.org) instalado
- [XAMPP](https://www.apachefriends.org) instalado (para base de datos)

---

## Cómo correr el proyecto en desarrollo

```bash
# 1. Instalar dependencias
npm install

# 2. Arrancar el servidor local
npm run dev
```

El proyecto estará disponible en `http://localhost:5173`

---

## Cómo compilar para producción

```bash
npm run build
```

Genera la carpeta `dist/` con el proyecto optimizado. Para usarlo con XAMPP, copiar el contenido de `dist/` a `c:/xampp/htdocs/Practica_2/`.

---

## Base de datos

Requiere XAMPP con Apache y MySQL activos.

1. Abrir phpMyAdmin en `http://localhost/phpmyadmin`
2. Crear base de datos `practica2`
3. La tabla `partidas` se crea con esta estructura:

```sql
CREATE TABLE partidas (
  id INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(100) NOT NULL,
  creada_en DATETIME NOT NULL,
  datos LONGTEXT NOT NULL,
  PRIMARY KEY (id)
);
```

---

## Estructura del proyecto

```
src/
├── main.js              — arranca Vue
├── App.vue              — componente raíz, orquesta las vistas
├── style.css            — estilos globales
├── components/          — vistas y componentes del juego
├── data/                — datos estáticos (pokémones, habilidades)
└── utils/               — funciones reutilizables (calcularStats)

api/
└── partidas.php         — API PHP para guardar y cargar partidas

public/                  — archivos estáticos (favicon, íconos)
```

---

## Comandos disponibles

| Comando | Descripción |
|---|---|
| `npm run dev` | Arranca el servidor local de desarrollo |
| `npm run build` | Compila el proyecto para producción |
| `npm run preview` | Previsualiza el build de producción localmente |
