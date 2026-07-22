# Instructions de développement pour CODEX

## Mission

Construire Velvet à partir de la documentation versionnée dans ce dépôt, sans remplacer une décision produit par une supposition technique. Velvet doit rester élégant, confidentiel, inclusif, sûr et simple à utiliser.

## Lecture obligatoire avant une tâche

1. `AGENTS.md`
2. `docs/00-GOVERNANCE/DECISION-REGISTRY.md`
3. `docs/02-PRODUCT/FEATURE-MAP.md`
4. `docs/01-BRAND/IMPLEMENTATION-GUIDE.md` pour toute tâche UI
5. `docs/01-BRAND/DESIGN-TOKENS.json` pour toute valeur visuelle
6. Les ADR et spécifications du domaine concerné
7. `docs/10-TECH/V1-DELIVERY-BLUEPRINT.md`
8. `docs/11-ROADMAP/V1-SCOPE-AND-ACCEPTANCE.md`

## Source de vérité

Ordre de priorité :

1. ADR validé le plus récent
2. Registre des décisions
3. Product Bible
4. Spécifications UX et fonctionnelles
5. Design system et tokens
6. Blueprint technique V1
7. Roadmap et critères d'acceptation
8. Notes fondateur, uniquement comme contexte

## Contrôle anti-régression produit

Avant de proposer une question, une règle ou une fonctionnalité :

- rechercher ses mots-clés dans le registre des décisions ;
- rechercher dans les ADR ;
- vérifier qu'elle n'a pas déjà été validée sous un autre nom ;
- traiter une idée compatible comme une extension, pas comme un nouvel arbitrage ;
- rédiger un ADR d'amendement lorsqu'elle contredit une décision existante.

Ne jamais rouvrir silencieusement un sujet validé.

## Règles impératives

- Ne jamais inventer une règle métier manquante.
- Marquer tout manque par `TBD` et créer une issue si cela bloque.
- Ne pas modifier un comportement validé sans nouvel ADR.
- Préserver la confidentialité par défaut et appliquer le principe du moindre privilège.
- Implémenter les contrôles de consentement côté serveur.
- Ne jamais simuler une capacité indisponible sur une plateforme.
- Toute action sensible doit être traçable et testable.
- Ne jamais committer de secret, média intime réel ou donnée personnelle de production.
- Les données de démonstration doivent être manifestement fictives.

## Fidélité visuelle

- Utiliser les tokens canoniques, jamais des couleurs approximatives.
- Logo : V ruban bordeaux/rose, VELVET en or champagne.
- Ne pas générer un V doré générique.
- Respecter les espaces publics plus ouverts et les espaces privés plus profonds.
- Éviter toute imagerie vulgaire, explicite ou stéréotypée.
- Prioriser la lisibilité, les visages, la complicité et les photographies raffinées.
- Toute maquette doit montrer les états de chargement, vide, erreur, désactivé et succès lorsque pertinent.

## Workflow attendu

1. Lire les sources obligatoires.
2. Résumer les décisions applicables dans le plan de travail.
3. Produire un plan d'implémentation court et vérifiable.
4. Identifier données, permissions, migrations, API et événements analytics concernés.
5. Créer ou mettre à jour les tests avant la livraison.
6. Implémenter par petites unités cohérentes.
7. Vérifier les critères d'acceptation et les cas limites.
8. Documenter toute nouvelle variable d'environnement, migration ou limitation.
9. Mettre à jour la documentation et le registre lorsqu'une décision évolue.

## Qualité minimale

- Typage strict.
- Validation des entrées côté client et serveur.
- Gestion explicite des erreurs.
- Tests unitaires sur les règles métier.
- Tests d'intégration sur authentification, consentement, invitations, conversations, permissions et médias.
- Tests end-to-end sur les parcours critiques V1.
- Journalisation structurée sans données intimes en clair.
- Accessibilité et responsive mobile-first.
- Sécurité des téléchargements et des URLs signées.
- Idempotence des actions critiques lorsque nécessaire.

## Definition of Done

Une fonctionnalité n'est terminée que si :

- le code est testé ;
- les états vides, chargement et erreur existent ;
- les permissions serveur sont vérifiées ;
- les événements analytics nécessaires sont documentés ;
- les textes sensibles respectent le ton Velvet ;
- les critères d'acceptation sont couverts ;
- l'accessibilité de base est vérifiée ;
- aucune donnée intime n'apparaît dans les logs ou notifications ;
- la documentation est mise à jour.

## Modules déjà normés

Le chantier `Velvet Conversations` dispose d'ADR détaillés dans `docs/04-VELVET-CONVERSATIONS/`. Les décisions de marque, profils, consentement, confiance et notifications sont indexées dans le registre.

## Arbitrages

En cas de contradiction ou d'ambiguïté, ne pas choisir silencieusement. Documenter le conflit, identifier les documents concernés et demander un arbitrage produit.
