import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'SEASAME Assist-Pro'**
  String get appTitle;

  /// App tagline
  ///
  /// In en, this message translates to:
  /// **'Smart University Ticketing'**
  String get tagline;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @roleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get roleStudent;

  /// No description provided for @roleTeacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get roleTeacher;

  /// No description provided for @roleAgent.
  ///
  /// In en, this message translates to:
  /// **'Support Agent'**
  String get roleAgent;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @filiere.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get filiere;

  /// No description provided for @selectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Select department'**
  String get selectDepartment;

  /// No description provided for @selectFiliere.
  ///
  /// In en, this message translates to:
  /// **'Select programme'**
  String get selectFiliere;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @myTickets.
  ///
  /// In en, this message translates to:
  /// **'My Tickets'**
  String get myTickets;

  /// No description provided for @newTicket.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get newTicket;

  /// No description provided for @allTickets.
  ///
  /// In en, this message translates to:
  /// **'All Tickets'**
  String get allTickets;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @ticketTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get ticketTitle;

  /// No description provided for @ticketDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get ticketDescription;

  /// No description provided for @ticketType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get ticketType;

  /// No description provided for @ticketPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get ticketPriority;

  /// No description provided for @ticketStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get ticketStatus;

  /// No description provided for @ticketDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get ticketDepartment;

  /// No description provided for @ticketCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get ticketCreatedBy;

  /// No description provided for @ticketAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get ticketAssignedTo;

  /// No description provided for @ticketCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get ticketCreatedAt;

  /// No description provided for @ticketUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get ticketUpdatedAt;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusWaitingOnUser.
  ///
  /// In en, this message translates to:
  /// **'Waiting on You'**
  String get statusWaitingOnUser;

  /// No description provided for @statusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get statusResolved;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @ticketTypeAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get ticketTypeAcademic;

  /// No description provided for @ticketTypeIT.
  ///
  /// In en, this message translates to:
  /// **'IT Issue'**
  String get ticketTypeIT;

  /// No description provided for @ticketTypeHR.
  ///
  /// In en, this message translates to:
  /// **'HR Request'**
  String get ticketTypeHR;

  /// No description provided for @ticketTypeFacility.
  ///
  /// In en, this message translates to:
  /// **'Facility'**
  String get ticketTypeFacility;

  /// No description provided for @ticketTypeClassroomIT.
  ///
  /// In en, this message translates to:
  /// **'Classroom IT'**
  String get ticketTypeClassroomIT;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get addComment;

  /// No description provided for @internalNote.
  ///
  /// In en, this message translates to:
  /// **'Internal note'**
  String get internalNote;

  /// No description provided for @submitComment.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitComment;

  /// No description provided for @aiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistant;

  /// No description provided for @aiHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue and I\'ll help draft a ticket…'**
  String get aiHint;

  /// No description provided for @aiDraftReady.
  ///
  /// In en, this message translates to:
  /// **'Draft ready — review and confirm'**
  String get aiDraftReady;

  /// No description provided for @aiConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create Ticket'**
  String get aiConfirm;

  /// No description provided for @aiEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Draft'**
  String get aiEdit;

  /// No description provided for @aiDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aiDiscard;

  /// No description provided for @noTickets.
  ///
  /// In en, this message translates to:
  /// **'No tickets yet'**
  String get noTickets;

  /// No description provided for @noTicketsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first ticket'**
  String get noTicketsHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search tickets…'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @sortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get sortNewest;

  /// No description provided for @sortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get sortOldest;

  /// No description provided for @sortPriority.
  ///
  /// In en, this message translates to:
  /// **'By priority'**
  String get sortPriority;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// No description provided for @validationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmail;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMatch;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @langFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get langFr;

  /// No description provided for @langAr.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get langAr;

  /// No description provided for @totalTickets.
  ///
  /// In en, this message translates to:
  /// **'Total Tickets'**
  String get totalTickets;

  /// No description provided for @openTickets.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openTickets;

  /// No description provided for @resolvedTickets.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolvedTickets;

  /// No description provided for @avgResolutionTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Resolution'**
  String get avgResolutionTime;

  // ── Phase 4: Agent Queue & Admin Panel ───────────────────────────────────────
  String get agentQueue;
  String get adminPanel;
  String get userManagement;
  String get departmentManagement;
  String get systemStats;
  String get bulkUpdate;
  String get bulkUpdateStatus;
  String selectedCount(int count);
  String get clearSelection;
  String get selectAll;
  String get noUsersFound;
  String get createUser;
  String get editUser;
  String get deleteUser;
  String get deleteUserConfirm;
  String get userSaved;
  String get userDeleted;
  String get assignRole;
  String get assignDepartment;
  String get totalUsers;
  String get totalAgents;
  String get closedTickets;
  String get activeTickets;
  String get systemOverview;
  String get departmentBreakdown;
  String get filterByDepartment;
  String get filterByStatus;
  String get filterByPriority;
  String get allDepartments;
  String get allStatuses;
  String get allPriorities;
  String get sortNewestFirst;
  String get sortOldestFirst;
  String get sortByPriority;
  String get updateStatus;
  String get deleteTicket;
  String get deleteTicketConfirm;
  String get deleteConfirmBtn;
  String get ticketDeleted;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
