---
type: session
title: "Session cc-1111–1126 + cc-1400: Receipt Scanner Phase 2 — OCR quality, UI polish, dual-image"
created: 2026-06-18
updated: 2026-06-18
tags:
  - receipt-scanner
  - textract
  - ios
  - backend
  - lambda
status: complete
related:
  - "[[tyler/hot]]"
  - "[[tyler/index]]"
  - "[[gunnerteam/masterdb-developer-handoff]]"
---

# Session cc-1111–1126 + cc-1400: Receipt Scanner Phase 2

**Lambda:** v283 → v291 (8 deploys)
**iOS:** cc-1111 through cc-1126 + cc-1400, all committed to `main`
**Date:** 2026-06-18

---

## Summary

Full receipt-scanner quality pass. The first phase (cc-1100–1110) built the infrastructure. This session focused on OCR accuracy, description cleaning, UI correctness, and a dual-image best-of selection strategy for vendor-dependent OCR performance.

---

## Backend Changes (fieldportal.js)

### cc-1111 — Fix stale `parseAmount` reference (502 fix)
- `parseAmount` was renamed to `num` in cc-1108 but the TOTAL summary parse was missed.
- `ReferenceError: parseAmount is not defined` → catch → 502 → empty line items on iOS.
- Fix: `parseAmount(fieldByType(summary, 'TOTAL'))` → `num(fieldByType(summary, 'TOTAL'))`.
- Lesson added to CLAUDE.md: `node --check` passes on undefined-reference runtime errors; always grep the whole file for the old name before deploying a rename.

### cc-1112 — Sales Tax line item
- Tax was a summary field, silently dropped from line items → P&L undercounted by tax amount.
- Added tax block after line-item loop: tries `TAX` field, falls back to `TOTAL − SUBTOTAL`.
- `category: 'tax'`, sign-aware (refunded tax on return receipt → `credit`), skip if `< $0.01`.

### cc-1115 — Trailing-minus detection (ABC credit memos)
- ABC prints amounts with trailing minus: `110.00-`, `793.37-`. These parsed as positive (cost).
- Added `/-\s*$/.test(str)` to `num()`'s sign test alongside existing leading-`-`/`(`/`CR`.

### cc-1117 — Description cleaning, Freight line, category tagging, ABC vendor detection
- `cleanDescription()` v1: UPC strip + trailing item code strip + trailing price strip.
- Freight line: tries `SHIPPING_HANDLING_CHARGE`, falls back to label text scan for `FREIGHT|SHIPPING`.
- Each line item gains `category`: `item` | `tax` | `freight`.
- Vendor haystack extended to include `doc.Blocks` raw OCR text → ABC logo now detected.

### cc-1121 — Strip trailing stray numbers
- Stray price-like numbers leaked into descriptions: `2"X3" ALUM DOWNSPOUT - WHITE 110.01`.
- Added `/\s+\$?\d{1,3}(?:,\d{3})*\.\d{2}$/` to `cleanDescription()`.
- Dimensions like `4'X8'`, `3X3`, `2.7M` don't match (no trailing `.dd`).

### cc-1122 — Dual-image extraction with reconciliation
- `parseExpenseDoc(out)` extracted: pure fn, takes Textract response → parsed result or `null`.
- `reconScore(r)`: `|total − Σ(lines)|`; fallback 999,999 for no-total; Infinity for empty.
- Handler accepts `imageBase64Alt` (second image). Runs both through Textract, originally sorted by `reconScore`.
- Backward compatible: single image → single result.
- `audit` records `candidates` count.

### cc-1124 — Rewrite cleanDescription + drop empty/junk lines
- New approach: split on `\n`, apply 5 regex passes per segment, filter `length ≥ 2`, pick longest segment.
- Passes: `<A>` tax markers, `qty@unit` fragments, leading UPC, stray prices, item codes (letter+digit, 6+ chars).
- Longest-wins: product name is virtually always the longest readable token.
- `rawItem` / `rowText` / `desc` split: `rowText` keeps raw text (preserves `3@10.01` for qty parsing); `desc` = cleaned name for display/Colin.
- Skip guard tightened: `!desc || desc.length < 2`.

### cc-1126 — Best-of selection: prefer original, switch to B&W only when clearly better
- Pure sort by `reconScore` caused regression: B&W junk words ("me", "the", "be") reconciled closer numerically on ABC credit memos.
- `garbageFraction(r)`: fraction of items with description `< 4` chars or no 3+ letter run.
- Selection: `results[0]` (original) is default; switch to `results[1]` (B&W) only when:
  - `reconScore(bw) + 1.0 < reconScore(original)` — reconciles > $1 better
  - `garbageFraction(bw) ≤ garbageFraction(original) + 0.05` — no more garbled
- Preserves HD's B&W win (clean + exact); keeps ABC on original (readable).

---

## iOS Changes

### cc-1113 — Fix Unit $ truncation in verify row
- Moved Cost/Credit picker from 4th column of metrics `HStack` to its own row below.
- `Unit $` gains `frame(minWidth: 90)`, no longer squeezed.

