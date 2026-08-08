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

### Le récit long : le carnet (v1.4)

**La vraie raison de revenir.** Les statistiques ne retiennent personne ; une histoire inachevée, si.

- **Un fragment par nuit.** À la fin de chaque nuit — survie *ou* mort — quand le joueur croit que c'est terminé, le téléphone vibre une dernière fois : l'entité envoie un dernier message. Ce sont les 12 fragments d'un récit qui se dévoile lentement.
- **L'histoire** : les alibis qu'on fait porter au joueur ne sont pas des inventions, ce sont les souvenirs de personnes réelles — celles que l'entité a interrogées avant lui, et qui ont disparu. Elle tient un carnet de prénoms, certains rayés. Elle ne cherche pas un menteur (« n'importe qui ment, ça ne m'apprend rien ») : elle cherche à savoir qui est encore là pour répondre. Le douzième fragment referme la boucle sur le joueur lui-même.
- **Les Archives** : écran dédié (accessible depuis l'écran verrouillé et l'écran de fin) où relire les fragments obtenus. Les suivants sont **masqués par des points qui conservent la forme exacte du texte manquant** — on voit précisément ce qu'on n'a pas encore. Le compteur « 3 / 12 » et la phrase « Elle n'a pas fini de parler » font le reste.
- **L'entité réécrit au joueur absent** : notification locale programmée à la fin de chaque nuit, qui arrive quelques heures plus tard et de préférence la nuit (22 h-1 h) — « Numéro inconnu · tu dors ? », « Ton dossier est resté ouvert. », « Tu as arrêté de répondre. Les autres aussi, au début. » Entièrement local, désactivable dans les réglages, et sans effet si la permission est refusée.
- **Mémoire des mensonges entre les nuits** : les improvisations verrouillées d'une nuit sont conservées, et l'entité en ressort une la nuit suivante (« La nuit dernière, tu as évoqué le nom de ton ami. Répète-le. »). Se contredire d'une partie à l'autre est désormais possible — et sanctionné.

### Méta-progression : les « nuits » (v1.3)

Le cœur de la rejouabilité. Chaque partie est une **nuit numérotée**, et la progression est persistante (survit à la fermeture de l'app).

- **Série de survies (streak)** et **record** : survivre allonge la série, mourir la remet à zéro — le record, lui, reste. C'est la boucle « encore une », comme un score à battre.
- **Difficulté progressive** pilotée par la série (niveau 0 à 5, plafonné) : la note d'alibi s'efface plus vite (45 s → 30 s), une **zone d'ombre supplémentaire** est sondée dès le niveau 2, une **re-vérification de plus** dès le niveau 3, et les entités impatientes relancent plus tôt. Plus on gagne, plus c'est dur — et plus la chute coûte cher.
- **Dossier des entités** : cinq pastilles sur l'écran de fin, grisées tant que l'entité n'a pas été rencontrée, cerclées de vert une fois vaincue. Le Miroir étant rare (~1/10), compléter le dossier demande des dizaines de nuits. Le texte sous les pastilles s'adapte : « Quelque chose ne t'a pas encore parlé. » → « Tu as survécu aux cinq. Elles le savent. »
- **L'entité se souvient** : dès la deuxième nuit, elle glisse une réplique de retour dans son intro (« Dossier rouvert. Ce n'est pas notre première conversation. », « tu es revenu 🙂 je savais. tu reviens toujours. »).
- **La notification de l'écran verrouillé change** selon l'état : « 1 nouveau message » la première fois, puis « Nuit n°7. On continue ? » ou « Je sais que tu vois ce message. » après une mort.

### Réalisme (v1.3)

- **Message supprimé** : une fois par nuit au maximum, l'entité laisse échapper un fragment (« derrière toi il y a », « je suis déjà venue devant chez ») aussitôt remplacé par *« Ce message a été supprimé »*. Le joueur ne connaîtra jamais la fin de la phrase.
- **Nouvelles zones d'ombre** dont une qui **invente un fait** sur le joueur — « Ton téléphone a été injoignable entre 21h et 23h. Explique. » — plus le témoin qui peut confirmer, ce qu'il a fait en rentrant, qui il a croisé, et la température des lieux pour le Creux.

### Intelligence du moteur (v1.2)

- **Écoute globale** : une contradiction est relevée où qu'elle apparaisse — répondre « vers 19h en sortant du bar » à une question d'horaire contredit le lieu de l'alibi, même si l'heure est bonne.
- **Aveux détectés** : « j'ai menti », « j'invente »... = contradiction immédiate.
- **La constance paie** : chaque bonne réponse fait légèrement redescendre la suspicion (plancher 0) — tenir son récit rattrape un début hésitant.

### Son et retour haptique (v1.2)

- **Effets sonores générés procéduralement** (aucun asset externe, WAV synthétisés) : réception, envoi, déverrouillage, glitch haché, drone grave de mort (battement 55/57,3 Hz). Coupables dans Réglages → Sons.
- **Haptique différenciée** : clic discret à l'envoi, impact léger à la réception, impact moyen sur contradiction relevée, impact fort sur l'avertissement de l'entité, vibration longue + double impact pendant la mort.

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
