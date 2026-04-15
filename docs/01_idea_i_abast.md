# 01_idea_i_abast.md

## 1. Títol provisional del joc

Grow A Industry

---

## 2. Tipus de microvideojoc escollit

El joc serà un simulador de gestió i presa de decisions ambientat en la indústria musical actual.

El jugador haurà de prendre decisions sobre artistes, cançons, videoclips, concerts, xarxes socials, discogràfiques i estudis de gravació.

El funcionament estarà inspirat en jocs com BitLife, Game Dev Tycoon o altres simuladors on el jugador va avançant per etapes i cada decisió té conseqüències.

---

## 3. Objectiu del joc

L’objectiu del joc és construir una indústria musical d’èxit començant des de zero.

El jugador començarà amb pocs diners, poca reputació i un estudi petit. A mesura que avanci podrà aconseguir artistes més famosos, produir cançons d’èxit, fer videoclips, participar en festivals i ampliar el seu estudi.

El repte serà arribar al final amb la màxima fama, reputació i diners possibles.

---

## 4. Rol del jugador

El jugador controla una persona que vol convertir-se en una figura important de la indústria musical.

Durant la partida haurà de:

- fitxar artistes;
- decidir si invertir en cançons o videoclips;
- escollir col·laboracions;
- gestionar problemes tècnics;
- prendre decisions sobre xarxes socials;
- reaccionar a polèmiques;
- controlar el pressupost;
- gestionar l’estrès i la reputació.

---

## 5. Regles bàsiques

- Cada torn representa una etapa de la carrera musical.
- A cada torn apareix un esdeveniment aleatori.
- El jugador ha d’escollir entre diferents opcions.
- Cada opció modifica estadístiques del jugador.
- Les estadístiques principals seran:
  - diners;
  - fama;
  - reputació;
  - seguidors;
  - estrès;
  - qualitat de l’estudi.
- Si una estadística baixa massa o puja massa poden aparèixer problemes.
- Algunes opcions només estaran disponibles si el jugador té prou diners o reputació.

---

## 6. Condicions de victòria i derrota

### Victòria

El jugador guanya si aconsegueix arribar al final de la partida amb una bona combinació de fama, diners i reputació.

Hi haurà diferents finals positius:

- productor llegendari;
- estudi multimilionari;
- gran estrella de la indústria;
- imperi musical internacional.

### Derrota

El jugador perd si passa alguna d’aquestes situacions:

- es queda sense diners;
- la reputació arriba a zero;
- l’estrès arriba al màxim;
- tots els artistes abandonen l’estudi;
- l’empresa fa fallida.

---

## 7. Bucle principal del joc

El bucle principal serà el següent:

1. Es mostra la situació actual del jugador.
2. Apareix un esdeveniment aleatori.
3. El jugador llegeix el problema o oportunitat.
4. Escull una opció.
5. Es modifiquen les estadístiques.
6. Es mostra el resultat.
7. Comença un nou torn.

Aquest bucle es repetirà durant tota la partida.

---

## 8. Repte principal i dificultat

El repte principal serà mantenir equilibrades totes les estadístiques.

Per exemple:

- gastar molts diners pot augmentar la fama però pot provocar problemes econòmics;
- fitxar artistes famosos pot donar molts seguidors però també molt estrès;
- invertir poc pot fer que la reputació baixi.

La dificultat estarà basada en les conseqüències de les decisions i en els esdeveniments aleatoris.

---

## 9. Limitacions explícites

Per evitar que el projecte sigui massa gran, hi haurà algunes limitacions:

- no hi haurà món obert;
- no hi haurà moviment lliure del personatge;
- no hi haurà multijugador;
- no hi haurà música real ni drets d’autor;
- no hi haurà animacions complexes;
- el joc es basarà principalment en pantalles, menús i botons;
- hi haurà un nombre limitat d’esdeveniments;
- hi haurà poques estadístiques per mantenir el projecte simple.

---

## 10. Riscos tècnics

Els principals riscos tècnics del projecte són:

- que el sistema d’esdeveniments sigui massa repetitiu;
- que hi hagi massa variables i sigui difícil equilibrar-les;
- que la interfície sigui massa complicada;
- que les dades del jugador no es guardin correctament;
- que el joc tingui errors quan diverses estadístiques canvien al mateix temps;
- que el temps disponible no sigui suficient per implementar totes les idees.

---

## 11. Exploració amb IA

### Prompt 1

"Generate ideas for a Roblox management game about the music industry with simple mechanics and high replayability."

#### Resposta resumida

La IA va proposar fer un joc centrat en prendre decisions sobre artistes, concerts, xarxes socials i discogràfiques. També va recomanar afegir esdeveniments aleatoris i diversos finals possibles.

### Prompt 2

"Suggest a simple gameplay loop for a music producer simulator game in Roblox."

#### Resposta resumida

La IA va suggerir fer un sistema de torns amb una situació, una decisió i una conseqüència. També va recomanar limitar les estadístiques per fer el projecte més viable.

---

## 12. Proposta final escollida

La proposta final serà un joc de gestió de la indústria musical basat en decisions.

El jugador començarà amb un estudi petit i haurà d’anar millorant-lo mentre fitxa artistes, produeix cançons i gestiona problemes.

El joc tindrà una estructura senzilla basada en pantalles, menús i esdeveniments aleatoris.

---

## 13. Justificació de viabilitat

Aquest projecte és viable perquè:

- no necessita gràfics 3D complexos;
- no necessita multijugador;
- es pot construir principalment amb interfícies i botons;
- les mecàniques són senzilles;
- es poden reutilitzar pantalles i components;
- el sistema es pot fer per fases;
- és possible començar amb poques funcionalitats i ampliar-les si sobra temps.

---

## 14. Mini pla de treball

### Fase 1

- Definir la idea del joc.
- Crear el README.
- Crear l’estructura del projecte.
- Configurar Roblox Studio, Rojo i GitHub.

### Fase 2

- Fer la pantalla d’inici.
- Crear les estadístiques del jugador.
- Crear el primer esdeveniment.

### Fase 3

- Crear més esdeveniments.
- Crear el sistema d’artistes.
- Crear els diferents finals.

### Fase 4

- Fer proves.
- Corregir errors.
- Millorar la interfície.
- Preparar la documentació final.

---

## 15. Eines previstes i justificació

- Roblox Studio: per crear el videojoc.
- Luau: per programar la lògica.
- Visual Studio Code: per editar el codi.
- Rojo: per sincronitzar Roblox Studio amb fitxers locals.
- Git i GitHub: per controlar versions i guardar el projecte.
- ChatGPT: per generar idees, prompts i ajuda amb el codi.
- Antigravity: per generar interfícies i prototips visuals.