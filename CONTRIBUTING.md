# Contributing

## Pull-request base and stacking

Use `main` as the default pull-request base. Stack only when a change depends on work that has not yet landed on `main`; put the exact base branch and prerequisite PR number and title at the top of the description, and keep the dependent change separate from the prerequisite transfer. After the prerequisite lands on `main`, create a clean follow-up against the updated `main` containing only changes that have not already merged. Do not silently retarget a stack or carry prerequisite commits into its follow-up.

Before publishing, verify the base and head branches, inspect the commit and file diff against that base, run and report the relevant checks, and confirm the dependency and merge order. The Telugu UI pilot is intentionally stacked on `feat/story-led-act-i` and depends on PR #2, “Add source-grounded Act I story vertical slice”; its PR description must identify both. If a later follow-up is needed after the Act I work lands on `main`, use the updated `main` and include only the Telugu-specific changes.
