# Registre des décisions Velvet

**Objectif :** empêcher la réouverture involontaire de sujets déjà arbitrés et orienter rapidement CODEX vers les sources normatives.

## Règles

- Toute décision explicitement validée est considérée comme acquise.
- Une nouvelle proposition ne remplace une décision existante qu'avec un nouvel ADR indiquant clairement ce qu'elle modifie.
- Ce registre est un index ; l'ADR reste la source normative.
- Avant de poser une question produit ou d'ouvrir une issue, rechercher ici puis dans les ADR.

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

### Comptes et profils

- Trois types de comptes : Membre, Organisateur privé, Professionnel.
- Tous les profils conservent la même qualité visuelle, sans hiérarchie graphique liée à l'ancienneté ou à la popularité.
- L'ancienneté peut être mise en avant après une durée significative.
- Vidéo de présentation facultative.
- Contenus épinglés autorisés et contrôlés par le membre.
- Profils Couple dynamiques : identité Couple et partenaires individuels activables indépendamment.
- Carte Couple : photo commune et portraits individuels.
- Albums publics et privés déjà arbitrés ; ne pas rouvrir leur principe sans consulter les ADR associés.

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

### Notifications

- Push mobile requis même application fermée.
- Catégories configurables.
- Trois modes de confidentialité : Standard, Discret, Invisible.
- Pas de spam et respect des périodes calmes.

## Procédure avant nouvelle question produit

1. Rechercher les mots-clés dans ce registre.
2. Rechercher dans `docs/03-ADR/`, `docs/04-VELVET-CONVERSATIONS/` et `docs/04-FEATURES/`.
3. Si une décision existe, la considérer comme verrouillée.
4. Si le besoin est une extension compatible, préciser qu'il s'agit d'une extension.
5. Si le besoin contredit l'existant, rédiger une proposition d'amendement et identifier l'ADR remplacé.

## Entretien

Ce fichier doit être mis à jour après chaque nouvelle décision majeure. Une pull request qui ajoute un ADR structurant sans mettre à jour ce registre est incomplète.
