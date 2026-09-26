# ExpenseFlow — Architecture (Flutter + Firebase + Node.js/MongoDB)

This document explains **how the pieces are wired together**: the Flutter
frontend, Firebase (Authentication), and the Node.js + MongoDB backend that
stores all app data. It's meant to be handed to a reviewer/instructor/sir
alongside the source code.

---

## 1. High-level picture

```
┌─────────────────────────────┐
│        Flutter App          │
│  (lib/) — Android/iOS/Web   │
│                              │
│  ┌────────────────────────┐ │
│  │   Firebase Auth SDK     │ │───────┐
│  │ (sign up / sign in /    │ │       │  ID Token (JWT)
│  │  password reset)        │ │       │  issued after login
│  └────────────────────────┘ │       │
│              │               │       │
│              ▼               │       ▼
│  ┌────────────────────────┐ │   ┌─────────────────────┐
│  │  AuthService             │ │   │   Firebase Auth      │
│  │  (lib/services/          │◄├──►│   (Google servers)   │
│  │   auth_service.dart)     │ │   └─────────────────────┘
│  └────────────────────────┘ │
│              │               │
│              ▼               │
│  ┌────────────────────────┐ │      Bearer <ID token>
│  │      ApiClient            │ │────────────────────────────┐
│  │ (lib/services/            │ │                             │
│  │  api_client.dart)         │ │                             │
│  └────────────────────────┘ │                             │
└─────────────────────────────┘                             │
                                                              ▼
                                          ┌──────────────────────────────────┐
                                          │   Node.js + Express backend       │
                                          │   (expenseflow-backend/)          │
                                          │                                    │
                                          │  middleware/auth.js               │
                                          │   -> verifies ID token via         │
                                          │      Firebase Admin SDK            │
                                          │   -> finds/creates matching        │
                                          │      MongoDB User document         │
                                          │                                    │
                                          │  routes/*  -> controllers/*        │
                                          │   -> scoped to req.userId          │
                                          └───────────────┬────────────────────┘
                                                          │  Mongoose
                                                          ▼
                                          ┌──────────────────────────────────┐
                                          │           MongoDB                 │
                                          │  Users, Transactions, Budgets,    │
                                          │  Recurring, Categories            │
                                          └──────────────────────────────────┘
```

**The one-line summary:** Firebase Auth answers *"who is this user?"*.
MongoDB (via the Node/Express backend) answers *"what data belongs to
them?"*. The Flutter app never talks to MongoDB directly — everything
goes through the backend's REST API, authenticated by a Firebase ID
token on every request.

---

## 2. Why split it this way?

| Concern | Handled by | Why |
|---|---|---|
| Sign up / sign in / password reset / email verification | **Firebase Auth** | Battle-tested, free tier, handles token refresh, email flows, and security out of the box — no need to reinvent password hashing/session management. |
| Transactions, budgets, recurring items, categories, user profile/settings | **MongoDB via a custom REST API** | Full control over the data model, querying, and business logic (e.g. the Financial Health Score calculation), which is easier to reason about and extend in plain Mongoose schemas than in Firestore's document model. |
| File uploads (avatars, receipts) | **Backend's own disk storage**, served at `/uploads/...` | Avoids a second paid cloud storage bill; kept simple for a project like this. |

This is a common real-world pattern: **"Firebase for auth, your own
API for everything else."** It gives you Firebase's login UX for free
while keeping full ownership of your actual application data.

---

## 3. Frontend (Flutter) — where each piece lives

