# Document de Proves

Durant el procés de desenvolupament s'han realitzat diverses proves per assegurar el correcte funcionament dels sistemes principals del joc, garantint una experiència jugable de principi a fi.

## 1. Proves del Bucle Econòmic (Core Loop)
* **Objectiu:** Verificar que el jugador pot mantenir-se a flot, generar ingressos i que no es produeixen situacions de bloqueig (soft-lock) econòmic.
* **Proves realitzades:**
  * S'han provat múltiples llançaments de cançons en nivell "Bedroom Demo" (cost $0) per assegurar que el jugador sempre té una via per continuar generant ingressos fins i tot si es queda a $0.
  * Verificació de la correcta interacció entre els inversors (sliders de comercial/originalitat/pressupost) i els modificadors d'èxit o fracàs (RNG del SongSystem).

## 2. Proves del Sistema d'Estrès
* **Objectiu:** Comprovar que l'estrès s'acumula correctament al fer accions (produir, interactuar) i que hi ha formes efectives i clares de reduir-lo per evitar el "Burnout".
* **Proves realitzades:**
  * Ús dels tres botons de descàrrega d'estrès: "Descansar" (Gratuït, poc alleujament), "Vacances" (Cost econòmic, molt alleujament) i "Donar-se un respir" (Efecte major però amb contrapartides de temps).
  * Comprovació de cooldowns de la UI vinculats correctament a l'estat global a través de `RunService.Heartbeat`.

## 3. Proves del Motor d'Esdeveniments Reactiu
* **Objectiu:** Validar que les accions del jugador (polèmiques, contractacions d'artistes problemàtics) desencadenen els pop-ups de decisions i modifiquen l'entorn.
* **Proves realitzades:**
  * S'han simulat pics d'estrès en artistes per forçar el salt de l'esdeveniment de "Artist Breakdown" i "Internal Beef".
  * S'han comprovat els esdeveniments de "Sellout Backlash" al prioritzar el mainstream en excés.
  * S'ha verificat la resolució de les decisions a través del `DecisionPopup` i la seva respectiva aplicació d'estadístiques via `StateResolver`.

## Resultat de les Proves
Tots els sistemes han passat les proves unitàries manuals i l'aplicació interactua correctament sense errors (crashes). El joc ha demostrat ser jugable de forma contínua amb les dades reaccionant com s'espera.
