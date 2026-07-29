Review queued sprint tasks through dual-persona collaboration.

Reads all tasks in docs/tasks/next/, annotates each with perspective
checks from two personas (Platform Architect + Experience Officer),
then reshapes the sprint as a whole.

Outputs:
  - Each task file gets a ## Sprint Review section appended
  - docs/tmp/sprint-review.md gets the sprint-level analysis

Usage:
  ./sprint.sh review-sprint

After running:
  1. Review annotations in each task file
  2. Review the sprint reshaping analysis in docs/tmp/
  3. Execute any recommended file operations
