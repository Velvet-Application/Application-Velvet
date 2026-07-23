# Registre des décisions Velvet

**Objectif :** empêcher la réouverture involontaire de sujets déjà arbitrés et orienter rapidement CODEX vers les sources normatives.

## Règles

- Toute décision explicitement validée est considérée comme acquise.
- Une nouvelle proposition ne remplace une décision existante qu'avec un nouvel ADR indiquant clairement ce qu'elle modifie.
- Ce registre est un index ; l'ADR reste la source normative.
- Avant de poser une question produit ou d'ouvrir une issue, rechercher ici puis dans les ADR.
- Chaque ADR acceptée doit être documentée et réellement commitée avant de poursuivre la discussion produit.
- « Go commits » signifie appliquer les changements au dépôt GitHub actif, créer les commits réels et communiquer leurs références.
- La roadmap, les métriques et le changelog produit doivent rester synchronisés avec les ADR acceptées.

## Décisions validées — synthèse

### Marque et interface

- Identité sombre, cinématographique et premium.
- Logo officiel : V ruban bordeaux/rose, logotype or champagne.
- Palette canonique documentée dans `docs/01-BRAND/DESIGN-TOKENS.json`.
- Architecture visuelle hybride entre espaces publics plus ouverts et espaces privés plus intimes.
- Photographie centrée sur les personnes ; albums traités comme des galeries artistiques.
- Animations pragmatiques ; fluidité prioritaire.
- Icônes hybrides : bibliothèque standard et icônes Velvet spécifiques.
- Illustrations minimalistes, sans mascotte ni style cartoon.
- Une signature sonore uniquement à l'ouverture.
- Cartes premium avec identité commune et déclinaisons par usage.

### Accueil et découverte

- Accueil sous forme de découverte intelligente personnalisée.
- Catégories et filtres restent accessibles pour les recherches ciblées.
- Ne pas rouvrir ce choix sans nouvelle décision formelle.
- Les profils abandonnés ou durablement inactifs sont progressivement retirés des recommandations.

### Comptes, identité et profils

- Trois types de comptes : Membre, Organisateur privé, Professionnel.
- La vérification d'identité et de majorité est obligatoire avant l'accès complet à Velvet.
- L'identité civile vérifiée reste privée ; le pseudonyme constitue l'identité publique.
- Chaque profil dispose d'un nom d'affichage libre et d'un `@username` unique et stable.
- Les pseudonymes liés aux codes du libertinage sont autorisés ; seuls les contenus illégaux, haineux, liés aux mineurs, frauduleux, usurpateurs ou manifestement abusifs sont refusés.
- Tous les profils conservent la même qualité visuelle, sans hiérarchie graphique liée à l'ancienneté ou à la popularité.
- L'ancienneté peut être mise en avant après une durée significative.
- Vidéo de présentation facultative.
- Contenus épinglés autorisés et contrôlés par le membre.
- Profils Couple dynamiques : identité Couple et partenaires individuels activables indépendamment.
- Carte Couple : photo commune et portraits individuels.
- Albums publics et privés déjà arbitrés ; ne pas rouvrir leur principe sans consulter les ADR associés.

### Modération

- Modération hybride avec première vérification par IA.
- Les cas ambigus, sensibles, signalés ou à risque sont transmis à un modérateur humain.
- Pendant la validation d'un remplacement, l'ancien contenu approuvé reste visible.
- Le propriétaire voit le contenu en attente et reçoit une notification de décision.
- Les dossiers sont priorisés selon le niveau de risque, notamment mineurs, contenus illicites et usurpation.

### Activité et disponibilité

