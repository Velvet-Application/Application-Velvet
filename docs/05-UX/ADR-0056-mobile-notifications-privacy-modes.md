# ADR-0056 - Notifications mobiles et modes de discrétion

Décision validée.

Velvet utilise des notifications push sur mobile afin d'informer les membres même lorsque l'application est fermée.

## Catégories

- Conversations : nouveaux messages, mentions, invitations et réactions importantes
- Rencontres : Invitation Velvet, match, demande d'accès à un album et recommandation
- Événements : invitation, validation, modification, annulation, rappel et place libérée
- Organisateurs : validation, liste d'attente, liste VIP et information importante
- Compte et sécurité : vérification, badge, connexion inhabituelle et changement sensible
- Premium : abonnement, parrainage et offres uniquement avec consentement marketing

Chaque catégorie peut être activée ou désactivée séparément. Velvet évite le spam, les faux prétextes d'engagement et les rappels redondants.

## Modes de confidentialité

### Standard

Le nom Velvet et le détail utile peuvent apparaître, par exemple : `Nouveau message de Claire`.

### Discret

Le nom Velvet peut apparaître, mais le contenu personnel est masqué : `Vous avez une nouvelle activité`.

### Invisible

Le nom Velvet, les personnes et le contenu sont masqués sur l'écran verrouillé : `Nouvelle notification`.

Le comportement final dépend également des capacités et réglages de confidentialité d'iOS ou Android.

Velvet peut regrouper les notifications proches et respecter des plages de repos définies par l'utilisateur.