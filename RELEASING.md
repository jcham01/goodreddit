# Publier une mise à jour (Android)

Au lancement sur Android, l'app interroge la dernière release GitHub de
`jcham01/goodreddit` (voir `ApiConstants.githubRepo`) et propose un dialogue de
mise à jour si la version publiée est plus récente que la version installée.
L'APK est téléchargé via le navigateur depuis l'asset de la release.

## Pré-requis (une seule fois)

1. Créer le repo GitHub — il doit être **public** pour que l'API
   `releases/latest` soit accessible sans authentification depuis l'app :

   ```sh
   git init
   git add -A && git commit -m "Initial commit"
   gh repo create jcham01/goodreddit --public --source=. --push
   ```

   Si le nom du repo diffère, mettre à jour `ApiConstants.githubRepo`.

## À chaque release

1. Incrémenter `version:` dans `pubspec.yaml` (ex. `1.1.0+2`).
2. Commit + push.
3. Construire l'APK **sur cette machine** :

   ```sh
   flutter build apk --release
   ```

4. Créer la release avec l'APK en asset — le tag doit être `v<version>` :

   ```sh
   gh release create v1.1.0 build/app/outputs/flutter-apk/app-release.apk \
     --title "v1.1.0" --notes "Description des changements"
   ```

Le corps de la release (`--notes`) est affiché tel quel dans le dialogue de
mise à jour de l'app.

## ⚠️ Signature

Android refuse d'installer une mise à jour signée avec une clé différente de
celle de l'app installée. Le build release utilise actuellement la config de
signature **debug** (`android/app/build.gradle.kts`), c'est-à-dire le keystore
debug de cette machine (`~/.android/debug.keystore`).

Conséquences :

- Construire les APK de release **toujours depuis cette machine** (ou copier le
  keystore), sinon la mise à jour échouera à l'installation.
- Pour builder en CI (GitHub Actions), il faudra d'abord créer un vrai keystore
  de release et l'injecter en secret.