- Velvet n'affiche pas publiquement d'heure exacte de dernière connexion.
- Un Indice d'Activité synthétique indique si le profil est très actif, actif, occasionnel, peu actif ou en sommeil.
- L'indice utilise plusieurs signaux d'activité réelle sans devenir un score de popularité.
- Les profils peu actifs sont dépriorisés ; les profils en sommeil ou abandonnés sont exclus des recommandations.
- Un Mode Absence permet d'indiquer une pause et, facultativement, une date de retour.
- Un indicateur de réactivité peut afficher une tendance générale de réponse sans révéler les horaires précis de connexion ou de lecture.

### Conversations

- Cycle : Découverte → Conversation → Confiance → Expériences → Souvenirs → Relation durable.
- Invitation Velvet obligatoire avant création du Salon.
- Aucune relance d'invitation.
- Statuts d'invitation et de messages définis.
- Accusés de lecture réciproques, sans heure précise de lecture.
- Ouverture sur la dernière activité non lue.
- Onglets Messages et Histoire.
- Participants modifiables par consentement unanime.
- Capture d'écran signalée uniquement lorsque le système le permet.
- Première rencontre réelle confirmée indépendamment avant inscription dans l'histoire partagée.

### Consentement et confiance

- Pacte Velvet personnel, modifiable et contextuel par Salon.
- Rappel avant rencontre, sans case obligatoire réduisant le consentement à une formalité.
- Charte : consentement, droit de changer d'avis, respect du refus, confidentialité, bienveillance, tolérance zéro.
- Velvet Trust Index multifacteur, non assimilable à un score de popularité.
- Il n'existe pas de badge ordinaire « Vérifié », puisque la vérification d'identité est obligatoire pour tous.

### Notifications

- Push mobile requis même application fermée.
- Catégories configurables.
- Trois modes de confidentialité : Standard, Discret, Invisible.
- Pas de spam et respect des périodes calmes.

### Gouvernance et pilotage

- Une seule question produit structurante est traitée à la fois.
- Une ADR acceptée est définitive sauf amendement explicite par une nouvelle ADR.
- `PROJECT-ROADMAP.md` est la source officielle de l'état du projet, du domaine actif et de l'ordre de traitement.
- `PRODUCT-METRICS.md` porte les estimations d'avancement par domaine.
- `CHANGELOG-PRODUCT.md` conserve l'historique daté des évolutions produit validées.
- Après chaque ADR acceptée, ces trois fichiers et le présent registre doivent être mis à jour avant de poursuivre.
- Les pourcentages d'avancement ne changent qu'après clôture d'une ADR ou d'un lot fonctionnel significatif.

## Procédure avant nouvelle question produit

1. Rechercher les mots-clés dans ce registre.
2. Rechercher dans `docs/adr/`, `docs/04-VELVET-CONVERSATIONS/` et `docs/04-FEATURES/`.
3. Consulter `PROJECT-ROADMAP.md` pour confirmer le domaine actif et la priorité.
4. Si une décision existe, la considérer comme verrouillée.
5. Si le besoin est une extension compatible, préciser qu'il s'agit d'une extension.
6. Si le besoin contredit l'existant, rédiger une proposition d'amendement et identifier l'ADR remplacé.
7. Après validation, documenter l'ADR, mettre à jour le registre, la roadmap, les métriques et le changelog, puis créer immédiatement le commit dédié avant de passer à la question suivante.

## ADR récentes

- `ADR-DA-020` : modération hybride IA puis humain.
- `ADR-DA-021` : pseudonymes libres, nom d'affichage et `@username` unique.
- `ADR-DA-022` : vérification obligatoire de l'identité et de la majorité.
- `ADR-DA-023` : Indice d'Activité Velvet, Mode Absence et indicateur de réactivité.
- `ADR-GOV-001` : une ADR acceptée entraîne une documentation et un commit Git immédiats.
- `ADR-GOV-002` : pilotage continu par roadmap, métriques, changelog et domaine actif.

## Entretien

Ce fichier doit être mis à jour après chaque nouvelle décision majeure. Une pull request ou un commit qui ajoute un ADR structurant sans mettre à jour les documents de pilotage est incomplet.