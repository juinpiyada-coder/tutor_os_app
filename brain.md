# TutorOS Flutter Client (`tutor_os_ui/app`) Architecture & App Brain

Welcome to the comprehensive architecture, design system, and developer reference for the **TutorOS Flutter Client Application (`tutor_os_ui/app`)**.

---

## 1. Overview & Architectural Role

`tutor_os_ui/app` is a cross-platform (Android, iOS, Web, Desktop) Flutter application that delivers tailored workspaces and portals for all TutorOS user personas: **Super Admins, Coaching Academy Owners (Admins), Branch Admins, Solo Tutors, Teachers, Students, and Parents**.

### Core Frontend Principles
- **Role-Adaptive Workspaces**: Dynamic navigation and feature suites customized per authenticated role (`ADMIN`, `SOLO_TUTOR`, `BRANCH_ADMIN`, `TEACHER`, `STUDENT`, `PARENT`, `SUPER_ADMIN`).
- **Unified Design System**: Custom theme tokens ([AppTheme](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/theme/app_theme.dart)) supporting light & dark modes with Royal Indigo (`#4F46E5`), Electric Cobalt (`#0B5AE6`), and Slate palettes.
- **Resilient Multi-Tenant Session Handling**: Centralized [ApiService](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/network/api_service.dart) maintaining JWT tokens, tenant contexts, and dual storage persistence via `SharedPreferences`.
- **Form State Validation**: Strict pre-submission input validation ([Validators](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/utils/validators.dart) and `Formz`) matching backend rules.
- **Graceful Zero-State & Retry UX**: Built-in empty states, loading shimmers, and connection retry mechanisms for fresh accounts.

---

## 2. Directory Structure

```
tutor_os_ui/app/
├── lib/
│   ├── main.dart             # Application initialization, theme binding, root router
│   ├── assets/               # Brand SVG logos, illustrations, character art
│   ├── core/                 # Foundation infrastructure
│   │   ├── forms/            # Formz input models (email, password, username, phone)
│   │   ├── network/          # ApiService (REST API clients, headers, session handlers)
│   │   ├── services/         # StorageService (dual session persistence)
│   │   ├── theme/            # AppTheme, color palettes, elevation, typography tokens
│   │   ├── utils/            # Validators (regex, password criteria, Indian phone format)
│   │   └── widgets/          # UniversalOwnerHeader, shared UI controls
│   ├── features/             # Feature domains grouped by role
│   │   ├── admin/            # Academy Admin, Branch Admin & Solo Tutor modules
│   │   │   ├── screens/      # AdminMainScreen, SoloTutorDashboard, Registration
│   │   │   │   ├── academics/      # Batches, Subjects, Courses, Curriculum
│   │   │   │   ├── assessments/    # Exam schedules, marks entry, grading
│   │   │   │   ├── branch_admin/   # Branch-specific admin views
│   │   │   │   ├── communications/ # Center announcements, SMS alerts
│   │   │   │   ├── directory/      # Student, Staff, Faculty, Parent registries
│   │   │   │   ├── finance/        # Fee plans, invoices, payments, expense ledger
│   │   │   │   ├── operations/     # Classes, daily timetables, live attendance
│   │   │   │   ├── reports/        # Center performance and revenue analytics
│   │   │   │   ├── settings/       # Institute profile, security, branch config
│   │   │   │   └── super_admin/    # Multi-tenant platform supervision
│   │   │   ├── services/     # AdminDashboardService, DirectoryService, SettingsService
│   │   │   └── widgets/      # MetricCard, QuickActionsGrid, TodayScheduleWidget
│   │   ├── auth/             # Login, Coaching Registration, Solo Onboarding, Student Enrollment
│   │   │   └── screens/      # LoginScreen, StudentCoachingEnrollScreen
│   │   ├── parent/           # Parent portal (attendance alerts, fee pay, progress)
│   │   ├── student/          # Student portal (classes, study materials, homework, exams, doubts)
│   │   └── teacher/          # Faculty portal (batches, attendance marking, homework grading)
│   └── shared/               # Reusable presentation widgets (InstituteHeader, MetricCard)
├── test/                     # Unit and widget test suites
│   └── core/utils/validators_test.dart
└── pubspec.yaml              # Dependencies, assets, and Flutter build configuration
```

