# 02_model_del_joc.md

## 1. Components principals del joc

Els components principals de **Grow A Industry** són els següents:

- **Jugador / Producció principal**: representa la persona que gestiona l’estudi i pren totes les decisions del joc.
- **Artistes**: persones que es poden fitxar, gestionar i fer créixer dins del projecte musical.
- **Estudi**: conjunt de millores, nivell i capacitat del sistema de producció.
- **Cançons / Produccions**: resultats de les accions creatives del jugador i dels artistes.
- **Esdeveniments**: situacions aleatòries o derivades de les decisions del jugador que afecten el progrés.
- **Sistema de xarxes socials**: accions relacionades amb promoció, comunitat i creixement de públic.
- **Sistema de sol·licituds / oportunitats**: artistes o oportunitats que arriben al jugador segons el seu progrés.

Aquests components formen el nucli del joc i es relacionen entre si per generar el bucle principal de gestió, producció i creixement.

---

## 2. Entitats identificades

Les entitats principals identificades per al joc són:

1. **PlayerData**
2. **Artist**
3. **Studio**
4. **SongProduction**
5. **Event**
6. **Request**
7. **SocialAction**

Tot i que es podrien crear més classes en una versió futura, aquestes són les més importants per a la primera arquitectura del sistema.

---

## 3. Atributs clau de cada entitat

### 3.1. PlayerData

Representa l’estat general de la partida i del jugador.

**Atributs principals:**
- `money`
- `fame`
- `followers`
- `reputation`
- `stress`
- `studioLevel`
- `mainstreamAudience`
- `undergroundAudience`
- `loyalFans`
- `haters`
- `riskLevel`
- `artists` (llista d’artistes signats)
- `currentIdentity`

### 3.2. Artist

Representa un artista fitxat o una possible futura incorporació.

**Atributs principals:**
- `name`
- `style`
- `mood`
- `talent`
- `loyalty`
- `ego`
- `stress`
- `risk`
- `status`
- `pendingUntil`
- `cooldowns`

### 3.3. Studio

Representa l’estudi i el seu nivell de desenvolupament.

**Atributs principals:**
- `computerLevel`
- `microphoneLevel`
- `speakersLevel`
- `decoLevel`
- `studioPoints`
- `studioLevel`
- `maxArtistSlots`

### 3.4. SongProduction

Representa una cançó o sessió de producció.

**Atributs principals:**
- `commercialValue`
- `experimentalValue`
- `budget`
- `promotion`
- `quality`
- `cost`
- `risk`
- `result`
- `hypeGenerated`

### 3.5. Event

Representa un esdeveniment del joc.

**Atributs principals:**
- `title`
- `description`
- `type`
- `options`
- `possibleOutcomes`
- `requirements`

### 3.6. Request

Representa una sol·licitud externa que arriba al jugador.

**Atributs principals:**
- `requestType`
- `senderName`
- `description`
- `reward`
- `risk`
- `requiresSlot`
- `expiresIn`

### 3.7. SocialAction

Representa una acció de xarxes socials.

**Atributs principals:**
- `actionName`
- `cooldown`
- `effectFollowers`
- `effectReputation`
- `effectHype`
- `effectRisk`
- `effectAudience`

---

## 4. Accions, mètodes o funcions principals

### 4.1. PlayerData

**Responsabilitats principals:**
- guardar l’estat global de la partida;
- actualitzar les estadístiques principals;
- calcular si el jugador compleix requisits;
- gestionar la identitat actual del jugador.

**Mètodes o funcions possibles:**
- `addMoney()`
- `addFollowers()`
- `addFame()`
- `addReputation()`
- `addStress()`
- `updateIdentity()`
- `canSignArtist()`

### 4.2. Artist

**Responsabilitats principals:**
- representar l’estat d’un artista;
- gestionar accions com parlar, donar bonus, gravar o descansar;
- controlar cooldowns i estat de pending.

**Mètodes o funcions possibles:**
- `talk()`
- `giveBonus()`
- `recordSong()`
- `rest()`
- `drop()`
- `updateMood()`
- `isAvailable()`

### 4.3. Studio

**Responsabilitats principals:**
- calcular el nivell d’estudi;
- definir la capacitat màxima d’artistes;
- aplicar els efectes de les millores.

**Mètodes o funcions possibles:**
- `calculateStudioPoints()`
- `calculateStudioLevel()`
- `getMaxArtistSlots()`
- `applyUpgradeEffects()`

### 4.4. SongProduction

**Responsabilitats principals:**
- calcular el resultat d’una producció;
- generar costos i recompenses;
- aplicar probabilitats de hit, viralitat o fracàs.

**Mètodes o funcions possibles:**
- `calculateCost()`
- `calculateRisk()`
- `produce()`
- `resolveOutcome()`

### 4.5. Event

**Responsabilitats principals:**
- representar un esdeveniment amb opcions;
- aplicar conseqüències segons la decisió del jugador.

