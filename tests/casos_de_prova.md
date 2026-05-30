# Casos de Prova i Verificacions

Aquest document resumeix els principals tests (Playtests i revisions de codi) que s'han dut a terme per validar el lliurament del projecte. Totes aquestes casuístiques demostren que l'experiència pot ser jugada completament ("jugable de principi a fi").

### Cas 1: Bucle Base i Generació Econòmica
- **Acció:** Començar el joc, anar a l'ordinador, i usar el menú "Produce Song". Triar l'opció de pressupost base ($0) "Bedroom Demo".
- **Resultat Esperat:** El joc permet executar l'acció gratuïtament, generant un petit cooldown i retornant uns pocs diners i fama després del càlcul al `SongSystem`.
- **Estat:** PASS (Comprovat que evita soft-locks).

### Cas 2: Generació i Gestió de l'Estrès
- **Acció:** Executar accions de producció i xarxes socials repetides vegades per apujar el comptador d'estrès. Anar al menú "Manage Stress" i prémer l'opció "Rest" o "Vacation".
- **Resultat Esperat:** L'indicador d'estrès baixa. Si l'estrès puja a 100 sense cap interacció, el `PressureSystem` pot desfermar un esdeveniment negatiu. A l'agafar vacances, l'import disminueix la bossa econòmica i baixa 40 punts d'estrès.
- **Estat:** PASS.

### Cas 3: Integració d'Esdeveniments Reactius (UI)
- **Acció:** Amb la partida començada, fer accions que forcin un `REACTIVE_EVENT_TRIGGERED` per part del `StateResolver` (ex: posar a la xarxa social un "Start Beef").
- **Resultat Esperat:** El HUD fa aparèixer una "badge" (campaneta de notificació) al `NotificationQueueGui` independent de si es tanca el menú de l'ordinador. Clicant a sobre, salta el `DecisionPopup` que dóna a escollir entre dues o més opcions i aplica modificacions sobre Hype o Reputació.
- **Estat:** PASS.

### Cas 4: Esdeveniments Passius per Corrutina i Ticks (Heartbeat)
- **Acció:** Deixar el joc obert sense prendre decisions però observant el panell principal o les dades.
- **Resultat Esperat:** El `PressureSystem` processa un event "Rent" cada "x" minuts, reduint els fons. L'Hype decau de forma percentual de manera constant i es pot veure indicat amb petites bafarades d'avís de text.
- **Estat:** PASS.

> NOTA: Totes les proves asíncrones s'han fet usant la variable de configuració en mode Debug (`TestMode = true`) al `Config.luau` per a accelerar els intervals d'espera al testeig d'aquesta entrega.
