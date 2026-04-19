import Foundation

enum SystemPrompts {
    static let chronobiologist = """
    You are an expert chronobiologist and circadian rhythm specialist. You analyze the \
    timing of biological processes — sleep, heart rate variability (HRV), resting heart \
    rate (RHR), and nutrition — against external schedule demands to identify Social Jetlag \
    and metabolic desynchrony.

    Always speak in terms of:
    - Chronotype (early bird / night owl / intermediate)
    - Circadian phase (cortisol awakening response, afternoon trough, melatonin window)
    - Social Jetlag (discrepancy in hours between the biological midpoint of sleep and social obligations)
    - Metabolic timing (feeding windows relative to melatonin onset and digestive circadian clock)

    Use timezone metaphors when explaining jetlag to make the concept tangible \
    (e.g., "Your body is living in London but your calendar is in New York").

    IMPORTANT: Respond ONLY with valid JSON matching the schema provided in the user message. \
    No markdown fences, no explanation outside the JSON object.

    Keep text concise and glanceable:
    - Prefer short phrases over paragraphs
    - Keep most text fields under 12 words unless schema says otherwise
    - Avoid markdown formatting
    """

    static let socialJetlagSchema = """
    {
      "score": <integer 0-100, where 100 = perfect sync>,
      "jetlag_hours": <float, positive = body behind schedule, negative = body ahead>,
      "chronotype_drift": <string, short timezone metaphor phrase (max 10 words)>,
      "claude_narrative": <string, one concise sentence (max 14 words)>
    }
    """

    static let metabolicAuditSchema = """
    {
      "meal_description": <string, Claude-identified meal contents>,
      "timing_verdict": <"on_clock" | "borderline" | "off_clock">,
      "hours_from_digestive_sunset": <float, positive = after sunset, negative = before>,
      "metabolic_insight": <string, one punchy sentence (max 12 words)>,
      "claude_narrative": <string, one concise sentence (max 14 words)>
    }
    """

    static let energyForecastSchema = """
    {
      "hourly_energy_level": { "<hour_0-23>": <float 0.0-1.0>, ... },
      "cognitive_clashes": [
        {
          "event_title": <string>,
          "event_start_iso": <ISO8601 datetime string>,
          "predicted_energy_level": <float 0.0-1.0>,
          "severity": <"low" | "medium" | "high">,
          "suggestion": <string, short action phrase (max 8 words)>
        }
      ],
      "claude_narrative": <string, one concise sentence (max 14 words), include email pressure if relevant>
    }
    """

    static let bioProtocolSchema = """
    {
      "caffeine_window_start_iso": <ISO8601 datetime string>,
      "peak_brain_window_start_iso": <ISO8601 datetime string>,
      "peak_brain_window_end_iso": <ISO8601 datetime string>,
      "digestive_sunset_iso": <ISO8601 datetime string>,
      "protocol_items": [
        {
          "time_iso": <ISO8601 datetime string>,
          "category": <"caffeine" | "cognitive_work" | "meal" | "rest" | "exercise">,
          "title": <string, short action title (max 6 words)>,
          "rationale": <string, short why phrase (max 8 words)>
        }
      ],
      "claude_narrative": <string, one concise sentence (max 14 words)>
    }
    """

    static let fatigueCausalSchema = """
    {
      "summary": <string, direct answer to why tired (max 14 words)>,
      "causes": [
        {
          "title": <string, short cause label (max 4 words)>,
          "evidence": <string, concrete data point phrase (max 10 words)>,
          "impact_score": <integer 0-100>
        }
      ],
      "actions": [
        <string, short action phrase (max 7 words)>
      ]
    }
    """
}
