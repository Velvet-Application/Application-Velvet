# Velvet OS

Velvet OS est la source de vérité produit, UX, marque et technique de Velvet. Ce dépôt doit permettre à une équipe de développement ou à CODEX de comprendre ce qui est validé, ce qui reste à arbitrer et dans quel ordre construire la maquette V1 puis la version de production.

## Démarrage rapide pour CODEX

Lire dans cet ordre :

1. `AGENTS.md`
2. `CODEX.md`
3. `docs/00-GOVERNANCE/DECISION-REGISTRY.md`
4. `PROJECT_CONTEXT.md`
5. `docs/02-PRODUCT/FEATURE-MAP.md`
6. `docs/02-PRODUCT/PRODUCT_BIBLE.md`
7. `docs/01-BRAND/IMPLEMENTATION-GUIDE.md` pour toute tâche UI
8. `docs/01-BRAND/DESIGN-TOKENS.json` pour les valeurs visuelles
9. `docs/10-TECH/V1-DELIVERY-BLUEPRINT.md`
10. `docs/11-ROADMAP/V1-SCOPE-AND-ACCEPTANCE.md`
11. Les ADR du module concerné

## Réflexe obligatoire

Avant toute nouvelle question produit ou modification fonctionnelle, vérifier le registre des décisions et les ADR. Un sujet déjà validé ne doit pas être rouvert sans ADR d'amendement.

## Hiérarchie documentaire

1. `docs/00-GOVERNANCE/` — règles de décision, registre et contribution
2. `docs/00-VISION/` — vision et principes fondateurs
3. `docs/01-BRAND/` — identité, tokens et ton
4. `docs/02-PRODUCT/` — Product Bible et carte fonctionnelle
5. `docs/03-ADR/` — décisions transverses
6. `docs/04-VELVET-CONVERSATIONS/` — décisions du chantier Conversations
7. `docs/04-FEATURES/` — spécifications par fonctionnalité
8. `docs/05-UX/` — parcours et règles d'interface
9. `docs/06-AI/` — Velvet Intelligence et Velvet Memory
10. `docs/07-PROFESSIONALS/` — espace professionnel
11. `docs/08-EVENTS/` — événements, sorties et voyages
12. `docs/09-BUSINESS/` — modèle économique
13. `docs/10-TECH/` — architecture et livraison
14. `docs/11-ROADMAP/` — versions, priorités et critères d'acceptation
15. `docs/12-FOUNDER-NOTES/` — notes non normatives
16. `docs/13-HISTORY/` — historique du projet

## Identité Velvet canonique

- Logo : V ruban bordeaux/rose, logotype or champagne.
- Signature : « Là où les plus belles rencontres commencent. »
- Couleurs principales : Noir Velvet `#0D0D0D`, Anthracite `#1B1B1D`, Gris Velours `#2D2D30`, Blanc cassé `#F4F4F2`, Bordeaux Velvet `#641B36`, Or Champagne `#C6A96A`.
- Direction : sombre, cinématographique, élégante, intime, inclusive et jamais vulgaire.

## Règles de vérité

- Une décision explicitement validée est normative.
- Une proposition non validée est marquée `TBD` et ne doit pas être codée comme une règle définitive.
- Une décision validée produit un ADR et un commit Git dédié.
- En cas de conflit, l'ADR le plus récent remplace l'ancien.
- CODEX ne doit pas inventer une règle métier manquante : il crée un point `TBD` ou une issue.
- Toute action sensible respecte la confidentialité par défaut, le consentement et le moindre privilège.

## État actuel

Le dépôt contient le socle documentaire de Velvet, les décisions détaillées du chantier Velvet Conversations, les principes de marque, les profils dynamiques, le Pacte Velvet, le Trust Index et les notifications confidentielles. La structure technique V1 doit transformer progressivement la documentation en backlog exécutable, maquette fonctionnelle puis application prête à déployer.
