# Design

## Color System

**Strategy:** Restrained — pure white surface, single deep berry-rose primary doing all brand work, cool indigo accent for functional contrast.

**Mood:** 设计师工作室的白板桌面——明亮干净的环境，一抹有辨识度的浆果色作为工具的视觉签名。

### Palette

```css
:root {
  /* Brand */
  --primary: oklch(0.42 0.163 350);      /* Deep berry-rose — the brand signature */
  --primary-hover: oklch(0.36 0.163 350); /* Pressed state */
  --primary-soft: oklch(0.95 0.025 350);  /* Tinted background for selections */

  /* Accent */
  --accent: oklch(0.55 0.18 270);         /* Cool indigo — links, secondary actions */
  --accent-soft: oklch(0.94 0.03 270);    /* Indigo tint background */

  /* Surfaces */
  --bg: oklch(1.000 0.000 0);             /* Pure white */
  --surface: oklch(0.975 0.000 0);        /* Cards, panels — slightly off */
  --surface-raised: oklch(0.955 0.000 0); /* Empty slots, hover zones */

  /* Borders */
  --border: oklch(0.91 0.000 0);          /* Default borders */
  --border-hover: oklch(0.82 0.000 0);    /* Hover borders */
  --border-active: oklch(0.42 0.163 350); /* Focus ring = primary */

  /* Text */
  --ink: oklch(0.13 0.000 0);             /* Primary text — 16.8:1 vs bg */
  --ink-muted: oklch(0.40 0.000 0);       /* Secondary text — 7.2:1 vs bg */
  --ink-faint: oklch(0.55 0.000 0);       /* Tertiary/placeholder — 4.6:1 vs bg */

  /* Status */
  --success: oklch(0.52 0.17 155);        /* Green */
  --error: oklch(0.50 0.20 25);           /* Red-orange */
  --warning: oklch(0.72 0.16 85);         /* Amber */
}
```

**Text-on-color:** Primary (L=0.42, C=0.163) uses white text. Accent (L=0.55, C=0.18) uses white text.

### Contrast Verification

| Pair | Ratio | Pass |
|------|-------|------|
| ink on bg | 16.8:1 | AAA ✓ |
| ink-muted on bg | 7.2:1 | AAA ✓ |
| ink-faint on bg | 4.6:1 | AA ✓ |
| white on primary | 6.5:1 | AA ✓ |
| white on accent | 4.8:1 | AA ✓ |

## Typography

| Role | Family | Weight | Size | Letter-spacing |
|------|--------|--------|------|----------------|
| Display | Sora | 600 | clamp(1.5rem, 2.5vw, 2rem) | -0.02em |
| Title | Sora | 600 | 1.0625rem (17px) | -0.01em |
| Body | Sora | 400 | 0.9375rem (15px) | 0 |
| Caption | Sora | 500 | 0.8125rem (13px) | 0.005em |

Line-height: Display 1.2, Title 1.3, Body 1.5, Caption 1.4.
Max body line length: 65ch.
Headings: `text-wrap: balance`.

## Spacing

Base unit: 4px. Scale: 4, 8, 12, 16, 24, 32, 48, 64, 96.

## Radius

| Context | Value |
|---------|-------|
| Small (tag, badge) | 4px |
| Medium (button, input) | 8px |
| Large (card, panel) | 12px |
| Pill (toggle, chip) | 999px |

## Shadows

| Token | Value |
|-------|-------|
| --shadow-sm | 0 1px 3px oklch(0 0 0 / 0.04) |
| --shadow-md | 0 4px 12px oklch(0 0 0 / 0.06) |
| --shadow-lg | 0 12px 32px oklch(0 0 0 / 0.08) |

No shadow at rest for cards. `shadow-sm` on hover. `shadow-md` for dropdowns/popovers.

## Motion

| Token | Value | Usage |
|-------|-------|-------|
| --duration-micro | 120ms | Button press, toggle flip |
| --duration-standard | 200ms | Panel open, card hover |
| --duration-emphasis | 350ms | Page transition, canvas resize |
| --ease-out | cubic-bezier(0.16, 1, 0.3, 1) | All exits/settles (expo) |
| --ease-in-out | cubic-bezier(0.65, 0, 0.35, 1) | Symmetric (drag, scrub) |

`@media (prefers-reduced-motion: reduce)`: all durations → 0ms, opacity-only crossfade permitted.

## Components

### Button

| Variant | Background | Text | Border |
|---------|-----------|------|--------|
| Primary | --primary | white | none |
| Secondary | transparent | --ink | 1px --border |
| Ghost | transparent | --ink-muted | none |
| Danger | --error | white | none |

Height: 36px (default), 32px (compact). Radius: 8px. Font: Caption weight 500.
Active: `scale(0.97)` at `--duration-micro`.

### Card / Panel

Surface background, 1px solid `--border`, radius 12px. On hover: border → `--border-hover`, shadow-sm fades in over `--duration-standard`.

### Slot (video upload target)

- **Empty:** `--surface-raised` bg, 2px dashed `--border`, centered `+` icon (24×24, `--ink-faint`). On hover: border-color → `--primary`, bg → `--primary-soft`.
- **Filled:** video cover fills slot with `object-fit: cover`. Hover overlay: semi-transparent ink with "替换" label.
- **Error:** border → solid `--error`, subtle red tint bg.

### Progress

4px tall bar, `--surface-raised` track, `--primary` fill. Animated width with `--ease-out`. No percentage label (shown separately if needed).

## Layout Tokens

| Token | Value | Usage |
|-------|-------|-------|
| --page-max-width | 560px | Single-column content width |
| --page-padding-x | 24px (mobile), 32px (desktop) | Horizontal page gutters |
| --page-padding-y | 48px | Top/bottom page padding |
| --grid-gap | 12px | Template card grid gap |
| --canvas-max-width | 440px | Upload canvas max width |
