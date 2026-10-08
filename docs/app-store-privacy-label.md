# App Store Connect — Privacy label (Motiva)

Use this when filling **App Privacy** so it matches the app + Notion Privacy Policy.

## Tracking
- **No** — we do not track users across apps/websites (ATT not used).

## Data types to declare (typical with RevenueCat + subscriptions)

| Data | Purpose | Linked to user | Used for tracking |
|------|---------|----------------|-------------------|
| **Purchases** | App functionality (Premium) | Yes | No |
| **User ID** (anonymous app user ID from RevenueCat) | App functionality | Yes | No |

Do **not** claim “Data Not Collected” if Apple expects purchase/subscription data while RevenueCat is integrated.

## Data stored only on device (usually not “collected” for label)
- Favorites, streak, onboarding choices, reminder times, theme/topic — local UserDefaults.

## URLs for App Store Connect
- **Privacy Policy:** Notion Privacy page (same as in app)
- **Support URL:** Notion Help & Support page