```
lib/
├─ main.dart                       # Initializes Firebase, then AuthService, then runApp()
├─ firebase_options.dart           # Auto-generated Firebase project config (flutterfire configure)
├─ services/
│  ├─ auth_service.dart            # Wraps FirebaseAuth (sign in/up/out) + syncs MongoDB profile
│  ├─ api_client.dart              # Thin REST client — attaches Firebase ID token to every call
│  ├─ firestore_service.dart       # Despite the name, this now calls the Mongo backend's REST
│  │                                 API (kept the name so repositories didn't need renaming)
│  ├─ storage_service.dart         # Uploads avatars/receipts to the backend (not Firebase Storage)
│  └─ local_storage_service.dart   # SharedPreferences — used ONLY for Demo Mode (never synced)
├─ repositories/
│  ├─ transaction_repository.dart  # Routes to FirestoreService (real login) or
│  ├─ budget_repository.dart       #   LocalStorageService (Demo Mode), so providers/UI
│  ├─ recurring_repository.dart    #   never need to know which backend is active
│  └─ auth_repository.dart
└─ providers/                      # Riverpod providers consumed by the UI (dashboard,
                                    # transactions, budgets, profile, etc.)
```

### Request flow for a signed-in user (e.g. adding a transaction)

1. UI calls a Riverpod provider → `TransactionRepository.add(...)`.
2. Since `isDemo == false`, the repository calls
   `FirestoreService.upsertTransaction(uid, txn)`.
3. That calls `ApiClient.put('/api/transactions/<id>', txn.toJson())`.
4. `ApiClient` fetches the current Firebase user's ID token
   (`user.getIdToken()` — cached and auto-refreshed by the Firebase SDK)
   and attaches it as `Authorization: Bearer <token>`.
5. Request goes out to `AppConstants.apiBaseUrl` (the Node.js backend).
6. If the server returns `401`, `ApiClient` retries **once** with a
   force-refreshed token (handles the rare case of a stale cached token
   right after sign-in) before surfacing an error.

### Demo Mode vs. Authenticated Mode

Every repository takes an `isDemo` flag and branches:

- **Demo Mode** → everything is read/written to `SharedPreferences` via
  `LocalStorageService`. No network calls, no Firebase, no MongoDB.
  Lets someone try/grade the app instantly with zero setup.
- **Authenticated Mode** → Firebase Auth + the Mongo backend, as
  described above.

This branching lives entirely inside the repositories, so the UI and
providers are identical regardless of which mode is active.

### Configuring the backend URL

`lib/core/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://expenseflowv1-b.onrender.com',
);
```

- Defaults to the deployed backend on Render.
- Override for local development:
  ```
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000   # Android emulator
  flutter run --dart-define=API_BASE_URL=http://localhost:5000  # iOS sim / desktop
  ```

---

## 4. Backend (`expenseflow-backend/`) — Node.js + Express + MongoDB

```
expenseflow-backend/
├─ server.js                  # Boots the HTTP server
├─ src/
│  ├─ app.js                  # Express app: middleware + route mounting
│  ├─ config/
│  │  ├─ db.js                # Connects Mongoose to MONGODB_URI
│  │  └─ firebaseAdmin.js     # Initializes Firebase Admin SDK (verifies ID tokens)
│  ├─ middleware/
│  │  ├─ auth.js              # requireAuth: verifies token, attaches req.userId
│  │  └─ errorHandler.js
│  ├─ models/                 # Mongoose schemas: User, Transaction, Budget,
│  │                            Recurring, Category
│  ├─ controllers/            # One per resource; makeCrudController.js
│  │                            factors out the common CRUD pattern
│  └─ routes/                 # Maps /api/... paths to controllers
└─ .env                       # MONGODB_URI, FIREBASE_SERVICE_ACCOUNT_JSON, etc. (not committed)
```

### How a request is authenticated (`middleware/auth.js`)

1. Every protected route requires an `Authorization: Bearer <token>`
   header — the Firebase ID token the Flutter app attached.
2. `firebaseAdmin.auth().verifyIdToken(idToken)` verifies the token's
   signature and expiry **against Google's servers' public keys** —
   the backend never has to trust the client's claim of who it is.
3. The decoded token's `uid` is looked up in MongoDB's `User`
   collection. **First time this uid is seen** → a new `User` document
   is created automatically (`findOrCreateFromFirebaseUser`), and a
   default set of expense/income categories is seeded for them.
