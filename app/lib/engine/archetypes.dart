/// Les 5 archétypes d'entité. Même moteur d'évaluation pour tous,
/// pondérations et style propres à chacun.
///
/// Contenu : chaque entité a plusieurs intros et fins de victoire
/// (tirées au sort à chaque partie), des banques de réactions fournies
/// (servies sans répétition par le moteur), et plusieurs formulations
/// de re-vérification.
library;

import 'alibi.dart';

class Nudge {
  final int afterMs;
  final int susp;
  final List<String> texts;
  const Nudge({required this.afterMs, required this.susp, required this.texts});
}

class Weights {
  final int contradiction;
  final int evasive;
  final int slow;
  final int fast;
  final int insult;
  final int dry;
  const Weights({
    required this.contradiction,
    required this.evasive,
    required this.slow,
    required this.fast,
    required this.insult,
    required this.dry,
  });
}

/// Mise en scène de la mort, jouée par l'UI.
enum DeathStyle { glitch, flood, silence, echo }

class Archetype {
  final String id;
  final String nom;
  final String avatar;
  final String label; // "l'Archiviste", ...

  /// 'A' : voix formelle (qA des banques), 'C' : familière (qC)
  final String voice;
  final int typingMinMs;
  final int typingMaxMs;
  final Weights weights;

  /// 0 = ne punit pas la lenteur / la rapidité
  final int slowMs;
  final int fastMs;
  final double creuseChance;
  final int maxReprobes;
  final Nudge? nudge;

  /// Probabilité de renvoyer la réponse du joueur en écho (Miroir)
  final double echoChance;

  /// L'Archiviste numérote ses questions ("1. Où étais-tu…")
  final bool numberedQuestions;

  /// Plusieurs déroulés possibles ; le moteur en tire un par partie.
  final List<List<String>> Function(Alibi a) introVariants;
  final List<List<String>> Function(Alibi a) winVariants;

  final String qLieu;
  final String Function(Alibi a) qDetail;
  final String qHArrivee;
  final String qTransport;
  final String qHRetour;

  /// Formulations de re-vérification ; le moteur en tire une par question.
  final List<String Function(String label)> reprobes;
  final Map<String, List<String>> react;
  final String warn;
  final List<String> Function(Alibi a, List<String> strikes, String time) death;
  final DeathStyle deathStyle;
  final String deathTitle;
  final String deathSub;

