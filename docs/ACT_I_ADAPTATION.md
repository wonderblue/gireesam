# Act I vertical slice: adaptation notes

## Source and scope

This slice is grounded in the [Telugu Wikisource transcription of *Kanyasulkam*, Act I, permanent revision 252038](https://te.wikisource.org/w/index.php?title=కన్యాశులకము/ప్రథమాంకము&oldid=252038). The page labels the reproduced work **1961**, names Gurajada Apparao as its author, and links a scan used for the transcription. This identifies the chosen witness; it is not a claim that the page is a critical edition or the only authoritative text. The selected act moves from **Bonkula Dibba** to **Madhuravani’s room**.

This is a focused, playable adaptation of two Act I locations, not a complete adaptation of the play and not a translation. It contains no newly fabricated Telugu lines and presents no game text as a quotation. English scene copy and connective narration are original adaptation writing, explicitly marked **ADAPTED SCENE** in game. The main menu retains the separate ordinary platformer route.

## What the scenes stage

At Bonkula Dibba, Gireesam admits spending the 20 rupees taken from Pootakullamma for provisions on dancing girls. He looks for an exit through Venkatesam, whose failed exam and account of receiving little teaching puncture Gireesam’s tutor performance. Gireesam wraps requests for books, money, sweets, cigars, and transport in that performance.

In Madhuravani’s room, she questions Ramappantulu’s terms. The witness has him offer 200 rupees toward the debts she names, reach for her, and see her refuse both the unwanted touch and the money. The game’s visible notes depict that witnessed offer; the optional **case note** is a new UI/mechanic, not a ledger, receipt, or object claimed to appear in the text. It records only the amount offered and her refusal. If the player shares this neutral note, an optional review marker opens; Madhuravani decides whether the information matters to her terms. Choosing not to record it leaves her core boundary and final scene fully available. Neither path changes score, time, reputation, money, romance, or anyone’s consent.

The source sequence has **Ramappantulu hide under the bed before Gireesam enters**. Gireesam later invents a Hyderabad appointment and hides there too when Pootakullamma arrives. Her broom accidentally hits Ramappantulu; Gireesam then gets out and knocks him while escaping. The playable stealth segment preserves the two men’s sequence and makes the farce about their conduct. It does not target Pootakullamma or Subbi. The final Madhuravani-led “terms” card is original adaptation framing, not a claim that its English wording occurs in the witness.

## Character intent and boundaries

Madhuravani is not a prize, a route gate, or an obstacle to be overcome. Her financial decisions, consent, prior commitments, and final terms remain hers; Gireesam’s deception and Ramappantulu’s pressure earn no rewards. Pootakullamma is not the butt of the search gag, and Subbi is not a playable target or joke. This two-location milestone does not implement the broader household negotiation/evidence loop or decision arcs for Buchamma and Venkamma; those belong in later, source-checked story work rather than being invented into this slice.

Keep comedy aimed at Gireesam’s pretension and situational farce exposing the men’s behaviour. Do not turn any woman’s boundary, consent, poverty, or circumstances into a collectible, penalty, or punchline.

## Play and implementation

Choose **PLAY ACT I · STORY** at the title screen. Move between labelled story markers and interact with **E**, gamepad **Y**, or the on-screen action button. Recording the 200-rupee offer and refusal unlocks an optional terms-review stop; leaving the private exchange unrecorded skips only that stop. At **Ramappantulu under the bed**, observe his hiding beat. At the later search, hide Gireesam for the short stealth hold; peeking resets the hold. After the broom beat, reach Madhuravani’s final terms.

The route is implemented in `scenes/story_game.tscn`, `scripts/act_i_story.gd`, `scripts/act_i_director.gd`, and `data/story/act_i_*.json`. It is isolated from the standard stage registry and standard reputation/score systems. Story choices do not award rewards.

## Language, access, and release checks

The new scene prose is English. The project has English and Simplified Chinese JSON catalogs, but the current runtime localization service registers **English only** (`I18n.SUPPORTED_LOCALES`). Its existing Godot localization contract expects `zh-CN` and fails on the missing runtime catalog entry; this slice does not change that loader mismatch. It adds no Telugu translation, Telugu interface strings, or Telugu font. Telugu glyph coverage, shaping, and rendering are **not tested or claimed**. Telugu localization and font validation remain release requirements for a Telugu-language adaptation.

The route provides keyboard, gamepad, and on-screen touch interaction. The story contract checks the title entry, E/Y bindings, touch-button presence, and story progression; it does not yet simulate activation of every input path. There has been no story-specific screen-reader, switch-access, low-vision, or comprehensive responsive-layout acceptance. Do not describe accessibility as fully verified.

Run `pnpm test:act-i` for source facts, route progression, the evidence-access consequence, both hiding beats, and the Madhuravani-led ending. Run `pnpm test:contract` for the existing gameplay/UI/tuning/VFX regressions, and `pnpm test:checks` for exported-pack profile and loader-language checks. The Web export builds with `pnpm export`; `pnpm verify-export` includes the Act I contract against the pack. On the current Godot 4.7.2 baseline, that full verifier is blocked by the existing `test/exported_pack_boot.gd:81` access to `FontVariation.data`, which errors and times out before the remaining suite completes. A targeted Act I run against `dist/index.pck` is useful but does not replace resolving that broader verifier failure or interactive build acceptance.

## Rules for future contributors

- Keep each historical claim traceable to the linked permanent witness revision and record any source/edition change here.
- Distinguish source actions from invented mechanics and staging. The case note may repeat only the witnessed 200-rupee offer and refusal; do not invent a ledger balance, receipt, debt total, or financial verdict.
- Do not fabricate Telugu lines, machine-translate lines and present them as text, or put quotation marks around adaptation prose. Get exact text and attribution/licensing review before adding a quotation.
- Preserve the two-location order, the fact that Ramappantulu hides before Gireesam, and the later shared hiding/search sequence. Mark any deliberate compression as adaptation.
- Keep Madhuravani’s choices hers. An evidence choice may open or omit optional context, but must not alter her core refusal, access to her final terms, or consent.
- Aim humour at Gireesam’s pretension and farce exposing the men. Never make Pootakullamma or Subbi the target.
- Keep traversal purposeful—reaching a person, observing an exchange, or hiding—not a generic jump gauntlet or combat sequence.
- Do not describe this Act I slice as a full-play adaptation or claim untested Telugu, accessibility, or export support.
