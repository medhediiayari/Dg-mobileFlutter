# DG Flow RC — Application Flutter

Application mobile **Flutter** (Android / iOS) du **Parcours RC** de DG Flow : les valideurs du
circuit (Directeur Projet → Directeur d'Exploitation → Directeur d'Études → Service Gestion)
consultent, approuvent, rejettent ou renvoient les **RC et avenants**, demandent ou répondent à une
information, et chacun suit le parcours de ses documents.

Même principe que l'application React Native (`mobile RC/`), avec **le design du web DG Flow** :
mêmes couleurs, mêmes polices (IBM Plex Sans / Mono), mêmes icônes (Lucide), mêmes codes visuels
pour les statuts, le parcours et les décisions. Toutes les références graphiques relevées dans le
web et leur équivalent Flutter sont dans **[`docs/design-web.md`](docs/design-web.md)**.

**L'application est uniquement un front.** Ses API sont servies par **DG Flow web** (Next.js,
`C:\Users\user\Desktop\dgflow`), sous le préfixe **`/mobile/v1`** :

```
 ┌──────────────────────┐   HTTPS (JSON)   ┌──────────────────────────────────────┐
 │ App Flutter (app/)   │ ───────────────► │ DG Flow web (Next.js)                │
 │ Android / iOS        │   /mobile/v1/*   │  app/mobile/v1/**  ← API de l'app    │
 └──────────▲───────────┘ ◄─────────────── │  lib/mobile/**     ← jetons, audit…  │
            │ push FCM                     │  lib/*             ← règles du web   │
            │                              └───────┬──────────────────┬───────────┘
 ┌──────────┴───────────┐                          │ Prisma           │ S3
 │ Firebase / APNs      │                  ┌───────▼──────┐   ┌───────▼──────┐
 └──────────────────────┘                  │ PostgreSQL   │   │ MinIO dg-flow│
                                           │ DG Flow      │   │              │
                                           └──────────────┘   └──────────────┘
```

