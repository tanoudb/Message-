/// Générateur d'alibi + banques de contenu.
/// La note n'affiche QUE les faits. Tout ce qu'elle ne dit pas est une
/// zone d'ombre implicite : le joueur improvise, le jeu verrouille.
library;

import 'dart:math';

/// Question de creusement / zone d'ombre. [qA] : voix formelle, [qC] : familière.
class Creuse {
  final String key;
  final String label;
  final String qA;
  final String qC;
  const Creuse(this.key, this.label, this.qA, this.qC);
}

class DetailFact {
  final String canon;
  final List<String> syn;
  final List<String> incompat;
  const DetailFact(this.canon, this.syn, this.incompat);
}

class Lieu {
  final String canon;
  final List<String> syn;
  final List<String> incompat;
  final List<DetailFact> details;
  final String qDetail;
  final List<Creuse> creuser;
  const Lieu(this.canon, this.syn, this.incompat, this.details, this.qDetail, this.creuser);
}

class TransportFact {
  final String canon;
  final List<String> syn;
  final List<String> incompat;
  final Creuse creuser;
  const TransportFact(this.canon, this.syn, this.incompat, this.creuser);
}

class Alibi {
  final String prenom;
  final String metier;
  final Lieu lieu;
  final DetailFact detail;
  final TransportFact transport;
  final int hArrivee;
  final int hRetour;
  const Alibi({
    required this.prenom,
    required this.metier,
    required this.lieu,
    required this.detail,
    required this.transport,
    required this.hArrivee,
    required this.hRetour,
  });
}

const List<String> prenoms = [
  'Julien', 'Camille', 'Maxime', 'Léa', 'Romain', 'Sarah', 'Thomas', 'Chloé',
  'Nadia', 'Hugo', 'Inès', 'Lucas', 'Emma', 'Yanis', 'Manon', 'Karim',
  'Élodie', 'Bastien', 'Aïcha', 'Théo',
];

const List<String> metiers = [
  'serveur en brasserie', 'vendeur en magasin', 'livreur', 'étudiant',
  'agent de sécurité', 'préparateur de commandes', 'infirmier de nuit',
  'caissier', 'cuisinier', 'chauffeur VTC', 'barman', 'standardiste',
  'magasinier', 'aide-soignant',
];

