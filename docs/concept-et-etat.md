# MESSAGES — Concept et état du projet

*Titre de travail. Jeu Android d'horreur, 100% hors-ligne.*

---

## 1. Le concept

Le jeu simule l'interface d'un smartphone. Au lancement, l'écran devient littéralement celui d'un téléphone : écran verrouillé avec l'heure et la batterie *réelles* de l'appareil, notification qui apparaît, puis une app "Messages" façon WhatsApp/iMessage — bulles de conversation, indicateur "en train d'écrire...".

Le joueur y échange avec une **entité inconnue** qui l'interroge sur ce qu'il a fait la veille au soir. Le twist : à chaque partie, le joueur reçoit une **identité et un alibi générés aléatoirement**, qu'il doit mémoriser puis défendre sans se contredire — jusqu'à ce que l'alibi s'effrite ou que l'entité soit convaincue.

Casse du 4ᵉ mur assumée : heure réelle, batterie réelle, l'entité peut s'en servir contre le joueur ("il est 23h47 et tu ne dors pas").

## 2. Boucle de jeu

1. **Alibi.** Le joueur reçoit une identité (prénom, métier) et des faits sur sa soirée (lieu, détail, horaires, transport). La note ne révèle **jamais** quelles zones seront creusées — tout ce qu'elle ne dit pas doit être improvisé sur le moment, et retenu.
2. La note **s'efface** après un délai (45 s) ou quand le joueur confirme l'avoir mémorisée.
3. L'entité engage la conversation en **texte libre** : questions factuelles (vérifiables contre l'alibi) et questions ouvertes (le joueur invente, la réponse est verrouillée comme canon).
4. L'entité **creuse** : une bonne réponse déclenche souvent une question de suivi ("quel cinéma ? son nom.") plutôt qu'un passage direct à la suite. Elle revient aussi plus tard sur 1-2 improvisations verrouillées pour vérifier que le joueur ne s'est pas contredit lui-même.
5. Chaque réponse est jugée sur plusieurs signaux combinés : cohérence avec l'alibi, contradiction avec une improvisation antérieure, vitesse de réponse, ton, contenu.
6. Trop d'erreurs cumulées ou trop de contrariété = mort, mise en scène différemment selon l'entité. Sinon, le joueur passe le round.

## 3. Rejouabilité (roguelike)

- L'**entité** est tirée aléatoirement parmi plusieurs archétypes à chaque partie — personnalité, ton, style d'interrogation et critères de suspicion différents. Tirage pondéré : le Miroir est rare (~1/10).
- L'**alibi** (lieu, détail, transport, horaires, zones d'ombre sondées) est généré différemment à chaque partie.
- Objectif : jamais deux parties identiques, inspiration Minecraft.

## 4. Contraintes techniques (tranchées)

