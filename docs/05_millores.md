# Document de Millores Iteratives

Durant el desenvolupament del projecte s'han dut a terme múltiples iteracions de disseny i funcionalitat basades en el feedback i la necessitat de complir els requeriments del bucle de joc.

## 1. Solució del Soft-Lock Econòmic
**Problema inicial:** El jugador es podia quedar a $0, no podent assumir el cost de producció més baix, el que portava a un estat d'impàs on era impossible avançar (soft-lock).
**Millora introduïda:** Es va implementar dins el sistema `SongSystem.luau` la categoria de producció "Bedroom Demo" (Demo a l'habitació) amb un cost base de $0 i un estrès generat petit. Això assegura que sempre hi ha una opció de jugar. A més, té una petita probabilitat d'èxit viral afegint sorpresa i sortida al pou econòmic.

## 2. Refinament de la Interfície (UI)
**Problema inicial:** El menú del "Studio Computer" sobreposava certs elements inferiors i no deixava llegir algunes opcions. A més, els Pop-ups d'esdeveniments no es mostraven per pantalla.
**Millora introduïda:**
* S'ha eixamplat i reestructurat la finestra de l'ordinador a 3 columnes.
* S'han centrat els elements i retocat l'HUD flotant de la quantitat de diners perquè quadri a la cantonada.
* S'ha construït un "NotificationQueueGui" independent del Menú Principal perquè sobrevisqui a les transicions i llançi correctament el `DecisionPopup`.

## 3. Ampliació de les opcions de Gestió d'Estrès
**Problema inicial:** L'estrès pujava contínuament, sent poc abastable la seva reducció, castigant massa l'experiència de gestió.
**Millora introduïda:** Creació d'un sistema balancejat al `StressMenu.luau` connectat a `ArtistSystem` amb múltiples perfils d'alleujament de l'estrès (Descans, Vacances, Pausa), obligant a establir decisions entre gastar diners o gastar temps (cooldowns).

## 4. Poliment de Codificació dels Payloads d'Esdeveniments
**Problema inicial:** Les opcions dels esdeveniments narratius (com conflictes interns o "sellouts") fallaven perquè els arbres d'esdeveniments s'estaven definint diferent segons si provenien del `NarrativeChainSystem` o del `ReactiveEventEngine`.
**Millora introduïda:** Normalització dels paràmetres passats pel EventBus, capturant sempre l'objecte "Options" en un payload superior estructurat, deixant la UI agnòstica de la lògica backend.
