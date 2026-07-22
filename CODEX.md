# Instructions de développement pour CODEX

## Mission
Construire Velvet à partir de la documentation versionnée dans ce dépôt, sans remplacer une décision produit par une supposition technique.

## Source de vérité
Ordre de priorité :
1. ADR validés
2. Product Bible
3. Spécifications UX et fonctionnelles
4. Blueprint technique V1
5. Roadmap et critères d'acceptation
6. Notes fondateur, uniquement comme contexte

## Règles impératives
- Ne jamais inventer une règle métier manquante.
- Marquer tout manque par `TBD` et créer une issue si cela bloque.
- Ne pas modifier un comportement validé sans nouvel ADR.
- Préserver la confidentialité par défaut et appliquer le principe du moindre privilège.
- Implémenter les contrôles de consentement côté serveur.
- Ne jamais simuler une capacité indisponible sur une plateforme.
- Toute action sensible doit être traçable et testable.

## Workflow attendu
1. Lire les ADR du domaine.
2. Produire un plan d'implémentation court.
3. Créer ou mettre à jour les tests avant la livraison.
4. Implémenter par petites unités cohérentes.
5. Vérifier les critères d'acceptation.
6. Documenter toute nouvelle variable d'environnement, migration ou limitation.
7. Ne jamais committer de secret.

## Qualité minimale
- Typage strict.
- Validation des entrées côté client et serveur.
- Gestion explicite des erreurs.
- Tests unitaires sur les règles métier.
- Tests d'intégration sur authentification, consentement, invitations, conversations et médias.
- Tests end-to-end sur les parcours critiques V1.
- Journalisation structurée sans données intimes en clair.
- Accessibilité et responsive mobile-first.

## Definition of Done
Une fonctionnalité n'est terminée que si :
- le code est testé ;
- les états vides, chargement et erreur existent ;
- les permissions serveur sont vérifiées ;
- les événements analytics nécessaires sont documentés ;
- les textes sensibles respectent le ton Velvet ;
- les critères d'acceptation sont couverts ;
- la documentation est mise à jour.

## Modules déjà normés
Le chantier `Velvet Conversations` dispose d'ADR détaillés dans `docs/04-VELVET-CONVERSATIONS/`.

## Arbitrages
En cas de contradiction ou d'ambiguïté, ne pas choisir silencieusement. Documenter le conflit et demander un arbitrage produit.
