// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SEASAME Assist-Pro';

  @override
  String get tagline => 'Smart University Ticketing';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signOut => 'Sign Out';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get createAccount => 'Create account';

  @override
  String get role => 'Role';

  @override
  String get roleStudent => 'Student';

  @override
  String get roleTeacher => 'Teacher';

  @override
  String get roleAgent => 'Support Agent';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get department => 'Department';

  @override
  String get filiere => 'Programme';

  @override
  String get selectDepartment => 'Select department';

  @override
  String get selectFiliere => 'Select programme';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get myTickets => 'My Tickets';

  @override
  String get newTicket => 'New Ticket';

  @override
  String get allTickets => 'All Tickets';

  @override
  String get queue => 'Queue';

  @override
  String get reports => 'Reports';

  @override
  String get users => 'Users';

  @override
  String get settings => 'Settings';

  @override
  String get ticketTitle => 'Title';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketType => 'Type';

  @override
  String get ticketPriority => 'Priority';

  @override
  String get ticketStatus => 'Status';

  @override
  String get ticketDepartment => 'Department';

  @override
  String get ticketCreatedBy => 'Created by';

  @override
  String get ticketAssignedTo => 'Assigned to';

  @override
  String get ticketCreatedAt => 'Created';

  @override
  String get ticketUpdatedAt => 'Updated';

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In Progress';

  @override
  String get statusWaitingOnUser => 'Waiting on You';

  @override
  String get statusResolved => 'Resolved';

  @override
  String get statusClosed => 'Closed';

  @override
  String get ticketTypeAcademic => 'Academic';

  @override
  String get ticketTypeIT => 'IT Issue';

  @override
  String get ticketTypeHR => 'HR Request';

  @override
  String get ticketTypeFacility => 'Facility';

  @override
  String get ticketTypeClassroomIT => 'Classroom IT';

  @override
  String get comments => 'Comments';

  @override
  String get addComment => 'Add a comment…';

  @override
  String get internalNote => 'Internal note';

  @override
  String get submitComment => 'Submit';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get aiHint => 'Describe your issue and I\'ll help draft a ticket…';

  @override
  String get aiDraftReady => 'Draft ready — review and confirm';

  @override
  String get aiConfirm => 'Create Ticket';

  @override
  String get aiEdit => 'Edit Draft';

  @override
  String get aiDiscard => 'Discard';

  @override
  String get noTickets => 'No tickets yet';

  @override
  String get noTicketsHint => 'Tap + to create your first ticket';

  @override
  String get search => 'Search tickets…';

  @override
  String get filter => 'Filter';

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortNewest => 'Newest first';

  @override
  String get sortOldest => 'Oldest first';

  @override
  String get sortPriority => 'By priority';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Something went wrong';

  @override
  String get retry => 'Retry';

  @override
  String get success => 'Success';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationEmail => 'Enter a valid email address';

  @override
  String get validationPasswordLength => 'Password must be at least 8 characters';

  @override
  String get validationPasswordMatch => 'Passwords do not match';

  @override
  String get language => 'Language';

  @override
  String get langEn => 'English';

  @override
  String get langFr => 'Français';

  @override
  String get langAr => 'العربية';

  @override
  String get totalTickets => 'Total Tickets';

  @override
  String get openTickets => 'Open';

  @override
  String get resolvedTickets => 'Resolved';

  @override
  String get avgResolutionTime => 'Avg. Resolution';

  // ── Phase 4 ─────────────────────────────────────────────────────────────────
  @override String get agentQueue => 'Agent Queue';
  @override String get adminPanel => 'Admin Panel';
  @override String get userManagement => 'User Management';
  @override String get departmentManagement => 'Department Management';
  @override String get systemStats => 'System Statistics';
  @override String get bulkUpdate => 'Bulk Update';
  @override String get bulkUpdateStatus => 'Update Status for Selected';
  @override String selectedCount(int count) => '$count selected';
  @override String get clearSelection => 'Clear Selection';
  @override String get selectAll => 'Select All';
  @override String get noUsersFound => 'No users found';
  @override String get createUser => 'Create User';
  @override String get editUser => 'Edit User';
  @override String get deleteUser => 'Delete User';
  @override String get deleteUserConfirm => 'Are you sure you want to delete this user?';
  @override String get userSaved => 'User saved successfully';
  @override String get userDeleted => 'User deleted successfully';
  @override String get assignRole => 'Assign Role';
  @override String get assignDepartment => 'Assign Department';
  @override String get totalUsers => 'Total Users';
  @override String get totalAgents => 'Total Agents';
  @override String get closedTickets => 'Closed';
  @override String get activeTickets => 'Active';
  @override String get systemOverview => 'System Overview';
  @override String get departmentBreakdown => 'Department Breakdown';
  @override String get filterByDepartment => 'Filter by Department';
  @override String get filterByStatus => 'Filter by Status';
  @override String get filterByPriority => 'Filter by Priority';
  @override String get allDepartments => 'All Departments';
  @override String get allStatuses => 'All Statuses';
  @override String get allPriorities => 'All Priorities';
  @override String get sortNewestFirst => 'Newest First';
  @override String get sortOldestFirst => 'Oldest First';
  @override String get sortByPriority => 'By Priority';
  @override String get updateStatus => 'Update Status';
  @override String get deleteTicket => 'Delete Ticket';
  @override String get deleteTicketConfirm => 'Are you sure you want to delete this ticket? This action cannot be undone.';
  @override String get deleteConfirmBtn => 'Yes, delete';
  @override String get ticketDeleted => 'Ticket deleted successfully';
}
