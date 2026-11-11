// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get alrLiv001Text =>
      'Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.';

  @override
  String get alrLiv002Text => 'Contatta il veterinario oggi stesso.';

  @override
  String get alrLiv003Text =>
      'Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.';

  @override
  String get alrLiv004Text => 'Parlane alla prossima visita.';

  @override
  String get alrLiv005Text =>
      'Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.';

  @override
  String get alrUri001Title => 'Sforzo a urinare: possibile urgenza';

  @override
  String alrUri001Text(String name) {
    return 'Se $name si mette in posizione e non esce urina, o escono solo poche gocce, contatta subito il veterinario o un pronto soccorso veterinario, anche di notte. Nel maschio un blocco delle vie urinarie è un\'emergenza: non aspettare il giorno dopo. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.';
  }

  @override
  String get alrUri002Title => 'Sforzo a urinare ripetuto';

  @override
  String get alrUri002Text =>
      'Più tentativi con sforzo o poche gocce in 24 ore. Contatta il veterinario oggi stesso; subito se non esce urina. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.';

  @override
  String get alrUri003Title => 'Pipì con sforzo o a gocce';

  @override
  String get alrUri003Text =>
      'Osserva le prossime pipì. Se non riesce a urinare affatto, contatta subito il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.';

  @override
  String alrUri004Title(String hours) {
    return 'Cucciolo senza pipì da $hours ore da sveglio';
  }

  @override
  String get alrUri004Text =>
      'Un cucciolo sveglio urina molto più spesso. Se non è una registrazione mancante, contatta subito il veterinario. Se escono solo gocce, conta come se non avesse urinato.';

  @override
  String alrUri005Title(String hours) {
    return 'Nessuna pipì da $hours ore';
  }

  @override
  String alrUri005Text(String name) {
    return 'Se $name non ha davvero urinato (e non è solo una registrazione mancante), è un\'urgenza, specie nei maschi. Se escono solo gocce, conta come se non avesse urinato.';
  }

  @override
  String alrUri006Title(String hours) {
    return 'Nessuna pipì registrata da $hours ore';
  }

  @override
  String alrUri006Text(String variant, String name, String hours) {
    String _temp0 = intl.Intl.selectLogic(variant, {
      'strainSpine':
          '$name è un maschio, si è sforzato a urinare nelle ultime 24 ore e da $hours ore non risulta nessuna pipì: può essere un blocco delle vie urinarie. Non aspettare di vedere se la fa: è un\'urgenza, anche di notte. Se escono solo gocce, conta come se non avesse urinato. Dopo una chirurgia della colonna, se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica.',
      'strain':
          '$name è un maschio, si è sforzato a urinare nelle ultime 24 ore e da $hours ore non risulta nessuna pipì: può essere un blocco delle vie urinarie. Non aspettare di vedere se la fa: è un\'urgenza, anche di notte. Se escono solo gocce, conta come se non avesse urinato.',
      'spine': 'Dopo una chirurgia della colonna, se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica. Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta subito il veterinario. Se non urina entro 24 ore in totale è comunque un\'urgenza.',
      'other': 'Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta subito il veterinario. Se non urina entro 24 ore in totale è comunque un\'urgenza.',
    });
    return '$_temp0';
  }

  @override
  String get alrUri007Title => 'Sangue nelle urine con malessere';

  @override
  String get alrUri007Text =>
      'Sangue nelle urine insieme a vomito o abbattimento richiede una visita oggi stesso.';

  @override
  String get alrUri008Title => 'Sangue durante il calore';

  @override
  String get alrUri008Text =>
      'Durante il calore è normale una perdita di sangue dalla vulva, che può macchiare la pipì. Senti il veterinario nei prossimi giorni se il calore dura più di 3-4 settimane o se la pipì resta rossa anche dopo; oggi stesso se si sforza a urinare, va molto spesso o è abbattuta.';

  @override
  String get alrUri009Title => 'Sangue nelle urine';

  @override
  String get alrUri009Text =>
      'Va sempre valutato dal veterinario entro 24-48 ore: può essere un segno di cistite o calcoli (solo il veterinario può dirlo). Se possibile raccogli un campione di urina.';

  @override
  String get alrUri010Title => 'Pipì piccole e frequenti';

  @override
  String alrUri010Text(String count) {
    return '$count pipì in 2 ore. Può essere un segno di cistite (solo il veterinario può dirlo): sentilo entro 24-48 ore, subito se c\'è sforzo senza urina.';
  }

  @override
  String get alrGi001Title => 'Conati a vuoto o addome gonfio';

  @override
  String get alrGi001Text =>
      'Conati senza riuscire a vomitare, addome gonfio, agitazione e salivazione possono indicare una torsione/dilatazione dello stomaco: è un\'emergenza in cui ogni minuto conta.';

  @override
  String get alrNeu001Title => 'Collasso o svenimento';

  @override
  String get alrNeu001Text =>
      'Un collasso o uno svenimento va sempre valutato subito, anche se si è ripreso: può dipendere da cuore, emorragia o calo di zuccheri.';

  @override
  String get alrGi002Title => 'Cucciolo con vomito o diarrea';

  @override
  String get alrGi002Text =>
      'Nei cuccioli vomito e diarrea insieme, o con abbattimento o inappetenza, richiedono una visita oggi stesso: la disidratazione è rapida e va esclusa la parvovirosi, soprattutto se non ha completato i vaccini. Subito se è molto abbattuto, ha sangue nelle feci o non trattiene l\'acqua.';

  @override
  String get alrDia001Title => 'Diabetico con vomito o abbattimento';

  @override
  String get alrDia001Text =>
      'Non fare l\'insulina senza aver sentito il veterinario. Vomito e abbattimento in un cane diabetico vanno valutati oggi stesso; subito se è molto debole, respira in modo strano o non beve.';

  @override
  String get alrFar001Title => 'Malessere durante la terapia per il Cushing';

  @override
  String get alrFar001Text =>
      'Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo. Non dare la prossima dose finché non hai parlato con il veterinario, e chiamalo subito.';

  @override
  String get alrFar002Title =>
      'Non mangia o è abbattuto durante antinfiammatori/cortisone';

  @override
  String get alrFar002Text =>
      'Può essere un effetto collaterale sullo stomaco: chiama il veterinario oggi. Non sospendere né aggiungere farmaci di tua iniziativa.';

  @override
  String get alrFar003Title => 'Antinfiammatori e cortisone insieme';

  @override
  String get alrFar003Text =>
      'Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: verifica col veterinario che sia voluto.';

  @override
  String get alrGi003Title => 'Vomito con sangue';

  @override
  String get alrGi003Text =>
      'Sangue o materiale scuro \"a fondi di caffè\" nel vomito: visita oggi stesso; subito se è abbattuto o ha le gengive pallide.';

  @override
  String get alrFar004Title =>
      'Vomito durante la terapia con antinfiammatori o cortisone';

  @override
  String alrFar004Text(String drug) {
    String _temp0 = intl.Intl.selectLogic(drug, {
      'fans': 'Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non dare la prossima dose di antinfiammatorio finché non l\'hai sentito, e non aggiungere altri farmaci (mai antidolorifici per persone).',
      'cortisone': 'Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere il cortisone di colpo e non aggiungere altri farmaci: chiedi a lui cosa fare.',
      'other': 'Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non dare la prossima dose di antinfiammatorio finché non l\'hai sentito, non sospendere il cortisone di colpo e non aggiungere altri farmaci (mai antidolorifici per persone).',
    });
    return '$_temp0';
  }

  @override
  String get alrGi004Title => 'Vomito ripetuto in un cane piccolo';

  @override
  String get alrGi004Text =>
      'Nei cuccioli e nei cani sotto i 5 kg disidratazione e ipoglicemia arrivano in fretta.';

  @override
  String get alrGi005Title => 'Vomito ripetuto';

  @override
  String alrGi005Text(String count) {
    return '$count episodi in 24 ore. Senti il veterinario entro 24 ore; subito se non trattiene nemmeno l\'acqua o è molto abbattuto.';
  }

  @override
  String get alrGi006Title => 'Ha vomitato una volta';

  @override
  String get alrGi006Text =>
      'Osserva: se si ripete, se è abbattuto o compaiono altri segni, senti il veterinario.';

  @override
  String get alrGi007aTitle => 'Feci nere';

  @override
  String alrGi007aText(String nsaid) {
    String _temp0 = intl.Intl.selectLogic(nsaid, {
      'yes': 'Feci nere durante una terapia con antinfiammatori o cortisone: potrebbe essere un sanguinamento dello stomaco. Chiama subito il veterinario; non dare la prossima dose di antinfiammatorio finché non l\'hai sentito.',
      'other': 'Feci nere durante una terapia con antinfiammatori o cortisone: potrebbe essere un sanguinamento dello stomaco. Chiama subito il veterinario.',
    });
    return '$_temp0';
  }

  @override
  String get alrGi007bTitle => 'Feci nere';

  @override
  String get alrGi007bText =>
      'Feci nere come catrame possono indicare sangue digerito: serve una visita oggi.';

  @override
  String get alrGi008Title => 'Cucciolo con sangue nelle feci';

  @override
  String get alrGi008Text =>
      'Nei cuccioli la diarrea con sangue richiede una visita oggi stesso (va esclusa la parvovirosi, soprattutto se non ha completato i vaccini).';

  @override
  String get alrGi009Title => 'Sangue nelle feci con vomito o abbattimento';

  @override
  String get alrGi009Text =>
      'Questa combinazione richiede una visita oggi stesso.';

  @override
  String get alrGi010Title => 'Sangue rosso nelle feci';

  @override
  String get alrGi010Text =>
      'Se si ripete, se c\'è diarrea abbondante o se cambia il suo comportamento, senti il veterinario entro 24-48 ore.';

  @override
  String get alrGi011Title => 'Cucciolo con diarrea';

  @override
  String get alrGi011Text =>
      'Nei cuccioli la disidratazione è rapida e va esclusa la parvovirosi: subito se vomita o è abbattuto.';

  @override
  String alrGi012Title(String vomit) {
    String _temp0 = intl.Intl.selectLogic(vomit, {
      'yes': 'Diarrea e vomito nelle ultime 24 ore',
      'other': 'Diarrea nelle ultime 24 ore',
    });
    return '$_temp0';
  }

  @override
  String get alrGi012Text =>
      'Assicurati che beva. Se persiste oltre 24-48 ore, se è abbattuto o vomita ripetutamente, senti il veterinario.';

  @override
  String alrGi013Title(String hours) {
    return 'Nessuna cacca da $hours ore';
  }

  @override
  String get alrGi013Text =>
      'Se non è una registrazione mancante: controlla che beva e si muova. Se si sforza senza risultato, vomita o è abbattuto, senti il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.';

  @override
  String get alrUri011Title => 'Fa pipì più spesso del solito';

  @override
  String alrUri011Text(String diabetic, String recent, String usual) {
    String _temp0 = intl.Intl.selectLogic(diabetic, {
      'yes':
          'Negli ultimi 3 giorni $recent uscite al giorno contro $usual abituali. Può essere un segno di infezione urinaria, diabete o problemi renali (solo il veterinario può dirlo): parlane entro qualche giorno. In un cane diabetico segnalalo al veterinario: la terapia potrebbe andare rivista.',
      'other':
          'Negli ultimi 3 giorni $recent uscite al giorno contro $usual abituali. Può essere un segno di infezione urinaria, diabete o problemi renali (solo il veterinario può dirlo): parlane entro qualche giorno.',
    });
    return '$_temp0';
  }

  @override
  String get alrUri012Title => 'Beve molto';

  @override
  String alrUri012Text(String ml) {
    return 'In media $ml ml al giorno, oltre i 100 ml/kg. La sete eccessiva può essere un segno di malattie da approfondire (solo il veterinario può dirlo). Non ridurre l\'acqua: parlane con il veterinario.';
  }

  @override
  String get alrUri013Title => 'Beve poco';

  @override
  String alrUri013Text(String ml) {
    return 'Con le crocchette $ml ml al giorno sono pochi (meno di 20 ml/kg). Se non è una registrazione incompleta e mangia poco o è abbattuto, senti il veterinario.';
  }

  @override
  String get alrRep001Title => 'Attenzione all\'utero (piometra)';

  @override
  String get alrRep001Text =>
      'In una femmina non sterilizzata, nelle settimane dopo il calore, sete e pipì aumentate, perdite dalla vulva, vomito o abbattimento possono indicare un\'infezione dell\'utero (piometra), che è un\'urgenza.';

  @override
  String get alrRep002Title =>
      'Femmina non sterilizzata: attenzione all\'utero';

  @override
  String alrRep002Text(String urgent) {
    String _temp0 = intl.Intl.selectLogic(urgent, {
      'yes': 'Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un\'infezione dell\'utero (piometra), che è un\'urgenza: contatta il veterinario oggi stesso. Registra i calori nella sezione Riproduzione: Zampa potrà avvisarti meglio.',
      'other': 'Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un\'infezione dell\'utero (piometra), che è un\'urgenza: osservala e senti il veterinario se compaiono altri segni. Registra i calori nella sezione Riproduzione: Zampa potrà avvisarti meglio.',
    });
    return '$_temp0';
  }

  @override
  String get alrUri014Title => 'Pipì in casa ripetute';

  @override
  String alrUri014Text(String count) {
    return '$count incidenti in 7 giorni in un cane adulto. Le cause possibili sono infezione urinaria, aumento della sete, incontinenza (frequente nelle femmine sterilizzate di taglia media e grande), declino cognitivo nell\'anziano, oppure intervalli troppo lunghi tra le uscite. Vale la pena parlarne con il veterinario. Se le perdite avvengono mentre dorme o riposa, registrale come \"Perdita di urina a riposo\".';
  }

  @override
  String get alrPes001Title => 'Il cucciolo non cresce';

  @override
  String get alrPes001Text =>
      'Un cucciolo dovrebbe aumentare di peso ogni settimana: se il peso è fermo da 2 settimane o cala, senti il veterinario; subito se mangia poco, vomita o ha diarrea.';

  @override
  String get alrPes002Title => 'Sta dimagrendo troppo in fretta';

  @override
  String get alrPes002Text =>
      'Oltre il 2% a settimana: un dimagrimento troppo rapido non è sano. Senti il veterinario per rivedere la dieta.';

  @override
  String alrPes003Title(String percent) {
    return 'Calo di peso del $percent%';
  }

  @override
  String get alrPes003Text =>
      'Un calo di peso non voluto merita una visita, soprattutto nel cane anziano.';

  @override
  String alrPes004Title(String percent) {
    return 'Calo di peso del $percent%';
  }

  @override
  String get alrPes004Text =>
      'Tienilo d\'occhio: se continua senza che tu abbia cambiato la dieta, senti il veterinario.';

  @override
  String alrPes005Title(String percent) {
    return 'Aumento di peso del $percent%';
  }

  @override
  String get alrPes005Text =>
      'Controlla razione e snack nella sezione Nutrizione.';

  @override
  String get alrPes006Title => 'Sottopeso';

  @override
  String get alrPes006Text =>
      'Prima di aumentare la razione fallo visitare, per escludere cause mediche.';

  @override
  String get alrPes007Title => 'Sovrappeso';

  @override
  String alrPes007Text(String growing, String bcs) {
    String _temp0 = intl.Intl.selectLogic(growing, {
      'yes':
          'Body Condition Score $bcs/9: per un cucciolo è sopra l\'ideale. Non ridurre il cibo da solo: durante la crescita la razione va decisa con il veterinario, controllando la curva di crescita.',
      'other':
          'Body Condition Score $bcs/9: la razione in Nutrizione è calcolata per un dimagrimento graduale. Prima di iniziare fai visitare il cane.',
    });
    return '$_temp0';
  }

  @override
  String get alrPes008Title => 'Leggermente sovrappeso';

  @override
  String get alrPes008Text => 'Riduci gli snack e ricontrolla tra un mese.';

  @override
  String alrTox001Title(String hasNote, String note) {
    String _temp0 = intl.Intl.selectLogic(hasNote, {
      'yes': 'Ha ingerito qualcosa: $note',
      'other': 'Ha ingerito qualcosa',
    });
    return '$_temp0';
  }

  @override
  String get alrTox001Text =>
      'Chiama subito il veterinario o un centro antiveleni, anche se sta bene. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell\'etichetta.';

  @override
  String get alrTox002Title => 'Sorveglianza dopo un\'ingestione';

  @override
  String alrTox002Text(String hasNote, String date, String note) {
    String _temp0 = intl.Intl.selectLogic(hasNote, {
      'yes':
          'Il $date ha ingerito: $note. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.',
      'other':
          'Il $date ha ingerito. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.',
    });
    return '$_temp0';
  }

  @override
  String get alrRes001Title => 'Gengive pallide o blu';

  @override
  String get alrRes001Text =>
      'Possono indicare un problema di circolazione, respirazione o un\'emorragia: è un\'emergenza.';

  @override
  String get alrRes002Title => 'Gengive rosso scuro';

  @override
  String get alrRes002Text =>
      'Gengive rosso scuro possono indicare un colpo di calore, un\'infezione grave o uno shock. Se ha preso caldo o ha fatto sforzi, inizia subito a raffreddarlo con acqua fresca (vedi Emergenze) e poi parti; negli altri casi parti subito per il veterinario.';

  @override
  String get alrRes003Title => 'Gengive gialle';

  @override
  String get alrRes003Text =>
      'Il colore giallo (ittero) va valutato dal veterinario oggi stesso.';

  @override
  String alrRes004Title(String rate) {
    return 'Respira molto veloce nel sonno ($rate/min)';
  }

  @override
  String get alrRes004Text =>
      'Oltre 40 respiri al minuto a riposo: possibile difficoltà respiratoria o cardiaca.';

  @override
  String get alrRes005Title => 'Respiri nel sonno oltre 40/min';

  @override
  String get alrRes005Text =>
      'Rimisura tra 15-30 minuti mentre dorme tranquillo. Se resta sopra 40, o respira con fatica a bocca aperta, vai subito dal veterinario.';

  @override
  String get alrRes006Title => 'Respiri nel sonno sopra 30/min';

  @override
  String get alrRes006Text =>
      'Due misure di fila sopra 30 respiri al minuto: segnalalo al veterinario oggi, soprattutto se ha una malattia di cuore.';

  @override
  String get alrRes007Title => 'Respiri nel sonno in aumento';

  @override
  String alrRes007Text(String week, String month) {
    return 'Media della settimana $week/min contro $month/min del mese precedente: segnalalo al veterinario oggi.';
  }

  @override
  String get alrRes008Title => 'Fatica a respirare';

  @override
  String get alrRes008Text =>
      'Respiro affannoso a riposo, bocca aperta o lingua scura: tienilo calmo e al fresco e vai subito dal veterinario.';

  @override
  String get alrRes009Title => 'Tosse in un cane con malattia di cuore';

  @override
  String get alrRes009Text =>
      'Nei cardiopatici la tosse va segnalata al veterinario oggi.';

  @override
  String get alrRes010Title => 'Tosse in un Cavalier King';

  @override
  String get alrRes010Text =>
      'Il Cavalier è predisposto alla malattia della valvola mitrale: segnala la tosse al veterinario e conta i respiri nel sonno.';

  @override
  String get alrRes011Title => 'Tosse da più giorni';

  @override
  String get alrRes011Text =>
      'Tosse che dura da più di 3 giorni o con abbattimento: senti il veterinario entro 24-48 ore. Evita il contatto con altri cani.';

  @override
  String alrDia002Title(String value) {
    return 'Glicemia bassa ($value mg/dL)';
  }

  @override
  String get alrDia002Text =>
      'Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. Se trema, barcolla, ha convulsioni o non è ben sveglio, vai direttamente al pronto soccorso veterinario. Non fare la prossima insulina senza averlo sentito.';

  @override
  String alrDia003Title(String value) {
    return 'Glicemia al limite basso ($value mg/dL)';
  }

  @override
  String get alrDia003Text =>
      'Segnalala al veterinario oggi, prima della prossima insulina.';

  @override
  String alrDia004Title(String value) {
    return 'Glicemia alta ($value mg/dL)';
  }

  @override
  String get alrDia004Text =>
      'Segnalala al veterinario: la terapia potrebbe andare rivista. Se vomita, è abbattuto o non mangia, oggi stesso.';

  @override
  String get alrDia005Title => 'Due dosi di insulina ravvicinate';

  @override
  String alrDia005Text(String hours) {
    return 'Due dosi di insulina registrate a $hours ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. Intanto offrigli il suo pasto e non lasciarlo solo. Se è un errore di registrazione, cancellane una.';
  }

  @override
  String get alrRep003Title => 'Tremori in una cagna che allatta';

  @override
  String get alrRep003Text =>
      'Possibile eclampsia (calcio basso dopo il parto): è un\'emergenza. Allontana i cuccioli e vai subito dal veterinario.';

  @override
  String get alrNeu002Title => 'Cucciolo debole o tremante';

  @override
  String get alrNeu002Text =>
      'Nei cuccioli piccoli può essere un\'ipoglicemia. Se è cosciente strofina un po\' di miele sulle gengive, poi vai subito dal veterinario.';

  @override
  String get alrNeu003Title => 'Convulsione in un cane diabetico';

  @override
  String get alrNeu003Text =>
      'Può essere un\'ipoglicemia. Se è cosciente strofina un po\' di miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e vai subito dal veterinario.';

  @override
  String get alrNeu004aTitle => 'Convulsione lunga o senza ripresa';

  @override
  String get alrNeu004aText =>
      'Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un\'emergenza.';

  @override
  String alrNeu004bTitle(String count) {
    return '$count convulsioni in 24 ore';
  }

  @override
  String get alrNeu004bText =>
      'Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un\'emergenza.';

  @override
  String get alrNeu005Title => 'Prima convulsione';

  @override
  String get alrNeu005Text =>
      'Una prima crisi va sempre valutata dal veterinario. Annota durata e cosa è successo prima e dopo.';

  @override
  String get alrNeu006Title => 'Crisi più frequenti questo mese';

  @override
  String alrNeu006Text(String count, String average) {
    return '$count crisi questo mese contro una media di $average: parlane con il veterinario, la terapia potrebbe andare rivista.';
  }

  @override
  String get alrDia006Title => 'Possibile ipoglicemia';

  @override
  String get alrDia006Text =>
      'Tremori o barcollamento in un cane diabetico: se è cosciente strofina miele o glucosio sulle gengive e vai subito dal veterinario.';

  @override
  String get alrNeu007Title => 'Tremori, barcollamento o testa inclinata';

  @override
  String get alrNeu007Text =>
      'Segni neurologici: se sono comparsi all\'improvviso è un\'urgenza. Pensa anche a possibili sostanze ingerite.';

  @override
  String alrTmp001aTitle(String temp) {
    return 'Temperatura $temp °C';
  }

  @override
  String get alrTmp001aText =>
      'Temperatura molto alta: possibile colpo di calore. Raffreddalo subito con acqua fresca o fredda e fai aria, poi vai subito dal veterinario.';

  @override
  String alrTmp001bTitle(String temp) {
    return 'Temperatura $temp °C';
  }

  @override
  String get alrTmp001bText =>
      'Temperatura troppo bassa: tienilo al caldo e vai subito dal veterinario.';

  @override
  String alrTmp002Title(String temp) {
    return 'Febbre ($temp °C)';
  }

  @override
  String get alrTmp002Text =>
      'Normale 38,0-39,2 °C. Non dare antipiretici per persone (sono tossici).';

  @override
  String get alrCib001aTitle => 'Non mangia';

  @override
  String get alrCib001aText =>
      'Se non ha mangiato o ha vomitato, non fare l\'insulina senza aver sentito il veterinario.';

  @override
  String get alrCib001bTitle => 'Non mangia';

  @override
  String get alrCib001bText => 'Pasti saltati: serve una visita oggi.';

  @override
  String get alrCib002Title => 'Ha saltato i pasti';

  @override
  String get alrCib002Text =>
      'Se non mangia da 24 ore senti il veterinario entro 1-2 giorni; prima se vomita o è abbattuto.';

  @override
  String get alrCib003aTitle => 'Abbattuto';

  @override
  String alrCib003aText(String reason) {
    String _temp0 = intl.Intl.selectLogic(reason, {
      'signs':
          'Abbattimento insieme ad altri segni: contatta il veterinario oggi.',
      'puppy':
          'Abbattimento in un cane cucciolo: contatta il veterinario oggi.',
      'diabetic':
          'Abbattimento in un cane diabetico: contatta il veterinario oggi.',
      'other': 'Abbattimento in un cane anziano: contatta il veterinario oggi.',
    });
    return '$_temp0';
  }

  @override
  String get alrCib003bTitle => 'Abbattuto';

  @override
  String get alrCib003bText =>
      'Osservalo: se non torna vivace entro la giornata, o compaiono vomito, diarrea, febbre o gengive pallide, senti il veterinario.';

  @override
  String get alrDia007Title => 'Insulina fatta senza che abbia mangiato';

  @override
  String get alrDia007Text =>
      'Chiama ora il veterinario e chiedi come comportarti. Nelle prossime ore offrigli il suo pasto e osservalo: se compaiono debolezza, tremori o barcollamento strofina miele sulle gengive e vai subito dal veterinario.';

  @override
  String get alrUri015Title => 'Urina scura o color caffè';

  @override
  String alrUri015Text(String variant) {
    String _temp0 = intl.Intl.selectLogic(variant, {
      'tickUrgent': 'Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Hai trovato zecche di recente? Dillo al veterinario. Con abbattimento o febbre serve una visita oggi.',
      'tick': 'Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Hai trovato zecche di recente? Dillo al veterinario. Se si ripete, senti il veterinario.',
      'urgent': 'Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Con abbattimento o febbre serve una visita oggi.',
      'other': 'Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. Se si ripete, senti il veterinario.',
    });
    return '$_temp0';
  }

  @override
  String get alrFar005Title => 'Loperamide in una razza a rischio MDR1';

  @override
  String get alrFar005Text =>
      'Nelle razze con possibile mutazione MDR1 la loperamide può dare effetti neurologici: verifica con il veterinario.';

  @override
  String get alrRep004Title => 'Malessere nella prima settimana dopo il parto';

  @override
  String get alrRep004Text =>
      'Febbre, perdite maleodoranti o abbattimento dopo il parto possono indicare un\'infezione dell\'utero: contatta il veterinario oggi.';

  @override
  String get alrRep005Title => 'Mammelle gonfie, calde o dolenti';

  @override
  String get alrRep005Text =>
      'Può essere una mastite: contatta il veterinario oggi. Non spremere le mammelle.';

  @override
  String get alrRep006aTitle =>
      'Temperatura calata da oltre 24 ore senza parto';

  @override
  String get alrRep006aText =>
      'Il calo di temperatura sotto 37,5 °C precede il parto: se dopo 24 ore non è iniziato il travaglio, chiama il veterinario.';

  @override
  String get alrRep006bTitle => 'Parto atteso entro circa 24 ore';

  @override
  String get alrRep006bText =>
      'La temperatura sotto 37,5 °C di solito precede il parto di circa 24 ore. Prepara la cassa parto.';

  @override
  String get alrAlt001Title => 'Non appoggia la zampa';

  @override
  String get alrAlt001Text =>
      'Non caricare l\'arto è un segno di dolore importante: visita oggi. Non dare antidolorifici per persone.';

  @override
  String get alrAlt002Title => 'Zoppia da più giorni';

  @override
  String get alrAlt002Text =>
      'Una zoppia che dura da 3-5 giorni va vista dal veterinario.';

  @override
  String get alrAlt003Title => 'Prurito, pelle o orecchie';

  @override
  String get alrAlt003Text =>
      'Senti il veterinario entro qualche giorno; prima se si gratta fino a ferirsi o scuote molto la testa.';

  @override
  String get alrAlt004Title => 'Problema ai denti';

  @override
  String get alrAlt004Text =>
      'Alito cattivo, gengive che sanguinano o fatica a masticare: controllo dentale al prossimo appuntamento, prima se mangia poco.';

  @override
  String alrAlt005Title(String count) {
    return 'Denti: $count spazzolature in 7 giorni';
  }

  @override
  String get alrAlt005Text =>
      'Ideale ogni giorno, almeno 3 volte a settimana (AAHA 2019).';

  @override
  String get alrUri016Title => 'Perdite di urina a riposo';

  @override
  String get alrUri016Text =>
      'Perdite mentre dorme o riposa: spesso è un problema curabile (incontinenza). Parlane con il veterinario. Non ridurre l\'acqua.';

  @override
  String get alrRep007Title => 'Perdite purulente';

  @override
  String get alrRep007Text =>
      'Perdite purulente in una femmina non sterilizzata possono indicare un\'infezione dell\'utero: contatta il veterinario oggi stesso.';

  @override
  String get alrRep008Title => 'Perdite vulvari';

  @override
  String alrRep008Text(String variant) {
    String _temp0 = intl.Intl.selectLogic(variant, {
      'spayedPus': 'In una femmina sterilizzata, perdite con pus o cattivo odore possono indicare un\'infezione della vagina o di ciò che resta dell\'utero: contatta il veterinario oggi.',
      'spayed': 'Perdite dalla vulva in una femmina sterilizzata vanno fatte vedere nei prossimi giorni. Se sono sangue e lei si comporta come in calore, dillo al veterinario: a volte resta un pezzetto di ovaio. Oggi stesso se è abbattuta, beve molto o compaiono pus o cattivo odore.',
      'other': 'Perdite fuori dal calore vanno valutate dal veterinario entro 1-2 giorni; oggi stesso se è abbattuta, beve molto o le perdite sono purulente.',
    });
    return '$_temp0';
  }

  @override
  String get alrUri017Title => 'Pipì di notte, prima non succedeva';

  @override
  String get alrUri017Text =>
      'Due o più notti su 7 con pipì notturna: può essere un segno di sete aumentata o di un problema urinario. Prenota una visita.';

  @override
  String get alrRep009Title => 'Gravidanza oltre i 70 giorni';

  @override
  String get alrRep009Text =>
      'Il parto non è ancora avvenuto: contatta il veterinario oggi.';

  @override
  String alrRep010Title(String date) {
    return 'Parto vicino (presunto il $date)';
  }

  @override
  String get alrRep010Text =>
      'Prepara la cassa parto. Chiama subito il veterinario se: contrazioni forti per oltre 30 minuti senza cuccioli, oltre 2 ore tra un cucciolo e l\'altro, perdite verdi o nere senza cuccioli.';

  @override
  String get alrRep011Title => 'Calore che dura da oltre 4 settimane';

  @override
  String get alrRep011Text =>
      'Un calore persistente va valutato dal veterinario. Se è già finito, registra \"Fine calore\".';

  @override
  String alrFar006Title(String drug) {
    return 'Dose non confermata: $drug';
  }

  @override
  String alrFar006Text(String time) {
    return 'Prevista alle $time. Se l\'hai saltata, non raddoppiare la successiva: chiedi al veterinario cosa fare.';
  }

  @override
  String get alrGi014Title => 'Feci molto dure';

  @override
  String get alrGi014Text =>
      'Punteggio 1 della scala fecale: controlla che beva abbastanza. Se si sforza senza risultato, senti il veterinario.';

  @override
  String get alrChi001Title => 'Ferita aperta o che sanguina';

  @override
  String get alrChi001Text =>
      'Punti aperti o sanguinamento della ferita: copri con una garza pulita, impedisci che si lecchi e contatta il veterinario oggi. Subito se il sanguinamento è abbondante o si vede tessuto interno.';

  @override
  String get alrChi002Title => 'Ferita arrossata, gonfia o con secrezione';

  @override
  String get alrChi002Text =>
      'Può essere un\'infiammazione o un\'infezione della ferita: mantieni il collare elisabettiano e senti il veterinario entro 1-2 giorni; prima se peggiora o compare febbre.';

  @override
  String get alrChi003Title => 'Non ha ancora mangiato dopo l\'intervento';

  @override
  String get alrChi003Text =>
      'L\'appetito di solito torna entro 24-48 ore dall\'intervento: contatta il veterinario oggi.';

  @override
  String get alrAlt006Title => 'Possibile forasacco';

  @override
  String get alrAlt006Text =>
      'In stagione dei forasacchi, scuotere la testa o starnutire all\'improvviso dopo un prato richiede una visita oggi: prima si toglie, meno danni fa.';

  @override
  String get alrPrv001Title => 'Ciclo vaccinale non completo';

  @override
  String get alrPrv001Text =>
      'Finché non è completo, evita aree frequentate da cani sconosciuti e chiama il veterinario per fissare la dose.';

  @override
  String alrPrv002Title(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count scadenze superate',
      one: 'Una scadenza superata',
    );
    return '$_temp0';
  }

  @override
  String alrPrv002Text(String items) {
    return '$items';
  }

  @override
  String get prv001Title => 'Microchip e iscrizione all\'anagrafe canina';

  @override
  String get prv001Text =>
      'Obbligatoria per legge (L. 281/1991, O.M. 6/8/2008, anagrafe SINAC): entro 60 giorni dalla nascita e comunque prima della cessione. Se hai adottato il cane, verifica che sia intestato a te.';

  @override
  String get prv002Title => 'Verifica che l\'anagrafe sia intestata a te';

  @override
  String prv002Text(String microchip) {
    return 'Controlla sul portale dell\'anagrafe canina della tua Regione (o SINAC) che il microchip $microchip sia intestato a te e che indirizzo e telefono siano aggiornati.';
  }

  @override
  String prv003Title(String dose) {
    String _temp0 = intl.Intl.selectLogic(dose, {
      'first': 'Vaccino core (cimurro, epatite, parvovirosi) – 1ª dose',
      'second': 'Vaccino core (cimurro, epatite, parvovirosi) – 2ª dose',
      'other': 'Vaccino core (cimurro, epatite, parvovirosi) – 3ª dose',
    });
    return '$_temp0';
  }

  @override
  String prv003Text(String dose) {
    String _temp0 = intl.Intl.selectLogic(dose, {
      'first': 'WSAVA: prima dose a 6-8 settimane.',
      'second': 'Ogni 2-4 settimane fino a 16 settimane o più.',
      'other': 'L\'ultima dose non prima delle 16 settimane.',
    });
    return '$_temp0';
  }

  @override
  String get prv004Title =>
      'Vaccino core (cimurro, epatite, parvovirosi) – verifica il libretto';

  @override
  String get prv004Text =>
      'Nessun vaccino core registrato. Se non trovi il libretto, il veterinario può fare una dose (WSAVA considera protettiva una dose dei vaccini core vivi attenuati nell\'adulto) oppure dosare gli anticorpi.';

  @override
  String get prv005Title =>
      'Vaccino core (cimurro, epatite, parvovirosi) – richiamo';

  @override
  String get prv005Text =>
      'WSAVA 2024: richiamo a 26 settimane (oppure a 12 mesi secondo il veterinario), poi ogni 3 anni se il vaccino usato lo prevede.';

  @override
  String prv006Title(String dose) {
    String _temp0 = intl.Intl.selectLogic(dose, {
      'first': 'Leptospirosi – 1ª dose',
      'other': 'Leptospirosi – 2ª dose',
    });
    return '$_temp0';
  }

  @override
  String prv006Text(String dose) {
    String _temp0 = intl.Intl.selectLogic(dose, {
      'first': 'Consigliata in Italia: 2 dosi a 2-4 settimane di distanza, poi richiamo annuale.',
      'other': 'Completa l\'avvio vaccinale.',
    });
    return '$_temp0';
  }

  @override
  String get prv007Title => 'Leptospirosi';

  @override
  String get prv007Text =>
      'Se non è mai stato vaccinato servono 2 dosi a 2-4 settimane; poi richiamo annuale. Verifica il libretto.';

  @override
  String get prv008Title => 'Sverminazione cucciolo';

  @override
  String get prv008Text =>
      'Ogni 2 settimane fino a 2 settimane dopo lo svezzamento, poi ogni mese fino a 6 mesi.';

  @override
  String get prv009Title => 'Esame delle feci';

  @override
  String get prv009Text =>
      'Da 1 a 4 volte l\'anno secondo lo stile di vita (o sverminazione periodica secondo il veterinario).';

  @override
  String prv010Title(String year) {
    return 'Prevenzione filariosi (stagione $year)';
  }

  @override
  String get prv010Text =>
      'ESCCAP Italia: profilassi mensile fino a dicembre (un mese dopo la fine della stagione delle zanzare). Se non era protetto, chiedi al veterinario se serve prima un test.';

  @override
  String get prv011Title =>
      'Filariosi: chiedi al veterinario se fare una dose ora e il test';

  @override
  String get prv011Text =>
      'Se non era protetto quest\'estate, il veterinario valuterà un test (antigene + microfilarie) prima di iniziare; il test affidabile si fa in primavera.';

  @override
  String prv012Title(String year) {
    return 'Test filariosi e leishmaniosi annuale ($year)';
  }

  @override
  String get prv012Text =>
      'Prima di iniziare la profilassi: antigene della filaria e, nelle zone a rischio, test per la leishmania.';

  @override
  String prv013Title(String year) {
    return 'Inizio profilassi filariosi $year';
  }

  @override
  String prv013Text(String south) {
    String _temp0 = intl.Intl.selectLogic(south, {
      'yes': 'Mensile fino a dicembre (al Sud valuta con il veterinario la copertura tutto l\'anno). Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono anche iniezioni a lento rilascio da 6 o 12 mesi.',
      'other': 'Mensile fino a dicembre. Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono anche iniezioni a lento rilascio da 6 o 12 mesi.',
    });
    return '$_temp0';
  }

  @override
  String prv014Title(String year) {
    return 'Repellente anti-pappataci (leishmaniosi) $year';
  }

  @override
  String get prv014Text =>
      'Da aprile a novembre per tutti i cani, anche al Nord: la leishmaniosi è ormai presente in molte aree. Il collare dura secondo il prodotto, lo spot-on 3-4 settimane. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c\'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto.';

  @override
  String get prv015Title => 'Antiparassitario esterno (zecche e pulci)';

  @override
  String get prv015Text =>
      'Frequenza secondo il prodotto (1-3 mesi). Al Centro-Sud anche tutto l\'anno. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c\'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto.';

  @override
  String prv016Title(String senior) {
    String _temp0 = intl.Intl.selectLogic(senior, {
      'yes': 'Controllo geriatrico semestrale',
      'other': 'Visita di controllo annuale',
    });
    return '$_temp0';
  }

  @override
  String prv016Text(String senior) {
    String _temp0 = intl.Intl.selectLogic(senior, {
      'yes': 'Per i cani anziani: visita ed esami del sangue e delle urine ogni 6 mesi.',
      'other': 'Visita generale, peso, denti, richiami.',
    });
    return '$_temp0';
  }

  @override
  String get nut001Text =>
      'In allattamento il fabbisogno arriva a 4-8 volte quello di riposo: lascia il cibo a disposizione (alimento per cuccioli) e acqua fresca sempre. Se trema, ansima, è agitata o barcolla, chiama subito il veterinario.';

  @override
  String nut002Text(String meals) {
    return 'Per la sua età sono consigliati $meals pasti al giorno: nei cuccioli piccoli pochi pasti possono causare ipoglicemia.';
  }

  @override
  String get nut003Text =>
      'Cucciolo di taglia grande: usa un alimento specifico \"puppy large breed\" e non aggiungere integratori di calcio. Mantienilo snello (BCS 4-5): crescere più in fretta non lo fa diventare più grande, aumenta il rischio di problemi alle articolazioni.';

  @override
  String nut004Text(String conditions) {
    String _temp0 = intl.Intl.selectLogic(conditions, {
      'yes': 'Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane. Con le patologie registrate la dieta va decisa con il veterinario.',
      'other': 'Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane.',
    });
    return '$_temp0';
  }

  @override
  String get nut005Text =>
      'Sottopeso: prima fallo visitare per escludere cause mediche, poi aumenta la razione gradualmente in 1-2 settimane.';

  @override
  String get nutFat001Text => 'gravidanza avanzata';

  @override
  String get nutFat002Text => 'gravidanza (prime 6 settimane)';

  @override
  String get nutFat003Text => 'allattamento (4-8 × RER)';

  @override
  String get nutFat004Text => 'cucciolo sotto i 4 mesi';

  @override
  String get nutFat005Text => 'cucciolo in crescita';

  @override
  String get nutFat006Text =>
      'programma di dimagrimento (calcolato sul peso ideale)';

  @override
  String get nutFat007Text => 'sottopeso: calcolato sul peso ideale';

  @override
  String get nutFat008Text => 'cane da lavoro/sport intenso';

  @override
  String get nutFat009Text => 'cane molto attivo';

  @override
  String get nutFat010Text => 'cane sedentario o incline al sovrappeso';

  @override
  String get nutFat011Text => 'cane anziano';

  @override
  String get nutFat012Text => 'adulto sterilizzato';

  @override
  String get nutFat013Text => 'adulto non sterilizzato';

  @override
  String get scaBcs1Text =>
      'Emaciato: costole, vertebre e bacino visibili a distanza.';

  @override
  String get scaBcs2Text =>
      'Molto magro: costole facilmente visibili, nessun grasso palpabile.';

  @override
  String get scaBcs3Text =>
      'Magro: costole facilmente palpabili, vita evidente.';

  @override
  String get scaBcs4Text =>
      'Sottile: costole palpabili con poco grasso, vita ben visibile.';

  @override
  String get scaBcs5Text =>
      'Ideale: costole palpabili senza eccesso di grasso, vita visibile da sopra.';

  @override
  String get scaBcs6Text =>
      'Leggermente sovrappeso: costole palpabili con lieve grasso in più.';

  @override
  String get scaBcs7Text =>
      'Sovrappeso: costole palpabili a fatica, vita poco visibile.';

  @override
  String get scaBcs8Text =>
      'Obeso: costole non palpabili, nessuna vita, addome disteso.';

  @override
  String get scaBcs9Text =>
      'Obesità grave: depositi di grasso su collo, arti e base della coda.';

  @override
  String get tos001Title =>
      'Xilitolo (gomme e dolci \"senza zucchero\", dentifricio per persone, burro di arachidi light, integratori)';

  @override
  String get tos001Text => 'ipoglicemia e danno al fegato anche a piccole dosi';

  @override
  String get tos002Title => 'Uva e uvetta';

  @override
  String get tos002Text => 'insufficienza renale acuta, dose imprevedibile';

  @override
  String get tos003Title =>
      'Cioccolato e cacao (più è fondente, più è pericoloso)';

  @override
  String get tos003Text =>
      'teobromina: vomito, agitazione, aritmie, convulsioni';

  @override
  String get tos004Title =>
      'Cipolla, aglio, porro, erba cipollina (anche cotti, in polvere o nei sughi)';

  @override
  String get tos004Text =>
      'possono causare anemia. Già da circa 5 g di cipolla per kg di peso, cioè mezza cipolla piccola per un cane di 10 kg, e meno per l\'aglio. Piccole quantità ripetute si sommano. I segni possono comparire dopo 1-5 giorni.';

  @override
  String get tos005Title =>
      'Farmaci per persone: paracetamolo, ibuprofene, naprossene, ketoprofene, aspirina';

  @override
  String get tos005Text => 'ulcere, danno a reni e fegato, anemia';

  @override
  String get tos006Title =>
      'Altri farmaci umani: antidepressivi, farmaci per ADHD, farmaci per il cuore';

  @override
  String get tos006Text => 'agitazione, aritmie, convulsioni';

  @override
  String get tos007Title => 'Veleni per topi (anticoagulanti, colecalciferolo)';

  @override
  String get tos007Text => 'emorragie anche dopo 3-5 giorni; danno renale';

  @override
  String get tos008Title => 'Lumachicidi a base di metaldeide';

  @override
  String get tos008Text => 'tremori e convulsioni gravi in poco tempo';

  @override
  String get tos009Title =>
      'Antigelo (glicole etilenico), insetticidi, bocconi avvelenati';

  @override
  String get tos009Text => 'insufficienza renale, sintomi neurologici';

  @override
  String get tos010Title => 'Processionaria del pino (febbraio-maggio)';

  @override
  String get tos010Text =>
      'necrosi di lingua e bocca: subito dal veterinario, non strofinare';

  @override
  String get tos011Title => 'Cannabis / THC';

  @override
  String get tos011Text => 'barcollamento, perdita di urina, letargia';

  @override
  String get tos012Title =>
      'Piante: oleandro, Cycas revoluta, tasso, mughetto, azalea, ricino, bulbi';

  @override
  String get tos012Text => 'effetti su cuore, fegato o sistema nervoso';

  @override
  String get tos013Title =>
      'Funghi selvatici, alghe tossiche in acqua stagnante';

  @override
  String get tos013Text => 'danno al fegato, sintomi neurologici';

  @override
  String get tos014Title => 'Rospi e morsi di vipera';

  @override
  String get tos014Text =>
      'salivazione, gonfiore, collasso: subito dal veterinario';

  @override
  String get tos015Title => 'Noci di macadamia';

  @override
  String get tos015Text => 'debolezza, tremori, febbre';

  @override
  String get tos016Title => 'Alcol e impasti lievitati crudi';

  @override
  String get tos016Text => 'intossicazione, dilatazione dello stomaco';

  @override
  String get tos017Title =>
      'Caffeina (caffè, tè, energy drink), noce moscata, luppolo';

  @override
  String get tos017Text => 'agitazione, tachicardia, ipertermia, convulsioni';

  @override
  String get tos018Title => 'Cibo ammuffito e compost';

  @override
  String get tos018Text => 'tremori e convulsioni (micotossine)';

  @override
  String get tos019Title =>
      'Batterie a bottone, magneti, pannocchie, noccioli, ossa cotte';

  @override
  String get tos019Text => 'ustioni interne, ostruzioni e perforazioni';

  @override
  String get tos020Title => 'Avocado';

  @override
  String get tos020Text =>
      'disturbi gastrointestinali; il nocciolo causa ostruzioni';

  @override
  String get tos021Title =>
      'Cibi molto grassi (avanzi, fritti) e sale in eccesso';

  @override
  String get tos021Text => 'pancreatite; vomito e convulsioni da sale';

  @override
  String get stg001Title => 'Stagione della processionaria';

  @override
  String get stg001Text =>
      'Evita le pinete e i nidi bianchi sui pini. Se il cane la tocca con la bocca (salivazione, lingua gonfia): subito dal veterinario, senza strofinare.';

  @override
  String get stg002Title => 'Stagione dei forasacchi';

  @override
  String get stg002Text =>
      'Dopo i prati controlla orecchie, zampe (tra le dita) e narici. Se scuote la testa o starnutisce all\'improvviso, senti il veterinario.';

  @override
  String get stg003Title => 'Caldo: rischio colpo di calore';

  @override
  String stg003Text(String atRisk, String name) {
    String _temp0 = intl.Intl.selectLogic(atRisk, {
      'yes':
          'Per $name il rischio è più alto. Passeggiate nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. Nel Regno Unito circa 3 colpi di calore su 4 avvengono durante lo sforzo: nei giorni caldi, passeggiate brevi e nelle ore fresche.',
      'other': 'Passeggiate nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. Nel Regno Unito circa 3 colpi di calore su 4 avvengono durante lo sforzo: nei giorni caldi, passeggiate brevi e nelle ore fresche.',
    });
    return '$_temp0';
  }

  @override
  String get stg004Title => 'Veleni per lumache e topi';

  @override
  String get stg004Text =>
      'In questa stagione sono più usati nei giardini e negli orti: tienilo al guinzaglio vicino a coltivazioni e cantine.';

  @override
  String get stg005Title => 'Acqua stagnante e leptospirosi';

  @override
  String get stg005Text =>
      'Non farlo bere da pozzanghere, fossi e stagni: la leptospirosi si trasmette con l\'urina dei topi ed è trasmissibile all\'uomo. Vomito, abbattimento e sete dopo un bagno in acque ferme → veterinario oggi.';

  @override
  String get stg006Title => 'Freddo';

  @override
  String stg006Text(String fragile, String name) {
    String _temp0 = intl.Intl.selectLogic(fragile, {
      'yes':
          'Per $name il freddo pesa di più. Uscite brevi quando gela, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli (sciacquali al rientro).',
      'other': 'Uscite brevi quando gela, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli (sciacquali al rientro).',
    });
    return '$_temp0';
  }

  @override
  String get stg007Title => 'Zecche';

  @override
  String stg007Text(String allYear) {
    String _temp0 = intl.Intl.selectLogic(allYear, {
      'yes': 'Al Centro-Sud le zecche sono presenti tutto l\'anno: mantieni la protezione e controlla il pelo dopo le passeggiate.',
      'other': 'Stagione delle zecche (marzo-novembre): controlla il pelo dopo le passeggiate.',
    });
    return '$_temp0';
  }

  @override
  String get stg008Title => 'Botti di Capodanno';

  @override
  String get stg008Text =>
      'Tienilo in casa, con una zona tranquilla e finestre chiuse; controlla che la medaglietta sia aggiornata. Se è molto pauroso, parlane prima con il veterinario.';

  @override
  String get raz001Title =>
      'Torace profondo: attenzione alla torsione gastrica';

  @override
  String get raz001Text =>
      'Pasti divisi, niente corse subito dopo mangiato. Addome gonfio con conati a vuoto è un\'emergenza.';

  @override
  String get raz002Title => 'Razza brachicefala';

  @override
  String get raz002Text =>
      'Respira peggio con caldo e sforzo: evita le ore calde e segnala al veterinario russare forte o affanno.';

  @override
  String get raz003Title => 'Possibile mutazione MDR1';

  @override
  String get raz003Text =>
      'Chiedi al veterinario il test MDR1 prima di usare alcuni antiparassitari e farmaci (es. ivermectina ad alte dosi).';

  @override
  String get raz004Title => 'Dalmata: calcoli di urati';

  @override
  String get raz004Text =>
      'Acqua abbondante e dieta concordata con il veterinario; segnala sforzo o sangue nelle urine.';

  @override
  String get raz005Title => 'Schiena lunga';

  @override
  String get raz005Text =>
      'Evita salti da divani e scale ripide. Dolore alla schiena o zampe posteriori deboli: subito dal veterinario.';

  @override
  String get raz006Title => 'Razza toy: trachea e zuccheri';

  @override
  String get raz006Text =>
      'Predisposta al collasso tracheale (tosse \"a clacson\": usa la pettorina, non il collare) e, da cucciolo, all\'ipoglicemia: pasti frequenti.';

  @override
  String get raz007Title => 'Schnauzer nano: pancreatite';

  @override
  String get raz007Text =>
      'Evita avanzi e cibi grassi; vomito e dolore addominale dopo un pasto grasso vanno visti dal veterinario.';

  @override
  String get raz008Title => 'Dobermann: cuore';

  @override
  String get raz008Text =>
      'Predisposto alla cardiomiopatia dilatativa: chiedi al veterinario dei controlli cardiologici periodici (ECG Holter, ecografia).';

  @override
  String get raz009Title => 'Cocker: orecchie';

  @override
  String get raz009Text =>
      'Predisposto alle otiti: controlla e asciuga le orecchie dopo bagni e passeggiate sotto la pioggia.';

  @override
  String get raz010Title => 'Bulldog francese: schiena';

  @override
  String get raz010Text =>
      'Predisposto all\'ernia del disco: dolore alla schiena o zampe posteriori deboli vanno visti subito.';

  @override
  String get raz011Title => 'Cavalier King: cuore';

  @override
  String get raz011Text =>
      'Predisposto alla malattia della valvola mitrale: conta i respiri nel sonno ogni settimana (sezione Diari).';

  @override
  String get raz012Title => 'Sterilizzazione nelle taglie grandi';

  @override
  String get raz012Text =>
      'Per alcune razze grandi gli studi indicano che l\'età della sterilizzazione può influire su articolazioni e alcuni tumori (Hart et al. 2020). Non esiste un\'età giusta per tutti: parlane con il veterinario.';

  @override
  String get cuc001Title =>
      'Finestra di socializzazione (fino a ~14 settimane)';

  @override
  String get cuc001Text =>
      'Fagli conoscere con calma persone, rumori, superfici e cani vaccinati e sani, anche prima della fine dei vaccini, in ambienti controllati (AVSAB 2008). Finché i vaccini non sono completi evita parchi e aree con feci di cani sconosciuti; sì a cani sani e vaccinati, case di amici e classi per cuccioli con protocollo igienico. Abitualo a trasportino e manipolazione.';

  @override
  String get cuc002Title => 'Educazione al bisogno';

  @override
  String get cuc002Text =>
      'Premia subito, fuori, appena ha fatto. Non punire gli incidenti: pulisci con un detergente enzimatico. Zampa ti dice quando portarlo fuori.';

  @override
  String get via001Title => 'Età minima';

  @override
  String get via001Text =>
      'Antirabbico da 12 settimane + 21 giorni: in genere non si viaggia prima delle 15 settimane di età.';

  @override
  String get via002Title => 'Microchip registrato';

  @override
  String get via002Text =>
      'Obbligatorio e impiantato prima del vaccino antirabbico.';

  @override
  String get via003Title => 'Vaccino antirabbico valido';

  @override
  String via003Text(String hasRabies, String date) {
    String _temp0 = intl.Intl.selectLogic(hasRabies, {
      'yes':
          'La prima vaccinazione è valida dopo 21 giorni; i richiami fatti in tempo valgono subito. Durata 1-3 anni secondo la scheda tecnica (ultimo: $date).',
      'other': 'Nessun antirabbico in cartella.',
    });
    return '$_temp0';
  }

  @override
  String get via004Title => 'Passaporto europeo per animali';

  @override
  String get via004Text =>
      'Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. (UE) 2016/429 e Reg. delegato (UE) 2026/131, in vigore dal 22 aprile 2026; i passaporti rilasciati prima restano validi. Verifica prima di partire sul sito del Ministero della Salute.';

  @override
  String get via005Title => 'Trattamento contro la tenia Echinococcus';

  @override
  String get via005Text =>
      'Va fatto da un veterinario e registrato sul passaporto 24-120 ore (da 1 a 5 giorni) prima dell\'ingresso nei Paesi indenni. Verifica l\'elenco aggiornato prima di partire, con il veterinario o sul sito del Ministero della Salute.';

  @override
  String get via006Title => 'Rischi parassitari della destinazione';

  @override
  String get via006Text =>
      'Chiedi al veterinario: filaria, leishmania e zecche variano molto tra paesi.';

  @override
  String get scaQol1Title => 'Dolore (Hurt)';

  @override
  String get scaQol1Text =>
      'Il dolore è controllato? Respira bene? 10 = nessun dolore';

  @override
  String get scaQol2Title => 'Fame (Hunger)';

  @override
  String get scaQol2Text => 'Mangia abbastanza? 10 = appetito normale';

  @override
  String get scaQol3Title => 'Idratazione';

  @override
  String get scaQol3Text => 'Beve abbastanza? 10 = sì';

  @override
  String get scaQol4Title => 'Igiene';

  @override
  String get scaQol4Text => 'Si mantiene pulito, niente piaghe? 10 = sì';

  @override
  String get scaQol5Title => 'Felicità';

  @override
  String get scaQol5Text => 'Interagisce, gioca, risponde? 10 = come sempre';

  @override
  String get scaQol6Title => 'Mobilità';

  @override
  String get scaQol6Text => 'Si alza e cammina da solo? 10 = sì';

  @override
  String get scaQol7Title => 'Più giorni buoni che cattivi';

  @override
  String get scaQol7Text => '10 = quasi tutti buoni';

  @override
  String get lab001Text => 'Creatinina';

  @override
  String get lab002Text => 'SDMA';

  @override
  String get lab003Text => 'Urea (BUN)';

  @override
  String get lab004Text => 'ALT';

  @override
  String get lab005Text => 'Fosfatasi alcalina (ALP)';

  @override
  String get lab006Text => 'Glucosio';

  @override
  String get lab007Text => 'Fruttosamina';

  @override
  String get lab008Text => 'Ematocrito';

  @override
  String get lab009Text => 'Globuli bianchi';

  @override
  String get lab010Text => 'Piastrine';

  @override
  String get lab011Text => 'Proteine totali';

  @override
  String get lab012Text => 'Albumina';

  @override
  String get lab013Text => 'T4 totale';

  @override
  String get lab014Text => 'Peso specifico urinario';

  @override
  String get lab015Text => 'UPC (proteinuria)';

  @override
  String get lab016Text => 'Pressione sistolica';

  @override
  String get lab017Text => 'Titolo Leishmania';

  @override
  String get emg001Title => 'Addome gonfio, conati a vuoto, agitazione';

  @override
  String get emg001Text =>
      'Possibile torsione/dilatazione dello stomaco: ogni minuto conta.';

  @override
  String get emg002Title =>
      'Fatica a respirare, respiro rumoroso, lingua o gengive blu';

  @override
  String get emg002Text => 'Tienilo calmo e al fresco durante il trasporto.';

  @override
  String get emg003Title =>
      'Gengive pallide o bianche, collasso, debolezza improvvisa';

  @override
  String get emg003Text => 'Può indicare un\'emorragia interna o uno shock.';

  @override
  String get emg004Title =>
      'Convulsioni oltre 5 minuti, oppure 2 o più in 24 ore';

  @override
  String get emg004Text =>
      'Non mettere le mani in bocca; allontana gli oggetti; cronometra.';

  @override
  String get emg005Title =>
      'Colpo di calore: ansima molto, barcolla, gengive rosso scuro';

  @override
  String get emg005Text =>
      'Raffreddalo subito: bagnalo abbondantemente con acqua fresca o fredda e fai aria. Non coprirlo con asciugamani bagnati. Poi vai subito dal veterinario continuando a raffreddarlo in auto, anche se sembra riprendersi.';

  @override
  String get emg006Title =>
      'Sospetto avvelenamento, morso di vipera, contatto con processionaria';

  @override
  String get emg006Text =>
      'Porta la confezione o una foto. Non provocare il vomito di tua iniziativa (niente sale o acqua ossigenata).';

  @override
  String get emg007Title =>
      'Sforzo a urinare senza risultato, o nessuna pipì da 24 ore';

  @override
  String get emg007Text => 'Nel maschio un blocco urinario è un\'emergenza.';

  @override
  String get emg008Title =>
      'Cucciolo con vomito e diarrea, soprattutto se non vaccinato';

  @override
  String get emg008Text =>
      'Va esclusa la parvovirosi; la disidratazione è rapida.';

  @override
  String get emg009Title =>
      'Cucciolo di taglia toy debole, tremante o che non risponde';

  @override
  String get emg009Text =>
      'Possibile ipoglicemia: solo se è cosciente, un po\' di miele sulle gengive, poi subito dal veterinario.';

  @override
  String get emg010Title =>
      'Femmina non sterilizzata abbattuta, che beve molto o ha perdite dalla vulva, settimane dopo il calore';

  @override
  String get emg010Text => 'Possibile piometra (infezione dell\'utero).';

  @override
  String get emg011Title => 'Parto difficile';

  @override
  String get emg011Text =>
      'Oltre 30 minuti di contrazioni forti senza cucciolo, oltre 2 ore tra un cucciolo e l\'altro, perdite verdi o nere, gravidanza oltre i 70 giorni.';

  @override
  String get emg012Title => 'Cagna che allatta e trema, barcolla o è agitata';

  @override
  String get emg012Text => 'Possibile eclampsia (calcio basso).';

  @override
  String get emg013Title =>
      'Traumi (investimento, caduta, morsi), sanguinamenti, feci nere';

  @override
  String get emg013Text =>
      'Anche se sembra stare bene: le lesioni interne non si vedono.';

  @override
  String get emg014Title => 'Dolore intenso, guaisce se toccato, non si alza';

  @override
  String get emg014Text =>
      'Non dare farmaci per persone: molti sono tossici per il cane.';

  @override
  String get emg015Title =>
      'Ha ingerito un oggetto, ossa, pannocchie, batterie o farmaci';

  @override
  String get emg015Text => 'Chiama prima di fare qualsiasi cosa.';

  @override
  String get emg016Title =>
      'Reazione allergica grave: muso o palpebre gonfie, orticaria diffusa, vomito o fatica a respirare dopo puntura, farmaco o vaccino';

  @override
  String get emg016Text =>
      'Il gonfiore del muso può chiudere le vie respiratorie: vai subito.';

  @override
  String get emg017Title =>
      'Occhio sporgente, ferito, molto dolente o perdita improvvisa della vista';

  @override
  String get emg017Text =>
      'Impedisci che si gratti; non mettere colliri di tua iniziativa.';

  @override
  String get emg018Title =>
      'Ustioni, folgorazione (cavi elettrici) o quasi-annegamento';

  @override
  String get emg018Text =>
      'Anche se sembra stare bene: i danni a polmoni e cuore possono comparire nelle ore successive.';

  @override
  String get emg019Title => 'Sospetto avvelenamento';

  @override
  String emg019Text(String cav, String phone) {
    String _temp0 = intl.Intl.selectLogic(cav, {
      'yes':
          'Chiama subito il tuo veterinario o il pronto soccorso veterinario. Per sapere quanto è pericoloso ciò che ha ingerito puoi chiamare anche il Centro Antiveleni di Milano (Ospedale Niguarda), $phone, 24 ore su 24: risponde anche per gli animali e ti chiederà nome e recapiti. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell\'etichetta. Se ha convulsioni, respira male o non è ben sveglio, parti subito per il pronto soccorso veterinario e chiama durante il tragitto.',
      'other': 'Chiama subito il tuo veterinario o il pronto soccorso h24: sapranno contattare un centro antiveleni. Tieni a portata la confezione o una foto dell\'etichetta.',
    });
    return '$_temp0';
  }

  @override
  String get emg020Title => 'Aggiungi i numeri utili';

  @override
  String get emg020Text =>
      'Nel profilo del cane inserisci il telefono del tuo veterinario e di un pronto soccorso h24: li troverai qui.';

  @override
  String get emg021Title => 'Cosa dire al telefono';

  @override
  String emg021Text(
    String name,
    String sex,
    String neutered,
    String age,
    String weight,
    String breed,
    String hasBreed,
  ) {
    String _temp0 = intl.Intl.selectLogic(sex, {
      'male': 'maschio',
      'other': 'femmina',
    });
    String _temp1 = intl.Intl.selectLogic(neutered, {
      'yes': ' sterilizzato/a',
      'other': '',
    });
    String _temp2 = intl.Intl.selectLogic(hasBreed, {
      'yes': ', $breed',
      'other': '',
    });
    return '$name, $_temp0$_temp1, $age, $weight kg$_temp2.';
  }

  @override
  String get uiEmg001Text => 'Emergenze';

  @override
  String get uiEmg002Text => 'Chiama il mio veterinario';

  @override
  String get uiEmg003Text => 'Pronto soccorso veterinario h24';

  @override
  String get uiEmg004Title => 'Cerca pronto soccorso veterinario vicino a me';

  @override
  String get uiEmg004Text => 'Apre la mappa';

  @override
  String get uiEmg005Text => 'Vai subito dal veterinario se…';

  @override
  String uiEmg007Text(String hasNote, String note, String time) {
    String _temp0 = intl.Intl.selectLogic(hasNote, {
      'yes': 'Ha ingerito: $note alle $time.',
      'other': 'Ha ingerito: (descrivi cosa e quanto) alle $time.',
    });
    return '$_temp0';
  }

  @override
  String uiEmg008Text(String hasDrugs, String drugs) {
    String _temp0 = intl.Intl.selectLogic(hasDrugs, {
      'yes': 'Farmaci in corso: $drugs.',
      'other': 'Farmaci in corso: nessuno.',
    });
    return '$_temp0';
  }

  @override
  String uiEmg009Text(String conditions) {
    return 'Patologie note: $conditions.';
  }

  @override
  String uiEmg010Text(String allergies) {
    return 'Allergie: $allergies.';
  }

  @override
  String get uiEmg011Text =>
      'Cosa è successo e da quando; come respira; colore delle gengive.';

  @override
  String get uiDos001Title => 'Dose saltata?';

  @override
  String uiDos001Text(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'insulin': 'Confermi che l\'insulina non è stata fatta? Non farla in ritardo e non raddoppiare la prossima senza aver sentito il veterinario. Se non sei sicuro che sia stata fatta, non rifarla.',
      'antiepileptic': 'Confermi che la dose non è stata data? Con i farmaci per le convulsioni una dose saltata può far tornare le crisi: chiama il veterinario oggi per sapere se darla adesso.',
      'other': 'Confermi che questa dose non è stata data? Non raddoppiare la prossima: chiedi al veterinario cosa fare.',
    });
    return '$_temp0';
  }

  @override
  String uiDos002Title(String kind, String name) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'insulin': '💉 Insulina di $name: segnata?',
      'other': '💊 Dose confermata per $name?',
    });
    return '$_temp0';
  }

  @override
  String uiDos002Text(String kind, String app) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'insulin': 'Se è stata fatta, segna \"Dato\". Se non sei sicuro che sia stata fatta, non rifarla: chiedi al veterinario.',
      'antiepileptic':
          'Apri $app e segna \"Dato\" o \"Saltato\". Con i farmaci per le convulsioni una dose saltata può far tornare le crisi: se l\'hai saltata, chiama il veterinario oggi per sapere se darla adesso.',
      'other':
          'Apri $app e segna \"Dato\" o \"Saltato\". Se l\'hai saltata non raddoppiare la successiva: chiedi al veterinario.',
    });
    return '$_temp0';
  }
}
