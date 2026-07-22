# Velvet OS

Velvet OS est la source de vérité produit, UX et technique de Velvet. Ce dépôt doit permettre à une équipe de développement ou à CODEX de comprendre ce qui est validé, ce qui reste à arbitrer et dans quel ordre construire la maquette V1 puis la version de production.

## Démarrage rapide pour CODEX

Lire dans cet ordre :

1. `CODEX.md`
2. `PROJECT_CONTEXT.md`
3. `docs/02-PRODUCT/PRODUCT_BIBLE.md`
4. `docs/10-TECH/V1-DELIVERY-BLUEPRINT.md`
5. `docs/11-ROADMAP/V1-SCOPE-AND-ACCEPTANCE.md`
6. Les ADR du module concerné

## Hiérarchie documentaire

1. `docs/00-GOVERNANCE/` — règles de décision et de contribution
2. `docs/00-VISION/` — vision et principes fondateurs
3. `docs/01-BRAND/` — identité et ton
4. `docs/02-PRODUCT/` — Product Bible et périmètre fonctionnel
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

## Règles de vérité

- Une décision explicitement validée est normative.
- Une proposition non validée est marquée `TBD` et ne doit pas être codée comme une règle définitive.
- Une décision validée produit un ADR et un commit Git dédié.
- En cas de conflit, l'ADR le plus récent remplace l'ancien.
- CODEX ne doit pas inventer une règle métier manquante : il crée un point `TBD` ou une issue.

## État actuel

Le dépôt contient le socle documentaire de Velvet et les premières décisions détaillées du chantier Velvet Conversations. La structure technique V1 est conçue pour transformer progressivement la documentation en backlog exécutable, maquette fonctionnelle puis application prête à déployer.
