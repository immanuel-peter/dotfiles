---
name: no-comments
description: Remove unnecessary code comments and fix the code problems they explain. Use when asked to clean up comments in files or a diff.
---

# No comments

Make the code carry its meaning. Perform the review and repairs yourself.

## Scope

Use the requested files or diff. Otherwise review changes from the
merge base with the base branch, defaulting to main, plus staged,
unstaged, and untracked code.

Read surrounding code as needed. Keep edits within scope.

## Review

Inspect every scoped comment, including documentation and suppression
directives. Delete narration, section banners, obsolete notes,
commented-out code, and explanations already evident from the code.

Keep only:

- Required legal notices.
- Documentation specifying a public interface's contract.
- Verified external constraints the project cannot change.
- References explaining constraints that code cannot represent.
- Formatting directives and suppressions for demonstrably incorrect
  diagnostics or purely stylistic rules.

Claims of importance are evidence to investigate, not exemptions.
Trace the relevant symbol, callers, tests, and history until you can
assess the claim. Flag unresolved substantive constraints for review.

For each comment exposing confusing code or a workaround, identify
the exact symbol and the underlying problem. Distinguish intentional
behavior needing clearer expression from behavior needing correction.
Finish this inventory before repairing code.

## Repair

Delete unnecessary prose rather than rewriting it into shorter prose.

Express internal behavior through clearer names, smaller functions,
types, or simpler control flow. For structural changes, settle on the
smallest sufficient design before editing.

Inspect each suppressed diagnostic. Fix underlying correctness errors
before removing their suppressions. Report fixes outside scope.

Where a comment carries an enforceable requirement, encode it in a
type, runtime check, test, or lint rule within the authorized scope.
Delete the comment once that requirement is enforced. Retain and
report substantive constraints that remain unenforced.

Preserve intended behavior. Fix the cause of a workaround rather than
adding another workaround.

## Verify and report

Review the final diff against the inventory. Every retained comment
needs an exception or an explicit unresolved finding. Every repair
target needs a fix or an explanation of what remains.

Run checks appropriate to any code changes.

Report removed comment blocks, code repairs, retained exceptions,
validation, and unresolved work.