- **Même base, même bucket, mêmes règles que le web** : les routes `/mobile/v1` appellent
  directement les bibliothèques du web (statuts, garde de consultation, paiement, approbation SG,
  notifications, emails, exports Excel, journal d'audit). Rien n'est copié ni réécrit.
- Le web n'est pas modifié dans son fonctionnement : ses routes `/api/*`, son middleware et son
  RBAC sont inchangés ; l'API mobile vit à part (`app/mobile/v1`) avec sa propre authentification
  par jeton.
- Documentation de l'API : **`dgflow/docs/API_MOBILE.md`**.

---

## API : uniquement les routes `/mobile/v1` de DG Flow web

L'app Flutter n'appelle **que** les nouvelles routes **`/mobile/v1/*`**, ajoutées au backend de
DG Flow web (`dgflow/app/mobile/v1/**`). Elle n'a pas d'autre backend. Elle n'appelle ni les
routes `/api/*` du web, réservées au navigateur et authentifiées par cookie, ni l'API de l'app
React Native.

L'adresse appelée est `API_URL` + `/mobile/v1` (`app/lib/core/config/app_config.dart`) :

| Écran / fonction | Routes consommées |
|---|---|
| Démarrage, connexion | `GET /meta`, `POST /auth/login`, `POST /auth/microsoft`, `POST /auth/refresh`, `POST /auth/logout` |
| Profil | `GET /me`, `POST /me/role-actif`, `GET·DELETE /me/sessions`, `POST·DELETE /me/appareils` (jeton push) |
| À traiter, Suivi | `GET /rc` |
| Fiche RC, tableau, fichiers | `GET /rc/:id`, `/parcours`, `/tableau`, `/fichiers`, `/pieces/:id`, `/export/document`, `/export/tableau`, `POST /rc/:id/consultations` |
| Décisions | `POST /rc/:id/approuver`, `/rejeter`, `/demande-info`, `/reponse-info`, `/bon-de-commande`, `/evenements/:id/pieces` |
| Alertes | `GET /notifications`, `/notifications/non-lues`, `POST /notifications/:id/lue`, `/notifications/tout-lire` |

## Base de données : une seule, celle du web, sans synchronisation

- **Il n'y a qu'une base** : la base PostgreSQL de DG Flow web. Le web et l'app mobile lisent et
  écrivent les **mêmes tables**. Les fichiers sont dans le **même bucket MinIO** `dg-flow`.
- **Aucune synchronisation** à prévoir : pas de base mobile, pas de copie, pas de tâche de
  synchro. Une décision prise dans l'app est visible immédiatement sur le web, et inversement.
  Les notifications, emails et lignes du journal d'audit sont les mêmes.
- **Aucune table ajoutée, aucune migration** : les sessions mobiles et les jetons push sont
  rangés dans la table existante `user_preferences`.
- **Sur le téléphone**, l'app ne garde que la session (jetons, dans le stockage sécurisé),
  l'identifiant de l'installation (push), le dernier email saisi et le thème. Les données RC sont toujours relues depuis l'API. Les pièces
  ouvertes sont téléchargées dans un dossier temporaire.

---

## Contenu

```
flutterDgflow/
├── README.md          ← ce fichier
├── app/               ← application Flutter (README propre : app/README.md)
│   ├── lib/core/      ← client API, modèles, session, push, mode démonstration
│   ├── lib/features/  ← écrans : connexion, À traiter, Suivi, fiche, tableau, décision, alertes, profil
│   ├── lib/ui/        ← jetons du web (jetons_web.dart), thème clair / sombre, composants
│   └── test/          ← 67 tests (modèles, client HTTP, démonstration, écrans)
├── docs/design-web.md ← design du web repris par l'app : couleurs, polices, icônes, composants
└── docs/captures/     ← captures d'écran (design du web, clair et sombre)
```

---

## Démarrage rapide

### 1. API — DG Flow web

Dans `C:\Users\user\Desktop\dgflow` :

1. Secret de l'API mobile dans **`.env.local`** (non versionné) — déjà créé sur ce poste :
   ```
   MOBILE_JWT_SECRET=<48 octets hexadécimaux>     # node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
   ```
   Sans ce secret, `/mobile/v1/*` répond 503 `MOBILE_API_DISABLED` (le site web, lui, fonctionne).
2. Lancer le web comme d'habitude (`npm run dev`, ou `npm run build` puis `npm start`).
3. Contrôle : `curl http://localhost:3000/mobile/v1/meta`
   → `{"api":"1.0.0","versionMinimaleApp":"1.0.0","sso":{"microsoft":null}}`

> ⚠️ En local, laisser `MAIL_*` vides dans le `.env` du web : sinon chaque décision prise depuis
> l'app envoie de vrais emails aux vrais utilisateurs.

### 2. Application

```powershell
cd flutterDgflow\app
flutter pub get
flutter run                                                    # émulateur Android → http://10.0.2.2:3000
flutter run --dart-define=API_URL=http://192.168.1.20:3000     # téléphone sur le Wi-Fi : IP du PC
flutter run --dart-define=DEMO=true                            # démonstration, sans API ni compte
```

Se connecter avec un compte DG Flow (mêmes identifiants que le web).

### Vérifier

```powershell
# App
cd flutterDgflow\app
flutter analyze ; flutter test ; flutter build apk --debug

# API mobile (dans dgflow)
npx vitest run tests/mobile-api.test.ts
```

---

## Notifications push (Firebase)

L'app est prête : il ne manque que le projet Firebase. Sans ses fichiers, l'app fonctionne
normalement et Profil → Notifications indique « Firebase non configuré ».

**Côté app :**

1. Console Firebase → projet DG Flow → *Ajouter une application* **Android**, nom de package
   `fr.dggroup.dgflow.rcflutter` → télécharger `google-services.json` dans `app/android/app/`.
   Gradle l'intègre automatiquement au prochain build. Ces fichiers ne sont pas versionnés.
2. iOS, sur Mac : application **Apple**, bundle `fr.dggroup.dgflow.rcflutter`.
   - Glisser `GoogleService-Info.plist` dans Xcode (`app/ios/Runner.xcworkspace`, cible *Runner*,
     cocher *Copy items if needed*).
   - Firebase → Paramètres → Cloud Messaging → importer la **clé APNs** (.p8) du compte Apple
     Developer.
   - La capacité *Push Notifications* (`Runner/Runner.entitlements`) et le mode d'arrière-plan
     *remote-notification* sont déjà déclarés.
3. Reconstruire l'app (`flutter run` ou `flutter build apk`).

**Côté web** (`dgflow/.env.local`, puis redémarrer le web) :

```
FCM_SERVICE_ACCOUNT_FILE=C:\chemin\vers\dgflow-firebase-service-account.json   # Firebase → Paramètres → Comptes de service → Générer une clé privée
MOBILE_PUSH_RELAY_ENABLED=true
```

En production, utiliser le secret Swarm `fcm_service_account_json` à la place.

**Fonctionnement :**

- À la connexion, l'app demande l'autorisation (Android 13+, iOS), obtient le jeton FCM et le
  déclare à `POST /mobile/v1/me/appareils`. Le jeton est mis à jour quand il change, retiré à la
  déconnexion et depuis Profil → Notifications.
- Le relais du web lit la table `notifications` toutes les 15 s et pousse chaque notification RC
  vers les téléphones de son destinataire.
- App au premier plan : notification locale. App en arrière-plan ou fermée : notification
  système, canal Android « Circuit de validation RC », badge = non lues.
- Toucher la notification ouvre la fiche du RC et marque la notification comme lue.

**Tester :** se connecter dans l'app. Le web journalise
`[push] relais FCM de l'app mobile démarré`. Ensuite, une action RC sur le web qui notifie ce
compte (renvoi, demande d'information, document à traiter) arrive sur le téléphone en moins de
15 s. Émulateur Android : utiliser une image *Google Play*.

## Connexion Microsoft (optionnel)

Inscription Entra ID « client public » avec la redirection `dgflowrcflutter://auth`, puis
`AZURE_AD_MOBILE_CLIENT_ID` côté web (le tenant est `AZURE_AD_TENANT_ID` du web). Le bouton
apparaît automatiquement dans l'app (lu via `/mobile/v1/meta`).

## Builds

| Commande | Usage |
|---|---|
| `flutter build apk --debug` | APK de test (http autorisé pour l'API locale) |
| `flutter build appbundle --release` | Google Play (https uniquement) — configurer la signature release |
| `flutter build ipa` (Mac) | App Store / TestFlight — bundle `fr.dggroup.dgflow.rcflutter` |

En production, l'API doit être en **HTTPS** (nom public du web) : passer
`--dart-define=API_URL=https://<domaine DG Flow>` au build.

---

## Ce qui a été vérifié

- **App** : `flutter analyze` sans problème, 67 tests verts, parcours complet en démonstration sur
  émulateur Android avec le design du web, clair et sombre (12 captures dans `docs/captures/`),
  mode réel jusqu'à l'écran de connexion.
- **API `/mobile/v1` (web)** : TypeScript sans erreur sur les fichiers mobiles, 13 tests unitaires
  (jetons, configuration, enveloppe des routes, `/meta`), et **608/608 réponses de lecture
  identiques** à l'API mobile React Native sur la base de développement (liste, fiche, tableau,
  parcours, fichiers — 4 rôles, 84 documents, lecture seule).
- **Non testé** : connexion réelle et décisions de bout en bout depuis l'app (aucun compte de test
  disponible), notifications push réelles (Firebase non configuré), SSO Microsoft, build iOS.
