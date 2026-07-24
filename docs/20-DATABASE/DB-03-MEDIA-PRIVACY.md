# DB-03 — Médias, albums et confidentialité

## Objectif

DB-03 fournit le socle de stockage logique, de visibilité et d'autorisation des photos et vidéos Velvet. Le modèle doit empêcher qu'une simple URL de stockage devienne un droit d'accès.

## Principes invariants

- Un objet média est privé par défaut.
- Les fichiers bruts ne sont jamais référencés directement dans les profils publics.
- Toute consultation est décidée par la base à partir du profil actif, du niveau de visibilité, d'une éventuelle autorisation et de sa date d'expiration.
- La suppression fonctionnelle est immédiate ; la purge physique peut être différée et auditée.
- Une autorisation d'album privé est révocable à tout moment.
- Une autorisation accordée à un profil ne vaut pas pour les autres profils gérés par le même compte.
- Les médias identifiants d'un profil couple suivent le double consentement défini par DB-01.
- Les métadonnées sensibles, empreintes techniques et résultats de modération ne sont pas exposés aux clients.

## Entités

### media_assets

Registre d'un fichier logique : propriétaire, type, statut de traitement, dimensions, durée, hash, chemin de stockage et niveau de sensibilité.

### media_albums

Collection ordonnée appartenant à un profil. Visibilité possible : `public`, `members`, `private`, `temporary` ou `hidden`.

### media_album_items

Association ordonnée entre album et média, avec légende facultative.

### media_access_grants

Autorisation explicite d'un profil source vers un profil bénéficiaire, avec portée, expiration et révocation.

### media_moderation_cases

Résultats internes de modération, accessibles uniquement au service role.

## Autorisations

- `public` : visible uniquement lorsque le profil est actif et découvrable.
- `members` : visible aux membres actifs du profil propriétaire.
- `private` : visible aux membres du profil propriétaire et aux profils disposant d'un grant actif.
- `temporary` : identique à `private`, mais le grant doit obligatoirement expirer.
- `hidden` : jamais visible via les lectures clientes.

## Commandes publiques

Les écritures directes sont interdites. Les mutations passent par des fonctions `security definer` : création d'album, ajout/retrait de média, demande d'accès, octroi, révocation et suppression logique.

## Double consentement couple

La publication d'un média identifiant, l'ouverture d'un album privé et les changements de visibilité sensibles utilisent `profile_sensitive_actions`. L'exécution est atomique après toutes les approbations requises.

## Stockage

Le bucket Supabase reste privé. La base retourne seulement un droit logique. Une Edge Function générera ensuite une URL signée courte après réévaluation de l'autorisation.

## Validation

```bash
npx supabase db reset
npx supabase test db
npx supabase db lint --level error
```
