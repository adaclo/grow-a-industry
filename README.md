# Grow A Industry

Grow A Industry es un microvideojuego desarrollado en Roblox Studio inspirado en simuladores de gestión y juegos narrativos de decisiones como BitLife.

En este juego el jugador asume el rol de un productor musical que empieza desde su habitación con un presupuesto mínimo y debe construir una gran industria discográfica. A través de un ordenador de estudio virtual (Studio Computer), el jugador tomará todas las decisiones ejecutivas y creativas.

A lo largo de la partida el jugador deberá:
- Producir canciones ajustando presupuestos y estrategias de marketing.
- Fichar y gestionar una plantilla de artistas con egos y lealtades variables.
- Usar las redes sociales para ganar notoriedad (a veces a costa de polémicas).
- Gestionar su propio estrés para evitar el síndrome del trabajador quemado (burnout).
- Mejorar el estudio de grabación para desbloquear opciones de mayor nivel.
- Enfrentarse a eventos dinámicos y narrativos (filtraciones, peleas entre artistas, cancelaciones) que reaccionan a sus decisiones.

---

## Instruccions d'execució

Per executar i jugar al projecte localment:
1. Obre el projecte a **Roblox Studio** utilitzant l'arxiu `grow-a-industry.rbxl`.
2. Assegura't de tenir instal·lat el plugin de **Rojo** si vols sincronitzar els canvis des del codi font al Visual Studio Code.
3. Prem el botó de **Play** (F5) dins de Roblox Studio per iniciar la partida.

## Controls

