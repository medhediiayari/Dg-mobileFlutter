import 'package:dgflow_rc/core/utils/format.dart';
import 'package:dgflow_rc/core/utils/parcours.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
    Intl.defaultLocale = 'fr_FR';
  });

  group('Montants (comme Intl fr-FR du RN)', () {
    test('séparateur fine insécable, espace insécable avant €', () {
      expect(Format.euros(1234567.891), '1 234 567,89 €');
      expect(Format.euros(1234.5), '1 234,50 €');
      expect(Format.euros(0), '0,00 €');
      expect(Format.euros(999), '999,00 €');
    });

    test('arrondi', () {
      expect(Format.euros(1326480.5, arrondi: true), '1 326 481 €');
      expect(Format.euros(-43519.5, arrondi: true), '-43 520 €');
    });

    test('absent', () {
      expect(Format.euros(null), '—');
      expect(Format.euros(double.nan), '—');
    });

    test('écarts signés', () {
      expect(Format.eurosSignes(1200), '+1 200,00 €');
      expect(Format.eurosSignes(-1520.4), '-1 520,40 €');
      expect(Format.eurosSignes(0), '0,00 €');
      expect(Format.eurosSignes(null), '—');
    });

    test('nombres et pourcentages', () {
      expect(Format.nombre(2850), '2 850');
      expect(Format.nombre(18.5), '18,5');
      expect(Format.pourcentage(60), '60 %');
      expect(Format.pourcentage(1.25), '1,25 %');
      expect(Format.pourcentage(null), '—');
    });
  });

  group('Dates', () {
    final d = DateTime(2026, 10, 19, 8, 5);

    test('date et heure', () {
      expect(Format.date(d), '19/10/2026');
      expect(Format.dateHeure(d), '19/10/2026 à 08:05');
      expect(Format.date(null), '—');
      expect(Format.dateIso('2027-04-15T00:00:00.000Z'), anyOf('15/04/2027', '14/04/2027'));
      expect(Format.dateIso('pas une date'), 'pas une date');
    });

    test('relatif', () {
      final m = DateTime(2026, 10, 19, 12);
      expect(Format.relatif(m.subtract(const Duration(seconds: 20)), maintenant: m), "à l'instant");
      expect(Format.relatif(m.subtract(const Duration(minutes: 5)), maintenant: m), 'il y a 5 min');
      expect(Format.relatif(m.subtract(const Duration(hours: 3)), maintenant: m), 'il y a 3 h');
      expect(Format.relatif(m.subtract(const Duration(hours: 30)), maintenant: m), 'hier');
      expect(Format.relatif(m.subtract(const Duration(days: 4)), maintenant: m), 'il y a 4 j');
      expect(Format.relatif(DateTime(2026, 9, 1), maintenant: m), '01/09/2026');
      expect(Format.relatif(null), '');
    });
  });

  group('Divers', () {
    test('tailles de fichier', () {
      expect(Format.taille(512), '512 o');
      expect(Format.taille(48 * 1024), '48 Ko');
      expect(Format.taille(2316800), '2,2 Mo');
    });

    test('version minimale', () {
      expect(Format.versionInferieure('1.0.0', '1.0.1'), isTrue);
      expect(Format.versionInferieure('1.2.0', '1.10.0'), isTrue);
      expect(Format.versionInferieure('2.0.0', '1.9.9'), isFalse);
      expect(Format.versionInferieure('1.0.0', '1.0.0'), isFalse);
      expect(Format.versionInferieure('1.0', '1.0.0'), isFalse);
      expect(Format.versionInferieure('1.0.0+3', '1.0.1'), isTrue);
    });

    test('pluriel', () {
      expect(Format.pluriel(1, 'document'), '1 document');
      expect(Format.pluriel(3, 'document'), '3 documents');
      expect(Format.pluriel(2, 'prix manquant', 'prix manquants'), '2 prix manquants');
    });
  });

  group('Position dans le parcours', () {
    test('brouillon', () {
      final p = positionParcours('draft');
      expect(p.index, 0);
      expect(p.mode, ModeParcours.brouillon);
      expect(p.phrase, 'Brouillon, chez le responsable de projet');
    });

    test('en attente', () {
      final p = positionParcours('approved_by_directeur_projet');
      expect(p.index, 2);
      expect(p.mode, ModeParcours.attente);
      expect(p.phrase, "Chez le directeur d'exploitation");
    });

    test('renvoi', () {
      final p = positionParcours('rejected_by_service_gestion_to_directeur_projet');
      expect(p.index, 1);
      expect(p.origine, 4);
      expect(p.mode, ModeParcours.renvoi);
      expect(p.phrase, 'Renvoyé au directeur projet par le SG');
      expect(positionParcours('rejected_by_directeur_exploitation').origine, 2);
      expect(positionParcours('rejected_by_responsable_etude_to_responsable_projet').index, 0);
    });

    test('terminé', () {
      final p = positionParcours('approved_by_service_gestion');
      expect(p.index, 5);
      expect(p.mode, ModeParcours.termine);
    });
  });
}
