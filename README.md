# zzzync

**The Social Jetlag Resolver** — an iOS app that correlates your wearable biometrics, calendar schedule, and food logs to calculate how out-of-sync your body clock is with your actual life, then gives you a personalized daily protocol to fix it.

Built with SwiftUI + Claude AI + HealthKit + EventKit + Supabase.

---

## What it does

Most fatigue isn't from lack of sleep — it's from *mistimed* sleep. zzzync measures the gap between when your body wants to function and when your calendar demands it.

**Social Jetlag Score** — compares your sleep midpoints over the last 7 days against the time of your first calendar event each day. A night-owl who has 8AM standups has high social jetlag. Claude quantifies the drift in hours and explains it in circadian terms.

**Metabolic Window Audit** — you photograph or describe a meal. Claude Vision cross-references the meal timestamp against your HRV and RHR trends to determine whether you ate inside or outside your biological feeding window.

**Energy Forecast** — Claude maps your hourly energy curve against today's calendar and flags "Cognitive Clashes" — meetings scheduled during your predicted circadian trough.

**Daily Bio-Protocol** — a personalized 24-hour timeline: when to take your first coffee, when your brain peaks, when to stop eating. Recalculates every morning.

---

## Screenshots

| Dashboard | Jetlag Map | Bio-Protocol |
|---|---|---|
| Sync Score ring + metric tiles | 7-day sleep midpoint vs. first event | Optimized daily timeline |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI, Swift Charts, swift-markdown-ui |
| AI | Claude claude-sonnet-4-6 (vision + structured JSON) |
| Health data | HealthKit (sleep, HRV, RHR) |
| Calendar | EventKit (all iOS-synced calendars incl. Google) |
| Backend | Supabase (Postgres, anonymous auth, row-level security) |
| Persistence | Local-first: UserDefaults → Supabase write-through sync |
| Project gen | xcodegen (`project.yml`) |

---

## Setup

### Requirements

- Xcode 15+
- iOS 17+ device (HealthKit requires a real device, not Simulator)
- An [Anthropic API key](https://console.anthropic.com)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### 1. Clone

```bash
git clone https://github.com/adylagad/zzzync.git
cd zzzync
```

### 2. Add your API key

```bash
cp Config.xcconfig.example Config.xcconfig
```

Open `Config.xcconfig` and set your key:

```
CLAUDE_API_KEY = sk-ant-api03-...
```

`Config.xcconfig` is gitignored — your key never touches source control.

### 3. Generate the Xcode project

```bash
xcodegen generate
```

### 4. Open and run

```bash
open zzzync.xcodeproj
```

Select your device, hit Run. Grant HealthKit and Calendar permissions when prompted.

---

## Project Structure

```
zzzync/
├── Core/
│   ├── AppState.swift              # @Observable root state
│   └── Extensions/
│       ├── Date+Circadian.swift    # sleepMidpoint(), timeString helpers
│       └── Color+Zzzync.swift      # Design system colors
├── Models/                         # Codable structs (Supabase-ready)
│   ├── SleepRecord.swift
│   ├── BiometricRecord.swift
│   ├── FoodLog.swift + MetabolicAuditResult
│   ├── EnergyForecast.swift + CognitiveClash
│   └── BioProtocol.swift + ProtocolItem
├── Services/
│   ├── HealthKitService.swift      # Sleep/HRV/RHR queries + mock fallback
│   ├── CalendarService.swift       # EventKit wrapper
│   ├── ClaudeService.swift         # All 4 AI analysis methods
│   ├── FoodLogService.swift        # Photo → base64 → Claude Vision
│   ├── LocalStore.swift            # UserDefaults + Supabase write-through
│   └── SupabaseService.swift       # Anonymous auth + CRUD
├── ViewModels/                     # @Observable, one per tab
└── Views/
    ├── Dashboard/                  # Sync Score ring, metric tiles
    ├── JetlagMap/                  # 7-day chart, Claude narrative
    ├── MetabolicAudit/             # Food log list, expandable cards
    ├── EnergyForecast/             # Energy curve, clash list
    ├── BioProtocol/                # Daily timeline
    ├── Onboarding/                 # Permission flow
    └── Shared/                     # LoadingCardView, InsightBubble, MetricTile
```

---

## How the AI works

All Claude calls use a chronobiology-focused system prompt that frames Claude as a circadian rhythm specialist. Every response is requested as structured JSON and decoded into typed Swift models — no markdown parsing for data, only for narrative text.

```
You are an expert chronobiologist and circadian rhythm specialist. Analyze biological
process timing — sleep, HRV, RHR, nutrition — against external schedule demands to
identify Social Jetlag and metabolic desynchrony. Respond in JSON only.
```

Four analysis methods in `ClaudeService.swift`:

| Method | Input | Output |
|---|---|---|
| `analyzeSocialJetlag` | 7 sleep records + calendar events | `SocialJetlagResult` with score + narrative |
| `auditFoodLog` | Food photo/description + biometrics | `MetabolicAuditResult` with verdict + insight |
| `generateEnergyForecast` | Today's events + biometrics + last sleep | `EnergyForecast` with hourly curve + clashes |
| `generateBioProtocol` | Jetlag result + forecast + recent meals | `BioProtocol` with 24h timeline |

---

## Mock Data

HealthKit requires a real device with health data. If no data is available (Simulator or fresh device), `HealthKitService` falls back to a built-in mock that tells a clear Social Jetlag story: a night-owl chronotype with weekday 12AM–1AM bedtimes shifting to 2AM–3AM on weekends, HRV in the 28–44ms range, RHR 57–66bpm.

---

## Roadmap

See [NEXT_PHASES.md](NEXT_PHASES.md) for the full roadmap. Highlights:

- **Phase 2** — Supabase Edge Function proxy (move Claude key off device), full cloud sync, Sign in with Apple
- **Phase 3** — Gmail/Outlook integration for email stress signals in the Energy Forecast
- **Phase 4** — Proactive notifications (Bio-Protocol reminders, jetlag drift alerts)
- **Phase 5** — Android via Health Connect
- **Phase 6** — Oura, Whoop, Garmin deep integration

---

## License

MIT
