# MESSAGES

*Titre de travail. Jeu d'horreur pour Android, 100 % hors-ligne.*

Le jeu simule l'interface d'un smartphone : écran verrouillé (heure et batterie **réelles** de l'appareil), notification, puis une app de messagerie où une **entité inconnue** interroge le joueur sur sa soirée de la veille. À chaque partie, le joueur reçoit une **identité et un alibi générés aléatoirement** qu'il doit mémoriser avant qu'ils ne s'effacent — puis défendre sans jamais se contredire.

## Jouer au prototype

Ouvrir [`index.html`](index.html) (v3, dernière version) dans un navigateur — idéalement sur mobile ou en mode responsive. Aucune dépendance, aucun serveur, aucun réseau : tout le moteur (génération d'alibi, évaluation du texte libre, archétypes) tourne en local.

## Contenu du dépôt

| Chemin | Rôle |
|---|---|
| `index.html` | **Prototype v3** — les 5 archétypes d'entité, banques étoffées |
| `prototypes/messages-v2.html` | Archive du prototype v2 (2 archétypes) testé par Ethan |
| `docs/concept-et-etat.md` | Conception complète et état d'avancement du projet |

## Les 5 entités

| Archétype | Rareté | Signature |
|---|---|---|
| L'Archiviste | courant | froid, factuel, archive chaque contradiction |
| La Confidente | courant | chaleureuse, punit le ton plus que les faits |
| Le Métronome | courant | rafales, s'impatiente, punit trop lent **et** trop rapide |
| Le Creux | courant | silences, questions sensorielles, se sert des vraies données du téléphone |
| Le Miroir | ~1/10 | copie le style d'écriture du joueur, lui renvoie ses propres mots |

Voir `docs/concept-et-etat.md` pour la conception détaillée (boucle de jeu, moteur d'évaluation, contraintes techniques, feuille de route).
