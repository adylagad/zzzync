This is a much tighter, more specialized build. By focusing on **zzzync**, you are targeting the specific friction between "The Calendar" (Corporate Time) and "The Body" (Biological Time).

Since you’re excluding environmental factors like light, the app becomes a **pure data-correlation powerhouse** using Claude to map internal bio-signals against external productivity demands.

---

# PRD: zzzync (The Social Jetlag Resolver)

## 1. Executive Summary

**zzzync** is a circadian alignment platform that bridges the gap between Apple Health/Google Health Connect, your professional schedule (Calendar/Email), and your nutrition. It identifies **Social Jetlag**—the specific biological stress caused by the mismatch between when your body wants to function and when your life demands it.

---

## 2. The Problem Space

- **Social Jetlag:** The "Monday Morning" feeling. Users' internal clocks shift late on weekends, but their calendars stay fixed at 8:00 AM on Mondays.
- **Digestive Desynchrony:** Users eat based on meeting gaps, not biological hunger windows, leading to chronic stomach upset and brain fog.

---

## 3. Core Features (The "zzzync" Suite)

### A. The "Social Jetlag" Map

- **Data Sources:** Wearable Sleep Midpoints (last 7 days) vs. First Calendar Event of the day.
- **Claude’s Role:** Calculate the **Chronotype Drift**.
- **The Insight:** _"Your body is currently living in the London time zone, but your calendar is in New York. You are experiencing a 5-hour Social Jetlag."_

### B. The "Metabolic Window" Auditor (Food + Bio-Sync)

- **Input:** User uploads a photo or text log of a meal.
- **Logic:** Claude compares the meal timestamp against the user's **Resting Heart Rate (RHR) Trend** and **HRV**.
- **The Verdict:** Claude determines if the stomach upset is caused by "Off-Clock Eating" (e.g., eating a high-protein meal during the biological "melatonin window").

### C. The "Workload vs. Energy" Forecast (Calendar + Email)

- **Integration:** Scan Calendar for meeting density and Email for "High Priority" or "Stressful" senders.
- **Claude’s Role:** Identify "Cognitive Clashes."
- **The Insight:** _"You have a high-stakes board meeting at 2:00 PM, which is your predicted 'Circadian Trough' (lowest energy). Suggesting a 15-minute 'Biological Power Up' at 1:30 PM."_

---

## 4. Technical Architecture

| Layer       | Component              | Function                                                                                      |
| :---------- | :--------------------- | :-------------------------------------------------------------------------------------------- |
| **Input A** | **Wearable APIs**      | Sleep stages, HRV, RHR, and Activity.                                                         |
| **Input B** | **Google/Outlook API** | Meeting times, email frequency, and "Deep Work" blocks.                                       |
| **Input C** | **Claude Vision/Text** | Food logging (identifying macros and timing).                                                 |
| **Engine**  | **Claude 3.5 Sonnet**  | **The Auditor:** Correlates the three inputs to find the "Why" behind fatigue/stomach issues. |
| **Output**  | **zzzync UI**          | A visual "Sync Score" and a daily "Bio-Protocol."                                             |

---

## 5. Example User Scenarios

### Scenario 1: The "Why am I tired?" (Social Jetlag)

- **The Data:** User slept 8 hours, but their sleep midpoint shifted 3 hours later on Saturday/Sunday.
- **The Calendar:** First meeting is Monday at 8:30 AM.
- **zzzync Analysis:** Claude explains that while the _quantity_ of sleep was fine, the _timing_ shift caused a hormonal lag. Result: Fatigue.

### Scenario 2: The "Why is my stomach upset?" (Metabolic Timing)

- **The Data:** User ate a burger at 9:00 PM. Wearable shows RHR stayed elevated (+10 bpm) until 4:00 AM.
- **zzzync Analysis:** Claude correlates the late-night calorie intake with the lack of cardiovascular recovery. Result: Morning nausea and "Heavy" feeling.

---

## 6. The "Hackathon" Differentiator: The "Bio-Protocol"

Instead of a static report, **zzzync** generates a dynamic schedule for the next 24 hours:

1.  **Caffeine Window:** "Wait until 10:30 AM (Your cortisol peak is naturally high right now)."
2.  **Fastest Brain Window:** "Schedule your email replies for 11:00 AM."
3.  **Digestive Sunset:** "Stop all solid food by 7:30 PM to avoid tomorrow's stomach upset."

---

## 7. Success Metrics

- **Correlation Depth:** Does the app identify that "Nausea" is linked to "Late Meeting Stress + Late Night Eating"?
- **Clarity:** Can the user understand their "Social Jetlag" score in under 5 seconds?
- **Actionability:** Does the app provide a specific "Syncing" task?

---

### Implementation Note for the Hack:

Focus your **System Prompt** for Claude on **"Chronobiology."** Tell Claude it is an expert in the _timing_ of biological processes.

**The Winning Pitch:** "Google tells you _what_ is wrong; **zzzync** tells you _when_ you went wrong—and how to get back in sync."

Does this refined PRD align with the technical stack you’re building right now?