4. `req.userId` is set to that MongoDB `User._id`, and every downstream
   controller scopes its queries to it — so one user can never read or
   write another user's transactions, budgets, etc.

### Data endpoints (all under `/api`, all require auth)

| Resource | Base path | Backed by |
|---|---|---|
| Auth/profile sync | `/api/auth/me`, `/api/users/me` | `User` model |
| Transactions | `/api/transactions` | `Transaction` model |
| Budgets | `/api/budgets` | `Budget` model |
| Recurring payments | `/api/recurring` | `Recurring` model |
| Categories | `/api/categories` | `Category` model |
| File uploads (avatar/receipt) | `/api/uploads/...` | Local disk, served at `/uploads/...` |

Each resource controller follows the same CRUD shape
(`makeCrudController.js`), always filtered by `req.userId`.

### Environment configuration (`.env`)

```
PORT=5000
MONGODB_URI=mongodb+srv://<user>:<password>@<cluster>.mongodb.net/expenseflow
FIREBASE_SERVICE_ACCOUNT_JSON={...}   # from Firebase Console > Project settings > Service accounts
BASE_URL=http://localhost:5000
CORS_ORIGIN=*
```

`FIREBASE_SERVICE_ACCOUNT_JSON` is what lets the **backend** (not just
the Flutter app) talk to Firebase — specifically, to verify ID tokens
via the Admin SDK. This is a separate credential from the Flutter app's
`firebase_options.dart` (which is a *public* client config, safe to
ship in the app).

---

## 5. Firebase's exact role (and what it does *not* do)

Firebase is used **only** for:
- Email/password sign-up and sign-in (`firebase_auth` package)
- Password reset emails
- Email verification
- Issuing/refreshing the short-lived ID token (JWT) that proves identity

Firebase is **not** used for:
- Storing transactions/budgets/recurring items/categories (that's MongoDB)
- File storage (receipts/avatars are stored by the Node backend on disk)
- Real-time sync — data is fetched/pushed over plain REST, not Firestore
  listeners

This is why `firestore_service.dart` — despite its name — contains no
Firestore code at all; it's a REST client to the Mongo backend. The
name was kept so none of the repositories that depend on it needed to
change when the backend was swapped from Firestore to Node/MongoDB.

---

## 6. End-to-end example: user registers and adds their first expense

1. **Flutter** — `AuthService.register()` calls
   `FirebaseAuth.createUserWithEmailAndPassword`. Firebase creates the
   account and returns a `User` + ID token.
2. **Flutter** — `AuthService` calls the backend's `/api/auth/me` with
   that token attached.
3. **Backend** — `requireAuth` verifies the token via Firebase Admin,
   finds no matching MongoDB user yet, so **creates one**
   (`User.create(...)`) and seeds default categories for them.
4. **Flutter** — receives the new `UserModel` from MongoDB, displays
   the dashboard.
5. User taps **+** and adds an expense. `TransactionRepository.add()`
   → `FirestoreService.upsertTransaction()` → `ApiClient.put()` →
   `PUT /api/transactions/<id>` with the ID token attached.
6. **Backend** — verifies the token again (every request is
   independently authenticated, no server-side session), saves the
   transaction to MongoDB scoped to `req.userId`.
7. Next app launch (or another device, same account) — Firebase
   restores the session automatically, the app calls `/api/transactions`
   again, and the same data comes back from MongoDB.

---

## 7. Running it locally

**Backend:**
```bash
cd expenseflow-backend
cp .env.example .env      # fill in MONGODB_URI + FIREBASE_SERVICE_ACCOUNT_JSON
npm install
npm run dev                # nodemon, http://localhost:5000
```

**Frontend:**
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000   # Android emulator
```

Firebase project config for the Flutter app itself
(`lib/firebase_options.dart`) is already generated via
`flutterfire configure` and checked in — it's public client config,
safe to ship.
