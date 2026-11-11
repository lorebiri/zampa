import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('it')];

  /// ALR-LIV-001 · testo · frase d'azione del livello SUBITO
  ///
  /// In it, this message translates to:
  /// **'Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.'**
  String get alrLiv001Text;

  /// ALR-LIV-002 · testo · frase d'azione del livello OGGI
  ///
  /// In it, this message translates to:
  /// **'Contatta il veterinario oggi stesso.'**
  String get alrLiv002Text;

  /// ALR-LIV-003 · testo · frase d'azione del livello ATTENZIONE
  ///
  /// In it, this message translates to:
  /// **'Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.'**
  String get alrLiv003Text;

  /// ALR-LIV-004 · testo · frase d'azione del livello INFO
  ///
  /// In it, this message translates to:
  /// **'Parlane alla prossima visita.'**
  String get alrLiv004Text;

  /// ALR-URI-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sforzo a urinare: possibile urgenza'**
  String get alrUri001Title;

  /// ALR-URI-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Se {name} si mette in posizione e non esce urina, o escono solo poche gocce, contatta subito il veterinario o un pronto soccorso veterinario, anche di notte. Nel maschio un blocco delle vie urinarie è un\'emergenza: non aspettare il giorno dopo. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.'**
  String alrUri001Text(String name);

  /// ALR-URI-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sforzo a urinare ripetuto'**
  String get alrUri002Title;

  /// ALR-URI-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Più tentativi con sforzo o poche gocce in 24 ore. Contatta il veterinario oggi stesso; subito se non esce urina. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.'**
  String get alrUri002Text;

  /// ALR-URI-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Pipì con sforzo o a gocce'**
  String get alrUri003Title;

  /// ALR-URI-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Osserva le prossime pipì. Se non riesce a urinare affatto, contatta subito il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.'**
  String get alrUri003Text;

  /// ALR-URI-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo senza pipì da {hours} ore da sveglio'**
  String alrUri004Title(String hours);

  /// ALR-URI-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Un cucciolo sveglio urina molto più spesso. Se non è una registrazione mancante, contatta subito il veterinario. Se escono solo gocce, conta come se non avesse urinato.'**
  String get alrUri004Text;

  /// ALR-URI-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Nessuna pipì da {hours} ore'**
  String alrUri005Title(String hours);

  /// ALR-URI-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Se {name} non ha davvero urinato (e non è solo una registrazione mancante), è un\'urgenza, specie nei maschi. Se escono solo gocce, conta come se non avesse urinato.'**
  String alrUri005Text(String name);

  /// ALR-URI-006 · titolo · spine = yes se intervento alla colonna negli ultimi 14 giorni
  ///
  /// In it, this message translates to:
  /// **'Nessuna pipì registrata da {hours} ore'**
  String alrUri006Title(String hours);

  /// ALR-URI-006 · testo · spine = yes se intervento alla colonna negli ultimi 14 giorni
  ///
  /// In it, this message translates to:
  /// **'{spine, select, yes{Dopo una chirurgia della colonna, se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica. Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta subito il veterinario. Se non urina entro 24 ore in totale è comunque un\'urgenza.} other{Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta subito il veterinario. Se non urina entro 24 ore in totale è comunque un\'urgenza.}}'**
  String alrUri006Text(String spine);

  /// ALR-URI-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sangue nelle urine con malessere'**
  String get alrUri007Title;

  /// ALR-URI-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Sangue nelle urine insieme a vomito o abbattimento richiede una visita oggi stesso.'**
  String get alrUri007Text;

  /// ALR-URI-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sangue durante il calore'**
  String get alrUri008Title;

  /// ALR-URI-008 · testo
  ///
  /// In it, this message translates to:
  /// **'In calore è normale una perdita di sangue dalla vulva. Se il sangue è nelle urine stesse, se si sforza o se il calore dura più di 3-4 settimane, senti il veterinario.'**
  String get alrUri008Text;

  /// ALR-URI-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sangue nelle urine'**
  String get alrUri009Title;

  /// ALR-URI-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Va sempre valutato dal veterinario entro 24-48 ore: può essere un segno di cistite o calcoli (solo il veterinario può dirlo). Se possibile raccogli un campione di urina.'**
  String get alrUri009Text;

  /// ALR-URI-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Pipì piccole e frequenti'**
  String get alrUri010Title;

  /// ALR-URI-010 · testo
  ///
  /// In it, this message translates to:
  /// **'{count} pipì in 2 ore. Può essere un segno di cistite (solo il veterinario può dirlo): sentilo entro 24-48 ore, subito se c\'è sforzo senza urina.'**
  String alrUri010Text(String count);

  /// ALR-GI-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Conati a vuoto o addome gonfio'**
  String get alrGi001Title;

  /// ALR-GI-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Conati senza riuscire a vomitare, addome gonfio, agitazione e salivazione possono indicare una torsione/dilatazione dello stomaco: è un\'emergenza in cui ogni minuto conta.'**
  String get alrGi001Text;

  /// ALR-NEU-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Collasso o svenimento'**
  String get alrNeu001Title;

  /// ALR-NEU-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Un collasso o uno svenimento va sempre valutato subito, anche se si è ripreso: può dipendere da cuore, emorragia o calo di zuccheri.'**
  String get alrNeu001Text;

  /// ALR-GI-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo con vomito o diarrea'**
  String get alrGi002Title;

  /// ALR-GI-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cuccioli vomito e diarrea insieme, o con abbattimento o inappetenza, richiedono una visita oggi stesso: la disidratazione è rapida e va esclusa la parvovirosi, soprattutto se non ha completato i vaccini. Subito se è molto abbattuto, ha sangue nelle feci o non trattiene l\'acqua.'**
  String get alrGi002Text;

  /// ALR-DIA-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Diabetico con vomito o abbattimento'**
  String get alrDia001Title;

  /// ALR-DIA-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Non fare l\'insulina senza aver sentito il veterinario. Vomito e abbattimento in un cane diabetico vanno valutati oggi stesso; subito se è molto debole, respira in modo strano o non beve.'**
  String get alrDia001Text;

  /// ALR-FAR-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Malessere durante la terapia per il Cushing'**
  String get alrFar001Title;

  /// ALR-FAR-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo: sospendi la prossima dose solo se te lo dice il veterinario e chiamalo subito.'**
  String get alrFar001Text;

  /// ALR-FAR-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Non mangia o è abbattuto durante antinfiammatori/cortisone'**
  String get alrFar002Title;

  /// ALR-FAR-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Può essere un effetto collaterale sullo stomaco: chiama il veterinario oggi. Non sospendere né aggiungere farmaci di tua iniziativa.'**
  String get alrFar002Text;

  /// ALR-FAR-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Antinfiammatori e cortisone insieme'**
  String get alrFar003Title;

  /// ALR-FAR-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: verifica col veterinario che sia voluto.'**
  String get alrFar003Text;

  /// ALR-GI-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vomito con sangue'**
  String get alrGi003Title;

  /// ALR-GI-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Sangue o materiale scuro \"a fondi di caffè\" nel vomito: visita oggi stesso; subito se è abbattuto o ha le gengive pallide.'**
  String get alrGi003Text;

  /// ALR-FAR-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vomito durante la terapia con antinfiammatori o cortisone'**
  String get alrFar004Title;

  /// ALR-FAR-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere né aggiungere farmaci di tua iniziativa.'**
  String get alrFar004Text;

  /// ALR-GI-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vomito ripetuto in un cane piccolo'**
  String get alrGi004Title;

  /// ALR-GI-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cuccioli e nei cani sotto i 5 kg disidratazione e ipoglicemia arrivano in fretta.'**
  String get alrGi004Text;

  /// ALR-GI-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vomito ripetuto'**
  String get alrGi005Title;

  /// ALR-GI-005 · testo
  ///
  /// In it, this message translates to:
  /// **'{count} episodi in 24 ore. Senti il veterinario entro 24 ore; subito se non trattiene nemmeno l\'acqua o è molto abbattuto.'**
  String alrGi005Text(String count);

  /// ALR-GI-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ha vomitato una volta'**
  String get alrGi006Title;

  /// ALR-GI-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Osserva: se si ripete, se è abbattuto o compaiono altri segni, senti il veterinario.'**
  String get alrGi006Text;

  /// ALR-GI-007a · titolo
  ///
  /// In it, this message translates to:
  /// **'Feci nere'**
  String get alrGi007aTitle;

  /// ALR-GI-007a · testo
  ///
  /// In it, this message translates to:
  /// **'Feci nere durante una terapia con antinfiammatori o cortisone: chiama subito il veterinario, potrebbe trattarsi di un sanguinamento dello stomaco.'**
  String get alrGi007aText;

  /// ALR-GI-007b · titolo
  ///
  /// In it, this message translates to:
  /// **'Feci nere'**
  String get alrGi007bTitle;

  /// ALR-GI-007b · testo
  ///
  /// In it, this message translates to:
  /// **'Feci nere come catrame possono indicare sangue digerito: serve una visita oggi.'**
  String get alrGi007bText;

  /// ALR-GI-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo con sangue nelle feci'**
  String get alrGi008Title;

  /// ALR-GI-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cuccioli la diarrea con sangue richiede una visita oggi stesso (va esclusa la parvovirosi, soprattutto se non ha completato i vaccini).'**
  String get alrGi008Text;

  /// ALR-GI-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sangue nelle feci con vomito o abbattimento'**
  String get alrGi009Title;

  /// ALR-GI-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Questa combinazione richiede una visita oggi stesso.'**
  String get alrGi009Text;

  /// ALR-GI-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sangue rosso nelle feci'**
  String get alrGi010Title;

  /// ALR-GI-010 · testo
  ///
  /// In it, this message translates to:
  /// **'Se si ripete, se c\'è diarrea abbondante o se cambia il suo comportamento, senti il veterinario entro 24-48 ore.'**
  String get alrGi010Text;

  /// ALR-GI-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo con diarrea'**
  String get alrGi011Title;

  /// ALR-GI-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cuccioli la disidratazione è rapida e va esclusa la parvovirosi: subito se vomita o è abbattuto.'**
  String get alrGi011Text;

  /// ALR-GI-012 · titolo
  ///
  /// In it, this message translates to:
  /// **'{vomit, select, yes{Diarrea e vomito nelle ultime 24 ore} other{Diarrea nelle ultime 24 ore}}'**
  String alrGi012Title(String vomit);

  /// ALR-GI-012 · testo
  ///
  /// In it, this message translates to:
  /// **'Assicurati che beva. Se persiste oltre 24-48 ore, se è abbattuto o vomita ripetutamente, senti il veterinario.'**
  String get alrGi012Text;

  /// ALR-GI-013 · titolo
  ///
  /// In it, this message translates to:
  /// **'Nessuna cacca da {hours} ore'**
  String alrGi013Title(String hours);

  /// ALR-GI-013 · testo
  ///
  /// In it, this message translates to:
  /// **'Se non è una registrazione mancante: controlla che beva e si muova. Se si sforza senza risultato, vomita o è abbattuto, senti il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.'**
  String get alrGi013Text;

  /// ALR-URI-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Fa pipì più spesso del solito'**
  String get alrUri011Title;

  /// ALR-URI-011 · testo
  ///
  /// In it, this message translates to:
  /// **'{diabetic, select, yes{Negli ultimi 3 giorni {recent} uscite al giorno contro {usual} abituali. Può essere un segno di infezione urinaria, diabete o problemi renali (solo il veterinario può dirlo): parlane entro qualche giorno. In un cane diabetico segnalalo al veterinario: la terapia potrebbe andare rivista.} other{Negli ultimi 3 giorni {recent} uscite al giorno contro {usual} abituali. Può essere un segno di infezione urinaria, diabete o problemi renali (solo il veterinario può dirlo): parlane entro qualche giorno.}}'**
  String alrUri011Text(String diabetic, String recent, String usual);

  /// ALR-URI-012 · titolo
  ///
  /// In it, this message translates to:
  /// **'Beve molto'**
  String get alrUri012Title;

  /// ALR-URI-012 · testo
  ///
  /// In it, this message translates to:
  /// **'In media {ml} ml al giorno, oltre i 100 ml/kg. La sete eccessiva può essere un segno di malattie da approfondire (solo il veterinario può dirlo). Non ridurre l\'acqua: parlane con il veterinario.'**
  String alrUri012Text(String ml);

  /// ALR-URI-013 · titolo
  ///
  /// In it, this message translates to:
  /// **'Beve poco'**
  String get alrUri013Title;

  /// ALR-URI-013 · testo
  ///
  /// In it, this message translates to:
  /// **'Con le crocchette {ml} ml al giorno sono pochi (meno di 20 ml/kg). Se non è una registrazione incompleta e mangia poco o è abbattuto, senti il veterinario.'**
  String alrUri013Text(String ml);

  /// ALR-REP-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Attenzione all\'utero (piometra)'**
  String get alrRep001Title;

  /// ALR-REP-001 · testo
  ///
  /// In it, this message translates to:
  /// **'In una femmina non sterilizzata, nelle settimane dopo il calore, sete e pipì aumentate, perdite dalla vulva, vomito o abbattimento possono indicare un\'infezione dell\'utero (piometra), che è un\'urgenza.'**
  String get alrRep001Text;

  /// ALR-REP-002 · titolo · urgent = yes con 2 o più segni
  ///
  /// In it, this message translates to:
  /// **'Femmina non sterilizzata: attenzione all\'utero'**
  String get alrRep002Title;

  /// ALR-REP-002 · testo · urgent = yes con 2 o più segni
  ///
  /// In it, this message translates to:
  /// **'{urgent, select, yes{Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un\'infezione dell\'utero (piometra), che è un\'urgenza: contatta il veterinario oggi stesso. Registra i calori nella sezione Riproduzione: Zampa potrà avvisarti meglio.} other{Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un\'infezione dell\'utero (piometra), che è un\'urgenza: osservala e senti il veterinario se compaiono altri segni. Registra i calori nella sezione Riproduzione: Zampa potrà avvisarti meglio.}}'**
  String alrRep002Text(String urgent);

  /// ALR-URI-014 · titolo
  ///
  /// In it, this message translates to:
  /// **'Pipì in casa ripetute'**
  String get alrUri014Title;

  /// ALR-URI-014 · testo
  ///
  /// In it, this message translates to:
  /// **'{count} incidenti in 7 giorni in un cane adulto. Le cause possibili sono infezione urinaria, aumento della sete, incontinenza (frequente nelle femmine sterilizzate di taglia media e grande), declino cognitivo nell\'anziano, oppure intervalli troppo lunghi tra le uscite. Vale la pena parlarne con il veterinario. Se le perdite avvengono mentre dorme o riposa, registrale come \"Perdita di urina a riposo\".'**
  String alrUri014Text(String count);

  /// ALR-PES-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Il cucciolo non cresce'**
  String get alrPes001Title;

  /// ALR-PES-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Un cucciolo dovrebbe aumentare di peso ogni settimana: se il peso è fermo da 2 settimane o cala, senti il veterinario; subito se mangia poco, vomita o ha diarrea.'**
  String get alrPes001Text;

  /// ALR-PES-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sta dimagrendo troppo in fretta'**
  String get alrPes002Title;

  /// ALR-PES-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Oltre il 2% a settimana: un dimagrimento troppo rapido non è sano. Senti il veterinario per rivedere la dieta.'**
  String get alrPes002Text;

  /// ALR-PES-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Calo di peso del {percent}%'**
  String alrPes003Title(String percent);

  /// ALR-PES-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Un calo di peso non voluto merita una visita, soprattutto nel cane anziano.'**
  String get alrPes003Text;

  /// ALR-PES-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Calo di peso del {percent}%'**
  String alrPes004Title(String percent);

  /// ALR-PES-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Tienilo d\'occhio: se continua senza che tu abbia cambiato la dieta, senti il veterinario.'**
  String get alrPes004Text;

  /// ALR-PES-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Aumento di peso del {percent}%'**
  String alrPes005Title(String percent);

  /// ALR-PES-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Controlla razione e snack nella sezione Nutrizione.'**
  String get alrPes005Text;

  /// ALR-PES-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sottopeso'**
  String get alrPes006Title;

  /// ALR-PES-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Prima di aumentare la razione fallo visitare, per escludere cause mediche.'**
  String get alrPes006Text;

  /// ALR-PES-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sovrappeso'**
  String get alrPes007Title;

  /// ALR-PES-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Body Condition Score {bcs}/9: la razione in Nutrizione è calcolata per un dimagrimento graduale. Prima di iniziare fai visitare il cane.'**
  String alrPes007Text(String bcs);

  /// ALR-PES-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Leggermente sovrappeso'**
  String get alrPes008Title;

  /// ALR-PES-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Riduci gli snack e ricontrolla tra un mese.'**
  String get alrPes008Text;

  /// ALR-TOX-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'{hasNote, select, yes{Ha ingerito qualcosa: {note}} other{Ha ingerito qualcosa}}'**
  String alrTox001Title(String hasNote, String note);

  /// ALR-TOX-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama subito il veterinario o un centro antiveleni, anche se sta bene. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell\'etichetta.'**
  String get alrTox001Text;

  /// ALR-TOX-002 · titolo · date = giorno/mese
  ///
  /// In it, this message translates to:
  /// **'Sorveglianza dopo un\'ingestione'**
  String get alrTox002Title;

  /// ALR-TOX-002 · testo · date = giorno/mese
  ///
  /// In it, this message translates to:
  /// **'{hasNote, select, yes{Il {date} ha ingerito: {note}. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.} other{Il {date} ha ingerito. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.}}'**
  String alrTox002Text(String hasNote, String date, String note);

  /// ALR-RES-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Gengive pallide o blu'**
  String get alrRes001Title;

  /// ALR-RES-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Possono indicare un problema di circolazione, respirazione o un\'emorragia: è un\'emergenza.'**
  String get alrRes001Text;

  /// ALR-RES-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Gengive rosso scuro'**
  String get alrRes002Title;

  /// ALR-RES-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Gengive rosso scuro, soprattutto dopo caldo o sforzo, possono indicare un colpo di calore o uno shock: raffreddalo con acqua (vedi Emergenze) e vai subito dal veterinario.'**
  String get alrRes002Text;

  /// ALR-RES-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Gengive gialle'**
  String get alrRes003Title;

  /// ALR-RES-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Il colore giallo (ittero) va valutato dal veterinario oggi stesso.'**
  String get alrRes003Text;

  /// ALR-RES-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Respira molto veloce nel sonno ({rate}/min)'**
  String alrRes004Title(String rate);

  /// ALR-RES-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Oltre 40 respiri al minuto a riposo: possibile difficoltà respiratoria o cardiaca.'**
  String get alrRes004Text;

  /// ALR-RES-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Respiri nel sonno oltre 40/min'**
  String get alrRes005Title;

  /// ALR-RES-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Rimisura tra 15-30 minuti mentre dorme tranquillo. Se resta sopra 40, o respira con fatica a bocca aperta, vai subito dal veterinario.'**
  String get alrRes005Text;

  /// ALR-RES-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Respiri nel sonno sopra 30/min'**
  String get alrRes006Title;

  /// ALR-RES-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Due misure di fila sopra 30 respiri al minuto: segnalalo al veterinario oggi, soprattutto se ha una malattia di cuore.'**
  String get alrRes006Text;

  /// ALR-RES-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Respiri nel sonno in aumento'**
  String get alrRes007Title;

  /// ALR-RES-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Media della settimana {week}/min contro {month}/min del mese precedente: segnalalo al veterinario oggi.'**
  String alrRes007Text(String week, String month);

  /// ALR-RES-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Fatica a respirare'**
  String get alrRes008Title;

  /// ALR-RES-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Respiro affannoso a riposo, bocca aperta o lingua scura: tienilo calmo e al fresco e vai subito dal veterinario.'**
  String get alrRes008Text;

  /// ALR-RES-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Tosse in un cane con malattia di cuore'**
  String get alrRes009Title;

  /// ALR-RES-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cardiopatici la tosse va segnalata al veterinario oggi.'**
  String get alrRes009Text;

  /// ALR-RES-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Tosse in un Cavalier King'**
  String get alrRes010Title;

  /// ALR-RES-010 · testo
  ///
  /// In it, this message translates to:
  /// **'Il Cavalier è predisposto alla malattia della valvola mitrale: segnala la tosse al veterinario e conta i respiri nel sonno.'**
  String get alrRes010Text;

  /// ALR-RES-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Tosse da più giorni'**
  String get alrRes011Title;

  /// ALR-RES-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Tosse che dura da più di 3 giorni o con abbattimento: senti il veterinario entro 24-48 ore. Evita il contatto con altri cani.'**
  String get alrRes011Text;

  /// ALR-DIA-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Glicemia bassa ({value} mg/dL)'**
  String alrDia002Title(String value);

  /// ALR-DIA-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. Non fare la prossima insulina senza averlo sentito.'**
  String get alrDia002Text;

  /// ALR-DIA-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Glicemia al limite basso ({value} mg/dL)'**
  String alrDia003Title(String value);

  /// ALR-DIA-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Segnalala al veterinario oggi, prima della prossima insulina.'**
  String get alrDia003Text;

  /// ALR-DIA-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Glicemia alta ({value} mg/dL)'**
  String alrDia004Title(String value);

  /// ALR-DIA-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Segnalala al veterinario: la terapia potrebbe andare rivista. Se vomita, è abbattuto o non mangia, oggi stesso.'**
  String get alrDia004Text;

  /// ALR-DIA-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Due dosi di insulina ravvicinate'**
  String get alrDia005Title;

  /// ALR-DIA-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Due dosi di insulina registrate a {hours} ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. Se è un errore di registrazione, cancellane una.'**
  String alrDia005Text(String hours);

  /// ALR-REP-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Tremori in una cagna che allatta'**
  String get alrRep003Title;

  /// ALR-REP-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile eclampsia (calcio basso dopo il parto): è un\'emergenza. Allontana i cuccioli e vai subito dal veterinario.'**
  String get alrRep003Text;

  /// ALR-NEU-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo debole o tremante'**
  String get alrNeu002Title;

  /// ALR-NEU-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Nei cuccioli piccoli può essere un\'ipoglicemia. Se è cosciente strofina un po\' di miele sulle gengive, poi vai subito dal veterinario.'**
  String get alrNeu002Text;

  /// ALR-NEU-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Convulsione in un cane diabetico'**
  String get alrNeu003Title;

  /// ALR-NEU-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Può essere un\'ipoglicemia. Se è cosciente strofina un po\' di miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e vai subito dal veterinario.'**
  String get alrNeu003Text;

  /// ALR-NEU-004a · titolo
  ///
  /// In it, this message translates to:
  /// **'Convulsione lunga o senza ripresa'**
  String get alrNeu004aTitle;

  /// ALR-NEU-004a · testo
  ///
  /// In it, this message translates to:
  /// **'Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un\'emergenza.'**
  String get alrNeu004aText;

  /// ALR-NEU-004b · titolo
  ///
  /// In it, this message translates to:
  /// **'{count} convulsioni in 24 ore'**
  String alrNeu004bTitle(String count);

  /// ALR-NEU-004b · testo
  ///
  /// In it, this message translates to:
  /// **'Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un\'emergenza.'**
  String get alrNeu004bText;

  /// ALR-NEU-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Prima convulsione'**
  String get alrNeu005Title;

  /// ALR-NEU-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Una prima crisi va sempre valutata dal veterinario. Annota durata e cosa è successo prima e dopo.'**
  String get alrNeu005Text;

  /// ALR-NEU-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Crisi più frequenti questo mese'**
  String get alrNeu006Title;

  /// ALR-NEU-006 · testo
  ///
  /// In it, this message translates to:
  /// **'{count} crisi questo mese contro una media di {average}: parlane con il veterinario, la terapia potrebbe andare rivista.'**
  String alrNeu006Text(String count, String average);

  /// ALR-DIA-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Possibile ipoglicemia'**
  String get alrDia006Title;

  /// ALR-DIA-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Tremori o barcollamento in un cane diabetico: se è cosciente strofina miele o glucosio sulle gengive e vai subito dal veterinario.'**
  String get alrDia006Text;

  /// ALR-NEU-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Tremori, barcollamento o testa inclinata'**
  String get alrNeu007Title;

  /// ALR-NEU-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Segni neurologici: se sono comparsi all\'improvviso è un\'urgenza. Pensa anche a possibili sostanze ingerite.'**
  String get alrNeu007Text;

  /// ALR-TMP-001a · titolo
  ///
  /// In it, this message translates to:
  /// **'Temperatura {temp} °C'**
  String alrTmp001aTitle(String temp);

  /// ALR-TMP-001a · testo
  ///
  /// In it, this message translates to:
  /// **'Temperatura molto alta: possibile colpo di calore. Raffreddalo subito con acqua fresca o fredda e fai aria, poi vai subito dal veterinario.'**
  String get alrTmp001aText;

  /// ALR-TMP-001b · titolo
  ///
  /// In it, this message translates to:
  /// **'Temperatura {temp} °C'**
  String alrTmp001bTitle(String temp);

  /// ALR-TMP-001b · testo
  ///
  /// In it, this message translates to:
  /// **'Temperatura troppo bassa: tienilo al caldo e vai subito dal veterinario.'**
  String get alrTmp001bText;

  /// ALR-TMP-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Febbre ({temp} °C)'**
  String alrTmp002Title(String temp);

  /// ALR-TMP-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Normale 38,0-39,2 °C. Non dare antipiretici per persone (sono tossici).'**
  String get alrTmp002Text;

  /// ALR-CIB-001a · titolo
  ///
  /// In it, this message translates to:
  /// **'Non mangia'**
  String get alrCib001aTitle;

  /// ALR-CIB-001a · testo
  ///
  /// In it, this message translates to:
  /// **'Se non ha mangiato o ha vomitato, non fare l\'insulina senza aver sentito il veterinario.'**
  String get alrCib001aText;

  /// ALR-CIB-001b · titolo
  ///
  /// In it, this message translates to:
  /// **'Non mangia'**
  String get alrCib001bTitle;

  /// ALR-CIB-001b · testo
  ///
  /// In it, this message translates to:
  /// **'Pasti saltati: serve una visita oggi.'**
  String get alrCib001bText;

  /// ALR-CIB-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ha saltato i pasti'**
  String get alrCib002Title;

  /// ALR-CIB-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Se non mangia da 24 ore senti il veterinario entro 1-2 giorni; prima se vomita o è abbattuto.'**
  String get alrCib002Text;

  /// ALR-CIB-003a · titolo · reason: signs = con altri segni, puppy, diabetic, other = anziano
  ///
  /// In it, this message translates to:
  /// **'Abbattuto'**
  String get alrCib003aTitle;

  /// ALR-CIB-003a · testo · reason: signs = con altri segni, puppy, diabetic, other = anziano
  ///
  /// In it, this message translates to:
  /// **'{reason, select, signs{Abbattimento insieme ad altri segni: contatta il veterinario oggi.} puppy{Abbattimento in un cane cucciolo: contatta il veterinario oggi.} diabetic{Abbattimento in un cane diabetico: contatta il veterinario oggi.} other{Abbattimento in un cane anziano: contatta il veterinario oggi.}}'**
  String alrCib003aText(String reason);

  /// ALR-CIB-003b · titolo
  ///
  /// In it, this message translates to:
  /// **'Abbattuto'**
  String get alrCib003bTitle;

  /// ALR-CIB-003b · testo
  ///
  /// In it, this message translates to:
  /// **'Osservalo: se non torna vivace entro la giornata, o compaiono vomito, diarrea, febbre o gengive pallide, senti il veterinario.'**
  String get alrCib003bText;

  /// ALR-DIA-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Insulina fatta senza che abbia mangiato'**
  String get alrDia007Title;

  /// ALR-DIA-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama ora il veterinario e chiedi come comportarti. Nelle prossime ore offrigli il suo pasto e osservalo: se compaiono debolezza, tremori o barcollamento strofina miele sulle gengive e vai subito dal veterinario.'**
  String get alrDia007Text;

  /// ALR-URI-015 · titolo · variant: tick = stagione delle zecche (marzo-novembre), urgent = abbattimento o febbre
  ///
  /// In it, this message translates to:
  /// **'Urina scura o color caffè'**
  String get alrUri015Title;

  /// ALR-URI-015 · testo · variant: tick = stagione delle zecche (marzo-novembre), urgent = abbattimento o febbre
  ///
  /// In it, this message translates to:
  /// **'{variant, select, tickUrgent{Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Hai trovato zecche di recente? Dillo al veterinario. Con abbattimento o febbre serve una visita oggi.} tick{Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Hai trovato zecche di recente? Dillo al veterinario. Se si ripete, senti il veterinario.} urgent{Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Con abbattimento o febbre serve una visita oggi.} other{Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Se si ripete, senti il veterinario.}}'**
  String alrUri015Text(String variant);

  /// ALR-FAR-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Loperamide in una razza a rischio MDR1'**
  String get alrFar005Title;

  /// ALR-FAR-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Nelle razze con possibile mutazione MDR1 la loperamide può dare effetti neurologici: verifica con il veterinario.'**
  String get alrFar005Text;

  /// ALR-REP-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Malessere nella prima settimana dopo il parto'**
  String get alrRep004Title;

  /// ALR-REP-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Febbre, perdite maleodoranti o abbattimento dopo il parto possono indicare un\'infezione dell\'utero: contatta il veterinario oggi.'**
  String get alrRep004Text;

  /// ALR-REP-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Mammelle gonfie, calde o dolenti'**
  String get alrRep005Title;

  /// ALR-REP-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Può essere una mastite: contatta il veterinario oggi. Non spremere le mammelle.'**
  String get alrRep005Text;

  /// ALR-REP-006a · titolo
  ///
  /// In it, this message translates to:
  /// **'Temperatura calata da oltre 24 ore senza parto'**
  String get alrRep006aTitle;

  /// ALR-REP-006a · testo
  ///
  /// In it, this message translates to:
  /// **'Il calo di temperatura sotto 37,5 °C precede il parto: se dopo 24 ore non è iniziato il travaglio, chiama il veterinario.'**
  String get alrRep006aText;

  /// ALR-REP-006b · titolo
  ///
  /// In it, this message translates to:
  /// **'Parto atteso entro circa 24 ore'**
  String get alrRep006bTitle;

  /// ALR-REP-006b · testo
  ///
  /// In it, this message translates to:
  /// **'La temperatura sotto 37,5 °C di solito precede il parto di circa 24 ore. Prepara la cassa parto.'**
  String get alrRep006bText;

  /// ALR-ALT-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Non appoggia la zampa'**
  String get alrAlt001Title;

  /// ALR-ALT-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Non caricare l\'arto è un segno di dolore importante: visita oggi. Non dare antidolorifici per persone.'**
  String get alrAlt001Text;

  /// ALR-ALT-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Zoppia da più giorni'**
  String get alrAlt002Title;

  /// ALR-ALT-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Una zoppia che dura da 3-5 giorni va vista dal veterinario.'**
  String get alrAlt002Text;

  /// ALR-ALT-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Prurito, pelle o orecchie'**
  String get alrAlt003Title;

  /// ALR-ALT-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Senti il veterinario entro qualche giorno; prima se si gratta fino a ferirsi o scuote molto la testa.'**
  String get alrAlt003Text;

  /// ALR-ALT-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Problema ai denti'**
  String get alrAlt004Title;

  /// ALR-ALT-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Alito cattivo, gengive che sanguinano o fatica a masticare: controllo dentale al prossimo appuntamento, prima se mangia poco.'**
  String get alrAlt004Text;

  /// ALR-ALT-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Denti: {count} spazzolature in 7 giorni'**
  String alrAlt005Title(String count);

  /// ALR-ALT-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Ideale ogni giorno, almeno 3 volte a settimana (AAHA 2019).'**
  String get alrAlt005Text;

  /// ALR-URI-016 · titolo
  ///
  /// In it, this message translates to:
  /// **'Perdite di urina a riposo'**
  String get alrUri016Title;

  /// ALR-URI-016 · testo
  ///
  /// In it, this message translates to:
  /// **'Perdite mentre dorme o riposa: spesso è un problema curabile (incontinenza). Parlane con il veterinario. Non ridurre l\'acqua.'**
  String get alrUri016Text;

  /// ALR-REP-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Perdite purulente'**
  String get alrRep007Title;

  /// ALR-REP-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Perdite purulente in una femmina non sterilizzata possono indicare un\'infezione dell\'utero: contatta il veterinario oggi stesso.'**
  String get alrRep007Text;

  /// ALR-REP-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Perdite vulvari'**
  String get alrRep008Title;

  /// ALR-REP-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Perdite fuori dal calore vanno valutate dal veterinario entro 1-2 giorni; oggi stesso se è abbattuta, beve molto o le perdite sono purulente.'**
  String get alrRep008Text;

  /// ALR-URI-017 · titolo
  ///
  /// In it, this message translates to:
  /// **'Pipì di notte, prima non succedeva'**
  String get alrUri017Title;

  /// ALR-URI-017 · testo
  ///
  /// In it, this message translates to:
  /// **'Due o più notti su 7 con pipì notturna: può essere un segno di sete aumentata o di un problema urinario. Prenota una visita.'**
  String get alrUri017Text;

  /// ALR-REP-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Gravidanza oltre i 70 giorni'**
  String get alrRep009Title;

  /// ALR-REP-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Il parto non è ancora avvenuto: contatta il veterinario oggi.'**
  String get alrRep009Text;

  /// ALR-REP-010 · titolo · date = giorno/mese
  ///
  /// In it, this message translates to:
  /// **'Parto vicino (presunto il {date})'**
  String alrRep010Title(String date);

  /// ALR-REP-010 · testo · date = giorno/mese
  ///
  /// In it, this message translates to:
  /// **'Prepara la cassa parto. Chiama subito il veterinario se: contrazioni forti per oltre 30 minuti senza cuccioli, oltre 2 ore tra un cucciolo e l\'altro, perdite verdi o nere senza cuccioli.'**
  String get alrRep010Text;

  /// ALR-REP-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Calore che dura da oltre 4 settimane'**
  String get alrRep011Title;

  /// ALR-REP-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Un calore persistente va valutato dal veterinario. Se è già finito, registra \"Fine calore\".'**
  String get alrRep011Text;

  /// ALR-FAR-006 · titolo · time = HH:MM
  ///
  /// In it, this message translates to:
  /// **'Dose non confermata: {drug}'**
  String alrFar006Title(String drug);

  /// ALR-FAR-006 · testo · time = HH:MM
  ///
  /// In it, this message translates to:
  /// **'Prevista alle {time}. Se l\'hai saltata, non raddoppiare la successiva: chiedi al veterinario cosa fare.'**
  String alrFar006Text(String time);

  /// ALR-GI-014 · titolo
  ///
  /// In it, this message translates to:
  /// **'Feci molto dure'**
  String get alrGi014Title;

  /// ALR-GI-014 · testo
  ///
  /// In it, this message translates to:
  /// **'Punteggio 1 della scala fecale: controlla che beva abbastanza. Se si sforza senza risultato, senti il veterinario.'**
  String get alrGi014Text;

  /// ALR-CHI-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ferita aperta o che sanguina'**
  String get alrChi001Title;

  /// ALR-CHI-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Punti aperti o sanguinamento della ferita: copri con una garza pulita, impedisci che si lecchi e contatta il veterinario oggi. Subito se il sanguinamento è abbondante o si vede tessuto interno.'**
  String get alrChi001Text;

  /// ALR-CHI-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ferita arrossata, gonfia o con secrezione'**
  String get alrChi002Title;

  /// ALR-CHI-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Può essere un\'infiammazione o un\'infezione della ferita: mantieni il collare elisabettiano e senti il veterinario entro 1-2 giorni; prima se peggiora o compare febbre.'**
  String get alrChi002Text;

  /// ALR-CHI-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Non ha ancora mangiato dopo l\'intervento'**
  String get alrChi003Title;

  /// ALR-CHI-003 · testo
  ///
  /// In it, this message translates to:
  /// **'L\'appetito di solito torna entro 24-48 ore dall\'intervento: contatta il veterinario oggi.'**
  String get alrChi003Text;

  /// ALR-ALT-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Possibile forasacco'**
  String get alrAlt006Title;

  /// ALR-ALT-006 · testo
  ///
  /// In it, this message translates to:
  /// **'In stagione dei forasacchi, scuotere la testa o starnutire all\'improvviso dopo un prato richiede una visita oggi: prima si toglie, meno danni fa.'**
  String get alrAlt006Text;

  /// ALR-PRV-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ciclo vaccinale non completo'**
  String get alrPrv001Title;

  /// ALR-PRV-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Finché non è completo, evita aree frequentate da cani sconosciuti e chiama il veterinario per fissare la dose.'**
  String get alrPrv001Text;

  /// ALR-PRV-002 · titolo · items = prime 3 voci scadute, separate da « · »
  ///
  /// In it, this message translates to:
  /// **'{count, plural, =1{Una scadenza superata} other{{count} scadenze superate}}'**
  String alrPrv002Title(int count);

  /// ALR-PRV-002 · testo · items = prime 3 voci scadute, separate da « · »
  ///
  /// In it, this message translates to:
  /// **'{items}'**
  String alrPrv002Text(String items);

  /// PRV-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Microchip e iscrizione all\'anagrafe canina'**
  String get prv001Title;

  /// PRV-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Obbligatoria per legge (L. 281/1991, O.M. 6/8/2008, anagrafe SINAC): entro 60 giorni dalla nascita e comunque prima della cessione. Se hai adottato il cane, verifica che sia intestato a te.'**
  String get prv001Text;

  /// PRV-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Verifica che l\'anagrafe sia intestata a te'**
  String get prv002Title;

  /// PRV-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Controlla sul portale dell\'anagrafe canina della tua Regione (o SINAC) che il microchip {microchip} sia intestato a te e che indirizzo e telefono siano aggiornati.'**
  String prv002Text(String microchip);

  /// PRV-003 · titolo · il titolo diventa il nome della voce in cartella: la logica riconosce «core» e «ª dose»
  ///
  /// In it, this message translates to:
  /// **'{dose, select, first{Vaccino core (cimurro, epatite, parvovirosi) – 1ª dose} second{Vaccino core (cimurro, epatite, parvovirosi) – 2ª dose} other{Vaccino core (cimurro, epatite, parvovirosi) – 3ª dose}}'**
  String prv003Title(String dose);

  /// PRV-003 · testo · il titolo diventa il nome della voce in cartella: la logica riconosce «core» e «ª dose»
  ///
  /// In it, this message translates to:
  /// **'{dose, select, first{WSAVA: prima dose a 6-8 settimane.} second{Ogni 2-4 settimane fino a 16 settimane o più.} other{L\'ultima dose non prima delle 16 settimane.}}'**
  String prv003Text(String dose);

  /// PRV-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vaccino core (cimurro, epatite, parvovirosi) – verifica il libretto'**
  String get prv004Title;

  /// PRV-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Nessun vaccino core registrato. Se non trovi il libretto, il veterinario può fare una dose (WSAVA considera protettiva una dose dei vaccini core vivi attenuati nell\'adulto) oppure dosare gli anticorpi.'**
  String get prv004Text;

  /// PRV-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Vaccino core (cimurro, epatite, parvovirosi) – richiamo'**
  String get prv005Title;

  /// PRV-005 · testo
  ///
  /// In it, this message translates to:
  /// **'WSAVA 2024: richiamo a 26 settimane (oppure a 12 mesi secondo il veterinario), poi ogni 3 anni se il vaccino usato lo prevede.'**
  String get prv005Text;

  /// PRV-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'{dose, select, first{Leptospirosi – 1ª dose} other{Leptospirosi – 2ª dose}}'**
  String prv006Title(String dose);

  /// PRV-006 · testo
  ///
  /// In it, this message translates to:
  /// **'{dose, select, first{Consigliata in Italia: 2 dosi a 2-4 settimane di distanza, poi richiamo annuale.} other{Completa l\'avvio vaccinale.}}'**
  String prv006Text(String dose);

  /// PRV-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Leptospirosi'**
  String get prv007Title;

  /// PRV-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Se non è mai stato vaccinato servono 2 dosi a 2-4 settimane; poi richiamo annuale. Verifica il libretto.'**
  String get prv007Text;

  /// PRV-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sverminazione cucciolo'**
  String get prv008Title;

  /// PRV-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Ogni 2 settimane fino a 2 settimane dopo lo svezzamento, poi ogni mese fino a 6 mesi.'**
  String get prv008Text;

  /// PRV-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Esame delle feci'**
  String get prv009Title;

  /// PRV-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Da 1 a 4 volte l\'anno secondo lo stile di vita (o sverminazione periodica secondo il veterinario).'**
  String get prv009Text;

  /// PRV-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Prevenzione filariosi (stagione {year})'**
  String prv010Title(String year);

  /// PRV-010 · testo
  ///
  /// In it, this message translates to:
  /// **'ESCCAP Italia: profilassi mensile fino a dicembre (un mese dopo la fine della stagione delle zanzare). Se non era protetto, chiedi al veterinario se serve prima un test.'**
  String get prv010Text;

  /// PRV-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Filariosi: chiedi al veterinario se fare una dose ora e il test'**
  String get prv011Title;

  /// PRV-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Se non era protetto quest\'estate, il veterinario valuterà un test (antigene + microfilarie) prima di iniziare; il test affidabile si fa in primavera.'**
  String get prv011Text;

  /// PRV-012 · titolo
  ///
  /// In it, this message translates to:
  /// **'Test filariosi e leishmaniosi annuale ({year})'**
  String prv012Title(String year);

  /// PRV-012 · testo
  ///
  /// In it, this message translates to:
  /// **'Prima di iniziare la profilassi: antigene della filaria e, nelle zone a rischio, test per la leishmania.'**
  String get prv012Text;

  /// PRV-013 · titolo
  ///
  /// In it, this message translates to:
  /// **'Inizio profilassi filariosi {year}'**
  String prv013Title(String year);

  /// PRV-013 · testo
  ///
  /// In it, this message translates to:
  /// **'{south, select, yes{Mensile fino a dicembre (al Sud valuta con il veterinario la copertura tutto l\'anno). Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono anche iniezioni a lento rilascio da 6 o 12 mesi.} other{Mensile fino a dicembre. Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono anche iniezioni a lento rilascio da 6 o 12 mesi.}}'**
  String prv013Text(String south);

  /// PRV-014 · titolo
  ///
  /// In it, this message translates to:
  /// **'Repellente anti-pappataci (leishmaniosi) {year}'**
  String prv014Title(String year);

  /// PRV-014 · testo
  ///
  /// In it, this message translates to:
  /// **'Da aprile a novembre per tutti i cani, anche al Nord: la leishmaniosi è ormai presente in molte aree. Il collare dura secondo il prodotto, lo spot-on 3-4 settimane. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c\'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto.'**
  String get prv014Text;

  /// PRV-015 · titolo
  ///
  /// In it, this message translates to:
  /// **'Antiparassitario esterno (zecche e pulci)'**
  String get prv015Title;

  /// PRV-015 · testo
  ///
  /// In it, this message translates to:
  /// **'Frequenza secondo il prodotto (1-3 mesi). Al Centro-Sud anche tutto l\'anno. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c\'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto.'**
  String get prv015Text;

  /// PRV-016 · titolo
  ///
  /// In it, this message translates to:
  /// **'{senior, select, yes{Controllo geriatrico semestrale} other{Visita di controllo annuale}}'**
  String prv016Title(String senior);

  /// PRV-016 · testo
  ///
  /// In it, this message translates to:
  /// **'{senior, select, yes{Per i cani anziani: visita ed esami del sangue e delle urine ogni 6 mesi.} other{Visita generale, peso, denti, richiami.}}'**
  String prv016Text(String senior);

  /// NUT-001 · testo
  ///
  /// In it, this message translates to:
  /// **'In allattamento il fabbisogno arriva a 4-8 volte quello di riposo: lascia il cibo a disposizione (alimento per cuccioli) e acqua fresca sempre. Se trema, ansima, è agitata o barcolla, chiama subito il veterinario.'**
  String get nut001Text;

  /// NUT-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Per la sua età sono consigliati {meals} pasti al giorno: nei cuccioli piccoli pochi pasti possono causare ipoglicemia.'**
  String nut002Text(String meals);

  /// NUT-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo di taglia grande: usa un alimento specifico \"puppy large breed\" e non aggiungere integratori di calcio. Mantienilo snello (BCS 4-5): crescere più in fretta non lo fa diventare più grande, aumenta il rischio di problemi alle articolazioni.'**
  String get nut003Text;

  /// NUT-004 · testo
  ///
  /// In it, this message translates to:
  /// **'{conditions, select, yes{Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane. Con le patologie registrate la dieta va decisa con il veterinario.} other{Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane.}}'**
  String nut004Text(String conditions);

  /// NUT-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Sottopeso: prima fallo visitare per escludere cause mediche, poi aumenta la razione gradualmente in 1-2 settimane.'**
  String get nut005Text;

  /// NUT-FAT-001 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'gravidanza avanzata'**
  String get nutFat001Text;

  /// NUT-FAT-002 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'gravidanza (prime 6 settimane)'**
  String get nutFat002Text;

  /// NUT-FAT-003 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'allattamento (4-8 × RER)'**
  String get nutFat003Text;

  /// NUT-FAT-004 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cucciolo sotto i 4 mesi'**
  String get nutFat004Text;

  /// NUT-FAT-005 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cucciolo in crescita'**
  String get nutFat005Text;

  /// NUT-FAT-006 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'programma di dimagrimento (calcolato sul peso ideale)'**
  String get nutFat006Text;

  /// NUT-FAT-007 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'sottopeso: calcolato sul peso ideale'**
  String get nutFat007Text;

  /// NUT-FAT-008 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cane da lavoro/sport intenso'**
  String get nutFat008Text;

  /// NUT-FAT-009 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cane molto attivo'**
  String get nutFat009Text;

  /// NUT-FAT-010 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cane sedentario o incline al sovrappeso'**
  String get nutFat010Text;

  /// NUT-FAT-011 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'cane anziano'**
  String get nutFat011Text;

  /// NUT-FAT-012 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'adulto sterilizzato'**
  String get nutFat012Text;

  /// NUT-FAT-013 · testo · motivo del fattore MER (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'adulto non sterilizzato'**
  String get nutFat013Text;

  /// SCA-BCS-1 · testo
  ///
  /// In it, this message translates to:
  /// **'Emaciato: costole, vertebre e bacino visibili a distanza.'**
  String get scaBcs1Text;

  /// SCA-BCS-2 · testo
  ///
  /// In it, this message translates to:
  /// **'Molto magro: costole facilmente visibili, nessun grasso palpabile.'**
  String get scaBcs2Text;

  /// SCA-BCS-3 · testo
  ///
  /// In it, this message translates to:
  /// **'Magro: costole facilmente palpabili, vita evidente.'**
  String get scaBcs3Text;

  /// SCA-BCS-4 · testo
  ///
  /// In it, this message translates to:
  /// **'Sottile: costole palpabili con poco grasso, vita ben visibile.'**
  String get scaBcs4Text;

  /// SCA-BCS-5 · testo
  ///
  /// In it, this message translates to:
  /// **'Ideale: costole palpabili senza eccesso di grasso, vita visibile da sopra.'**
  String get scaBcs5Text;

  /// SCA-BCS-6 · testo
  ///
  /// In it, this message translates to:
  /// **'Leggermente sovrappeso: costole palpabili con lieve grasso in più.'**
  String get scaBcs6Text;

  /// SCA-BCS-7 · testo
  ///
  /// In it, this message translates to:
  /// **'Sovrappeso: costole palpabili a fatica, vita poco visibile.'**
  String get scaBcs7Text;

  /// SCA-BCS-8 · testo
  ///
  /// In it, this message translates to:
  /// **'Obeso: costole non palpabili, nessuna vita, addome disteso.'**
  String get scaBcs8Text;

  /// SCA-BCS-9 · testo
  ///
  /// In it, this message translates to:
  /// **'Obesità grave: depositi di grasso su collo, arti e base della coda.'**
  String get scaBcs9Text;

  /// TOS-001 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Xilitolo (gomme e dolci \"senza zucchero\", dentifricio per persone, burro di arachidi light, integratori)'**
  String get tos001Title;

  /// TOS-001 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'ipoglicemia e danno al fegato anche a piccole dosi'**
  String get tos001Text;

  /// TOS-002 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Uva e uvetta'**
  String get tos002Title;

  /// TOS-002 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'insufficienza renale acuta, dose imprevedibile'**
  String get tos002Text;

  /// TOS-003 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Cioccolato e cacao (più è fondente, più è pericoloso)'**
  String get tos003Title;

  /// TOS-003 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'teobromina: vomito, agitazione, aritmie, convulsioni'**
  String get tos003Text;

  /// TOS-004 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Cipolla, aglio, porro, erba cipollina (anche cotti o in polvere)'**
  String get tos004Title;

  /// TOS-004 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'anemia: alterazioni del sangue da circa 5 g/kg, effetto cumulativo'**
  String get tos004Text;

  /// TOS-005 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Farmaci per persone: paracetamolo, ibuprofene, naprossene, ketoprofene, aspirina'**
  String get tos005Title;

  /// TOS-005 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'ulcere, danno a reni e fegato, anemia'**
  String get tos005Text;

  /// TOS-006 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Altri farmaci umani: antidepressivi, farmaci per ADHD, farmaci per il cuore'**
  String get tos006Title;

  /// TOS-006 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'agitazione, aritmie, convulsioni'**
  String get tos006Text;

  /// TOS-007 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Veleni per topi (anticoagulanti, colecalciferolo)'**
  String get tos007Title;

  /// TOS-007 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'emorragie anche dopo 3-5 giorni; danno renale'**
  String get tos007Text;

  /// TOS-008 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Lumachicidi a base di metaldeide'**
  String get tos008Title;

  /// TOS-008 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'tremori e convulsioni gravi in poco tempo'**
  String get tos008Text;

  /// TOS-009 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Antigelo (glicole etilenico), insetticidi, bocconi avvelenati'**
  String get tos009Title;

  /// TOS-009 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'insufficienza renale, sintomi neurologici'**
  String get tos009Text;

  /// TOS-010 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Processionaria del pino (febbraio-maggio)'**
  String get tos010Title;

  /// TOS-010 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'necrosi di lingua e bocca: subito dal veterinario, non strofinare'**
  String get tos010Text;

  /// TOS-011 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Cannabis / THC'**
  String get tos011Title;

  /// TOS-011 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'barcollamento, perdita di urina, letargia'**
  String get tos011Text;

  /// TOS-012 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Piante: oleandro, Cycas revoluta, tasso, mughetto, azalea, ricino, bulbi'**
  String get tos012Title;

  /// TOS-012 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'effetti su cuore, fegato o sistema nervoso'**
  String get tos012Text;

  /// TOS-013 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Funghi selvatici, alghe tossiche in acqua stagnante'**
  String get tos013Title;

  /// TOS-013 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'danno al fegato, sintomi neurologici'**
  String get tos013Text;

  /// TOS-014 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Rospi e morsi di vipera'**
  String get tos014Title;

  /// TOS-014 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'salivazione, gonfiore, collasso: subito dal veterinario'**
  String get tos014Text;

  /// TOS-015 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Noci di macadamia'**
  String get tos015Title;

  /// TOS-015 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'debolezza, tremori, febbre'**
  String get tos015Text;

  /// TOS-016 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Alcol e impasti lievitati crudi'**
  String get tos016Title;

  /// TOS-016 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'intossicazione, dilatazione dello stomaco'**
  String get tos016Text;

  /// TOS-017 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Caffeina (caffè, tè, energy drink), noce moscata, luppolo'**
  String get tos017Title;

  /// TOS-017 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'agitazione, tachicardia, ipertermia, convulsioni'**
  String get tos017Text;

  /// TOS-018 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Cibo ammuffito e compost'**
  String get tos018Title;

  /// TOS-018 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'tremori e convulsioni (micotossine)'**
  String get tos018Text;

  /// TOS-019 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Batterie a bottone, magneti, pannocchie, noccioli, ossa cotte'**
  String get tos019Title;

  /// TOS-019 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'ustioni interne, ostruzioni e perforazioni'**
  String get tos019Text;

  /// TOS-020 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Avocado'**
  String get tos020Title;

  /// TOS-020 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'disturbi gastrointestinali; il nocciolo causa ostruzioni'**
  String get tos020Text;

  /// TOS-021 · titolo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'Cibi molto grassi (avanzi, fritti) e sale in eccesso'**
  String get tos021Title;

  /// TOS-021 · testo · titolo = alimento, testo = pericolo
  ///
  /// In it, this message translates to:
  /// **'pancreatite; vomito e convulsioni da sale'**
  String get tos021Text;

  /// STG-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Stagione della processionaria'**
  String get stg001Title;

  /// STG-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Evita le pinete e i nidi bianchi sui pini. Se il cane la tocca con la bocca (salivazione, lingua gonfia): subito dal veterinario, senza strofinare.'**
  String get stg001Text;

  /// STG-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Stagione dei forasacchi'**
  String get stg002Title;

  /// STG-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Dopo i prati controlla orecchie, zampe (tra le dita) e narici. Se scuote la testa o starnutisce all\'improvviso, senti il veterinario.'**
  String get stg002Text;

  /// STG-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Caldo: rischio colpo di calore'**
  String get stg003Title;

  /// STG-003 · testo
  ///
  /// In it, this message translates to:
  /// **'{atRisk, select, yes{Per {name} il rischio è più alto. Passeggiate nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. Il 74% dei colpi di calore avviene durante lo sforzo.} other{Passeggiate nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. Il 74% dei colpi di calore avviene durante lo sforzo.}}'**
  String stg003Text(String atRisk, String name);

  /// STG-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Veleni per lumache e topi'**
  String get stg004Title;

  /// STG-004 · testo
  ///
  /// In it, this message translates to:
  /// **'In questa stagione sono più usati nei giardini e negli orti: tienilo al guinzaglio vicino a coltivazioni e cantine.'**
  String get stg004Text;

  /// STG-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Acqua stagnante e leptospirosi'**
  String get stg005Title;

  /// STG-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Non farlo bere da pozzanghere, fossi e stagni: la leptospirosi si trasmette con l\'urina dei topi ed è trasmissibile all\'uomo. Vomito, abbattimento e sete dopo un bagno in acque ferme → veterinario oggi.'**
  String get stg005Text;

  /// STG-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Freddo'**
  String get stg006Title;

  /// STG-006 · testo
  ///
  /// In it, this message translates to:
  /// **'{fragile, select, yes{Per {name} il freddo pesa di più. Uscite brevi quando gela, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli (sciacquali al rientro).} other{Uscite brevi quando gela, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli (sciacquali al rientro).}}'**
  String stg006Text(String fragile, String name);

  /// STG-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Zecche'**
  String get stg007Title;

  /// STG-007 · testo
  ///
  /// In it, this message translates to:
  /// **'{allYear, select, yes{Al Centro-Sud le zecche sono presenti tutto l\'anno: mantieni la protezione e controlla il pelo dopo le passeggiate.} other{Stagione delle zecche (marzo-novembre): controlla il pelo dopo le passeggiate.}}'**
  String stg007Text(String allYear);

  /// STG-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Botti di Capodanno'**
  String get stg008Title;

  /// STG-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Tienilo in casa, con una zona tranquilla e finestre chiuse; controlla che la medaglietta sia aggiornata. Se è molto pauroso, parlane prima con il veterinario.'**
  String get stg008Text;

  /// RAZ-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Torace profondo: attenzione alla torsione gastrica'**
  String get raz001Title;

  /// RAZ-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Pasti divisi, niente corse subito dopo mangiato. Addome gonfio con conati a vuoto è un\'emergenza.'**
  String get raz001Text;

  /// RAZ-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Razza brachicefala'**
  String get raz002Title;

  /// RAZ-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Respira peggio con caldo e sforzo: evita le ore calde e segnala al veterinario russare forte o affanno.'**
  String get raz002Text;

  /// RAZ-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Possibile mutazione MDR1'**
  String get raz003Title;

  /// RAZ-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiedi al veterinario il test MDR1 prima di usare alcuni antiparassitari e farmaci (es. ivermectina ad alte dosi).'**
  String get raz003Text;

  /// RAZ-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Dalmata: calcoli di urati'**
  String get raz004Title;

  /// RAZ-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Acqua abbondante e dieta concordata con il veterinario; segnala sforzo o sangue nelle urine.'**
  String get raz004Text;

  /// RAZ-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Schiena lunga'**
  String get raz005Title;

  /// RAZ-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Evita salti da divani e scale ripide. Dolore alla schiena o zampe posteriori deboli: subito dal veterinario.'**
  String get raz005Text;

  /// RAZ-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Razza toy: trachea e zuccheri'**
  String get raz006Title;

  /// RAZ-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Predisposta al collasso tracheale (tosse \"a clacson\": usa la pettorina, non il collare) e, da cucciolo, all\'ipoglicemia: pasti frequenti.'**
  String get raz006Text;

  /// RAZ-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Schnauzer nano: pancreatite'**
  String get raz007Title;

  /// RAZ-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Evita avanzi e cibi grassi; vomito e dolore addominale dopo un pasto grasso vanno visti dal veterinario.'**
  String get raz007Text;

  /// RAZ-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Dobermann: cuore'**
  String get raz008Title;

  /// RAZ-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Predisposto alla cardiomiopatia dilatativa: chiedi al veterinario dei controlli cardiologici periodici (ECG Holter, ecografia).'**
  String get raz008Text;

  /// RAZ-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cocker: orecchie'**
  String get raz009Title;

  /// RAZ-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Predisposto alle otiti: controlla e asciuga le orecchie dopo bagni e passeggiate sotto la pioggia.'**
  String get raz009Text;

  /// RAZ-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Bulldog francese: schiena'**
  String get raz010Title;

  /// RAZ-010 · testo
  ///
  /// In it, this message translates to:
  /// **'Predisposto all\'ernia del disco: dolore alla schiena o zampe posteriori deboli vanno visti subito.'**
  String get raz010Text;

  /// RAZ-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cavalier King: cuore'**
  String get raz011Title;

  /// RAZ-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Predisposto alla malattia della valvola mitrale: conta i respiri nel sonno ogni settimana (sezione Diari).'**
  String get raz011Text;

  /// RAZ-012 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sterilizzazione nelle taglie grandi'**
  String get raz012Title;

  /// RAZ-012 · testo
  ///
  /// In it, this message translates to:
  /// **'Per alcune razze grandi gli studi indicano che l\'età della sterilizzazione può influire su articolazioni e alcuni tumori (Hart et al. 2020). Non esiste un\'età giusta per tutti: parlane con il veterinario.'**
  String get raz012Text;

  /// CUC-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Finestra di socializzazione (fino a ~14 settimane)'**
  String get cuc001Title;

  /// CUC-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Fagli conoscere con calma persone, rumori, superfici e cani vaccinati e sani, anche prima della fine dei vaccini, in ambienti controllati (AVSAB 2008). Finché i vaccini non sono completi evita parchi e aree con feci di cani sconosciuti; sì a cani sani e vaccinati, case di amici e classi per cuccioli con protocollo igienico. Abitualo a trasportino e manipolazione.'**
  String get cuc001Text;

  /// CUC-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Educazione al bisogno'**
  String get cuc002Title;

  /// CUC-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Premia subito, fuori, appena ha fatto. Non punire gli incidenti: pulisci con un detergente enzimatico. Zampa ti dice quando portarlo fuori.'**
  String get cuc002Text;

  /// VIA-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Età minima'**
  String get via001Title;

  /// VIA-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Antirabbico da 12 settimane + 21 giorni: in genere non si viaggia prima delle 15 settimane di età.'**
  String get via001Text;

  /// VIA-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Microchip registrato'**
  String get via002Title;

  /// VIA-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Obbligatorio e impiantato prima del vaccino antirabbico.'**
  String get via002Text;

  /// VIA-003 · titolo · date = giorno/mese/anno
  ///
  /// In it, this message translates to:
  /// **'Vaccino antirabbico valido'**
  String get via003Title;

  /// VIA-003 · testo · date = giorno/mese/anno
  ///
  /// In it, this message translates to:
  /// **'{hasRabies, select, yes{La prima vaccinazione è valida dopo 21 giorni; i richiami fatti in tempo valgono subito. Durata 1-3 anni secondo la scheda tecnica (ultimo: {date}).} other{Nessun antirabbico in cartella.}}'**
  String via003Text(String hasRabies, String date);

  /// VIA-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Passaporto europeo per animali'**
  String get via004Title;

  /// VIA-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. (UE) 576/2013 e successive modifiche; verifica prima di partire sul sito del Ministero della Salute.'**
  String get via004Text;

  /// VIA-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Trattamento contro Echinococcus'**
  String get via005Title;

  /// VIA-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Obbligatorio 24-120 h prima dell\'ingresso in Regno Unito, Irlanda, Finlandia, Norvegia e Malta.'**
  String get via005Text;

  /// VIA-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Rischi parassitari della destinazione'**
  String get via006Title;

  /// VIA-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiedi al veterinario: filaria, leishmania e zecche variano molto tra paesi.'**
  String get via006Text;

  /// SCA-QOL-1 · titolo
  ///
  /// In it, this message translates to:
  /// **'Dolore (Hurt)'**
  String get scaQol1Title;

  /// SCA-QOL-1 · testo
  ///
  /// In it, this message translates to:
  /// **'Il dolore è controllato? Respira bene? 10 = nessun dolore'**
  String get scaQol1Text;

  /// SCA-QOL-2 · titolo
  ///
  /// In it, this message translates to:
  /// **'Fame (Hunger)'**
  String get scaQol2Title;

  /// SCA-QOL-2 · testo
  ///
  /// In it, this message translates to:
  /// **'Mangia abbastanza? 10 = appetito normale'**
  String get scaQol2Text;

  /// SCA-QOL-3 · titolo
  ///
  /// In it, this message translates to:
  /// **'Idratazione'**
  String get scaQol3Title;

  /// SCA-QOL-3 · testo
  ///
  /// In it, this message translates to:
  /// **'Beve abbastanza? 10 = sì'**
  String get scaQol3Text;

  /// SCA-QOL-4 · titolo
  ///
  /// In it, this message translates to:
  /// **'Igiene'**
  String get scaQol4Title;

  /// SCA-QOL-4 · testo
  ///
  /// In it, this message translates to:
  /// **'Si mantiene pulito, niente piaghe? 10 = sì'**
  String get scaQol4Text;

  /// SCA-QOL-5 · titolo
  ///
  /// In it, this message translates to:
  /// **'Felicità'**
  String get scaQol5Title;

  /// SCA-QOL-5 · testo
  ///
  /// In it, this message translates to:
  /// **'Interagisce, gioca, risponde? 10 = come sempre'**
  String get scaQol5Text;

  /// SCA-QOL-6 · titolo
  ///
  /// In it, this message translates to:
  /// **'Mobilità'**
  String get scaQol6Title;

  /// SCA-QOL-6 · testo
  ///
  /// In it, this message translates to:
  /// **'Si alza e cammina da solo? 10 = sì'**
  String get scaQol6Text;

  /// SCA-QOL-7 · titolo
  ///
  /// In it, this message translates to:
  /// **'Più giorni buoni che cattivi'**
  String get scaQol7Title;

  /// SCA-QOL-7 · testo
  ///
  /// In it, this message translates to:
  /// **'10 = quasi tutti buoni'**
  String get scaQol7Text;

  /// LAB-001 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Creatinina'**
  String get lab001Text;

  /// LAB-002 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'SDMA'**
  String get lab002Text;

  /// LAB-003 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Urea (BUN)'**
  String get lab003Text;

  /// LAB-004 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'ALT'**
  String get lab004Text;

  /// LAB-005 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Fosfatasi alcalina (ALP)'**
  String get lab005Text;

  /// LAB-006 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Glucosio'**
  String get lab006Text;

  /// LAB-007 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Fruttosamina'**
  String get lab007Text;

  /// LAB-008 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Ematocrito'**
  String get lab008Text;

  /// LAB-009 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Globuli bianchi'**
  String get lab009Text;

  /// LAB-010 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Piastrine'**
  String get lab010Text;

  /// LAB-011 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Proteine totali'**
  String get lab011Text;

  /// LAB-012 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Albumina'**
  String get lab012Text;

  /// LAB-013 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'T4 totale'**
  String get lab013Text;

  /// LAB-014 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Peso specifico urinario'**
  String get lab014Text;

  /// LAB-015 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'UPC (proteinuria)'**
  String get lab015Text;

  /// LAB-016 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Pressione sistolica'**
  String get lab016Text;

  /// LAB-017 · testo · esame di laboratorio suggerito (nuovo ID, non clinico)
  ///
  /// In it, this message translates to:
  /// **'Titolo Leishmania'**
  String get lab017Text;

  /// EMG-001 · titolo
  ///
  /// In it, this message translates to:
  /// **'Addome gonfio, conati a vuoto, agitazione'**
  String get emg001Title;

  /// EMG-001 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile torsione/dilatazione dello stomaco: ogni minuto conta.'**
  String get emg001Text;

  /// EMG-002 · titolo
  ///
  /// In it, this message translates to:
  /// **'Fatica a respirare, respiro rumoroso, lingua o gengive blu'**
  String get emg002Title;

  /// EMG-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Tienilo calmo e al fresco durante il trasporto.'**
  String get emg002Text;

  /// EMG-003 · titolo
  ///
  /// In it, this message translates to:
  /// **'Gengive pallide o bianche, collasso, debolezza improvvisa'**
  String get emg003Title;

  /// EMG-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Può indicare un\'emorragia interna o uno shock.'**
  String get emg003Text;

  /// EMG-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Convulsioni oltre 5 minuti, oppure 2 o più in 24 ore'**
  String get emg004Title;

  /// EMG-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Non mettere le mani in bocca; allontana gli oggetti; cronometra.'**
  String get emg004Text;

  /// EMG-005 · titolo
  ///
  /// In it, this message translates to:
  /// **'Colpo di calore: ansima molto, barcolla, gengive rosso scuro'**
  String get emg005Title;

  /// EMG-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Raffreddalo subito: bagnalo abbondantemente con acqua fresca o fredda e fai aria. Non coprirlo con asciugamani bagnati. Poi vai subito dal veterinario continuando a raffreddarlo in auto, anche se sembra riprendersi.'**
  String get emg005Text;

  /// EMG-006 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sospetto avvelenamento, morso di vipera, contatto con processionaria'**
  String get emg006Title;

  /// EMG-006 · testo
  ///
  /// In it, this message translates to:
  /// **'Porta la confezione o una foto. Non provocare il vomito di tua iniziativa (niente sale o acqua ossigenata).'**
  String get emg006Text;

  /// EMG-007 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sforzo a urinare senza risultato, o nessuna pipì da 24 ore'**
  String get emg007Title;

  /// EMG-007 · testo
  ///
  /// In it, this message translates to:
  /// **'Nel maschio un blocco urinario è un\'emergenza.'**
  String get emg007Text;

  /// EMG-008 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo con vomito e diarrea, soprattutto se non vaccinato'**
  String get emg008Title;

  /// EMG-008 · testo
  ///
  /// In it, this message translates to:
  /// **'Va esclusa la parvovirosi; la disidratazione è rapida.'**
  String get emg008Text;

  /// EMG-009 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cucciolo di taglia toy debole, tremante o che non risponde'**
  String get emg009Title;

  /// EMG-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile ipoglicemia: solo se è cosciente, un po\' di miele sulle gengive, poi subito dal veterinario.'**
  String get emg009Text;

  /// EMG-010 · titolo
  ///
  /// In it, this message translates to:
  /// **'Femmina non sterilizzata abbattuta, che beve molto o ha perdite dalla vulva, settimane dopo il calore'**
  String get emg010Title;

  /// EMG-010 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile piometra (infezione dell\'utero).'**
  String get emg010Text;

  /// EMG-011 · titolo
  ///
  /// In it, this message translates to:
  /// **'Parto difficile'**
  String get emg011Title;

  /// EMG-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Oltre 30 minuti di contrazioni forti senza cucciolo, oltre 2 ore tra un cucciolo e l\'altro, perdite verdi o nere, gravidanza oltre i 70 giorni.'**
  String get emg011Text;

  /// EMG-012 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cagna che allatta e trema, barcolla o è agitata'**
  String get emg012Title;

  /// EMG-012 · testo
  ///
  /// In it, this message translates to:
  /// **'Possibile eclampsia (calcio basso).'**
  String get emg012Text;

  /// EMG-013 · titolo
  ///
  /// In it, this message translates to:
  /// **'Traumi (investimento, caduta, morsi), sanguinamenti, feci nere'**
  String get emg013Title;

  /// EMG-013 · testo
  ///
  /// In it, this message translates to:
  /// **'Anche se sembra stare bene: le lesioni interne non si vedono.'**
  String get emg013Text;

  /// EMG-014 · titolo
  ///
  /// In it, this message translates to:
  /// **'Dolore intenso, guaisce se toccato, non si alza'**
  String get emg014Title;

  /// EMG-014 · testo
  ///
  /// In it, this message translates to:
  /// **'Non dare farmaci per persone: molti sono tossici per il cane.'**
  String get emg014Text;

  /// EMG-015 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ha ingerito un oggetto, ossa, pannocchie, batterie o farmaci'**
  String get emg015Title;

  /// EMG-015 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama prima di fare qualsiasi cosa.'**
  String get emg015Text;

  /// EMG-016 · titolo
  ///
  /// In it, this message translates to:
  /// **'Reazione allergica grave: muso o palpebre gonfie, orticaria diffusa, vomito o fatica a respirare dopo puntura, farmaco o vaccino'**
  String get emg016Title;

  /// EMG-016 · testo
  ///
  /// In it, this message translates to:
  /// **'Il gonfiore del muso può chiudere le vie respiratorie: vai subito.'**
  String get emg016Text;

  /// EMG-017 · titolo
  ///
  /// In it, this message translates to:
  /// **'Occhio sporgente, ferito, molto dolente o perdita improvvisa della vista'**
  String get emg017Title;

  /// EMG-017 · testo
  ///
  /// In it, this message translates to:
  /// **'Impedisci che si gratti; non mettere colliri di tua iniziativa.'**
  String get emg017Text;

  /// EMG-018 · titolo
  ///
  /// In it, this message translates to:
  /// **'Ustioni, folgorazione (cavi elettrici) o quasi-annegamento'**
  String get emg018Title;

  /// EMG-018 · testo
  ///
  /// In it, this message translates to:
  /// **'Anche se sembra stare bene: i danni a polmoni e cuore possono comparire nelle ore successive.'**
  String get emg018Text;

  /// EMG-019 · titolo
  ///
  /// In it, this message translates to:
  /// **'Sospetto avvelenamento'**
  String get emg019Title;

  /// EMG-019 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama subito il tuo veterinario o il pronto soccorso h24: sapranno contattare un centro antiveleni. Tieni a portata la confezione o una foto dell\'etichetta.'**
  String get emg019Text;

  /// EMG-020 · titolo
  ///
  /// In it, this message translates to:
  /// **'Aggiungi i numeri utili'**
  String get emg020Title;

  /// EMG-020 · testo
  ///
  /// In it, this message translates to:
  /// **'Nel profilo del cane inserisci il telefono del tuo veterinario e di un pronto soccorso h24: li troverai qui.'**
  String get emg020Text;

  /// EMG-021 · titolo · testo = prima riga del promemoria; le altre righe sono UI-EMG-007…011
  ///
  /// In it, this message translates to:
  /// **'Cosa dire al telefono'**
  String get emg021Title;

  /// EMG-021 · testo · testo = prima riga del promemoria; le altre righe sono UI-EMG-007…011
  ///
  /// In it, this message translates to:
  /// **'{name}, {sex, select, male{maschio} other{femmina}}{neutered, select, yes{ sterilizzato/a} other{}}, {age}, {weight} kg{hasBreed, select, yes{, {breed}} other{}}.'**
  String emg021Text(
    String name,
    String sex,
    String neutered,
    String age,
    String weight,
    String breed,
    String hasBreed,
  );

  /// UI-EMG-001 · testo · titolo della scheda
  ///
  /// In it, this message translates to:
  /// **'Emergenze'**
  String get uiEmg001Text;

  /// UI-EMG-002 · testo
  ///
  /// In it, this message translates to:
  /// **'Chiama il mio veterinario'**
  String get uiEmg002Text;

  /// UI-EMG-003 · testo
  ///
  /// In it, this message translates to:
  /// **'Pronto soccorso veterinario h24'**
  String get uiEmg003Text;

  /// UI-EMG-004 · titolo
  ///
  /// In it, this message translates to:
  /// **'Cerca pronto soccorso veterinario vicino a me'**
  String get uiEmg004Title;

  /// UI-EMG-004 · testo
  ///
  /// In it, this message translates to:
  /// **'Apre la mappa'**
  String get uiEmg004Text;

  /// UI-EMG-005 · testo
  ///
  /// In it, this message translates to:
  /// **'Vai subito dal veterinario se…'**
  String get uiEmg005Text;

  /// UI-EMG-007 · testo
  ///
  /// In it, this message translates to:
  /// **'{hasNote, select, yes{Ha ingerito: {note} alle {time}.} other{Ha ingerito: (descrivi cosa e quanto) alle {time}.}}'**
  String uiEmg007Text(String hasNote, String note, String time);

  /// UI-EMG-008 · testo
  ///
  /// In it, this message translates to:
  /// **'{hasDrugs, select, yes{Farmaci in corso: {drugs}.} other{Farmaci in corso: nessuno.}}'**
  String uiEmg008Text(String hasDrugs, String drugs);

  /// UI-EMG-009 · testo
  ///
  /// In it, this message translates to:
  /// **'Patologie note: {conditions}.'**
  String uiEmg009Text(String conditions);

  /// UI-EMG-010 · testo
  ///
  /// In it, this message translates to:
  /// **'Allergie: {allergies}.'**
  String uiEmg010Text(String allergies);

  /// UI-EMG-011 · testo
  ///
  /// In it, this message translates to:
  /// **'Cosa è successo e da quando; come respira; colore delle gengive.'**
  String get uiEmg011Text;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