const List<Lieu> lieux = [
  Lieu(
    'au cinéma',
    ['cinema', 'cine', 'cinoche', 'film', 'seance', 'voir un film', 'ugc', 'pathe', 'gaumont', 'mk2', 'cgr'],
    ['bar', 'restaurant', 'resto', 'boulot', 'travail', 'salle de sport', 'gym', 'chez moi', 'reste chez moi', 'concert', 'boite'],
    [
      DetailFact("un film d'horreur", ['horreur', 'film d horreur', 'peur', 'flippant', 'epouvante'],
          ['comedie', 'comique', 'drole', 'dessin anime', 'romantique']),
      DetailFact('une comédie', ['comedie', 'comique', 'drole', 'rire', 'marrant', 'rigole'],
          ['horreur', 'peur', 'epouvante', 'drame']),
      DetailFact('un thriller', ['thriller', 'suspense', 'policier', 'enquete'],
          ['comedie', 'drole', 'dessin anime', 'romantique']),
    ],
    'ce que tu as vu',
    [
      Creuse('nom_lieu', 'le nom du cinéma', 'Quel cinéma ? Son nom.', "c'était quel ciné ? 🙂"),
      Creuse('affluence', 'le monde dans la salle', 'Il y avait du monde dans la salle ?', 'y avait du monde ?'),
      Creuse('fin_film', 'la fin du film', 'Comment ça se termine ?', 'et ça finit comment ?? spoile-moi 🙂'),
    ],
  ),
  Lieu(
    'au restaurant',
    ['restaurant', 'resto', 'manger', 'mange', 'diner', 'dine', 'bouffer', 'table'],
    ['cinema', 'cine', 'film', 'bar', 'salle de sport', 'gym', 'chez moi', 'reste chez moi', 'boulot', 'travail', 'boite'],
    [
      DetailFact('une pizza', ['pizza', 'italien', 'margherita', 'quatre fromages', '4 fromages', 'calzone'],
          ['burger', 'sushi', 'kebab', 'chinois', 'couscous']),
      DetailFact('un burger', ['burger', 'hamburger', 'frites', 'cheeseburger'],
          ['pizza', 'sushi', 'kebab', 'chinois', 'couscous']),
      DetailFact('des sushis', ['sushi', 'sushis', 'japonais', 'maki', 'california'],
          ['pizza', 'burger', 'kebab', 'italien', 'couscous']),
    ],
    'ce que tu as mangé',
    [
      Creuse('nom_lieu', 'le nom du restaurant', 'Quel restaurant ? Son nom.', "il s'appelle comment ce resto ?"),
      Creuse('paiement', 'le moyen de paiement', 'Tu as réglé comment ?', "t'as payé comment ?"),
      Creuse('dessert', 'le dessert', 'Dessert ?', 'et en dessert ?? 🙂'),
    ],
  ),
  Lieu(
    'chez un ami',
    ['ami', 'amie', 'pote', 'chez lui', 'chez elle', 'copain', 'copine', 'appart', 'pote a moi'],
    ['cinema', 'cine', 'restaurant', 'resto', 'bar', 'salle de sport', 'gym', 'boulot', 'travail', 'seul chez moi', 'boite'],
    [
      DetailFact('jouer aux jeux vidéo', ['jeux video', 'jeu video', 'jouer', 'console', 'manette', 'fifa', 'ps5', 'switch'],
          ['film', 'reviser', 'match', 'cuisine', 'serie']),
      DetailFact('regarder un match', ['match', 'foot', 'football', 'regarde le match', 'ligue'],
          ['jeux video', 'console', 'reviser', 'manette']),
      DetailFact('réviser ensemble', ['reviser', 'revisions', 'bosser', 'travailler', 'partiel', 'exam', 'cours'],
          ['jeux video', 'match', 'soiree', 'fete', 'console']),
    ],
    'ce que vous avez fait',
    [
      Creuse('nom_ami', 'le nom de ton ami', 'Cet ami a un nom. Donne-le.', "il s'appelle comment ? 🙂"),
      Creuse('habite', 'là où habite ton ami', 'Il habite où ?', 'il habite où ?'),
      Creuse('repas_ami', 'ce que vous avez mangé', 'Vous avez mangé quelque chose ?', 'vous avez grignoté quoi ?'),
    ],
  ),
  Lieu(
    'au bar',
    ['bar', 'pub', 'verre', 'pinte', 'comptoir', 'apero', 'picole', 'boire un coup'],
    ['cinema', 'cine', 'film', 'restaurant', 'resto', 'salle de sport', 'gym', 'chez moi', 'reste chez moi', 'boulot', 'travail', 'concert', 'boite'],
    [
      DetailFact('quelques bières', ['biere', 'bieres', 'pinte', 'pintes', 'demi', 'blonde', 'ipa'],
          ['cocktail', 'mojito', 'spritz', 'vin', 'coca', 'soda', 'sans alcool']),
      DetailFact('des cocktails', ['cocktail', 'cocktails', 'mojito', 'spritz', 'margarita', 'pina colada'],
          ['biere', 'pinte', 'demi', 'vin']),
      DetailFact('du vin', ['vin', 'rouge', 'blanc', 'rose', 'verre de vin'],
          ['biere', 'pinte', 'cocktail', 'mojito', 'spritz']),
    ],
    'ce que tu as bu',
    [
      Creuse('nom_lieu', 'le nom du bar', 'Quel bar ? Son nom.', "il s'appelle comment ce bar ?"),
      Creuse('musique', 'la musique du bar', 'Quelle musique passait ?', "c'était quoi l'ambiance ? la musique ?"),
      Creuse('prix', 'ce que tu as payé', "L'addition. Combien ?", "t'en as eu pour combien ? 🙂"),
    ],
  ),
  Lieu(
    'à la salle de sport',
    ['salle', 'sport', 'muscu', 'musculation', 'gym', 'entrainement', 'fitness', 'seance', 'basic fit', 'fitness park'],
    ['cinema', 'cine', 'film', 'bar', 'restaurant', 'resto', 'chez moi', 'reste chez moi', 'concert', 'boite', 'boulot', 'travail'],
    [
      DetailFact('séance haut du corps', ['haut du corps', 'pecs', 'developpe', 'bras', 'epaules', 'dos', 'push', 'traction'],
          ['jambes', 'squat', 'cardio', 'course', 'tapis', 'rameur']),
      DetailFact('séance jambes', ['jambes', 'squat', 'leg', 'presse', 'fessiers', 'mollets'],
          ['pecs', 'bras', 'epaules', 'haut du corps', 'cardio', 'tapis']),
      DetailFact('du cardio', ['cardio', 'tapis', 'course', 'couru', 'rameur', 'elliptique'],
          ['muscu', 'pecs', 'squat', 'fonte', 'developpe']),
    ],
    'ce que tu as travaillé',
    [
      Creuse('nom_lieu', 'le nom de ta salle', 'Quelle salle ? Son nom.', "t'es inscrit où ?"),
      Creuse('affluence', 'le monde dans la salle', 'Il y avait du monde ?', 'y avait du monde ?'),
      Creuse('duree', 'la durée de ta séance', 'Durée de la séance ?', "t'y es resté longtemps ?"),
    ],
  ),
  Lieu(
    'à un concert',
    ['concert', 'live', 'scene', 'festival', 'zenith', 'voir un groupe', 'salle de concert'],
    ['cinema', 'cine', 'film', 'restaurant', 'resto', 'bar', 'salle de sport', 'gym', 'chez moi', 'reste chez moi', 'boulot', 'travail', 'boite'],
    [
      DetailFact('un groupe de rock', ['rock', 'metal', 'guitare', 'groupe', 'riff'],
          ['rap', 'rappeur', 'dj', 'electro', 'techno', 'classique', 'jazz']),
      DetailFact('un rappeur', ['rap', 'rappeur', 'hip hop', 'freestyle'],
          ['rock', 'metal', 'guitare', 'classique', 'jazz', 'techno']),
      DetailFact("de l'électro", ['electro', 'dj', 'techno', 'house', 'set'],
          ['rock', 'metal', 'rap', 'rappeur', 'classique', 'jazz']),
    ],
    'ce que tu as écouté',
    [
      Creuse('nom_lieu', 'le nom de la salle', 'Quelle salle ? Son nom.', "c'était où ??"),
      Creuse('place', 'là où tu étais placé', 'Placé où, dans la salle ?', "t'étais où ? devant ??"),
      Creuse('morceau', 'le morceau qui t\'a marqué', 'Un morceau. Lequel ?', "ils ont joué quoi que t'as adoré ? 🙂"),
    ],
  ),
];

