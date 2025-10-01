# Code Review Checklist

- Does this PR have a single, well defined topic?
- Do the changes seem like a reasonable way to accomplish
  the goals?
- Are the significant majority of the changes on-topic?
- **(important)** Are all existing tests preserved except for
  intentional, topic related behavior changes?
- Are there new tests for any new intended behavior?
- Is the code formatting reasonable?
- Is all the code in the right places?
  - UI code goes in UI files.
  - UI is broken into named components, and properly separated
    out into not-too-big-files.
  - Game logic goes into game logic files (optimally, of pure functions).
  - Schemas in schema files.
- Will merging this PR, as is, improve the code base?
- Did this PR raise the coverage threshold (by at least 1%, until it's 80%)?
