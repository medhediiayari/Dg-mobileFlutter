# DG Flow RC — application Flutter

Application iOS / Android du **Parcours RC** de DG Flow (reprise de l'app React Native
`mobile RC/mobile`). Elle appelle l'API mobile hébergée par **DG Flow web** (Next.js), préfixe
`/mobile/v1`, même contrat JSON que l'API de l'app React Native ; au démarrage, l'app lit
`GET /mobile/v1/meta`.

## Lancer

```powershell
flutter pub get

# Mode démonstration : API simulée en mémoire, aucune requête réseau
flutter run --dart-define=DEMO=true

# Mode réel (défaut) : DG Flow web sur http://10.0.2.2:3000 (émulateur Android) ou http://localhost:3000
flutter run
flutter run --dart-define=API_URL=http://192.168.1.20:3000   # téléphone : l'IP du PC, jamais localhost
```

Les builds `debug` / `profile` Android autorisent le http en clair (API locale) ; un build
`release` n'accepte que https.

## Vérifier

```powershell
flutter analyze          # aucun problème attendu
flutter test             # modèles, format, client HTTP (rafraîchissement), API de démo, écrans
flutter build apk --debug
```

## Organisation

| Dossier | Contenu |
|---|---|
| `lib/core/api` | contrat `DgFlowApi`, client dio (jeton, rafraîchissement sérialisé), implémentation HTTP |
| `lib/core/models` | modèles typés et `fromJson` tolérants (nombres JS, Decimal en chaîne) |
| `lib/core/auth` | session (démarrage, connexion, rôle actif), coffre sécurisé, Microsoft (AppAuth) |
| `lib/core/push` | FCM + notifications locales ; désactivé proprement sans configuration Firebase |
| `lib/core/demo` | API de démonstration : mêmes règles et même JSON que l'API réelle |
| `lib/features/*` | écrans : connexion, À traiter, Suivi, fiche, tableau, fichiers, décision, alertes, profil |
| `lib/ui` | design du web DG Flow : jetons (`jetons_web.dart`), thème clair / sombre, composants partagés — voir `../docs/design-web.md` |
| `test/fixtures` | réponses JSON calquées sur le backend RN |

## Configuration à compléter

- **Firebase** : déposer `android/app/google-services.json` (application `fr.dggroup.dgflow.rcflutter`)
  — le plugin google-services (déclaré dans `android/settings.gradle.kts`) ne s'applique que si le
  fichier existe — et, sur Mac, glisser `GoogleService-Info.plist` dans Xcode (cible *Runner*).
  La capacité push iOS est déjà déclarée (`ios/Runner/Runner.entitlements`, mode d'arrière-plan
  `remote-notification`). Détails : README racine, « Notifications push ».
- **Microsoft Entra ID** : redirection `dgflowrcflutter://auth` à déclarer sur l'inscription
  mobile ; le bouton apparaît quand `/meta` renvoie `sso.microsoft`.
- **Signature release Android** : `android/app/build.gradle.kts` signe encore avec la clé debug.