const List<TransportFact> transports = [
  TransportFact('en métro', ['metro', 'ligne', 'rame', 'station'],
      ['voiture', 'conduit', 'velo', 'a pied', 'bus', 'taxi', 'uber', 'train'],
      Creuse('detail_transport', 'ta ligne de métro', 'Quelle ligne ?', 'quelle ligne ?')),
  TransportFact('en voiture', ['voiture', 'conduit', 'caisse', 'volant', 'bagnole'],
      ['metro', 'bus', 'a pied', 'velo', 'train', 'taxi', 'uber'],
      Creuse('detail_transport', "là où tu t'es garé", 'Garée où ?', "t'as trouvé à te garer ?? où ça ?")),
  TransportFact('à pied', ['a pied', 'pied', 'marche', 'marchant', 'marcher'],
      ['voiture', 'metro', 'bus', 'velo', 'conduit', 'taxi', 'uber', 'train'],
      Creuse('detail_transport', 'ton temps de marche', 'Combien de temps de marche ?', "t'as marché longtemps ?")),
  TransportFact('en bus', ['bus', 'arret'],
      ['voiture', 'metro', 'a pied', 'velo', 'conduit', 'taxi', 'train'],
      Creuse('detail_transport', 'ton numéro de bus', 'Quel numéro ?', 'quel bus ?')),
  TransportFact('à vélo', ['velo', 'bicyclette', 'velib', 'pedale'],
      ['voiture', 'metro', 'bus', 'a pied', 'conduit', 'taxi', 'uber', 'train'],
      Creuse('detail_transport', 'ton temps de trajet à vélo', 'Temps de trajet ?', "t'as pédalé longtemps ?")),
  TransportFact('en VTC', ['uber', 'vtc', 'taxi', 'chauffeur', 'bolt', 'heetch'],
      ['voiture', 'metro', 'bus', 'a pied', 'velo', 'train', 'conduit'],
      Creuse('detail_transport', 'le prix de la course', 'Le prix de la course ?', "t'en as eu pour combien ?")),
];

