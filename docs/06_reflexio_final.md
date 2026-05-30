# Reflexió Final

## Desenvolupament i Experiència d'Aprenentatge
El projecte "Grow A Industry" ha resultat ser un desafiament interessant de simulació arquitectònica. Fer un joc orientat exclusivament a la UI i dades invisibles canvia el paradigma tradicional dels jocs de plataformes on tot l'efecte del jugador és espacial i visual de manera directa. 

Aprendre a coordinar els diferents mòduls d'informació ha estat la feina més gran. S'ha treballat implementant estructures clàssiques com un `EventBus` que retransmet informació entre diferents `System`, així com separant correctament l'estat central al `PlayerDataManager` que funciona com un objecte de veritat única per a l'economia, la fama i les reputacions de la companyia discogràfica de l'usuari.

## Dificultats Trobades
* **Comunicació Client-Servidor / UI i Backing:** Mantenir actualitzada una interfície gràfica a Roblox de forma eficient no és trivial. Les asincronies, el fet d'usar un framework de UI propi basat en classes, instàncies i Tweens per a transicions (animacions), tot això coordinat amb esdeveniments, requeria d'una implementació molt atenta de quan es tancava o creava un contenidor ScreenGui perquè no es perdessin dades.
* **Balanç del Joc:** Regular preus, estrès, èxit o "hype decay" requereix moltes partides i canvis constants. Al principi, el joc tancava les portes massa de pressa a causa de l'impacte estricte de la manca de diners. Modificar el sistema per dotar-lo de "solucions zero" sense trencar el bucle global de l'economia va requerir disseny.

## Us de la IA
L'ús de models generatius ha ajudat a donar suport durant el desenvolupament. S'han utilitzat eines d'IA de forma col·laborativa per diagnosticar asimetries i fallades estructurals en objectes de Luau (com resoldre problemes en com el motor passava el paràmetre 'Options' a l'hora de rebre els paquets dels pop-ups de decisions narratives), alhora que s'ha dissenyat arquitectura per a menús en graella de 3 columnes quan la UI es solapava. Això m'ha permès destinar menys temps a trencar-me el cap per "sintaxis", i més a dissenyar com es comporta el món reactiu per dins.

## Conclusió
El simulador ha acabat presentant una experiència d'entorn sòlida, creant un framework de Roblox que, en si mateix, seria infinitament ampliable si s'hi afegissin dotzenes de narracions, tipologies d'artistes o esdeveniments, donat l'estat altament escalable i net del seu EventBus i ReactiveEventEngine. Ha estat un projecte molt didàctic.