**Mètodes o funcions possibles:**
- `canTrigger()`
- `getOptions()`
- `resolveChoice()`

### 4.6. Request

**Responsabilitats principals:**
- representar ofertes, col·laboracions o sol·licituds d’artistes;
- comprovar si requereixen slot lliure;
- aplicar recompenses o riscos.

**Mètodes o funcions possibles:**
- `canAccept()`
- `accept()`
- `reject()`

### 4.7. SocialAction

**Responsabilitats principals:**
- aplicar accions de xarxes socials;
- modificar comunitat, hype i audiència;
- controlar cooldowns.

**Mètodes o funcions possibles:**
- `execute()`
- `isAvailable()`
- `applyEffects()`

---

## 5. Explicació del diagrama de classes

El diagrama de classes representa les entitats principals del joc i les seves relacions.

L’objectiu del diagrama no és decorar la documentació, sinó deixar clara l’estructura que després es traduirà al codi. S’ha organitzat d’aquesta manera perquè el joc es basa en un nucli central, que és `PlayerData`, i al seu voltant hi giren la resta de sistemes.

Relacions principals:

- `PlayerData` conté o gestiona una col·lecció d’`Artist`.
- `PlayerData` té associat un únic `Studio`.
- `PlayerData` interactua amb `SongProduction`, `Event`, `Request` i `SocialAction`.
- `Artist` participa en accions de producció i en esdeveniments.
- `Studio` condiciona la capacitat del jugador i els requisits per fitxar artistes.
- `Request` i `Event` representen situacions externes que afecten el jugador.
- `SongProduction` depèn de les estadístiques del jugador, de l’estudi i dels artistes.

Aquest disseny permet separar responsabilitats i fer que el codi sigui més modular.

---

## 6. Explicació del diagrama de comportament

Per al diagrama de comportament s’ha triat un **diagrama d’activitat**, perquè és el que millor representa el bucle principal del joc.

El flux que representa és aquest:

1. El jugador obre el menú principal de l’ordinador.
2. Escull una acció:
   - produir una cançó;
   - fer una acció de xarxes socials;
   - gestionar artistes;
   - revisar l’estudi;
   - acceptar o rebutjar una sol·licitud.
3. El sistema comprova si compleix requisits i si no hi ha cooldowns.
4. Es resol l’acció.
5. Es calculen els canvis d’estadístiques.
6. Pot aparèixer un esdeveniment o una conseqüència.
7. El joc actualitza l’estat general.
8. El jugador torna a prendre una nova decisió.

Aquest diagrama reflecteix realment el flux del joc perquè Grow A Industry no és un joc lineal, sinó un joc de decisions repetides dins d’un bucle de gestió.

---

## 7. Correspondència entre diagrames i codi futur

El model es traduirà al codi de la manera següent:

- `PlayerData` es convertirà en un mòdul de dades globals de partida.
- `Artist` es convertirà en una estructura o classe amb propietats i funcions pròpies.
- `Studio` es traduirà en un mòdul encarregat de calcular nivell, punts i slots.
- `SongProduction` es convertirà en un sistema específic de producció i resolució de resultats.
- `Event` es convertirà en un sistema d’esdeveniments amb opcions i conseqüències.
- `Request` es traduirà en un sistema de sol·licituds entrants.
- `SocialAction` es convertirà en un mòdul de xarxes socials amb accions i cooldowns.

A nivell de codi, això vol dir que el projecte no es farà amb un únic script gran, sinó amb diversos fitxers organitzats per responsabilitats.

---

## 8. Estructura inicial del repositori

L’estructura inicial del repositori serà la següent:

```text
grow-a-industry/
├─ README.md
├─ default.project.json
├─ aftman.toml
├─ .gitignore
├─ src/
│  ├─ client/
│  │  ├─ init.client.luau
│  │  ├─ ui/
│  │  │  ├─ MainMenu.luau
│  │  │  ├─ ComputerMenu.luau
│  │  │  ├─ ArtistsMenu.luau
│  │  │  ├─ ManageArtistMenu.luau
│  │  │  ├─ SocialMediaMenu.luau
│  │  │  └─ ResultPopup.luau
│  │  └─ systems/
│  │     ├─ InteractionSystem.luau
│  │     └─ UpgradeVisibility.luau
│  ├─ server/
│  │  └─ init.server.luau
│  └─ shared/
│     ├─ PlayerDataManager.luau
│     ├─ StudioSystem.luau
│     ├─ ArtistSystem.luau
│     ├─ SongProductionSystem.luau
│     ├─ SocialMediaSystem.luau
│     ├─ EventSystem.luau
│     ├─ RequestSystem.luau
│     └─ Config.luau
├─ docs/
│  ├─ 01_idea_i_abast.md
│  └─ 02_model_del_joc.md
└─ diagrames/
   ├─ diagrama_classes.png
   └─ diagrama_comportament.png
```