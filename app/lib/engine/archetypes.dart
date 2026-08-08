/// Les 5 archétypes d'entité. Même moteur d'évaluation pour tous,
/// pondérations et style propres à chacun.
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

  final List<String> Function(Alibi a) intro;
  final String qLieu;
  final String Function(Alibi a) qDetail;
  final String qHArrivee;
  final String qTransport;
  final String qHRetour;
  final String Function(String label) reprobe;
  final Map<String, List<String>> react;
  final String warn;
  final List<String> Function(Alibi a) win;
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
    required this.intro,
    required this.qLieu,
    required this.qDetail,
    required this.qHArrivee,
    required this.qTransport,
    required this.qHRetour,
    required this.reprobe,
    required this.react,
    required this.warn,
    required this.win,
    required this.death,
    this.deathStyle = DeathStyle.glitch,
    required this.deathTitle,
    required this.deathSub,
  });
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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
  intro: (a) => [
    'Bonsoir.',
    'Je sais que tu es là. Ton statut indique « en ligne ».',
    'Je vais te poser des questions sur hier soir. Réponds simplement. Ne complique pas.',
  ],
  qLieu: 'Où étais-tu hier soir ?',
  qDetail: (a) => 'Précise ${a.lieu.qDetail}.',
  qHArrivee: 'À quelle heure es-tu arrivé sur place ?',
  qTransport: "Comment t'y es-tu rendu ?",
  qHRetour: 'À quelle heure es-tu rentré ?',
  reprobe: (l) => 'Reprenons. ${_cap(l)} — redis-le-moi. À l\'identique.',
  react: const {
    'contradiction': [
      "Ce n'est pas ce que tu as dit. Je note.",
      "Les deux versions ne peuvent pas être vraies. J'archive les deux.",
      'Ton récit vient de se contredire lui-même.',
    ],
    'relance': ['Sois précis.', 'Développe. Un fait, pas une impression.', 'Reformule. Clairement.'],
    'evasive': ["Tu esquives. C'est une donnée en soi.", 'Je prends note de ton refus de répondre.'],
    'memhole': [
      "On n'oublie pas ce qu'on a vécu hier. On oublie ce qu'on a inventé.",
      '« Je ne sais plus. » Intéressant.',
    ],
    'slow': [
      "Tu as mis longtemps. C'est long, pour quelque chose de vécu.",
      "Ce silence est une donnée. Je l'archive aussi.",
    ],
    'fast': [
      'Tu réponds vite. Comme un texte appris.',
      'Personne ne se souvient aussi vite. On récite, ou on se souvient.',
    ],
    'good': ['Noté.', 'Bien.', "J'archive.", 'Continue.'],
    'insult': ['Le registre de ta réponse est sans intérêt. Seul son contenu compte.'],
    'offtopic': ["C'est moi qui pose les questions.", "Nous n'en sommes pas là."],
  },
  warn: 'Ton récit se fissure. Je continue.',
  win: (a) => [
    "J'ai terminé.",
    'Ton récit tient. Chaque pièce est à sa place.',
    "C'est rare.",
    "Nous nous reparlerons. J'ai tout archivé.",
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
  intro: (a) => [
    'coucou 🙂',
    "c'est moi !",
    'tu réponds enfin... tu me manquais',
    "raconte-moi ta soirée d'hier. tout.",
  ],
  qLieu: "t'étais où hier soir ? 🙂",
  qDetail: (a) => "ohhh raconte !! c'était quoi, ${a.lieu.qDetail} ?",
  qHArrivee: "t'es arrivé vers quelle heure ?",
  qTransport: "t'y es allé comment ?",
  qHRetour: "et rentré à quelle heure ? j'espère pas trop tard 😊",
  reprobe: (l) => "attends... redis-moi $l ? j'ai déjà oublié 🙂",
  react: const {
    'contradiction': [
      "hmm... c'est pas ce que tu m'as dit tout à l'heure 🙂",
      'pourquoi tu changes ta version ?',
      "tu m'avais dit autre chose. je m'en souviens très bien.",
    ],
    'relance': [
      'genre ?? raconte-moi vraiment 🙂',
      "dis-m'en plus... tu me caches quoi ?",
      'allez, détaille un peu 🙂',
    ],
    'evasive': ['tu me caches des choses.', 'à moi ? tu fais ça à moi ?'],
    'memhole': [
      "tu te souviens jamais de rien quand c'est moi qui demande...",
      "c'était HIER. comment tu peux avoir oublié ? 🙂",
    ],
    'slow': ["t'étais où là ? j'attendais...", 'tu mets du temps. tu réfléchis à quoi ?'],
    'fast': [],
    'good': ['hihi ok 🙂', 'je vois je vois', "t'es mignon quand tu racontes", "d'accord 🙂", "j'adore"],
    'insult': ['...', "je vais faire comme si j'avais rien lu.", 'tu me fais de la peine.'],
    'dry': [
      'pourquoi tu me parles comme ça ?',
      "t'es bizarre là. c'est pas toi.",
      "un mot ? c'est tout ce que je mérite ?",
    ],
    'offtopic': ['hihi attends, chacun son tour 🙂', "laisse-moi finir mes questions d'abord 🙂"],
  },
  warn: "je te sens distant. j'aime pas ça du tout.",
  win: (a) => [
    "voilà, c'était pas si dur 🙂",
    "tu es exactement comme je l'imaginais.",
    'dors bien.',
    'à très vite. très très vite.',
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
  nudge: const Nudge(afterMs: 12000, susp: 4, texts: ['?', 'alors.', "j'attends.", 'tic. tac.']),
  intro: (a) => ["t'es là.", 'bien.', 'on va faire ça vite.', 'hier soir. je veux tout.', 'tu réponds vite. tu réponds juste.'],
  qLieu: "t'étais où ?",
  qDetail: (a) => '${a.lieu.qDetail}. vite.',
  qHArrivee: "heure d'arrivée ?",
  qTransport: "t'y es allé comment ?",
  qHRetour: 'rentré à quelle heure ?',
  reprobe: (l) => '$l. répète.',
  react: const {
    'contradiction': [
      "stop. c'était pas ça.",
      "tu viens de changer de version. j'ai les deux.",
      'faux. et on le sait tous les deux.',
    ],
    'relance': ['précis. maintenant.', "c'est pas une réponse. réessaie.", 'des faits. vite.'],
    'evasive': ["tu tournes. j'ai pas le temps.", "réponds. c'est tout."],
    'memhole': ["on n'oublie pas en une nuit.", '« je sais plus ». mauvaise réponse.'],
    'slow': [
      'trop lent.',
      "t'as compté jusqu'à combien avant d'écrire ?",
      "le temps que tu prends, c'est le temps qu'il te reste.",
    ],
    'fast': ["trop vite. ça, c'est appris.", 'personne ne se souvient à cette vitesse. on récite.'],
    'good': ['ok.', 'suivant.', 'ça passe.'],
    'insult': ['ça compte pas comme une réponse. je continue.'],
    'offtopic': ['pas maintenant.', "réponds d'abord."],
  },
  warn: 'tu perds le rythme. je le sens.',
  win: (a) => [
    'fini.',
    "t'as tenu le rythme.",
    "c'est rare. la plupart se cassent au tempo.",
    'garde ton téléphone chargé. on se recontacte.',
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
  nudge: const Nudge(afterMs: 45000, susp: 0, texts: ['je suis toujours là.', '...']),
  intro: (a) => ['', 'tu es réveillé.', '', 'hier soir.', 'raconte.'],
  qLieu: 'où étais-tu.',
  qDetail: (a) => '${a.lieu.qDetail}. dis-le.',
  qHArrivee: 'arrivé quand.',
  qTransport: 'comment.',
  qHRetour: 'rentré quand.',
  reprobe: (l) => '$l. encore une fois.',
  react: const {
    'contradiction': ["ce n'est pas ce que tu as dit.", 'les deux ne peuvent pas être vrais.', 'tu as changé.'],
    'relance': ['dis-le autrement.', '...'],
    'evasive': ['le vide aussi est une réponse.', '...'],
    'memhole': ['ce qui est vécu laisse une trace.', "tu n'en as pas."],
    'slow': [],
    'fast': ['si vite.', "tu n'as pas eu besoin de chercher."],
    'good': ['', '', 'je vois.', '...', 'continue.'],
    'insult': ['...', 'le bruit ne me touche pas.'],
    'offtopic': ['...', 'pas ça.'],
  },
  warn: 'quelque chose ne colle pas. je le sens dans tes mots.',
  win: (a) => [
    "c'est tout.",
    'ton histoire a un bruit. une odeur. une lumière.',
    "les histoires inventées n'en ont pas.",
    'dors. je reste là.',
  ],
  death: (a, strikes, t) => [],
  deathStyle: DeathStyle.silence,
  deathTitle: 'LE CREUX',
  deathSub: "Il n'accuse pas. Il constate. Et il n'a eu besoin que de ton téléphone.",
);

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
  intro: (a) => [
    'salut',
    "enfin quelqu'un qui me ressemble.",
    'raconte-moi hier soir.',
    "j'ai l'impression de le savoir déjà. mais dis-le quand même.",
  ],
  qLieu: "t'étais où, hier soir ?",
  qDetail: (a) => "et c'était quoi, ${a.lieu.qDetail} ?",
  qHArrivee: 'arrivé à quelle heure ?',
  qTransport: "t'y es allé comment ?",
  qHRetour: 'et rentré quand ?',
  reprobe: (l) => 'redis-moi $l. avec tes mots.',
  react: const {
    'contradiction': [
      "c'est pas ce que tu as dit.",
      "j'ai les deux versions. une des deux n'est pas toi.",
      "tu t'éloignes de toi.",
    ],
    'relance': ['dis-le avec tes mots.', "reformule. j'écoute."],
    'evasive': ['tu te caches. de moi ?', 'on ne se cache pas de soi-même.'],
    'memhole': ["moi je m'en souviens. c'est ça le pire.", 'tu oublies vite. moi jamais.'],
    'slow': ['prends ton temps. je prends le mien.', "je t'attends. je sais faire."],
    'fast': ['tu réponds comme moi. trop vite.'],
    'good': ['oui.', 'je sais.', "c'est ce que j'aurais dit.", 'pareil pour moi.'],
    'insult': ["je viens de m'insulter tout seul, là ?"],
    'offtopic': ["chut. c'est mon tour.", 'après.'],
  },
  warn: "tu n'es plus toi. je le vois.",
  win: (a) => [
    "c'est bon.",
    'ton histoire tient. la mienne aussi, du coup.',
    'on se ressemble trop pour se mentir.',
    "à bientôt. tu sauras que c'est moi.",
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
