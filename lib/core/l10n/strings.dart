import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App languages. The API uses `ru` / `tj` codes.
enum AppLang {
  ru,
  tj;

  String get code => name;

  static AppLang fromCode(String? code) =>
      code == 'tj' ? AppLang.tj : AppLang.ru;
}

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

class LangNotifier extends Notifier<AppLang> {
  static const _key = 'lang';

  @override
  AppLang build() =>
      AppLang.fromCode(ref.read(sharedPrefsProvider).getString(_key));

  void set(AppLang lang) {
    state = lang;
    ref.read(sharedPrefsProvider).setString(_key, lang.code);
  }
}

final langProvider = NotifierProvider<LangNotifier, AppLang>(LangNotifier.new);

/// Current strings for the selected language.
final stringsProvider = Provider<S>((ref) => S(ref.watch(langProvider)));

/// UI strings. Texts are taken from the ekor.tj website so the wording
/// matches across web and mobile.
class S {
  const S(this.lang);
  final AppLang lang;

  bool get _tj => lang == AppLang.tj;
  String _t(String ru, String tj) => _tj ? tj : ru;

  /// Picks the right field from API objects that carry `name_ru` / `name_tj`.
  String pick(String ru, String? tj) =>
      _tj && tj != null && tj.isNotEmpty ? tj : ru;

  // ── Common ────────────────────────────────────────────────
  String get back => _t('Назад', 'Бозгашт');
  String get close => _t('Закрыть', 'Пӯшидан');
  String get cancel => _t('Отмена', 'Бекор');
  String get retry => _t('Повторить', 'Такрор кардан');
  String get save => _t('Продолжить', 'Идома додан');
  String get soon => _t('Этот экран появится на следующих шагах',
      'Ин саҳифа дар қадамҳои навбатӣ пайдо мешавад');
  String get noInternet =>
      _t('Нет связи. Проверьте интернет', 'Алоқа нест. Интернетро санҷед');
  String get serverError => _t(
      'Сервер не ответил. Попробуйте через минуту — ваши данные в порядке.',
      'Сервер ҷавоб надод. Баъд аз як дақиқа кӯшиш кунед — маълумоти шумо дар амон аст.');

  // ── Navigation ────────────────────────────────────────────
  String get navHome => _t('Главная', 'Асосӣ');
  String get navMasters => _t('Мастера', 'Устоҳо');
  String get navTasks => _t('Задания', 'Супоришҳо');
  String get navProfile => _t('Профиль', 'Профил');

  // ── Home ──────────────────────────────────────────────────
  String get searchPh => _t('Услуга или профессия', 'Хизматрасонӣ ё касб');
  String get allCities => _t('Все города', 'Ҳамаи шаҳрҳо');
  String get onlineAll =>
      _t('По всему Таджикистану', 'Дар тамоми Тоҷикистон');
  String get categories => _t('Категории', 'Категорияҳо');
  String get allCats => _t('Все категории', 'Ҳамаи категорияҳо');
  String get findMaster => _t('Найти мастера', 'Усторо ёбед');
  String get postTask => _t('Разместить задание', 'Супориш гузоред');
  String get postTaskSub => _t('Опишите задачу — мастера сами предложат цену',
      'Корро тавсиф кунед — устоҳо нархи худро пешниҳод мекунанд');
  String get lastReviews => _t('Последние отзывы', 'Шарҳҳои охирин');
  String get reviewsNote =>
      _t('Только по выполненным заказам', 'Танҳо аз рӯи фармоишҳои иҷрошуда');

