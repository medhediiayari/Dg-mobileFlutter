/// Erreur renvoyée par l'API : `{ "error": "<message affichable>", "code": "<CODE_STABLE>" }`.
///
/// `code` pilote l'interface (CONSULTATION_REQUISE, SIGNATURE_MANQUANTE…),
/// `message` est en français et s'affiche tel quel.
class ApiException implements Exception {
  const ApiException(this.statut, this.message, this.code, [this.details]);

  /// Statut HTTP ; 0 pour un problème réseau.
  final int statut;
  final String message;
  final String code;
  final Map<String, dynamic>? details;

  bool get reseau => code == codeReseau;

  /// Erreur métier (4xx) : inutile de réessayer automatiquement.
  bool get metier => statut >= 400 && statut < 500;

  /// La garde de consultation a refusé la décision (409).
  bool get gardeConsultation =>
      code == 'CONSULTATION_REQUISE' || code == 'CONSULTATION_PERIMEE' || code == 'CONSULTATION_TABLEAU_REQUISE';

  static const String codeReseau = 'NETWORK';

  /// Codes qui ferment la session côté app.
  static const Set<String> codesSessionPerdue = {
    'REFRESH_INVALID',
    'SESSION_REVOKED',
    'ACCESS_CHANGED',
    'ACCOUNT_DISABLED',
    'TOKEN_INVALID',
  };

  @override
  String toString() => message;
}

/// Message affichable pour n'importe quelle erreur.
String messageErreur(Object? e) {
  if (e is ApiException) return e.message;
  if (e is FormatException) return 'Réponse inattendue du serveur.';
  return 'Une erreur est survenue';
}
