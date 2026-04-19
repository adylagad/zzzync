# zzzync — Next Phases

## Current State (Phase 1 — Complete)

Local-first iOS app. All core features are demoable:
- Sync Score ring on Dashboard (HealthKit sleep + HRV + RHR, with mock fallback)
- Jetlag Map with 7-day sleep midpoint chart vs. first calendar event
- Metabolic Audit with Claude Vision food logging
- Bio-Protocol timeline for the next 24 hours
- Supabase anonymous auth + write-through sync wired up
- Apple Health-inspired dark UI

---

## Phase 2 — Backend & Cloud Sync

**Goal:** Make data persistent across devices and remove the API key from the device.

### 2a. Supabase Edge Function Proxy
Move the Claude API key off the device entirely. All Claude calls route through a Supabase Edge Function that holds the key server-side.

- Create `supabase/functions/claude-proxy/index.ts`
- Accept the same request shape as the Anthropic API
- Verify the caller has a valid Supabase JWT (already issued during anonymous auth)
- `ClaudeService.swift` points to `<project>.supabase.co/functions/v1/claude-proxy` instead of `api.anthropic.com`
- Remove `Config.xcconfig` / `Info.plist` key injection entirely

### 2b. Full Cloud Sync
Replace the fire-and-forget Supabase writes in `LocalStore` with proper read-back so data survives reinstalls and syncs across devices.

- On app launch: pull latest records from Supabase and merge into UserDefaults
- Conflict resolution: last-write-wins by `updated_at` timestamp
- Tables already exist: `sleep_records`, `biometric_records`, `food_logs`, `social_jetlag_results`, `energy_forecasts`, `bio_protocols`

### 2c. Real User Accounts
Upgrade from anonymous auth to named accounts so users can log in on a new device and get their history back.

- Sign in with Apple (fastest, no extra backend work)
- Migrate anonymous `user_id` → real account on first sign-in (Supabase supports this natively)
- Add a minimal Settings tab: account info + sign-out

---

## Phase 3 — Email Intelligence

**Goal:** Complete the "Workload vs. Energy" forecast from the PRD — scan email for high-stakes senders and stress signals.

### Gmail / Outlook Integration
- Gmail: OAuth2 + Gmail API, scan last 7 days for unread threads from flagged senders
- Outlook: Microsoft Graph API, same approach
- Extract: sender priority score, thread length, subject keywords ("urgent", "board", "legal")
- Feed into `EnergyForecast` prompt as an additional signal: `emailStressSignals: [EmailStressSignal]`
- Claude then factors in "You have 3 unread threads from your CFO before the 2PM meeting"

### Smart Sender Tagging
- Let users tag contacts as "High Stakes" / "Low Stakes" in-app
- Stored in Supabase `contact_tags` table
- Persisted and used to weight the cognitive clash severity score

---

## Phase 4 — Proactive Notifications

**Goal:** Make zzzync act on the user's behalf, not just report.

### Bio-Protocol Reminders
- Local `UNUserNotificationCenter` notifications timed to each protocol item
- "Caffeine window opens in 15 min — skip the early coffee"
- "Digestive Sunset in 30 min — finish your last meal soon"
- Scheduled fresh each morning when the Bio-Protocol is generated

### Jetlag Drift Alerts
- Background `BGAppRefreshTask` runs nightly after sleep data lands in HealthKit
- If 3-day rolling jetlag score worsens by > 1.5h, send a nudge
- "Your body clock drifted 2h later this week. Pull-to-refresh for a recalibration protocol."

### Weekly Sync Report
- Sunday evening push notification: weekly summary card
- Best day, worst day, trend direction, one actionable tip from Claude

---

## Phase 5 — Android & Cross-Platform

**Goal:** Reach Android users (Google Fit / Health Connect) without rewriting the app.

- Evaluate React Native or Flutter for a shared codebase
- Android data sources: Health Connect API (sleep, HRV), Google Calendar API
- Supabase backend is already platform-agnostic — no changes needed there
- Claude service layer is pure HTTP — portable as-is

---

## Phase 6 — Wearable Deep Integration

**Goal:** First-class support for advanced wearable data beyond basic HealthKit.

| Wearable | New Signal | Use in zzzync |
|---|---|---|
| Oura Ring | Readiness score, sleep stages breakdown | Weight Sync Score more accurately |
| Whoop | Strain score, recovery % | Adjust Bio-Protocol intensity |
| Garmin / Polar | Body Battery | Energy Forecast calibration |
| Apple Watch (Ultra) | Blood oxygen, skin temp | Circadian phase refinement |

All integrate via HealthKit on iOS — no direct SDK needed for Apple Watch/Garmin. Oura and Whoop require their own OAuth APIs.

---

## Backlog (No Phase Assigned)

These are valid features but need more user feedback before prioritizing:

- **Manual sleep entry** — for users without a wearable
- **Edit / delete food logs** — basic data hygiene
- **Historical trend views** — 30/90-day charts for jetlag drift and metabolic score
- **Export** — CSV or PDF weekly report for sharing with a doctor/coach
- **Apple Watch app** — glanceable Sync Score on wrist, quick food log via Siri

---

## Decision Log

| Decision | Rationale |
|---|---|
| Local-first in Phase 1 | Ship a demoable app without backend complexity blocking UI work |
| Anonymous Supabase auth | Users get cloud sync without a signup gate; upgradeable to real accounts later |
| No streaming in Claude calls | Full response + loading skeleton is simpler and sufficient for Phase 1 UX |
| EventKit over Google Calendar API | Works for any iOS-synced calendar (including Google) with zero OAuth in Phase 1 |
| Mock HealthKit fallback | Allows demo on any device; mock data tells a clear Social Jetlag story |