### cc-1114 — Send original (non-B&W) image to Textract
- `makeScan` → `(bw: UIImage, ocr: UIImage)`: perspective-corrects once, captures color original, then applies B&W pipeline.
- `ScannedReceipt` gains `ocrImage: UIImage` field.
- `uploadScannedReceipt` sends `scan.ocrImage` (JPEG 0.85) to extract; PDF still uses `scan.pdfData` (B&W).
- Size guard: if JPEG > 5.25 MB, steps down to 0.7.

### cc-1116 — Multi-line wrapping description field
- `TextField("Description", ..., axis: .vertical)` with `lineLimit(1...3)`, `minimumScaleFactor(0.85)`, `fixedSize(horizontal: false, vertical: true)`.
- Still fully editable; short names render on one line.

### cc-1118 — Tax/freight grouping + reconciliation in verify UI
- `ReceiptLineCategory` enum: `item | tax | freight`. Added to `ReceiptLineDraft` with decode-tolerant `init(from:)` (defaults to `.item` when absent).
- `lineSum`, `receiptTotal`, `totalsMatch` computed properties.
- `lineRow` extracted to `@ViewBuilder` method; `Section("Line Items")` uses two `ForEach` passes with a "Taxes & Fees" divider.
- Items `ForEach` has `.onDelete` with `itemIndices` mapping; fees `ForEach` has same pattern.
- Summary section shows Receipt total + mismatch warning (`Color.appWarning`, non-blocking).

### cc-1119 — Move "Reading receipt…" HUD to top
- Both `scanHUD` and `errorHUD`: removed top `Spacer()`, changed `.padding(.bottom, 120)` to `.padding(.top, 60)`, added bottom `Spacer()`.
- `scanHUD` shape: `RoundedRectangle` → `Capsule()` (pill, matches job-name pill).
- Sits under safe area top + `topBar` (~52pt) at 60pt.

### cc-1120 — Delete any line + footer hint
- Fees `ForEach` gains `.onDelete` with `feeIndices` mapping (mirrors items pattern).
- `Section("Line Items")` converted to `header:` + `footer:` form (title string + footer isn't a valid SwiftUI init — must use trailing closures).
- Footer: "Swipe any line to delete. Use Add Line for anything the scan missed."

### cc-1123 — Send both original + B&W to extract
- `extractReceipt` gains `altBase64: String? = nil` param; body conditionally adds `imageBase64Alt`.
- `uploadScannedReceipt`: `asJpeg(_:)` closure tries quality 0.85 → 0.7 → 0.55 → 0.4, stops at ≤ 6.5 MB.
- `primary` = `ocrImage`; `alt` = `pages.first` (B&W).

### cc-1125 — Compact tax/freight rows; replace Net with Items vs Receipt total
- `lineRow` → dispatches to `itemRow` (full product layout) or compact fee row (read-only label + Amount + picker).
- `net` computed property removed (dead after Summary rewrite).
- Summary: "Items total" (unsigned `lineSum`) + optional "Receipt total" comparison + warning on mismatch.

### cc-1400 — Requests row icons contrast fix
- `requestRow` icon: flat `Color.appSecondary` glyph → white glyph on `themeManager.theme.secondary` filled `RoundedRectangle(cornerRadius: 11, style: .continuous)`.
- Disabled state: `Color.white.opacity(0.12)` fill + `0.4` opacity glyph.
- `themeManager` changed from `private` to `internal` in `JobGuidedView.swift` (extension-file access).

---

## Lambda Version History This Session

| Version | cc-prompt | Change |
|---|---|---|
| v284 | cc-1111 | parseAmount → num fix (502) |
| v285 | cc-1112 | Sales Tax line item |
| v286 | cc-1115 | Trailing-minus detection |
| v287 | cc-1117 | Item codes, Freight, category, ABC detection |
| v288 | cc-1121 | Trailing stray number strip |
| v289 | cc-1122 | Dual-image extraction + reconScore |
| v290 | cc-1124 | cleanDescription rewrite + junk-line drop |
| v291 | cc-1126 | garbageFraction + original-preferred selection |

---

## Key Patterns Established

**`node --check` does not catch runtime ReferenceErrors** — always grep the full file for the old name after renaming a helper.

**Dual-image OCR selection** — original color wins by default; B&W wins only when it reconciles > $1 better AND is no more garbled (garbageFraction within 0.05). Prevents numerically-close garbage from winning.

**cleanDescription segment approach** — split on newlines, apply passes per segment, filter short segments, pick longest. The longest surviving segment is reliably the product name.

**reconScore** — `|total − Σ(lines)|` for reconciliation distance. Fallback for no-total: `1_000_000 − lineCount` (prefer more lines).

**SwiftUI `Section` with header + footer** — must use trailing closure form `Section { content } header: { } footer: { }`. String title + footer is not a valid initializer.

**`private` on `@EnvironmentObject` in a split view** — blocks access from extension files. Remove `private` when the property is needed across the split; cite CLAUDE.md's split-file rule.
