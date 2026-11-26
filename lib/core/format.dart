import 'l10n/strings.dart';

// `S.pick(ru, tj)` returns the string for the current language.

/// Russian plural form: 1 мастер, 2 мастера, 5 мастеров.
String pluralRu(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

/// `1 250` — thousands separated by a narrow space.
String formatNumber(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

extension Formats on S {
  String get currency => pick('сомони', 'сомонӣ');

  String masters(int n) => pick(
        '$n ${pluralRu(n, 'мастер', 'мастера', 'мастеров')}',
        '$n усто',
      );

  String reviewsCount(int n) => pick(
        '$n ${pluralRu(n, 'отзыв', 'отзыва', 'отзывов')}',
        '$n шарҳ',
      );

  String ordersDone(int n) => pick(
        '$n ${pluralRu(n, 'заказ', 'заказа', 'заказов')}',
        '$n фармоиш',
      );

  String responsesCount(int n) => pick(
        '$n ${pluralRu(n, 'отклик', 'отклика', 'откликов')}',
        '$n ҷавоб',
      );

  String priceFrom(int price) =>
      pick('от ${formatNumber(price)} $currency', 'аз ${formatNumber(price)} $currency');

  /// Task budget: "150–300 сомони", "до 300", "Договорная".
  String budget(String mode, int? min, int? max) {
    if (mode == 'negotiable' || (min == null && max == null)) {
      return pick('Договорная', 'Бо мувофиқа');
    }
    if (min != null && max != null && min != max) {
      return '${formatNumber(min)}–${formatNumber(max)} $currency';
    }
    final v = min ?? max!;
    return '${formatNumber(v)} $currency';
  }

  String when(String when, DateTime? date) => switch (when) {
        'today' => pick('Сегодня', 'Имрӯз'),
        'tomorrow' => pick('Завтра', 'Фардо'),
        'week' => pick('На этой неделе', 'Дар ҳамин ҳафта'),
        'date' when date != null => shortDate(date),
        _ => pick('Не срочно', 'Фаврӣ нест'),
      };

  String experience(String? code) => switch (code) {
        'lt1' => pick('меньше года', 'камтар аз як сол'),
        '1_3' => pick('1–3 года', '1–3 сол'),
        '3_10' => pick('3–10 лет', '3–10 сол'),
        'gt10' => pick('больше 10 лет', 'зиёда аз 10 сол'),
        _ => '',
      };

  String langName(String code) => switch (code) {
        'ru' => pick('Русский', 'Русӣ'),
        'tj' => pick('Таджикский', 'Тоҷикӣ'),
        'uz' => pick('Узбекский', 'Ӯзбекӣ'),
        'en' => pick('Английский', 'Англисӣ'),
        _ => code,
      };

  List<String> get _months => pick(
        'января,февраля,марта,апреля,мая,июня,июля,августа,сентября,октября,ноября,декабря',
        'январ,феврал,март,апрел,май,июн,июл,август,сентябр,октябр,ноябр,декабр',
      ).split(',');

  String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// "сегодня", "вчера", "3 дня назад", or a date.
  String ago(DateTime d) {
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (days <= 0) {
      final mins = now.difference(d).inMinutes;
      if (mins < 60) {
        final m = mins < 1 ? 1 : mins;
        return pick('$m мин назад', '$m дақиқа пеш');
      }
      final h = now.difference(d).inHours;
      return pick('$h ч назад', '$h соат пеш');
    }
    if (days == 1) return pick('вчера', 'дирӯз');
    if (days < 7) {
      return pick('$days ${pluralRu(days, 'день', 'дня', 'дней')} назад',
          '$days рӯз пеш');
    }
    return shortDate(d);
  }

  String memberSince(DateTime d) =>
      pick('На eKor с ${d.year} года', 'Дар eKor аз соли ${d.year}');
}
