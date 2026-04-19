# Design System — CuePrompt

## Product Context
- **What this is:** macOS-native smart teleprompter that uses voice recognition to pace scrolling to natural speech
- **Who it's for:** Remote professionals presenting on camera — PMs, sales engineers, founders, consultants
- **Space/industry:** Presentation tools, teleprompter utilities
- **Project type:** Native macOS desktop app (SwiftUI)

## Aesthetic Direction
- **Direction:** Industrial Minimal
- **Decoration level:** Minimal — typography and spacing do all the work
- **Mood:** Premium dark utility. The app lives in the hardware (the notch) and should feel like an extension of the Mac itself. Think Raycast, Loom's overlay, or a broadcast studio control panel. Confident, competent, invisible during the actual presentation.
- **Reference sites:** Raycast, Loom, macOS Dynamic Island (iOS), professional broadcast teleprompters

## Typography
- **Display/Hero:** SF Pro Display (system) — native macOS feel, optimized for the platform
- **Body:** SF Pro Text (system) — legible at all sizes, integrates with accessibility features
- **UI/Labels:** SF Pro Text (same as body)
- **Data/Tables:** SF Mono — tabular-nums for slide counters, timecodes, WPM, word counts
- **Code:** SF Mono
- **Prompter default:** New York (Apple serif) — teleprompters traditionally use serif for readability at distance. Users can override in settings.
- **Loading:** All system fonts, no bundling required
- **Scale:**
  - Caption: 11px / SF Pro Text
  - Footnote: 12px / SF Pro Text
  - Body: 15px / SF Pro Text
  - Title 3: 17px / SF Pro Display, semibold
  - Title 2: 22px / SF Pro Display, bold
  - Title 1: 28px / SF Pro Display, bold
  - Large Title: 36px / SF Pro Display, bold
  - Prompter: User-configurable 16–64pt / New York

## Color
- **Approach:** Restrained — one distinctive accent, everything else serves readability
- **Primary accent:** #E8A430 (Amber) — broadcast studio warmth, not another blue Mac app. Used for CTAs, active states, slide markers, current-word highlight
- **Accent hover:** #F0B84D
- **Accent muted:** rgba(232, 164, 48, 0.15) — backgrounds for active sidebar items, tags
- **Surfaces:**
  - Primary (prompter): #000000 — pure black, no distraction
  - Surface (windows): #1C1C1E — Apple dark gray, distinguishes from prompter black
  - Elevated: #2C2C2E — cards, sidebars, grouped sections
  - Hover: #3A3A3C — interactive hover states
- **Text:**
  - Primary: #FFFFFF — prompter text, headings
  - Secondary: #E5E5E7 — body text, sidebar items
  - Muted: #8E8E93 — labels, section titles, timestamps
  - Faint: #48484A — placeholder text, disabled states
- **Semantic:**
  - Success/Mic active: #30D158 — the green dot means "listening"
  - Warning: #FF9F0A — model downloading, connection issues
  - Error: #FF453A — permission denied, speech failures
  - Info: #0A84FF — Chrome extension connected, tips
- **Dark mode:** This IS the dark mode. The app is dark-first.
- **Light mode:** Surface #FFFFFF, elevated #F2F2F7, accent darkened to #D4912A for contrast

## Spacing
- **Base unit:** 8px
- **Density:** Comfortable — pro tool but not cramped
- **Scale:** 2xs(2) xs(4) sm(8) md(16) lg(24) xl(32) 2xl(48) 3xl(64)

## Layout
- **Approach:** Grid-disciplined for home/settings. The prompter overlay is a full-bleed single-column text area.
- **Home window:** Sidebar (200px) + content area. Min 500x400.
- **Prompter overlay:** Full width of target screen, user-configurable height (200–800px), anchored to top.
- **Pill (collapsed):** Sits flush with notch, extends left with expand button.
- **Max content width:** 960px for settings forms
- **Border radius:**
  - sm: 4px — tags, small badges
  - md: 8px — buttons, inputs, cards, pill bottom corners
  - lg: 12px — windows, overlay panels, home window sections
  - full: 9999px — status dots, theme toggle pill
  - Prompter overlay: 0 top, 16px bottom corners (flush with screen top)

## Motion
- **Approach:** Minimal-functional
- **Hero animation:** Pill ↔ expanded transition — this is THE animation. Should feel smooth and deliberate.
- **Easing:** enter(ease-out: 0.16, 1, 0.3, 1) exit(ease-in: 0.55, 0.055, 0.675, 0.19) move(ease-in-out)
- **Duration:** micro(80ms) short(180ms) medium(300ms) long(500ms)
- **Rules:**
  - Hover states: micro (80ms)
  - Button presses, toggles: short (180ms)
  - Pill expand/collapse, window transitions: medium (300ms)
  - Countdown overlay: long (500ms per digit)
  - Prompter scroll: continuous, driven by speech engine (not animated in steps)

## Prompter-Specific Rules
- Background is always pure black (#000000)
- Text is white, read text dims to user-configurable opacity (10–80%)
- Current reading position stays vertically centered
- Top and bottom gradient fade masks (60px) ease text in/out
- Ear controls (flanking the notch) use muted white text, never the accent
- Status bar at bottom: SF Mono, rgba(255,255,255,0.3)
- The amber accent appears ONLY for the current-word highlight underline

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-17 | Initial design system created | Created by /design-consultation based on product context and design knowledge |
| 2026-04-17 | Amber accent #E8A430 | Broadcast studio warmth. Differentiates from every blue-accented Mac utility. |
| 2026-04-17 | System fonts only | Native macOS feel, no bundling overhead, accessibility integration |
| 2026-04-17 | New York as prompter default | Professional teleprompters use serif. Apple's serif is high quality and already on every Mac. |
| 2026-04-17 | Dark-first design | Teleprompter context demands dark. Home window matches for coherence. |
