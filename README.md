# MESSAGES

*Titre de travail. Jeu d'horreur pour Android, 100 % hors-ligne.*

Le jeu simule l'interface d'un smartphone : écran verrouillé (heure et batterie **réelles** de l'appareil), notification, puis une app de messagerie où une **entité inconnue** interroge le joueur sur sa soirée de la veille. À chaque partie, le joueur reçoit une **identité et un alibi générés aléatoirement** qu'il doit mémoriser avant qu'ils ne s'effacent — puis défendre sans jamais se contredire.

## Jouer

**Télécharger l'APK** : chaque push compile automatiquement l'app ([Actions](../../actions)) et publie les APK dans la release [`apk-latest`](../../releases/tag/apk-latest). Prendre `app-arm64-v8a-release.apk` pour un téléphone récent.

**App Android (Flutter)** — la version de référence :

```bash
cd app
flutter pub get
flutter run          # sur un appareil/émulateur branché
flutter test         # moteur + widgets
flutter build apk    # APK release
```

**Prototype HTML (v3)** — ouvrir [`index.html`](index.html) dans un navigateur, idéalement sur mobile ou en mode responsive.

Dans les deux cas : aucune dépendance réseau au runtime. Tout le moteur (génération d'alibi, évaluation du texte libre, archétypes) tourne en local.

## IA locale (optionnelle)

L'app peut embarquer un **LLM local** (Gemma via MediaPipe) qui rend les échanges vivants : l'entité reformule ses répliques dans son style et répond au contenu de ce que tu écris — toujours 100 % hors-ligne, l'inférence se fait sur le téléphone. **Le moteur de règles reste le juge** (alibi, contradictions, verrouillages) : le modèle n'est que la voix. Sans modèle installé, le jeu utilise ses banques de répliques écrites.

Installation :
1. Télécharger un modèle au format MediaPipe `.task`, ex. **Gemma 3 1B IT int4** (~550 Mo) depuis Hugging Face ([litert-community/Gemma3-1B-IT](https://huggingface.co/litert-community/Gemma3-1B-IT), licence Gemma à accepter) et le transférer sur le téléphone.
2. Dans le jeu : engrenage en haut à droite de l'écran verrouillé → **IA locale** → *Choisir le fichier modèle*.
3. Activer « Utiliser l'IA locale ». La génération se cache derrière l'indicateur « en train d'écrire… » ; en cas de lenteur ou d'erreur, la réplique écrite part à la place — le jeu ne casse jamais.

## Contenu du dépôt

| Chemin | Rôle |
|---|---|
| `app/` | **App Flutter Android** — moteur Dart pur (`lib/engine/`) + UI (`lib/ui/`) |
| `index.html` | Prototype HTML v3 — les 5 archétypes d'entité, banques étoffées |
| `prototypes/messages-v2.html` | Archive du prototype v2 (2 archétypes) testé par Ethan |
| `docs/concept-et-etat.md` | Conception complète et état d'avancement du projet |

## Le carnet

À la fin de chaque nuit — que tu survives ou non — l'entité envoie un dernier message quand tu crois que c'est fini. Douze fragments qui révèlent peu à peu d'où viennent ces alibis, à qui ils ont appartenu, et ce qu'elle cherche vraiment. Les **Archives** gardent ce que tu as obtenu et masquent le reste. Elle se souvient aussi de ce que tu as inventé les nuits précédentes — et elle peut te le ressortir. Si tu arrêtes de jouer, elle t'écrit.

## Les nuits

Chaque partie est une **nuit**. Survivre allonge une série ; mourir la casse (le record reste). Plus la série monte, plus les nuits durcissent : moins de temps pour mémoriser l'alibi, plus de zones d'ombre sondées, plus de re-vérifications, des entités plus pressantes. Un **dossier** garde la trace des cinq entités rencontrées et vaincues — le Miroir n'apparaissant qu'une fois sur dix, le compléter prend du temps. Et l'entité se souvient de toi d'une nuit à l'autre.

## Les 5 entités

| Archétype | Rareté | Signature |
|---|---|---|
| L'Archiviste | courant | froid, factuel, archive chaque contradiction |
| La Confidente | courant | chaleureuse, punit le ton plus que les faits |
| Le Métronome | courant | rafales, s'impatiente, punit trop lent **et** trop rapide |
| Le Creux | courant | silences, questions sensorielles, se sert des vraies données du téléphone |
| Le Miroir | ~1/10 | copie le style d'écriture du joueur, lui renvoie ses propres mots |

Voir `docs/concept-et-etat.md` pour la conception détaillée (boucle de jeu, moteur d'évaluation, contraintes techniques, feuille de route).
