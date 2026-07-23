# Velvet Project Roadmap

**Statut :** source officielle de pilotage du projet Velvet.

**Dernière mise à jour :** 23 juillet 2026

## Règles de gouvernance

- Une seule décision structurante est traitée à la fois.
- Une ADR validée est définitive et ne peut être rouverte sans nouvelle ADR d'amendement.
- Chaque ADR validée déclenche immédiatement :
  1. la création ou mise à jour de l'ADR ;
  2. la mise à jour du registre des décisions ;
  3. la mise à jour de cette roadmap ;
  4. la mise à jour des métriques produit ;
  5. la mise à jour du changelog produit ;
  6. un commit Git dédié.
- Les sujets clôturés ne doivent pas être reproposés.
- Le domaine en cours doit rester prioritaire jusqu'à verrouillage suffisant.

## Légende

- 🟢 Clôturé
- 🟡 En cours / partiellement arbitré
- ⚪ À traiter

## État des domaines

| Domaine | Statut | Avancement | Commentaire |
|---|---:|---:|---|
| Vision & positionnement | 🟢 | 100 % | ADN, valeurs, positionnement premium et philosophie produit verrouillés. |
| Branding & UX | 🟢 | 100 % | Identité visuelle, design tokens, animations, icônes, illustrations et signature sonore validés. |
| Comptes & profils | 🟢 | 95 % | Types de comptes, profils dynamiques, pseudonymes, vérification d'identité et cycle de vie définis. |
| Conversations | 🟢 | 95 % | Invitations, Salon Velvet, Carnet, histoire, consentement et comportements de lecture définis. |
| Sécurité & modération | 🟢 | 90 % | Modération IA-first, revue humaine et vérification obligatoire définies. Sanctions progressives à préciser. |
| Notifications & confidentialité | 🟢 | 95 % | Push, catégories, périodes calmes et modes de confidentialité définis. |
| Recherche & découverte | 🟡 | 70 % | Principes de recommandation, filtres et activité définis. Matching et contextualisation restent à arbitrer. |
| Événements | 🟡 | 60 % | Fondations posées. Création, inscriptions, paiements, listes d'attente, check-in, accès et avis restent à verrouiller. |
| Clubs | 🟡 | 55 % | Positionnement posé. Modèle fonctionnel et économique à détailler. |
| Professionnels | 🟡 | 50 % | Rôle défini. Offres, visibilité, outils et monétisation à arbitrer. |
| Administration / back-office | 🟡 | 40 % | Périmètre identifié. Workflows, rôles, journaux et dashboards à spécifier. |
| IA Velvet | 🟡 | 40 % | Modération couverte. Recherche, matching, recommandations et assistance restent à définir. |
| Monétisation | 🟡 | 60 % | Philosophie d'abonnement, devise et promotions validées. Offres détaillées restantes. |
| Gamification | ⚪ | 25 % | Badges, succès, ancienneté et récompenses à cadrer sans créer de popularité toxique. |
| Mobile avancé | ⚪ | 50 % | Web-first et notifications validés. Fonctions natives avancées à prioriser plus tard. |
| Analytics | ⚪ | 20 % | KPI produit, tableaux de bord et gouvernance des données à définir. |
| Juridique & conformité | 🟡 | 40 % | Consentement et identité cadrés. CGU, RGPD, conservation et droits utilisateurs à formaliser. |
| Développement complet | ⚪ | 0 % | Démarrera après verrouillage suffisant de l'architecture produit. |
| Recette | ⚪ | 0 % | À préparer après première version intégrée. |
| Pré-production | ⚪ | 0 % | À préparer après recette. |
| Lancement | ⚪ | 0 % | À préparer après validation pré-production. |

## Avancement global de référence

**Architecture produit estimée : 64 %.**

Ce pourcentage est un indicateur de pilotage, pas une mesure automatisée. Il doit être réévalué uniquement lorsqu'une ADR ou un lot fonctionnel structurant est clôturé.

## Ordre de traitement verrouillé

1. Recherche & Découverte
2. Événements
3. Clubs
4. Professionnels
5. Administration / Back-office
6. IA Velvet
7. Monétisation avancée
8. Gamification
9. Mobile avancé
10. Analytics
11. Juridique & conformité
12. Développement complet
13. Recette
14. Pré-production
15. Lancement

## Domaine actif

**Recherche & Découverte**

### Prochain objectif

Verrouiller le fonctionnement du moteur de découverte avant de passer au domaine Événements.

### Sujets à arbitrer dans ce domaine

- logique du matching intelligent ;
- poids de la proximité, de l'activité et des compatibilités ;
- personnalisation contextuelle ;
- diversité des recommandations ;
- prévention des bulles et de la sur-exposition ;
- contrôle utilisateur sur les recommandations ;
- explicabilité minimale des suggestions.

## Discipline de mise à jour

Ce document doit être mis à jour après chaque ADR validée. Une évolution produit structurante sans mise à jour de la roadmap est considérée comme incomplète.