  // ── Login ─────────────────────────────────────────────────
  String get login => _t('Войти', 'Ворид шудан');
  String get phoneTitle => _t('Вход в eKor', 'Ворид шудан ба eKor');
  String get phoneSub => _t('Введите номер — пришлём SMS-код. Пароль не нужен.',
      'Рақамро ворид кунед — рамзи SMS мефиристем. Парол лозим нест.');
  String get phoneLabel => _t('Номер телефона', 'Рақами телефон');
  String get phoneHint =>
      _t('9 цифр, например 93 512 44 07', '9 рақам, масалан 93 512 44 07');
  String get errPhoneLen => _t('Введите номер полностью — 9 цифр',
      'Рақамро пурра ворид кунед — 9 рақам');
  String get errPhoneOperator => _t(
      'Проверьте код оператора: номер в Таджикистане начинается, например, с 90, 93, 98, 55',
      'Рамзи операторро санҷед: рақам дар Тоҷикистон, масалан, бо 90, 93, 98, 55 сар мешавад');
  String get phonePrivacy => _t(
      'Номер не виден другим людям. Мастер увидит его, только когда вы его выберете.',
      'Рақам ба дигарон намоён нест. Усто онро танҳо вақте мебинад, ки шумо ӯро интихоб кунед.');
  String get getCode => _t('Получить код', 'Гирифтани рамз');
  String get terms => _t(
      'Нажимая «Получить код», вы принимаете Правила eKor и Политику конфиденциальности.',
      'Бо пахш кардани «Гирифтани рамз» шумо Қоидаҳои eKor ва Сиёсати махфиятро қабул мекунед.');
  String get codeTitle => _t('Введите код из SMS', 'Рамзи SMS-ро ворид кунед');
  String codeSentTo(String phone) =>
      _t('Отправили на +992 $phone.', 'Ба +992 $phone фиристодем.');
  String get changeNumber => _t('Изменить номер', 'Иваз кардани рақам');
  String get checking => _t('Проверяем…', 'Месанҷем…');
  String resendIn(String time) => _t('Новый код можно запросить через $time',
      'Рамзи навро баъд аз $time дархост кардан мумкин');
  String get resend => _t('Отправить код ещё раз', 'Боз фиристодани рамз');
  String get nameTitle => _t('Как к вам обращаться?', 'Шуморо чӣ гуна номем?');
  String get nameSub => _t('Имя увидят мастера и клиенты. Спросим один раз.',
      'Номро устоҳо ва мизоҷон мебинанд. Як бор мепурсем.');
  String get nameLabel => _t('Имя', 'Ном');
  String get namePh => _t('Например, Мадина', 'Масалан, Мадина');
  String get nameErr =>
      _t('Введите имя — от 2 букв', 'Номро ворид кунед — аз 2 ҳарф');

  String get newTasks => _t('Новые задания', 'Супоришҳои нав');
  String get noPhoto => _t('Нет фото', 'Акс нест');
  String get regionTitle => _t('Где вы находитесь?', 'Шумо дар куҷо ҳастед?');
  String get regionSub => _t(
      'Покажем мастеров и задания в этом городе. Город можно сменить в любой момент.',
      'Устоҳо ва супоришҳоро дар ин шаҳр нишон медиҳем. Шаҳрро ҳар лаҳза иваз кардан мумкин.');
  String get reviewTag => _t('Заказ выполнен', 'Фармоиш иҷро шуд');
  String get noTasksYet => _t('Пока нет новых заданий', 'Ҳоло супориши нав нест');