/// Zones d'ombre implicites — jamais montrées dans la note
const List<Creuse> sondes = [
  Creuse('compagnie', 'qui était avec toi',
      'Étais-tu seul ? Si non : qui était présent ?', "t'étais avec quelqu'un ? dis-moi tout 👀"),
  Creuse('raison', 'pourquoi tu y es allé',
      'Pourquoi ce soir-là, précisément ?', "et qu'est-ce qui t'a pris d'y aller hier ? 🙂"),
  Creuse('tenue', 'ce que tu portais',
      "Qu'est-ce que tu portais ?", "t'étais habillé comment ? 🙂"),
  Creuse('meteo', 'le temps qu\'il faisait',
      'Quel temps faisait-il ?', 'il faisait quel temps hier soir ?'),
  Creuse('avant_dormir', 'la dernière chose faite avant de dormir',
      'La dernière chose que tu as faite avant de dormir. Dis-la.', 'et juste avant de dormir, t\'as fait quoi ?'),
  Creuse('tel_eteint', 'ton téléphone éteint entre 21h et 23h',
      'Ton téléphone a été injoignable entre 21h et 23h. Explique.',
      "j'ai essayé de t'appeler hier soir. injoignable. pourquoi ? 🙂"),
  Creuse('temoin', 'qui peut confirmer t\'avoir vu',
      "Qui peut confirmer t'avoir vu là-bas ? Un nom.",
      "et qui t'a vu là-bas ? donne-moi un nom 🙂"),
  Creuse('en_rentrant', 'ce que tu as fait juste en rentrant',
      "Qu'as-tu fait immédiatement en rentrant ?",
      "et en rentrant, t'as fait quoi direct ?"),
  Creuse('croise', 'qui tu as croisé sur le trajet',
      'Sur le trajet. Qui as-tu croisé ?', "t'as croisé quelqu'un en chemin ?"),
];

/// Sondes sensorielles — réservées au Creux
const List<Creuse> sondesCreux = [
  Creuse('bruit', 'ce que tu entendais là-bas',
      "ferme les yeux. qu'est-ce que tu entendais, là-bas ?", "qu'est-ce que tu entendais ?"),
  Creuse('odeur', "l'odeur de l'endroit", 'ça sentait quoi ?', 'ça sentait quoi ?'),
  Creuse('lumiere', "la lumière de l'endroit", 'la lumière. décris-la.', 'la lumière ?'),
  Creuse('temperature', 'la température là-bas',
      'il faisait chaud, là-bas ? ou froid.', 'chaud ou froid ?'),
];

Alibi generateAlibi(Random rng) {
  final lieu = lieux[rng.nextInt(lieux.length)];
  return Alibi(
    prenom: prenoms[rng.nextInt(prenoms.length)],
    metier: metiers[rng.nextInt(metiers.length)],
    lieu: lieu,
    detail: lieu.details[rng.nextInt(lieu.details.length)],
    transport: transports[rng.nextInt(transports.length)],
    hArrivee: 18 + rng.nextInt(3),
    hRetour: 22 + rng.nextInt(2),
  );
}