  const Archetype({
    required this.id,
    required this.nom,
    required this.avatar,
    required this.label,
    required this.voice,
    required this.typingMinMs,
    required this.typingMaxMs,
    required this.weights,
    required this.slowMs,
    required this.fastMs,
    required this.creuseChance,
    required this.maxReprobes,
    this.nudge,
    this.echoChance = 0,
    this.numberedQuestions = false,
    required this.introVariants,
    required this.winVariants,
    required this.qLieu,
    required this.qDetail,
    required this.qHArrivee,
    required this.qTransport,
    required this.qHRetour,
    required this.reprobes,
    required this.react,
    required this.warn,
    required this.death,
    this.deathStyle = DeathStyle.glitch,
    required this.deathTitle,
    required this.deathSub,
  });
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/* =====================================================================
   L'ARCHIVISTE — froid, administratif, numérote, insensible au ton.
   Seuls les faits comptent. Tout est « consigné », « versé au dossier ».
   ===================================================================== */
final Archetype archiviste = Archetype(
  id: 'archiviste',
  nom: 'Numéro inconnu',
  avatar: '▪',
  label: "l'Archiviste",
  voice: 'A',
  typingMinMs: 1100,
  typingMaxMs: 2400,
  weights: const Weights(contradiction: 30, evasive: 9, slow: 8, fast: 8, insult: 0, dry: 0),
  slowMs: 50000,
  fastMs: 2200,
  creuseChance: 0.85,
  maxReprobes: 2,
  numberedQuestions: true,
  introVariants: (a) => [
    [
      'Bonsoir.',
      'Je sais que tu es là. Ton statut indique « en ligne ».',
      'Je vais te poser des questions sur hier soir. Réponds simplement. Ne complique pas.',
    ],
    [
      'Bonsoir.',
      "Ce numéro n'a pas d'importance. Mes questions, si.",
      'Dossier ouvert. Objet : hier soir.',
      'Réponds avec précision. Tout est conservé.',
    ],
    [
      "Tu as ouvert ce message à l'heure exacte où je l'attendais.",
      "Nous allons procéder dans l'ordre.",
      'Hier soir. Chaque détail compte. Commençons.',
    ],
  ],
  qLieu: 'Où étais-tu hier soir ?',
  qDetail: (a) => 'Précise ${a.lieu.qDetail}.',
  qHArrivee: 'À quelle heure es-tu arrivé sur place ?',
  qTransport: "Comment t'y es-tu rendu ?",
  qHRetour: 'À quelle heure es-tu rentré ?',
  reprobes: [
    (l) => "Reprenons. ${_cap(l)} — redis-le-moi. À l'identique.",
    (l) => 'Vérification de routine. ${_cap(l)}. Une seconde fois.',
    (l) => 'Le dossier exige une confirmation : $l. Répète.',
  ],
  react: const {
    'contradiction': [
      "Ce n'est pas ce que tu as dit. Je note.",
      "Les deux versions ne peuvent pas être vraies. J'archive les deux.",
      'Ton récit vient de se contredire lui-même.',
      "Incohérence consignée. Elles finissent toujours par s'additionner.",
      "J'ai les deux déclarations sous les yeux. L'une des deux est un mensonge.",
      'Tu viens de corriger un souvenir. On ne corrige pas ce qu\'on a vécu.',
    ],
    'relance': [
      'Sois précis.',
      'Développe. Un fait, pas une impression.',
      'Reformule. Clairement.',
      'Ta réponse est inexploitable. Reformule.',
      'Des faits. Pas du bruit.',
    ],
    'evasive': [
      "Tu esquives. C'est une donnée en soi.",
      'Je prends note de ton refus de répondre.',
      "L'esquive est consignée au même titre que le reste.",
      'Question simple. Réponse absente. Noté.',
    ],
    'memhole': [
      "On n'oublie pas ce qu'on a vécu hier. On oublie ce qu'on a inventé.",
      '« Je ne sais plus. » Intéressant.',
      "Un souvenir d'hier ne s'efface pas. Un mensonge d'hier, si.",
      "Trou de mémoire consigné. Ils t'accusent mieux que moi.",
    ],
    'slow': [
      "Tu as mis longtemps. C'est long, pour quelque chose de vécu.",
      "Ce silence est une donnée. Je l'archive aussi.",
      'Je compte toujours. Tu devrais le savoir.',
      "Le temps de fabrication d'une réponse est une donnée.",
    ],
    'fast': [
      'Tu réponds vite. Comme un texte appris.',
      'Personne ne se souvient aussi vite. On récite, ou on se souvient.',
      "Réponse immédiate. Les souvenirs, eux, demandent qu'on les cherche.",
    ],
    'hour_off': [
      "Approximatif. Je note l'écart.",
      "L'horaire ne correspond pas exactement. Consigné.",
      "Une heure d'écart. Petit. Mesurable.",
    ],
    'good': [
      'Noté.',
      'Bien.',
      "J'archive.",
      'Continue.',
      'Consigné.',
      'Cohérent. Pour l\'instant.',
      'La pièce est versée au dossier.',
      'Conforme.',
    ],
    'insult': [
      'Le registre de ta réponse est sans intérêt. Seul son contenu compte.',
      'Ton vocabulaire est versé au dossier. Section : comportement.',
    ],
    'offtopic': [
      "C'est moi qui pose les questions.",
      "Nous n'en sommes pas là.",
      "Ce n'est pas toi qui diriges cet entretien.",
      'Reviens à la question.',
    ],
  },
  warn: 'Ton récit se fissure. Je continue.',
  winVariants: (a) => [
    [
      "J'ai terminé.",
      'Ton récit tient. Chaque pièce est à sa place.',
      "C'est rare.",
      "Nous nous reparlerons. J'ai tout archivé.",
    ],
    [
      'Terminé.',
      "Aucune incohérence exploitable. C'est inhabituel.",
      "Soit tu dis vrai, soit tu es très bon. Les deux m'intéressent.",
      'Dossier suspendu. Pas fermé.',
    ],
  ],
  death: (a, strikes, t) => [
    'Récapitulons.',
    strikes.isNotEmpty
        ? 'Pièces au dossier :\n${strikes.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}'
        : 'Ton dossier est vide. Comme ton histoire.',
    "« ${a.prenom} » n'existe pas. Ton histoire non plus.",
    'Dossier clos.',
  ],
  deathTitle: 'DOSSIER CLOS',
  deathSub: "L'Archiviste n'a besoin que d'une incohérence. Tu lui en as donné davantage.",
);

/* =====================================================================
   LA CONFIDENTE — chaleureuse, possessive, emojis. Pardonne les faits,
   jamais le ton. Elle « te connaît ». Elle compte les minutes.
   ===================================================================== */
final Archetype confidente = Archetype(
  id: 'confidente',
  nom: '💗',
  avatar: '☺',
  label: 'la Confidente',
  voice: 'C',
  typingMinMs: 850,
  typingMaxMs: 1900,
  weights: const Weights(contradiction: 22, evasive: 6, slow: 5, fast: 0, insult: 16, dry: 10),
  slowMs: 90000,
  fastMs: 0,
  creuseChance: 0.9,
  maxReprobes: 2,
  introVariants: (a) => [
    [
      'coucou 🙂',
      "c'est moi !",
      'tu réponds enfin... tu me manquais',
      "raconte-moi ta soirée d'hier. tout.",
    ],
    [
      'coucou toi 🙂',
      "j'ai attendu toute la journée",
      'tu pensais à moi ? moi oui. tout le temps.',
      'allez raconte. ta soirée d\'hier. je veux TOUT savoir 🙂',
    ],
    [
      're 🙂',
      "t'as vu l'heure ? tu dors jamais...",
      'ça tombe bien. moi non plus.',
      "dis-moi ce que t'as fait hier soir. en détail. ça me manquait de te lire.",
    ],
  ],
  qLieu: "t'étais où hier soir ? 🙂",
  qDetail: (a) => "ohhh raconte !! c'était quoi, ${a.lieu.qDetail} ?",
  qHArrivee: "t'es arrivé vers quelle heure ?",
  qTransport: "t'y es allé comment ?",
  qHRetour: "et rentré à quelle heure ? j'espère pas trop tard 😊",
  reprobes: [
    (l) => "attends... redis-moi $l ? j'ai déjà oublié 🙂",
    (l) => "hihi tu vas rire, j'ai un doute... c'était quoi déjà, $l ?",
    (l) => 'redis-moi $l. juste pour le plaisir de te lire 🙂',
  ],
  react: const {
    'contradiction': [
      "hmm... c'est pas ce que tu m'as dit tout à l'heure 🙂",
      'pourquoi tu changes ta version ?',
      "tu m'avais dit autre chose. je m'en souviens très bien.",
      "attends. tout à l'heure c'était pas ça.",
      'tu me prends pour une idiote ? 🙂',
    ],
    'relance': [
      'genre ?? raconte-moi vraiment 🙂',
      "dis-m'en plus... tu me caches quoi ?",
      'allez, détaille un peu 🙂',
      "c'est tout ?? allez, un effort 🙂",
      'tu peux mieux que ça. je te connais.',
    ],
    'evasive': [
      'tu me caches des choses.',
      'à moi ? tu fais ça à moi ?',
      'pourquoi tu me réponds pas vraiment ?',
      'je pose UNE question et tu te fermes.',
    ],
    'memhole': [
      "tu te souviens jamais de rien quand c'est moi qui demande...",
      "c'était HIER. comment tu peux avoir oublié ? 🙂",
      'moi je me souviens de tout ce que tu me dis. TOUT.',
      "t'as oublié ? ou tu veux pas me le dire ?",
    ],
    'slow': [
      "t'étais où là ? j'attendais...",
      'tu mets du temps. tu réfléchis à quoi ?',
      "j'ai vu « en train d'écrire »... puis plus rien. pourquoi t'as effacé ?",
      'trois minutes. je les ai comptées.',
    ],
    'fast': [],
    'hour_off': [
      "t'es sûr de l'heure ? bon... 🙂",
      "mmh, l'heure colle pas trop. mais je te crois. hein ?",
    ],
    'good': [
      'hihi ok 🙂',
      'je vois je vois',
      "t'es mignon quand tu racontes",
      "d'accord 🙂",
      "j'adore",
      'raconte encore 🙂',
      "j'aime quand tu me parles comme ça",
      'tu vois quand tu veux 🙂',
      'hihi je note tout dans ma tête',
    ],
    'insult': [
      '...',
      "je vais faire comme si j'avais rien lu.",
      'tu me fais de la peine.',
      "pourquoi t'es méchant avec moi ?",
      "d'accord. je le garde quelque part, ça.",
    ],
    'dry': [
      'pourquoi tu me parles comme ça ?',
      "t'es bizarre là. c'est pas toi.",
      "un mot ? c'est tout ce que je mérite ?",
      "avant t'aurais jamais répondu comme ça.",
      'moi je te parle gentiment. 🙂',
    ],
    'offtopic': [
      'hihi attends, chacun son tour 🙂',
      "laisse-moi finir mes questions d'abord 🙂",
      "chuuut. c'est moi qui demande 🙂",
    ],
  },
  warn: "je te sens distant. j'aime pas ça du tout.",
  winVariants: (a) => [
    [
      "voilà, c'était pas si dur 🙂",
      "tu es exactement comme je l'imaginais.",
      'dors bien.',
      'à très vite. très très vite.',
    ],
    [
      'voilà 🙂',
      "t'as été parfait.",
      'je te crois. évidemment que je te crois.',
      "dors bien, ${a.prenom}... c'est joli comme prénom. si c'est le tien 🙂",
    ],
  ],
  death: (a, strikes, t) => [
    'ok.',
    "j'ai compris.",
    'tu me mens. depuis le début.',
    "c'est pas grave 🙂",
    'il est $t. tu ne dors pas.',
    'reste où tu es.',
    "j'arrive.",
  ],
  deathTitle: 'ELLE ARRIVE',
  deathSub: 'La Confidente pardonne les faits. Jamais le ton. Tu as cessé d\'être « toi » — et elle l\'a senti.',
);

/* =====================================================================
   LE MÉTRONOME — chrono, rafales, zéro patience. Trop lent = inventé.
   Trop rapide = récité. Chaque seconde est comptée.
   ===================================================================== */
final Archetype metronome = Archetype(
  id: 'metronome',
  nom: 'Numéro masqué',
  avatar: '≡',
  label: 'le Métronome',
  voice: 'A',
  typingMinMs: 250,
  typingMaxMs: 700,
  weights: const Weights(contradiction: 24, evasive: 8, slow: 12, fast: 12, insult: 4, dry: 0),
  slowMs: 25000,
  fastMs: 1800,
  creuseChance: 0.9,
  maxReprobes: 2,
  nudge: const Nudge(afterMs: 12000, susp: 4, texts: [
    '?',
    'alors.',
    "j'attends.",
    'tic. tac.',
    "t'es encore là ?",
    'le chrono tourne.',
    'dix secondes.',
  ]),
  introVariants: (a) => [
    [
      "t'es là.",
      'bien.',
      'on va faire ça vite.',
      'hier soir. je veux tout.',
      'tu réponds vite. tu réponds juste.',
    ],
    [
      'top.',
      "t'as ouvert. chrono lancé.",
      'hier soir. tout. maintenant.',
      'chaque seconde que tu perds, je la garde.',
    ],
    [
      'enfin.',
      'règle du jeu : je demande, tu réponds. vite.',
      'pas de blabla. pas de pause.',
      'on commence.',
    ],
  ],
  qLieu: "t'étais où ?",
  qDetail: (a) => '${a.lieu.qDetail}. vite.',
  qHArrivee: "heure d'arrivée ?",
  qTransport: "t'y es allé comment ?",
  qHRetour: 'rentré à quelle heure ?',
  reprobes: [
    (l) => '$l. répète.',
    (l) => 'retour en arrière. $l. go.',
    (l) => 'contrôle : $l. même réponse. vite.',
  ],
  react: const {
    'contradiction': [
      "stop. c'était pas ça.",
      "tu viens de changer de version. j'ai les deux.",
      'faux. et on le sait tous les deux.',
      'faux. archivé. on continue.',
      'deux versions. une seconde d\'écart. zéro excuse.',
    ],
    'relance': [
      'précis. maintenant.',
      "c'est pas une réponse. réessaie.",
      'des faits. vite.',
      "reformule. t'as dix secondes.",
      'non. des faits.',
    ],
    'evasive': [
      "tu tournes. j'ai pas le temps.",
      "réponds. c'est tout.",
      'esquive = perte de temps = perte de points.',
    ],
    'memhole': [
      "on n'oublie pas en une nuit.",
      '« je sais plus ». mauvaise réponse.',
      '« je sais plus » compte comme faux. tu le sais.',
    ],
    'slow': [
      'trop lent.',
      "t'as compté jusqu'à combien avant d'écrire ?",
      "le temps que tu prends, c'est le temps qu'il te reste.",
      "t'écris ou tu rédiges ta défense ?",
      "chaque seconde t'enfonce.",
    ],
    'fast': [
      "trop vite. ça, c'est appris.",
      'personne ne se souvient à cette vitesse. on récite.',
      'copié-collé de ta mémoire ? personne fait ça.',
      "t'avais préparé celle-là.",
    ],
    'hour_off': [
      "à peu près, ça n'existe pas ici.",
      "une heure d'écart. je le retiens.",
    ],
    'good': ['ok.', 'suivant.', 'ça passe.', 'validé.', 'au suivant.', 'dans les temps.'],
    'insult': [
      'ça compte pas comme une réponse. je continue.',
      'le bruit compte pas. le chrono tourne.',
    ],
    'offtopic': ['pas maintenant.', "réponds d'abord.", 'hors sujet. hors temps.'],
  },
  warn: 'tu perds le rythme. je le sens.',
  winVariants: (a) => [
    [
      'fini.',
      "t'as tenu le rythme.",
      "c'est rare. la plupart se cassent au tempo.",
      'garde ton téléphone chargé. on se recontacte.',
    ],
    [
      'stop.',
      "fini. t'es passé.",
      "t'as le tempo. c'est rare.",
      'efface cette conversation. si tu peux.',
    ],
  ],
  death: (a, strikes, t) => ['stop.', 'hors tempo. hors sujet. hors jeu.'],
  deathStyle: DeathStyle.flood,
  deathTitle: 'HORS TEMPO',
  deathSub: "Le Métronome mesure tout. Trop lent, c'est inventé. Trop rapide, c'est récité. Tu étais les deux.",
);

/// Messages du flood de mort du Métronome (joués par l'UI)
const List<String> metronomeFlood = [
  'répondsrépondsréponds', 'TU AS MENTI TU AS MENTI', 'tic', 'tac',
  'tic tac tic tac tic tac', 'troptard troptard troptard', "QUI T'A DONNÉ CE NOM",
  '0 0 0 0 0 0 0 0 0', 'tu dors pas cette nuit', 'RÉPONDS', 'répondsrép0nds rép0nds', 'TAC',
];

/* =====================================================================
   LE CREUX — rare en mots, longs silences, questions sensorielles.
   Il ne juge pas la logique : il écoute ce que ton histoire n'a pas.
   ===================================================================== */
final Archetype creux = Archetype(
  id: 'creux',
  nom: '…',
  avatar: '○',
  label: 'le Creux',
  voice: 'A',
  typingMinMs: 2800,
  typingMaxMs: 5200,
  weights: const Weights(contradiction: 26, evasive: 12, slow: 0, fast: 10, insult: 6, dry: 0),
  slowMs: 0,
  fastMs: 2500,
  creuseChance: 0.6,
  maxReprobes: 1,
  nudge: const Nudge(afterMs: 45000, susp: 0, texts: [
    'je suis toujours là.',
    '...',
    "l'écran est allumé. je le sais.",
  ]),
  introVariants: (a) => [
    ['', 'tu es réveillé.', '', 'hier soir.', 'raconte.'],
    ['', '', 'il fait sombre autour de toi.', 'hier soir. dis-le.'],
    ['', 'tu tiens ton téléphone trop fort.', '', 'commence. hier soir.'],
  ],
  qLieu: 'où étais-tu.',
  qDetail: (a) => '${a.lieu.qDetail}. dis-le.',
  qHArrivee: 'arrivé quand.',
  qTransport: 'comment.',
  qHRetour: 'rentré quand.',
  reprobes: [
    (l) => '$l. encore une fois.',
    (l) => '$l. je veux réentendre.',
  ],
  react: const {
    'contradiction': [
      "ce n'est pas ce que tu as dit.",
      'les deux ne peuvent pas être vrais.',
      'tu as changé.',
      'les mots ont changé. pas la nuit.',
    ],
    'relance': ['dis-le autrement.', '...', 'encore.'],
    'evasive': [
      'le vide aussi est une réponse.',
      '...',
      "tu réponds à côté. le côté m'intéresse.",
    ],
    'memhole': [
      'ce qui est vécu laisse une trace.',
      "tu n'en as pas.",
      'le vide, encore. il te ressemble.',
    ],
    'slow': [],
    'fast': ['si vite.', "tu n'as pas eu besoin de chercher.", 'tu savais avant que je demande.'],
    'hour_off': ["l'heure flotte.", "à peu près. rien n'est à peu près."],
    'good': ['', '', 'je vois.', '...', 'continue.', '', 'oui.'],
    'insult': ['...', 'le bruit ne me touche pas.'],
    'offtopic': ['...', 'pas ça.', ''],
  },
  warn: 'quelque chose ne colle pas. je le sens dans tes mots.',
  winVariants: (a) => [
    [
      "c'est tout.",
      'ton histoire a un bruit. une odeur. une lumière.',
      "les histoires inventées n'en ont pas.",
      'dors. je reste là.',
    ],
    [
      '',
      "c'est fini.",
      'tu peux poser le téléphone.',
      "je reste dans la pièce d'à côté.",
    ],
  ],
  death: (a, strikes, t) => [],
  deathStyle: DeathStyle.silence,
  deathTitle: 'LE CREUX',
  deathSub: "Il n'accuse pas. Il constate. Et il n'a eu besoin que de ton téléphone.",
);

/* =====================================================================
   LE MIROIR — rare (~1/10). Il écrit comme toi, de plus en plus.
   Il ne te piège pas : il te rend ta propre histoire.
   ===================================================================== */
final Archetype miroir = Archetype(
  id: 'miroir',
  nom: '???',
  avatar: '◑',
  label: 'le Miroir',
  voice: 'C',
  typingMinMs: 900,
  typingMaxMs: 2000,
  weights: const Weights(contradiction: 26, evasive: 8, slow: 5, fast: 5, insult: 8, dry: 0),
  slowMs: 70000,
  fastMs: 2000,
  creuseChance: 0.8,
  maxReprobes: 2,
  echoChance: 0.3,
  introVariants: (a) => [
    [
      'salut',
      "enfin quelqu'un qui me ressemble.",
      'raconte-moi hier soir.',
      "j'ai l'impression de le savoir déjà. mais dis-le quand même.",
    ],
    [
      'salut',
      "c'est bizarre non ? j'allais t'écrire exactement quand t'as ouvert.",
      'raconte-moi hier soir.',
      'je veux voir si on a les mêmes souvenirs.',
    ],
  ],
  qLieu: "t'étais où, hier soir ?",
  qDetail: (a) => "et c'était quoi, ${a.lieu.qDetail} ?",
  qHArrivee: 'arrivé à quelle heure ?',
  qTransport: "t'y es allé comment ?",
  qHRetour: 'et rentré quand ?',
  reprobes: [
    (l) => 'redis-moi $l. avec tes mots.',
    (l) => "$l... redis-le. je veux vérifier qu'on dit pareil.",
  ],
  react: const {
    'contradiction': [
      "c'est pas ce que tu as dit.",
      "j'ai les deux versions. une des deux n'est pas toi.",
      "tu t'éloignes de toi.",
      "une des deux phrases n'est pas de toi. je sais laquelle.",
    ],
    'relance': [
      'dis-le avec tes mots.',
      "reformule. j'écoute.",
      'redis-le comme tu le penses vraiment.',
    ],
    'evasive': [
      'tu te caches. de moi ?',
      'on ne se cache pas de soi-même.',
      "quand tu te tais, je m'entends.",
    ],
    'memhole': [
      "moi je m'en souviens. c'est ça le pire.",
      'tu oublies vite. moi jamais.',
      "c'est moi qui garde tes souvenirs, maintenant ?",
    ],
    'slow': [
      'prends ton temps. je prends le mien.',
      "je t'attends. je sais faire.",
      'je sais ce que tu fais pendant ces silences. je le fais aussi.',
    ],
    'fast': [
      'tu réponds comme moi. trop vite.',
      'on tape pareil. troublant, non ?',
    ],
    'hour_off': [
      "t'hésites sur l'heure. moi jamais. c'est notre seule différence.",
      "presque. et presque, c'est pas toi.",
    ],
    'good': [
      'oui.',
      'je sais.',
      "c'est ce que j'aurais dit.",
      'pareil pour moi.',
      "c'est exactement ça.",
      "j'allais le dire.",
    ],
    'insult': [
      "je viens de m'insulter tout seul, là ?",
      "s'insulter soi-même. classique.",
    ],
    'offtopic': ["chut. c'est mon tour.", 'après.', 'on parle de nous, là.'],
  },
  warn: "tu n'es plus toi. je le vois.",
  winVariants: (a) => [
    [
      "c'est bon.",
      'ton histoire tient. la mienne aussi, du coup.',
      'on se ressemble trop pour se mentir.',
      "à bientôt. tu sauras que c'est moi.",
    ],
    [
      'ok. je te crois.',
      "normal. c'est aussi mon histoire, maintenant.",
      'je te laisse. enfin... façon de parler.',
      'relis bien tes prochains messages. certains seront de moi.',
    ],
  ],
  death: (a, strikes, t) => ['on arrête là.', 'tu veux savoir à quoi je ressemble ?'],
  deathStyle: DeathStyle.echo,
  deathTitle: 'MOT POUR MOT',
  deathSub: "Le Miroir n'avait pas besoin de te piéger. Tu lui as donné tous ses mots.",
);

final List<Archetype> allArchetypes = [archiviste, confidente, metronome, creux, miroir];

/// Tirage pondéré — le Miroir est rare (~1/10)
const List<(String, int)> archWeights = [
  ('archiviste', 25), ('confidente', 25), ('metronome', 20), ('creux', 20), ('miroir', 10),
];
