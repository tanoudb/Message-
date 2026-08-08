/// Utilitaires texte du moteur : normalisation, distance de Levenshtein,
/// négation, extraction d'heure, mots pleins. Port fidèle du prototype v3.
library;

const Map<String, String> _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ç': 'c', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
};

String norm(String s) {
  var t = s.toLowerCase();
  _accents.forEach((k, v) => t = t.replaceAll(k, v));
  t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> tokens(String s) =>
    norm(s).split(' ').where((w) => w.isNotEmpty).toList();

int lev(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var prev = List<int>.generate(n + 1, (i) => i);
  var cur = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    cur[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost]
          .reduce((x, y) => x < y ? x : y);
    }
    final t = prev;
    prev = cur;
    cur = t;
  }
  return prev[n];
}

const Set<String> negWords = {'pas', 'jamais', 'non', 'aucun', 'aucune', 'ni', 'sans'};

/// Trouve un mot (à ~1-2 fautes près). Renvoie l'index du token, ou -1.
int findFuzzy(List<String> toks, String word) {
  final w = norm(word);
  final tol = w.length >= 6 ? 2 : (w.length >= 4 ? 1 : 0);
  for (var i = 0; i < toks.length; i++) {
    if (lev(toks[i], w) <= tol) return i;
  }
  return -1;
}

/// Le texte affirme-t-il ce mot ? (présent ET non nié dans les 3 tokens avant)
bool affirms(String text, String word) {
  final nw = norm(word);
  if (nw.contains(' ')) {
    final nt = norm(text);
    if (!nt.contains(nw)) return false;
    final before = nt.split(nw).first.trim().split(' ');
    final tail = before.length <= 3 ? before : before.sublist(before.length - 3);
    return !tail.any(negWords.contains);
  }
  final toks = tokens(text);
  final i = findFuzzy(toks, word);
  if (i < 0) return false;
  for (var k = (i - 3) < 0 ? 0 : i - 3; k < i; k++) {
    if (negWords.contains(toks[k])) return false;
  }
  return true;
}

bool affirmsAny(String text, List<String> words) =>
    words.any((w) => affirms(text, w));

bool hasAny(String text, List<String> words) {
  final t = tokens(text);
  return words.any((w) =>
      norm(w).contains(' ') ? norm(text).contains(norm(w)) : findFuzzy(t, w) >= 0);
}

int? extractHour(String text) {
  final t = norm(text);
  if (t.contains('minuit')) return 0;
  if (t.contains('midi')) return 12;
  final m = RegExp(r'(\d{1,2})\s*(h|heure)').firstMatch(t) ??
      RegExp(r'\b(\d{1,2})\b').firstMatch(t);
  if (m != null) {
    final h = int.parse(m.group(1)!);
    if (h >= 0 && h <= 23) return h;
  }
  return null;
}

final Set<String> stopwords =
    ('je tu il elle on nous vous ils elles le la les un une des de du d l a ai as '
            'est etait etais suis avec pour dans sur pas ne plus rien sais crois pense '
            'que qui quoi ou et mais donc or ni car si me te se ma ta sa mon ton son '
            'mes tes ses c ca cela y en tres bien tout toute vers genre juste truc '
            'chose comme ete alle allee bas la')
        .split(' ')
        .toSet();

List<String> contentWords(String text) =>
    tokens(text).where((w) => w.length >= 3 && !stopwords.contains(w)).toList();

const List<String> insults = [
  'connard', 'conne', 'connasse', 'batard', 'enfoire', 'ta gueule', 'ferme la',
  'nique', 'pute', 'encule', 'debile', 'abruti', 'fdp', 'ntm', 'casse toi', 'degage',
];

/// "je sais plus", "aucune idée" → aveu de trou de mémoire
const List<String> memoryHole = [
  'sais plus', 'souviens plus', 'souviens pas', 'aucune idee', 'je sais pas',
  'jsp', 'aucun souvenir', 'oublie',
];