---

## 3. Role Portals & Workspaces

### 3.1. Authentication & Onboarding (`features/auth`)
- **Login (`LoginScreen`)**: Alphanumeric authentication with FormState validation, automatic password obscuring, and dynamic role-based redirection to the appropriate workspace.
- **Institute Registration (`RegisterInstituteScreen`)**: Multi-step coaching center onboarding with password complexity validation (`helperText` + regex).
- **Solo Tutor Desk (`RegisterSoloTutorScreen`)**: Fast setup for single educators combining teaching and administrative desks.
- **Student Coaching Self-Enrollment (`StudentCoachingEnrollScreen`)**: Search and discover institutes, select batches, enter student/parent profiles, and enroll instantly.

### 3.2. Academy Admin Workspace (`features/admin`)
- **Command Dashboard (`AdminDashboard`)**: Real-time student counts, attendance percentages, fees overdue, today's schedule, and alert summaries with pull-to-refresh.
- **Academic Hierarchy**: Standards/Grades $\rightarrow$ Subjects $\rightarrow$ Batches $\rightarrow$ Timetables.
- **Directory Operations**: Add and manage student records, faculty profiles, and parent contact linkages.
- **Finance Hub**: Generate invoices, track cash/UPI payments, issue fee receipts, and calculate dues.
- **Assessments**: Create tests, enter scores, publish result report cards.

### 3.3. Solo Tutor Command Desk (`SoloTutorDashboard`)
- **Dual Educator & Business Desk**: Unified tabs for managing batches, taking student attendance, assigning homework, collecting fees, and tracking earnings without administrative overhead.

### 3.4. Student Portal (`features/student`)
- **Daily Classroom**: Live timetable, class check-in attendance, study notes, video lectures.
- **Assignments & Doubts**: Homework submissions with attachments, two-way doubt resolution with teachers.
- **Exam Results**: Progress cards, percentage metrics, and test history.

### 3.5. Teacher Portal (`features/teacher`)
- **Batch Teaching**: Batch student rosters, daily lecture schedules, attendance verification.
- **Evaluation Desk**: Grading student submissions, uploading chapter notes, answering doubts.

### 3.6. Parent Portal (`features/parent`)
- **Child Academic Monitoring**: Verified attendance records, fee invoice payments, performance trends.

---

## 4. State Management, Networking & Persistence

### 4.1. Network Client ([ApiService](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/network/api_service.dart))
- **Base URL & Headers**: Reads API endpoints from `.env` or defaults to `http://127.0.0.1:8000/api`.
- **Dynamic Context Headers**: Automatically attaches:
  - `Authorization: Bearer <JWT_TOKEN>`
  - `X-Tenant-Id: <TENANT_ID>`
  - `X-Branch-Id: <BRANCH_ID>`
- **Session Management**: `setSession()` synchronizes active memory state and writes session tokens to `StorageService`.

### 4.2. Dual Storage ([StorageService](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/services/storage_service.dart))
- Persists user credentials, roles, avatar URLs, and tenant codes using `SharedPreferences`.
- Automatically re-hydrates sessions on app launch via `ApiService.initSessionFromStorage()`.

---

## 5. UI Design System & Styling Tokens

### Color Palette ([AppTheme](file:///c:/Users/Admin/Downloads/main/production/tutor_os_ui/app/lib/core/theme/app_theme.dart))
- **Primary Navy**: `Color(0xFF0F3A88)` / `Color(0xFF1E1B4B)` — Headers, brand marks, and high-emphasis typography.
- **Electric Cobalt**: `Color(0xFF0B5AE6)` — Action buttons, active navigation, indicators.
- **Royal Indigo**: `Color(0xFF4F46E5)` — Hero gradients and badge accents.
- **Success Emerald**: `Color(0xFF10B981)` / `AppTheme.successBg` (`0xFF064E3B` in dark mode) — Verified attendance and completed tasks.
- **Urgent Coral / Warning Amber**: `Color(0xFFDC2626)` / `Color(0xFFF59E0B)` — Fee alerts, errors, and deadlines.