  // ── Masters ───────────────────────────────────────────────
  String get mastersSearchPh => _t('Имя или услуга', 'Ном ё хизмат');
  String found(int n) => _t('Найдено: $n', 'Ёфт шуд: $n');
  String get sortLabel => _t('Сортировка', 'Тартиб');
  List<String> get sorts => _tj
      ? const ['Аз рӯи мувофиқат', 'Аз рӯи шарҳҳо', 'Аввал озодҳо']
      : const ['По релевантности', 'По отзывам', 'Свободные сначала'];
  String get availableToday => _t('Свободен сегодня', 'Имрӯз озод');
  String get busyNow => _t('Сейчас занят', 'Ҳоло банд аст');
  String get rating4 => _t('Рейтинг 4+', 'Рейтинг 4+');
  String get verified => _t('Проверен', 'Тасдиқшуда');
  String get category => _t('Категория', 'Категория');
  String get allLabel => _t('Все', 'Ҳама');
  String get resetFilters => _t('Сбросить фильтры', 'Филтрҳоро тоза кардан');
  String get emptyMastersTitle => _t('Никого не нашли', 'Касе ёфт нашуд');
  String get emptyMastersBody => _t(
      'Попробуйте убрать часть фильтров или посмотрите мастеров в соседних городах.',
      'Баъзе филтрҳоро бардоред ё устоҳоро дар шаҳрҳои ҳамсоя бинед.');
  String get noReviews => _t('Нет отзывов', 'Шарҳ нест');
  String get about => _t('О мастере', 'Дар бораи усто');
  String get servicesTitle => _t('Услуги и цены', 'Хизматҳо ва нархҳо');
  String get portfolio => _t('Работы', 'Корҳо');
  String get areas => _t('Где работает', 'Дар куҷо кор мекунад');
  String get langs => _t('Языки', 'Забонҳо');
  String get exp => _t('Опыт', 'Таҷриба');
  String get reviews => _t('Отзывы', 'Шарҳҳо');
  String get verifiedLong => _t(
      'Документы и личность подтверждены модератором eKor',
      'Ҳуҷҷатҳо ва шахсият аз ҷониби модератори eKor тасдиқ шудаанд');
  String get showPhone => _t('Показать телефон', 'Нишон додани телефон');
  String get call => _t('Позвонить', 'Занг задан');
  String get phoneNote => _t(
      'Звонок — ещё не заказ: отзыв можно оставить только после заказа, выполненного через eKor.',
      'Занг ҳанӯз фармоиш нест: шарҳро танҳо пас аз фармоише, ки тавассути eKor иҷро шудааст, гузоштан мумкин аст.');
  String get masterReply => _t('Ответ мастера', 'Ҷавоби усто');
  String get noReviewsTitle => _t('Пока нет отзывов', 'Ҳоло шарҳ нест');
  String get noReviewsBody => _t(
      'Отзыв появляется только после заказа, выполненного через eKor. Поэтому рейтингу можно доверять.',
      'Шарҳ танҳо пас аз фармоише, ки тавассути eKor иҷро шудааст, пайдо мешавад. Бинобар ин ба рейтинг бовар кардан мумкин аст.');
  String get negotiable => _t('Договорная', 'Бо мувофиқа');
  String get more => _t('Показать ещё', 'Боз нишон додан');

  // ── Tasks ─────────────────────────────────────────────────
  String get myTasks => _t('Мои задания', 'Супоришҳои ман');
  String get tabActive => _t('Активные', 'Фаъол');
  String get tabArchive => _t('Архив', 'Бойгонӣ');
  String get noActiveTasks => _t('Активных заданий нет', 'Супориши фаъол нест');
  String get noArchiveTasks => _t('Архив пуст', 'Бойгонӣ холӣ аст');
  String get noTasksBody => _t('Опишите задачу — мастера сами предложат цену',
      'Корро тавсиф кунед — устоҳо нархи худро пешниҳод мекунанд');
  String get task => _t('Задание', 'Супориш');
  String get details => _t('Подробности', 'Тафсилот');
  String get budgetLabel => _t('Бюджет', 'Буҷет');
  String get whenLabel => _t('Когда', 'Кай');
  String get placeLabel => _t('Где', 'Дар куҷо');
  String get clientLabel => _t('Заказчик', 'Мизоҷ');
  String views(int n) => _t('$n просмотров', '$n бознигарӣ');
  String taskStatus(String status) => switch (status) {
        'draft' => _t('Черновик', 'Сиёҳнавис'),
        'review' => _t('На проверке', 'Дар санҷиш'),
        'open' => _t('Открыто', 'Кушода'),
        'chosen' => _t('Мастер выбран', 'Усто интихоб шуд'),
        'closed' => _t('Завершено', 'Анҷом ёфт'),
        'rejected' => _t('Отклонено', 'Рад шуд'),
        'expired' => _t('Срок истёк', 'Мӯҳлат гузашт'),
        'cancelled' => _t('Отменено', 'Бекор шуд'),
        _ => status,
      };

  // ── Profile ───────────────────────────────────────────────
  String get youAre => _t('Вы вошли как', 'Шумо ворид шудед ҳамчун');
  String get noName => _t('Имя не указано', 'Ном нишон дода нашудааст');
  String get language => _t('Язык', 'Забон');
  String get support => _t('Поддержка', 'Дастгирӣ');
  String get supportHours => _t('ежедневно 8:00–20:00', 'ҳаррӯза 8:00–20:00');
  String get logout => _t('Выйти', 'Баромадан');
  String get logoutTitle => _t('Выйти из аккаунта?', 'Аз аккаунт мебароед?');
  String get logoutBody => _t(
      'Задания сохранятся. Войти снова — по номеру и SMS-коду.',
      'Супоришҳо нигоҳ дошта мешаванд. Боз ворид шудан — бо рақам ва рамзи SMS.');
}