L'experiència de joc està dissenyada per ser purament de gestió a través d'una interfície (UI):
- **Ratolí (Clic Esquerre):** Ús general per navegar pels diferents menús (Producció, Artistes, Xarxes Socials, Gestió d'Estrès), comprar millores i prendre decisions en els esdeveniments reactius.

---

## Idea principal

El juego funciona como un simulador de gestión en tiempo real dirigido por acciones. A diferencia de un sistema estricto por turnos, el jugador es libre de interactuar con las aplicaciones de su ordenador, teniendo que lidiar con **costes económicos**, **tiempos de espera (cooldowns)** y el **estrés** acumulado.

Todas las acciones del jugador alimentan un **Motor de Eventos Reactivo** que evalúa el estado de la partida constantemente. Las consecuencias de una mala decisión (por ejemplo, apoyar públicamente a un artista problemático) pueden desencadenar eventos narrativos horas después, afectando a la percepción que las comunidades tienen sobre tu sello discográfico.

El objetivo es moldear tu propia identidad en la industria (productor underground purista o hitmaker mainstream) y llegar a la cima maximizando tu reputación, fama y dinero.

---

## Mecánicas principales

### 1. Sistema de Producción Musical
Crear música es el motor económico del juego. El jugador debe balancear el enfoque (Comercial vs Experimental), la Originalidad, el Marketing y el Presupuesto.
- **Niveles de Producción**: Desde un *Bedroom Demo* ($0 coste, ideal para evitar la bancarrota pero con resultados limitados) hasta producciones *Premium* ($1000 coste, alta fidelidad, grandes beneficios pero mayor riesgo de ser tachado de "vendido").
- **Géneros y Tendencias**: Adaptarse a géneros emergentes aumenta las posibilidades de éxito.
- **Resultados**: Las canciones pueden fracasar, ser un éxito moderado, convertirse en clásicos de culto o hacerse virales, dependiendo del riesgo y las variables introducidas.

### 2. Gestión de Artistas
El jugador no trabaja solo. Puede fichar artistas de distintos ámbitos (Underground o Mainstream).
- **Estadísticas Individuales**: Cada artista tiene Talento, Ego, Lealtad y un Género preferido.
- **Acciones Directas**: Puedes hablar con ellos (sube la lealtad, reduce estrés), pagarles bonos (sube la lealtad pero infla su ego), grabar canciones con ellos (aumenta ingresos), mandarles a descansar o, si son demasiado problemáticos, despedirlos.

### 3. Redes Sociales
Controlar la narrativa pública es clave para el éxito.
- **Postear Actualizaciones**: Sube seguidores, pero expone al jugador a reacciones mixtas.
- **Comprar Promoción**: Aumenta exponencialmente el alcance a cambio de dinero.
- **Empezar una Polémica (Beef)**: Crece muy rápido en popularidad, pero destroza la reputación y genera Haters.
- **Irse a las Sombras (Go Silent)**: Calma las aguas, reduce el estrés y la cantidad de Haters, perdiendo algo de relevancia comercial.

### 4. Gestión del Estrés
Toda acción (producir, manejar polémicas, fichar) consume energía mental. Si el jugador llega a 100 de estrés, sufrirá "Burnout", perdiendo dinero y reputación.
- Para evitarlo, existe la app de **Gestión de Estrés** donde se puede Descansar (gratis, baja efectividad), irse de Vacaciones (costoso pero muy efectivo) o Tomarse un Respiro largo.

### 5. Sistema de Comunidades e Identidad
El juego rastrea detalladamente quién te escucha:
- **Underground Audience**: Aprecian la originalidad y el riesgo. Odiarán que te vendas a lo comercial.
- **Mainstream Listeners**: Quieren hits comerciales y promocionados.
- **Loyal Fans**: Comprarán pase lo que pase y te defienden de los ataques.
- **Haters**: Aparecen por polémicas y decisiones avariciosas. Si tienes demasiados, sabotearán tus lanzamientos (review bombing).
Tus decisiones forman tu **Identidad de Sello**, que te otorgará modificadores pasivos durante la partida.

### 6. Motor de Eventos Reactivo
Las cosas no ocurren al azar. Si el ego de un artista es muy alto, podría insultar a un fan. Si lanzas tres canciones experimentales seguidas, tus fans comerciales podrían abandonarte. Estas cadenas narrativas aparecen como popups de decisiones donde deberás asumir el daño a tu reputación, gastar dinero para encubrirlo, o apoyar a tu artista asumiendo el caos mediático.

---

## Arquitectura del Proyecto

El juego utiliza una arquitectura de sistemas desacoplados impulsada por un `EventBus` y un `StateResolver`. 
- **PayloadLogger & ResultPopup**: Todas las acciones devuelven un paquete de datos uniforme (Payload) que describe los cambios en estadísticas, eventos especiales y reacciones de la comunidad. El `ResultPopup` interpreta este payload de manera universal.
- **ModifierSystem**: Evalúa pasivas temporales o permanentes antes de calcular cualquier resultado de RNG (por ejemplo, tener el estudio al nivel máximo mejora un 20% la probabilidad de éxito).
- **ControversySystem & PressureSystem**: Evalúan constantemente la cantidad de Haters y Estrés, disparando eventos críticos cuando cruzan ciertos umbrales.

## Tecnologías utilizadas

- **Roblox Studio**
- **Luau** (Lenguaje principal)
- **Visual Studio Code**
- **Git / GitHub**
- **Rojo** (Sincronización del proyecto)

---

## Estructura de Archivos

```text
src/
├─ client/
│  ├─ init.client.luau
│  └─ ui/                 # Interfaz de usuario, menús (ComputerMenu, StressMenu, etc.)
│
├─ server/
│  └─ init.server.luau
│
├─ shared/
│  └─ GameSystem/         # Lógica central del simulador
│     ├─ Architecture/    # Sistemas base (EventBus, Motor de Eventos, Resolutores de Estado, Comunidades)
│     ├─ PlayerDataManager.luau  # Gestor de estado global (dinero, fama, estrés)
│     ├─ SongSystem.luau         # Cálculos de producción musical
│     ├─ ArtistSystem.luau       # Comportamientos, cooldowns y stats de artistas
│     └─ SocialMediaSystem.luau  # Acciones de marketing y redes sociales
│
├─ docs/
├─ diagrames/
└─ exports/
```