- **Pas de moteur de jeu** (Godot/Unity exclus) — c'est une interface, pas un jeu physique/3D.
- App **Flutter** — tranché (Kotlin/Compose écarté). Le moteur de jeu est du Dart pur, sans dépendance Flutter, dans `app/lib/engine/` : testable en headless et séparé de l'UI.
- **Zéro backend, zéro API/IA en ligne au runtime.** Fonctionne 100% hors-ligne.
- **IA locale optionnelle** (LLM sur l'appareil, Gemma 3 1B via MediaPipe) : architecture « les règles jugent, le modèle parle ». Le LLM reformule les répliques de banque dans le style de l'entité (l'intention et le sens sont imposés par le moteur) et répond librement aux messages hors interrogatoire. Génération masquée par l'indicateur « en train d'écrire… » ; timeout et erreurs retombent sur la réplique de banque. Modèle `.task` fourni par le joueur via l'écran de réglages (pas de téléchargement intégré).
- Le texte libre du joueur est évalué par un **système de règles local** :
  - alibi stocké comme données structurées (pas du texte brut)
  - banques de mots-clés/synonymes et d'incompatibilités par sujet
  - détection de contradiction et de négation ("j'étais pas au bar" ≠ contradiction avec "bar")
  - tolérance aux fautes de frappe (distance de Levenshtein)
  - verrouillage des improvisations (1ʳᵉ réponse à une question ouverte = canon, re-vérifiée ensuite)

## 5. Les archétypes d'entité

Même moteur d'évaluation pour tous, mais pondérations et style propres à chacun. **Les 5 sont codés dans la v3.**

| Archétype | Style | Ce qui la rend suspicieuse | Mort |
|---|---|---|---|
| **L'Archiviste** | Froid, factuel, questions numérotées, insensible au ton | Contradictions factuelles pures | Envoie le dossier des contradictions, "Dossier clos." |
| **La Confidente** | Chaleureuse, emojis, questions personnelles | Rupture de ton (sécheresse, froideur) plus que les faits | Bascule en menace utilisant l'heure réelle : "j'arrive." |
| **Le Métronome** | Rythme rapide, messages en rafale, s'impatiente si on ne répond pas (relance temporisée) | Trop lent ET trop rapide ("récité") | Flood illisible, indicateur "en train d'écrire..." qui ne s'arrête plus |
| **Le Creux** | Rare en mots, silences (parfois aucune réaction), questions sensorielles décalées (bruit, odeur, lumière) | Réponses vides ou trop rapides, plus que la logique | Silence, faux départs de frappe, puis un seul message utilisant l'heure et la batterie réelles |
| **Le Miroir** | Rare (~1/10), adopte progressivement le style d'écriture du joueur (casse, ponctuation, emojis), renvoie parfois ses réponses en écho | Contradictions + rupture de style | Renvoie mot pour mot la plus longue phrase du joueur |

### Écriture des entités (app Flutter, version de référence)

- **Banques de réactions fournies** (4 à 9 répliques par situation et par entité) servies par un « sac » mélangé : aucune réplique ne se répète tant que sa banque n'est pas épuisée.
- **Plusieurs intros et plusieurs fins de victoire** par entité, tirées au sort à chaque partie.
- **Plusieurs formulations de re-vérification** (« Reprenons. X — redis-le-moi. » / « Vérification de routine… » / …), tirées au sort.
- **Réactions à l'heure approximative** propres à chaque entité (plus de réplique générique partagée).
- **L'Archiviste numérote ses questions** (« 1. Où étais-tu hier soir ? ») — prévu dans la conception d'origine, désormais codé.
- Touches de personnalité : la Confidente peut utiliser le prénom de l'alibi dans sa fin (« dors bien, Julien... si c'est ton prénom 🙂 »), le Métronome a des relances d'impatience supplémentaires, le Creux des silences même en fin heureuse, le Miroir des répliques d'identification troublantes.

Le prototype HTML (`index.html`) reste en contenu v3 : l'app Flutter est désormais la référence du contenu.

### Mécaniques v3 par archétype

- **Voix** : chaque archétype pioche les questions des banques dans sa voix ("A" formelle / "C" familière), avec en plus une transformation de style optionnelle (le Métronome écrit tout en minuscules, le Miroir applique le style du joueur).
- **Relance temporisée ("nudge")** : le Métronome relance après 12 s sans réponse (avec pénalité), le Creux après 45 s ("je suis toujours là.", sans pénalité).
- **Silences** : dans les listes de réactions, une chaîne vide = un temps de silence au lieu d'un message (utilisé par le Creux).
- **Morts mises en scène (`deathFx`)** : flood + typing infini (Métronome), silence + données réelles du téléphone (Creux), écho verbatim (Miroir). Vibration du téléphone à la mort quand l'API le permet.

## 6. Où on en est

**Statut : phase de prototypage, v3 prête à tester.**

- ✅ Conception validée : concept, boucle de jeu, contraintes techniques, mécanique des zones grises cachées et de l'approfondissement.
- ✅ Prototype HTML jouable (v1) : boucle complète, 2 archétypes, moteur d'évaluation de base.
- ✅ Retours de test v1 traités dans la v2 :
  - champ de saisie qui se bloquait → saisie libre active en permanence
  - le jeu "ne comprenait pas" les réponses → relance sans pénalité avant de sanctionner, gestion de la négation, détection des aveux d'oubli ("je sais plus")
  - parties trop courtes → questions d'approfondissement après une bonne réponse, re-vérification des improvisations verrouillées, zones d'ombre non annoncées dans l'alibi
- ✅ v2 archivée (`prototypes/messages-v2.html`), testée par Ethan.
- ✅ **v3 (`index.html`)** : les 3 archétypes restants codés (Métronome, Creux, Miroir), tirage pondéré des entités, banques étoffées (20 prénoms, 14 métiers, 6 lieux avec détails et questions de creusement, 6 transports, 5 zones d'ombre générales + 3 sensorielles pour le Creux).
- ✅ **Flutter tranché** et portage Android fait (`app/`) : moteur v3 complet en Dart pur (`app/lib/engine/`), UI native (`app/lib/ui/`) — écran verrouillé, note d'alibi qui se dissout, conversation avec indicateur de frappe, les 4 mises en scène de mort, vibration réelle, batterie réelle via `battery_plus`, mode plein écran immersif. 23 tests (`flutter test`), dont 100 parties complètes simulées ; APK debug compilé avec succès.
- 🔄 v3 HTML et app Flutter à tester sur appareil.

### Expérience (app Flutter)

- **Lancement noir** : splash et fond de fenêtre noirs — aucun flash blanc, l'app se comporte comme un écran de téléphone du début à la fin. Icône de launcher dédiée (bulle « en train d'écrire » + pastille rouge, icône adaptative Android).
- **Messagerie crédible** : accusé « Distribué » qui devient « Lu à HH:MM », temps de lecture de l'entité proportionnel à la longueur du message du joueur, vibration légère à chaque message reçu.
- **Frappe vivante** : l'entité peut commencer à écrire, s'arrêter, reprendre (probabilité par archétype — le Creux hésite beaucoup, le Métronome jamais). Pendant les silences du Creux, son statut passe « hors ligne ».
- **CI** : GitHub Action qui teste, compile et publie les APK dans la release `apk-latest` à chaque push.

**Reste à faire :**
- Tester l'app Flutter sur un vrai téléphone Android (rythme, clavier, vibrations, inférence IA locale)
- Ajuster l'équilibrage des 3 nouveaux archétypes, en particulier les fenêtres de temps du Métronome
- Intégrer les retours de test v2 d'Ethan s'il en reste de non couverts
- Étoffer encore les banques : plus d'alibis, de lieux, de détails, de questions de creusement par archétype
- Icône, écran de démarrage, build release signé
- Une fois le contenu à grande échelle nécessaire (grandes banques de dialogues/questions/synonymes), Fable 5 prendra le relais comme "concepteur de contenu" sur la base de cette conception
