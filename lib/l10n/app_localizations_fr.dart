// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'SEASAME Assist-Pro';

  @override
  String get tagline => 'Billetterie Universitaire Intelligente';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get email => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get haveAccount => 'Déjà un compte ?';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get role => 'Rôle';

  @override
  String get roleStudent => 'Étudiant';

  @override
  String get roleTeacher => 'Enseignant';

  @override
  String get roleAgent => 'Agent de support';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get department => 'Département';

  @override
  String get filiere => 'Filière';

  @override
  String get selectDepartment => 'Sélectionner un département';

  @override
  String get selectFiliere => 'Sélectionner une filière';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get myTickets => 'Mes tickets';

  @override
  String get newTicket => 'Nouveau ticket';

  @override
  String get allTickets => 'Tous les tickets';

  @override
  String get queue => 'File d\'attente';

  @override
  String get reports => 'Rapports';

  @override
  String get users => 'Utilisateurs';

  @override
  String get settings => 'Paramètres';

  @override
  String get ticketTitle => 'Titre';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketType => 'Type';

  @override
  String get ticketPriority => 'Priorité';

  @override
  String get ticketStatus => 'Statut';

  @override
  String get ticketDepartment => 'Département';

  @override
  String get ticketCreatedBy => 'Créé par';

  @override
  String get ticketAssignedTo => 'Assigné à';

  @override
  String get ticketCreatedAt => 'Créé le';

  @override
  String get ticketUpdatedAt => 'Mis à jour le';

  @override
  String get priorityLow => 'Faible';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get statusOpen => 'Ouvert';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusWaitingOnUser => 'En attente';

  @override
  String get statusResolved => 'Résolu';

  @override
  String get statusClosed => 'Fermé';

  @override
  String get ticketTypeAcademic => 'Académique';

  @override
  String get ticketTypeIT => 'Problème IT';

  @override
  String get ticketTypeHR => 'RH';

  @override
  String get ticketTypeFacility => 'Infrastructure';

  @override
  String get ticketTypeClassroomIT => 'IT salle de cours';

  @override
  String get comments => 'Commentaires';

  @override
  String get addComment => 'Ajouter un commentaire…';

  @override
  String get internalNote => 'Note interne';

  @override
  String get submitComment => 'Envoyer';

  @override
  String get aiAssistant => 'Assistant IA';

  @override
  String get aiHint => 'Décrivez votre problème, je vous aiderai à rédiger un ticket…';

  @override
  String get aiDraftReady => 'Brouillon prêt — vérifiez et confirmez';

  @override
  String get aiConfirm => 'Créer le ticket';

  @override
  String get aiEdit => 'Modifier le brouillon';

  @override
  String get aiDiscard => 'Ignorer';

  @override
  String get noTickets => 'Aucun ticket';

  @override
  String get noTicketsHint => 'Appuyez sur + pour créer votre premier ticket';

  @override
  String get search => 'Rechercher des tickets…';

  @override
  String get filter => 'Filtrer';

  @override
  String get sortBy => 'Trier par';

  @override
  String get sortNewest => 'Plus récent d\'abord';

  @override
  String get sortOldest => 'Plus ancien d\'abord';

  @override
  String get sortPriority => 'Par priorité';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get confirm => 'Confirmer';

  @override
  String get loading => 'Chargement…';

  @override
  String get error => 'Une erreur est survenue';

  @override
  String get retry => 'Réessayer';

  @override
  String get success => 'Succès';

  @override
  String get validationRequired => 'Ce champ est obligatoire';

  @override
  String get validationEmail => 'Saisissez une adresse e-mail valide';

  @override
  String get validationPasswordLength => 'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get validationPasswordMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get language => 'Langue';

  @override
  String get langEn => 'English';

  @override
  String get langFr => 'Français';

  @override
  String get langAr => 'العربية';

  @override
  String get totalTickets => 'Total tickets';

  @override
  String get openTickets => 'Ouverts';

  @override
  String get resolvedTickets => 'Résolus';

  @override
  String get avgResolutionTime => 'Délai moyen';

  // ── Phase 4 ─────────────────────────────────────────────────────────────────
  @override String get agentQueue => 'File des agents';
  @override String get adminPanel => 'Panneau d\'administration';
  @override String get userManagement => 'Gestion des utilisateurs';
  @override String get departmentManagement => 'Gestion des départements';
  @override String get systemStats => 'Statistiques système';
  @override String get bulkUpdate => 'Mise à jour groupée';
  @override String get bulkUpdateStatus => 'Mettre à jour le statut des sélectionnés';
  @override String selectedCount(int count) => '$count sélectionné(s)';
  @override String get clearSelection => 'Effacer la sélection';
  @override String get selectAll => 'Tout sélectionner';
  @override String get noUsersFound => 'Aucun utilisateur trouvé';
  @override String get createUser => 'Créer un utilisateur';
  @override String get editUser => 'Modifier l\'utilisateur';
  @override String get deleteUser => 'Supprimer l\'utilisateur';
  @override String get deleteUserConfirm => 'Êtes-vous sûr de vouloir supprimer cet utilisateur ?';
  @override String get userSaved => 'Utilisateur enregistré avec succès';
  @override String get userDeleted => 'Utilisateur supprimé avec succès';
  @override String get assignRole => 'Attribuer un rôle';
  @override String get assignDepartment => 'Attribuer un département';
  @override String get totalUsers => 'Total des utilisateurs';
  @override String get totalAgents => 'Total des agents';
  @override String get closedTickets => 'Fermés';
  @override String get activeTickets => 'Actifs';
  @override String get systemOverview => 'Vue d\'ensemble du système';
  @override String get departmentBreakdown => 'Répartition par département';
  @override String get filterByDepartment => 'Filtrer par département';
  @override String get filterByStatus => 'Filtrer par statut';
  @override String get filterByPriority => 'Filtrer par priorité';
  @override String get allDepartments => 'Tous les départements';
  @override String get allStatuses => 'Tous les statuts';
  @override String get allPriorities => 'Toutes les priorités';
  @override String get sortNewestFirst => 'Les plus récents d\'abord';
  @override String get sortOldestFirst => 'Les plus anciens d\'abord';
  @override String get sortByPriority => 'Par priorité';
  @override String get updateStatus => 'Mettre à jour le statut';
  @override String get deleteTicket => 'Supprimer le ticket';
  @override String get deleteTicketConfirm => 'Êtes-vous sûr de vouloir supprimer ce ticket ?';
  @override String get deleteConfirmBtn => 'Oui, supprimer';
  @override String get ticketDeleted => 'Ticket supprimé avec succès';
}
