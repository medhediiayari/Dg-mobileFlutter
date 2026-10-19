import 'dart:io';

import '../models/models.dart';

enum TypeConsultation {
  document('DOCUMENT'),
  tableau('TABLEAU');

  const TypeConsultation(this.code);
  final String code;
}

/// Progression d'un envoi ou d'un téléchargement (octets).
typedef Progression = void Function(int fait, int total);

/// Contrat de l'API mobile DG Flow (`/mobile/v1`, le JSON de l'API de l'app React Native).
///
/// Deux implémentations : [ApiHttp] (réelle, dio) et `ApiDemo` (en mémoire,
/// mode démonstration et tests). Toutes deux renvoient les mêmes modèles,
/// lus par les mêmes `fromJson`.
abstract interface class DgFlowApi {
  /// Appelé quand la session est perdue (rafraîchissement refusé, session révoquée…).
  set surSessionExpiree(void Function()? rappel);

  // ─── Session ────────────────────────────────────────────────────────────
  Future<Meta> meta();

  /// Relit les jetons du coffre ; `true` s'il y en a.
  Future<bool> restaurerSession();

  Future<ReponseConnexion> connexion({
    required String email,
    required String motDePasse,
    String? appareil,
    String? plateforme,
  });

  Future<ReponseConnexion> connexionMicrosoft({required String accessToken, String? appareil, String? plateforme});

  /// Révoque la session côté serveur (au mieux) puis efface les jetons.
  Future<void> deconnexion();

  Future<Profil> moi();
  Future<Profil> changerRole(int roleId);
  Future<List<SessionAppareil>> sessions();
  Future<void> revoquerSession(String sid);
  Future<void> enregistrerAppareil({required String installationId, required String jeton, required String plateforme});
  Future<void> supprimerAppareil(String installationId);

  // ─── RC ─────────────────────────────────────────────────────────────────
  Future<ReponseListe> liste(FiltresListe filtres, {int page = 1, int limite = 25});
  Future<Detail> detail(int rcId);
  Future<Parcours> parcours(int rcId);
  Future<Tableau> tableau(int rcId);
  Future<Consultation> enregistrerConsultation(int rcId, TypeConsultation type);
  Future<ResultatDecision> approuver(int rcId, {String? commentaire});
  Future<ResultatDecision> rejeter(int rcId, {required String motif, int? destinataireId});
  Future<ResultatDecision> demanderInfo(int rcId, {required int destinataireId, required String message});
  Future<ResultatDecision> repondreInfo(int rcId, {required String message});
  Future<ResultatDecision> bonDeCommande(int rcId, {required bool actif});
  Future<ResultatPieces> envoyerPieces(int rcId, int evenementId, List<PieceLocale> pieces, {Progression? progression});
  Future<List<FichierDossier>> fichiers(int rcId);

  /// Télécharge un fichier servi par l'API (`/rc/:id/pieces/:pieceId`, `/rc/:id/export/...`)
  /// dans le cache de l'application.
  Future<File> telecharger(String chemin, String nom, {Progression? progression});

  // ─── Notifications ──────────────────────────────────────────────────────
  Future<PageNotifications> notifications({int? avant, int limite = 30, bool nonLuesSeulement = false});
  Future<int> nonLues();
  Future<void> marquerLue(int id);
  Future<int> toutLire();
}