### Dark Theme & Dynamic Semantic Tokens
- **Canvas Background**: `AppTheme.getCanvasBackground(context)` (`#F5F2ED` Light / `#090D16` Dark).
- **Surface Cards**: `AppTheme.getSurfaceCard(context)` (`#FFFFFF` Light / `#111827` Dark).
- **Subtle Surface**: `AppTheme.getSurfaceSubtle(context)` (`#EAF0F6` Light / `#1F2937` Dark).
- **Borders & Dividers**: `AppTheme.getBorderSubtle(context)` (`#D9E1EC` Light / `#374151` Dark).
- **Typography Tokens**:
  - Headings: `AppTheme.getTextHeading(context)` (`#10213D` Light / `#F8FAFC` Dark).
  - Body Text: `AppTheme.getTextBody(context)` (`#3E4658` Light / `#CBD5E1` Dark).
  - Muted Text: `AppTheme.getTextMuted(context)` (`#72809C` Light / `#94A3B8` Dark).

### Typography
- **Headings**: Google Fonts `Plus Jakarta Sans` / `Outfit` for modern, crisp section titles.
- **Body & Controls**: Google Fonts `Inter` for legibility across metrics, data tables, and input fields.

---

## 6. Resolved Audit Issues & QA Benchmarks

- **TOS-AUTH-01 & TOS-AUTH-02 (Password Security & Username Separation)**:
  - Frontend form validation in `Validators.validatePassword` enforces 6+ characters, letters, numbers, symbols (`@`, `#`, `$`, `!`, etc.), and rejects identical username/password.
  - Parity in backend `PasswordHasher::validate` across `tutor_os_be`.
- **TOS-DASH-01 & TOS-DASH-02 (Post-Registration Dashboard Loading & Rehydration Reliability)**:
  - Fixed JWT session and tenant context hydration from nested `data['data']` in `ApiService`.
  - Added robust retry states, loading indicators, and zero-state fallbacks in `AdminDashboard` and `SoloTutorDashboard`.
  - Dual storage persistence via `StorageService` ensuring reliable state restoration across navigation and page refresh.
- **TOS-UI-01 (Dark Mode Typography & Visual Contrast)**:
  - Implemented dynamic semantic tokens (`getTextHeading`, `getTextBody`, `getTextMuted`, `getSurfaceCard`, `getBorderSubtle`, `getCanvasBackground`) in `AppTheme`.
  - Zero low-contrast text across cards, dialogs, bottom sheets, popup menus, and input fields in both light and dark themes.
- **TOS-NOTIF-01 (Universal Notifications & Action Routing)**:
  - Implemented `UniversalNotificationModal` linked to `UniversalOwnerHeader` with unread badge counter, category filter chips (`All`, `Unread`, `Academics`, `Finance`, `Exams`), "Mark all as read", empty states, and contextual routing.
- **TOS-BATCH-01, TOS-BATCH-02, TOS-BATCH-03 (Batch Creation & Class I–XII Standards)**:
  - Direct "Create Batch" action on Batches and Academic Structure pages.
  - Dedicated `AddBatchScreen` with required fields, timing selectors, capacity limits, validation, and persistent record creation.
  - Standardized Class selector with default Class I through Class XII grades fallback.
- **TOS-STUDENT-01 & TOS-STUDENT-02 (Add Student Flow & Duplicate Email Validation)**:
  - Dedicated `AddStudentScreen` with personal information, academic batch assignment, and parent linkage.
  - RFC-compliant email validation with sub-addressing support and database uniqueness checks.
- **TOS-PARENT-01 & TOS-PARENT-02 (Parent Contact Info & Secure Account Workflow)**:
  - Indian phone number validation (10 digits starting with 6-9, `+91`/`0` prefix handling) and parent email validation linked to student profiles.
  - Secure parent account creation with dynamic temporary credentials (`Parent@XXX`) and first-login password change policy rather than permanent shared default passwords.
- **TOS-UX-01 (Loading, Error & Empty States)**:
  - Built-in shimmer indicators, actionable retry buttons, and informative zero-state illustrations across all core screens.

---

## 7. Testing & Quality Assurance

### Running Unit & Form Validation Tests
```bash
cd tutor_os_ui/app
flutter test
```

### Static Analysis & Linter Check
```bash
flutter analyze
```

### Running Locally
```bash
# Web
flutter run -d chrome

# Android / iOS / Desktop
flutter run
```


