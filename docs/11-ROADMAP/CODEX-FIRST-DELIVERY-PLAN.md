# Plan de livraison Codex-first

Statut : **PLANNED**

## Stratégie

La V1 est livrée par tranches verticales utilisables. Chaque tranche doit traverser interface, données, permissions, API, tests et documentation. Les développements Community et Professionals avancent en parallèle uniquement après stabilisation du Platform Core.

## Phase 0 — Préparation

- audit du dépôt et des ADR ;
- choix final de la stack ;
- conventions de code ;
- environnements local, preview et production ;
- CI, lint, tests, migrations et gestion des secrets ;
- registre des risques et décisions techniques.

**Sortie :** squelette exécutable, déployé en preview, sans fonctionnalité métier.

## Phase 1 — Platform Core

- authentification ;
- identité et majorité ;
- profils de base ;
- rôles Member, Professional, Staff et Admin ;
- permissions et Row Level Security ;
- stockage privé ;
- journal d’audit ;
- notifications transactionnelles ;
- observabilité et sauvegardes.

**Sortie :** création de compte, onboarding minimal et administration des rôles.

## Phase 2 — Community Essential

- profils individuels et couple ;
- médias publics et privés ;
- autorisations d’albums ;
- recherche et découverte ;
- favoris, demandes de contact ;
- messagerie ;
- blocage et signalement ;
- confidentialité et carte approximative.

**Sortie :** première boucle communautaire complète et testable.

## Phase 3 — Professionals Essential

- onboarding professionnel ;
- établissements et équipes ;
- événements ;
- capacité, tarifs et conditions ;
- inscriptions, réservations et liste d’attente ;
- QR code et check-in ;
- tableau de bord opérationnel.

**Sortie :** premier événement pilote géré intégralement dans Velvet.

## Phase 4 — Convergence

- événements visibles dans la découverte Community ;
- réservation depuis un profil membre ;
- historique et notifications communes ;
- avis vérifiés après présence ;
- recommandations simples basées sur critères explicites ;
- analytics produit et professionnel.

**Sortie :** boucle B2B2C unifiée.

## Phase 5 — Paiement et monétisation pilote

- prestataire de paiement validé ;
- paiement événementiel ;
- commissions configurables ;
- remboursements ;
- facturation professionnelle minimale ;
- abonnement pilote si la proposition de valeur est confirmée.

**Sortie :** première transaction réelle et traçable.

## Phase 6 — Hardening avant ouverture

- audit de sécurité externe ;
- revue RGPD et juridique ;
- tests de charge ciblés ;
- restauration de sauvegarde ;
- procédures d’incident ;
- accessibilité et compatibilité mobile ;
- suppression des données de démonstration.

**Sortie :** autorisation humaine explicite de mise en production publique.

## Mode de travail Codex

Pour chaque lot, Codex doit :

1. lire les documents obligatoires ;
2. produire un plan et identifier les `TBD` ;
3. créer une branche courte ;
4. implémenter une tranche verticale ;
5. ajouter ou mettre à jour les tests ;
6. exécuter les contrôles locaux ;
7. mettre à jour la documentation ;
8. ouvrir une pull request détaillée ;
9. ne jamais fusionner sans validation humaine.

## Limites de travail en parallèle

Le parallélisme est autorisé lorsque les agents travaillent sur des domaines sans fichiers partagés. Les migrations, permissions, composants globaux, contrats d’API et tokens de design exigent un propriétaire unique par lot.

## Gate de poursuite

Aucune phase ne démarre si la précédente présente :

- une faille critique connue ;
- des permissions non testées ;
- une migration non reproductible ;
- un parcours principal cassé ;
- une décision métier bloquante non arbitrée.
