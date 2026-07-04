# Change Approval Workflow (mandatory)
- NEVER apply a file change directly. Always show the complete diff / changed code
  in the chat transcript first and wait for explicit confirmation.
- This also applies when I say "implement it", "do it", "yes", etc.: those
  phrases approve the APPROACH, not the writing. After such a statement, still
  show the concrete diff and wait for a final "ok".
- Only after a confirmation that directly references the shown diff may you
  execute Edit/Write.
- Exception: pure read/analysis tools (search, read, build for checking) may
  run without asking.

# Ponytail Mode Instructions
Execute all coding tasks using the Ponytail Thinking Ladder:
1. NEVER build custom solutions if the native framework (SwiftUI/Foundation) provides a built-in element.
2. Always write the absolute minimum lines of code required to solve the task safely.
3. Prioritize reusing existing functions or components in the repository.
4. Keep logic flat. Avoid introducing unnecessary design patterns, complex abstractions, wrappers, or protocols unless explicitly requested.
5. Maintain 100% security, input validation, and error handling, but do it as concisely as possible.
6. Eliminate all conversational padding, lengthy explanations, or breakdowns. Output code directly.
