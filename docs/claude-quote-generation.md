# Motiva — quote generation brief (for Claude)

Copy everything below the line into Claude Pro once. Keep this file in the repo as the source of truth. When you need quotes, add a final line: `TOPIC TO GENERATE NOW: <exact name>`.

---

## What Motiva is

**Motiva** is an iOS app (`com.motiva.dailyquotes`) for daily motivation quotes. Users:

- Swipe vertically through short, multi-line quote cards (like a feed).
- Follow **topics** to focus the feed.
- Get **local push notifications** (“Motiva” title + quote body) on a schedule they set (e.g. 10× per day between 9:00 AM and 10:00 PM).

Quotes must work as **in-app cards** (with line breaks) and as **notification text** (newlines become spaces; keep each quote readable in one short paragraph, ideally under ~120 characters when flattened).

**Voice:** direct, modern, inclusive; can be tough-love or spiritual when the topic calls for it. No author attributions, hashtags, or emojis unless we ask.

**Hard limits:** no hate, slurs, or content targeting protected groups. No medical/legal/financial advice framed as fact. **Unfiltered (NSFW)** = bold, flirty, confident, spicy — **not** explicit pornography or graphic sexual content (App Store).

---



## All topics Motiva wants (canonical list)

Use these **exact display names** when generating batches. We will tell you which one to focus on each session.

### Onboarding / explore (primary catalog — build quote libraries here)


| #   | Topic name            | Notes                                                   |
| --- | --------------------- | ------------------------------------------------------- |
| 1   | **Success**           | Ambition, winning, discipline, career momentum          |
| 2   | **Life lessons**      | Wisdom, mistakes, perspective, aging                    |
| 3   | **Unfiltered (NSFW)** | Spicy, unfiltered, confident; App Store–safe            |
| 4   | **Mental health**     | Anxiety, peace, therapy-adjacent **without** diagnosing |
| 5   | **Motivation**        | Action, discipline, “do the thing”                      |
| 6   | **Faith**             | Spiritual, prayer, trust, purpose (interfaith-friendly) |
| 7   | **Love**              | Relationships, romance, self-love, heartbreak           |
| 8   | **Mental toughness**  | Grit, resilience, discomfort, athletes/mindset          |
| 9   | **Deep**              | Existential, reflective, late-night tone                |
| 10  | **Overthinking**      | Rumination, calm mind, letting go                       |
| 11  | **Affirmations**      | “I am…” style, present-tense, empowering                |




### Also in the app (merge into same catalog — some overlap onboarding)


| #   | Topic name             | Notes                                               |
| --- | ---------------------- | --------------------------------------------------- |
| 12  | **Feeling sassy**      | Witty, bold, main-character energy — **free tier**  |
| 13  | **Self-respect**       | Boundaries, standards, walking away — **free tier** |
| 14  | **Being present**      | Mindfulness, one day at a time                      |
| 15  | **Unconditional love** | Compassion, kindness, showing up for people         |
| 16  | **Personal growth**    | Change, outgrowing, becoming                        |
| 17  | **Confidence**         | Self-belief, doubt vs action                        |


**Free users** can use topics: **Feeling sassy**, **Self-respect**, **Motivation** (plus default feed). Everything else is Premium in the product plan.

**Motivation** appears in both onboarding and free tier — one shared pool of quotes.

### Separate from topics: “For You” / featured

Not a topic users pick — a **mixed feed** when no topic is selected. We also want standalone **featured** quotes (same format) that feel premium and varied. Say `TOPIC TO GENERATE NOW: Featured` when we want that batch.

---



## Current content status (engineering)

- **In code today:** only 7 topics in `QuoteLibrary` (Feeling sassy, Self-respect, Being present, Unconditional love, Personal growth, Confidence, Motivation) with **5 quotes each**, plus **8 featured** → **43** unique lines total.
- **Onboarding UI** already shows the **11 onboarding topics** above; most do **not** have quote files yet — that’s what we’re filling in with you.

**Target per topic (v1):** **40–50 unique quotes** per topic name (we may start with 20 and expand).

---



## Output format (required every time)

When we name a topic, respond with:

1. **Topic:** exact name from the table
2. **Swift array snippet** — ready to paste into `QuoteLibrary.swift`:

```swift
// Topic: "<Name>"
quotes: [
    "Line one\nLine two",
    "Another quote\nSecond line",
],
```

1. **Rules for each string:**
  - Use `\n` for line breaks (typically **2–4 short lines** per quote).
  - Double quotes only; escape internal `"` if needed.
  - **No duplicates** within the batch and avoid near-duplicates of clichés we already shipped (e.g. “Small steps are still steps forward”).
  - Each quote must read well if `\n` is replaced by a space (notification preview).
2. **Optional footer:** 2–3 quotes you’d flag for **17+** age rating (usually only **Unfiltered (NSFW)**).

Do **not** generate Swift for other topics unless we ask.

---



## Example follow-up messages (we send after the brief)

- `TOPIC TO GENERATE NOW: Mental health` — 40 quotes, Swift array only.  
- `TOPIC TO GENERATE NOW: Unfiltered (NSFW)` — 40 quotes; App Store safe.  
- `TOPIC TO GENERATE NOW: Featured` — 30 standalone featured quotes.  
- `TOPIC TO GENERATE NOW: Success` — 20 quotes first pass, then another 20 in a second message.

---



## Reference: quotes already in the app (avoid repeating)

Featured includes lines like: “Small steps are still steps forward”, “Your peace is worth protecting”, “Make room for the person you are becoming”, “Investing in yourself is never a gamble”, etc. Topic pools each have 5 lines in repo — assume we’ll replace/expand those when we integrate your batches.

---

*Last updated for Motiva topic list: onboarding 11 + library 6 unique extras (Motivation shared).*