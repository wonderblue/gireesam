# Design Direction — Gireesam Account Layer

## Theme Name

**Ledger in the Lantern Light**

## Intro

Extend the existing warm, hand-painted Vizianagaram escape world with a restrained account layer that feels like a stitched travel ledger: useful, legible, and subordinate to the comic chase.

## Design movement

Keep the game world expressive and tactile. Account actions should feel like small paper tabs and ledger stamps rather than a modern dashboard dropped over the stage.

## Core principles

- Make account state understandable in one glance.
- Never hide offline play behind login.
- Show sync as a calm status, not a blocking spinner.
- Keep profile, progress, and records readable in English UI while preserving the game's existing dialogue/language content.
- Make logout and retry obvious and reversible.

## Color philosophy

Reuse the existing cocoa, parchment, mustard, teal, and rose palette. Use teal for connected/synced states, mustard for local-only or pending states, and rose only for errors or sign-out consequences.

## Layout paradigm

Use a compact account card on the title screen and a small account drawer/modal reachable from the same card. Put the player's name and sync state first, then progress summary, then Login/Logout/Sync actions. Avoid adding a persistent gameplay overlay beyond a small sync badge.

## Signature elements

Ledger lines, stitched dividers, a small account seal, and a two-state sync mark: cloud-and-seal for synced, folded-paper mark for local-only.

## Interaction philosophy

Login is always a direct button action. Sync is optimistic for ordinary progress, with server reconciliation and a visible retry state. Offline failure never interrupts a run.

## Animation

Use the existing gentle felt/card motion. Account state changes may fade or stamp in; no blocking transitions or high-frequency counters.

## Typography system

Use the existing bundled UI fonts and current English UI strings. Keep labels short enough for the game's established panels and preserve readability at the logical viewport.

## Brand essence

A smooth-talking escape artist who keeps one more ledger than he admits.

## Brand voice

UI copy is plain and reassuring; Gireesam's personality stays in dialogue and flavor text, not in ambiguous account/security language.

## Wordmark/logo

Reuse the existing Gireesam title artwork and favicon. No new branding asset is needed for this functional account layer.

## Signature brand color

Warm cocoa `#6A351F`, with teal `#2E8B7A` as the trustworthy sync accent.
