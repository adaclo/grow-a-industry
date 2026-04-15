# Grow A Industry

Grow A Industry es un microvideojuego desarrollado en Roblox Studio inspirado en juegos de decisiones como BitLife y en simuladores de gestión.

En este juego el jugador controla a una persona que empieza con pocos recursos y debe intentar construir una gran industria musical.

A lo largo de la partida el jugador deberá:

- fichar artistas;
- producir canciones;
- invertir en videoclips;
- gestionar conciertos;
- tomar decisiones sobre contratos;
- mejorar el estudio;
- reaccionar a eventos aleatorios;
- gestionar dinero, fama, reputación, seguidores y estrés.

Cada decisión afectará a la evolución de la carrera y del imperio musical del jugador.

---

## Idea principal

El juego funciona por turnos.

Cada turno representa una etapa de la carrera musical del jugador.

En cada etapa pueden aparecer distintos tipos de eventos:

- concierto;
- videoclip;
- discográfica;
- redes sociales;
- nuevo artista;
- polémica;
- colaboración;
- problema técnico;
- festival;
- entrevista;
- avería del estudio;
- viral en TikTok;
- filtración de una canción;
- cancelación de un artista.

El objetivo es llegar al final de la partida con la mayor reputación, fama y dinero posible.

---

## Mecánicas principales

### Sistema de estadísticas

El jugador tendrá varias estadísticas que cambiarán a lo largo de la partida:

- dinero;
- fama;
- reputación;
- seguidores;
- estrés;
- calidad del estudio;
- relación con artistas;
- popularidad de la discográfica.

### Sistema de decisiones

Cada evento ofrece varias opciones.

Cada opción modifica diferentes estadísticas y puede provocar consecuencias futuras.

Por ejemplo:

- invertir mucho dinero en un videoclip puede aumentar la fama;
- fichar un artista conflictivo puede aumentar los seguidores pero también el estrés;
- rechazar una colaboración puede hacer perder reputación.

### Sistema de artistas

Cada artista tendrá estadísticas propias:

- talento;
- ego;
- coste;
- popularidad;
- género musical;
- riesgo de polémica.

### Sistema de eventos aleatorios

Durante la partida podrán aparecer eventos como:

- canciones virales;
- cancelaciones;
- ofertas de discográficas;
- problemas técnicos;
- polémicas;
- giras;
- premios;
- entrevistas;
- filtraciones;
- rivalidades con otros productores.

### Sistema de finales

Dependiendo de las estadísticas del jugador, el juego podrá terminar de distintas formas:

- productor legendario;
- fracaso económico;
- productor underground;
- artista cancelado;
- estudio multimillonario;
- imperio musical internacional.

---

## Tecnologías utilizadas

- Roblox Studio
- Luau
- Visual Studio Code
- Git
- GitHub
- Rojo

---

## Estructura del proyecto

```text
src/
├─ client/
│  ├─ init.client.luau
│  └─ ui/
│     └─ MainMenu.luau
│
├─ server/
│  └─ init.server.luau
│
├─ shared/
│  ├─ Hello.luau
│  ├─ Producer.luau
│  ├─ Artist.luau
│  ├─ Event.luau
│  └─ GameManager.luau
│
├─ docs/
├─ diagrames/
└─ exports/