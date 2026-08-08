/// Le récit long : ce que l'entité laisse filtrer, une nuit après l'autre.
///
/// À la fin de chaque nuit (survie ou mort), l'entité envoie un dernier
/// message : un fragment. Les fragments s'assemblent en une révélation
/// sur ce que sont vraiment les alibis qu'on fait porter au joueur.
/// Ils sont conservés dans les Archives, les suivants restent masqués.
library;

class Fragment {
  /// Titre affiché dans les Archives (jamais dans la conversation).
  final String titre;

  /// Ce que l'entité envoie, une fois la nuit finie.
  final List<String> lignes;
  const Fragment(this.titre, this.lignes);
}

/// Le fil rouge, en 12 nuits.
const List<Fragment> storyFragments = [
  Fragment('I. Le prénom', [
    'Encore une chose.',
    "Ce prénom qu'on t'a donné cette nuit.",
    "Tu n'es pas le premier à le porter devant moi.",
  ]),
  Fragment('II. Le carnet', [
    'Avant de partir.',
    "J'ai un carnet. Des prénoms, des soirées, des horaires.",
    "Le tien y était avant que tu ouvres l'application.",
  ]),
  Fragment('III. Les rayures', [
    'Une précision.',
    'Dans le carnet, certains prénoms sont rayés.',
    'La rature ne veut pas dire que je les ai crus.',
  ]),
  Fragment('IV. Ceux d\'avant', [
    "Tu te demandes sûrement d'où viennent ces soirées.",
    "Elles ont été vécues. Par quelqu'un. Vraiment.",
    "Pas par toi.",
  ]),
  Fragment('V. La nuit du cinéma', [
    "Le premier s'appelait Julien.",
    'Il a répondu à toutes mes questions. Sans une seule faute.',
    "On ne l'a plus revu après.",
  ]),
  Fragment('VI. Ce que je cherche', [
    'Je ne cherche pas un menteur.',
    "N'importe qui ment. Ça ne m'apprend rien.",
    'Je cherche quelqu\'un de précis.',
  ]),
  Fragment('VII. Le point commun', [
    "Ils avaient tous une soirée à raconter.",
    "Ils avaient tous quelqu'un pour la confirmer.",
    "Aucun de ces témoins n'existait.",
  ]),
  Fragment('VIII. La liste se réduit', [
    'Il en reste peu.',
    'Chaque nuit, la liste raccourcit.',
    'Ce n\'est pas moi qui la raccourcis.',
  ]),
  Fragment('IX. Le tien', [
    "J'ai relu tes réponses des autres nuits.",
    'Tu inventes toujours les mêmes détails. Les gens vrais varient.',
    'Ça, c\'est intéressant.',
  ]),
  Fragment('X. Ce que tu portes', [
    "Ces soirées que tu récites ne sont pas des inventions.",
    "Ce sont des souvenirs. Ceux des disparus.",
    "Quelqu'un te les met dans la bouche. Ce n'est pas moi.",
  ]),
  Fragment('XI. La question', [
    "Je n'ai jamais voulu savoir si tu mentais.",
    'Je voulais savoir si tu étais encore là pour mentir.',
    'Les autres avaient cessé de répondre bien avant la fin.',
  ]),
  Fragment('XII. Dernière page', [
    "J'arrive au bout du carnet.",
    'Il y a un dernier prénom. Il n\'est pas rayé.',
    "Ce n'est pas un prénom qu'on t'a donné.",
    "C'est le tien.",
    'Bonne nuit.',
  ]),
];

/// Le fragment à délivrer pour la nuit n° [nightIndex] (0-based),
/// ou null quand le récit est terminé.
Fragment? fragmentFor(int nightIndex) =>
    nightIndex >= 0 && nightIndex < storyFragments.length
        ? storyFragments[nightIndex]
        : null;

int get storyLength => storyFragments.length;
