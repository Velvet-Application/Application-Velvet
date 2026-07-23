# Velvet Product Changelog

Ce document retrace les décisions produit validées. Il ne remplace ni les ADR ni l'historique technique Git.

## 23 juillet 2026

### Gouvernance

- Validation du pilotage continu par roadmap, métriques et changelog.
- Validation de la règle : une ADR acceptée déclenche immédiatement sa documentation, la mise à jour des référentiels et un commit dédié.
- Le fichier `PROJECT-ROADMAP.md` devient la source officielle de pilotage du projet.

### ADR-020 — Modération hybride IA-first

- Analyse initiale par intelligence artificielle.
- Intervention humaine uniquement en cas d'incertitude, de signalement ou de risque élevé.
- Le contenu existant reste visible pendant l'examen, sauf risque nécessitant une mesure conservatoire.

### ADR-021 — Architecture des pseudonymes

- Pseudonymes libertins autorisés.
- Rejet limité aux insultes, à la haine, aux références aux mineurs ou à l'illégal, à l'usurpation et au spam.
- Nom d'affichage public et identifiant `@username` unique.
- Identité civile conservée dans le périmètre privé et sécurisé.

### ADR-022 — Vérification d'identité obligatoire

- Vérification d'identité obligatoire pour tous les membres.
- Aucun badge public de vérification, puisque cette condition est universelle.
- Documents chiffrés et accès strictement limité.
- Vérification automatisée complétée par une revue humaine si nécessaire.

### ADR-023 — Velvet Activity Index

- Suppression de l'affichage classique de dernière connexion.
- Catégories : Très actif, Actif cette semaine, Activité occasionnelle, Peu actif et En sommeil.
- Calcul fondé sur plusieurs signaux d'usage et non sur une simple présence en ligne.
- Priorisation raisonnable des membres actifs dans la découverte.
- Mode Absence facultatif.
- Indicateur de comportement de réponse sans publication d'heure précise.

## Entretien

Chaque ADR acceptée doit ajouter une entrée datée résumant la décision et ses impacts produit majeurs.