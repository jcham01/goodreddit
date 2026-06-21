# GoodReddit

GoodReddit est un outil Flutter personnel pour rechercher des subreddits,
classer les résultats, inspecter les posts/commentaires récents, puis générer
des fichiers `MEMORY.md` et `SKILL.md` à partir d'un échantillon Reddit.

Ce projet assume un usage personnel et expérimental. Il n'est pas, en l'état,
une base saine pour une distribution publique sans durcir l'accès Reddit, la
chaîne de release Android, la confidentialité LLM et la couverture de tests.

## Fonctionnalités

- Recherche de subreddits via une session navigateur Reddit.
- Scoring composite: activité, taille, matching lexical et score sémantique LLM
  quand une clé est configurée.
- Transparence du ranking: l'UI distingue maintenant `Heuristic only`,
  `LLM applied` et `LLM failed - heuristic fallback`.
- Lecture des meilleurs posts d'un subreddit et de commentaires associés.
- Génération de fichiers agent `MEMORY.md` et `SKILL.md`.
- Export JSON/CSV via la feuille de partage système.
- Historique local des recherches.
- Vérification de mise à jour Android depuis la dernière release GitHub.

## Stack

- Flutter / Dart
- `flutter_bloc` pour l'état
- `get_it` pour l'injection de dépendances
- `dartz` pour `Either<Failure, T>`
- `flutter_inappwebview` pour Reddit via WebView/session navigateur
- `dio` pour les appels LLM et GitHub releases
- `hive` pour l'historique local
- `flutter_secure_storage` pour les clés LLM

## Installation

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Le projet contient actuellement les plateformes Android et iOS. Il n'y a pas de
cible `web/` ou `macos/` versionnée.

## Configuration LLM

Ouvrir les settings dans l'app, choisir un fournisseur, renseigner une clé API,
puis sauvegarder.

Fournisseurs prévus:

- Anthropic Claude
- OpenAI
- Google Gemini

Sans clé API, le classement reste heuristique. Si une clé est présente mais que
l'appel LLM échoue, la recherche continue avec le ranking heuristique et l'UI
affiche le fallback au lieu de prétendre que l'IA a été utilisée.

## Limites Assumées

### Accès Reddit

GoodReddit n'utilise pas OAuth Reddit officiel. L'app charge Reddit dans une
WebView et exécute des requêtes JSON depuis l'origine `reddit.com` avec les
cookies de session du navigateur embarqué.

Conséquences:

- C'est fragile: un changement Reddit peut casser la recherche ou le scraping.
- Ce n'est pas une architecture à considérer comme robuste pour un produit
  public.
- La connexion Reddit reste dans le store de cookies de la WebView.

### Qualité du Scoring

Le score affiché n'est pas une probabilité de pertinence. C'est une combinaison
pondérée de signaux simples:

- activité
- nombre d'abonnés
- présence des mots de la requête dans nom/titre/description
- score sémantique LLM si disponible

Les poids sont arbitraires et doivent être calibrés si le produit devient plus
sérieux.

### Échantillon Scrapé

Le scraping récupère un échantillon limité: meilleurs posts récents et
commentaires sur une petite partie de ces posts. Les fichiers générés peuvent
donc refléter un moment ou un biais de sélection, pas "la vérité" complète d'une
communauté.

### Données Envoyées Aux LLM

Les prompts envoyés aux fournisseurs LLM contiennent des titres, descriptions,
posts, commentaires et usernames Reddit. Même si ces données sont publiques, il
faut considérer qu'elles quittent l'app vers le fournisseur choisi.

## Release Android

Voir aussi [RELEASING.md](RELEASING.md).

Point volontairement non traité pour le moment: le build release utilise encore
la signature debug et l'app peut proposer une installation d'APK depuis GitHub.
C'est pratique pour un outil perso, mais ce n'est pas acceptable pour une
distribution sérieuse.

À durcir plus tard:

- vraie clé de signature release
- CI de build reproductible
- vérification de hash/signature de l'APK téléchargé
- canal de distribution plus fiable que l'installation manuelle d'APK

## Tests

Commandes:

```sh
flutter analyze
flutter test
```

La couverture reste volontairement légère mais couvre maintenant:

- le scoring composite de base
- le cas sans LLM configuré
- le cas LLM appliqué
- le cas LLM en échec avec fallback heuristique visible

À ajouter ensuite:

- tests Bloc/UI pour les états de recherche
- tests de parsing Reddit
- tests de génération/export
- tests d'update/versioning
- tests de persistance historique

## Architecture

Le code est organisé par feature:

- `auth`: session Reddit WebView
- `search`: recherche et ranking subreddit
- `scraper`: posts/commentaires
- `generator`: génération et export des fichiers agent
- `settings`: fournisseur/modèle/clé LLM
- `history`: historique local
- `update`: vérification de release Android

Chaque feature suit globalement `data`, `domain`, `presentation`.
