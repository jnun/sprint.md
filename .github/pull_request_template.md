## Summary
<!-- Brief description of changes -->

## Related Task(s)
<!-- Reference task IDs from docs/tasks/ -->
- Closes #[TASK_ID]
- Related: `docs/tasks/[stage]/[ID]-[description].md`

## Changes Made
<!-- List key changes -->
-
-
-

## Testing
<!-- How were these changes tested? -->
- [ ] Manual testing completed
- [ ] Scripts run successfully
- [ ] Documentation updated

## Task Movement
<!-- Which tasks are moving through the pipeline? -->
```bash
# Tasks moving to review:
git mv docs/tasks/doing/ID-*.md docs/tasks/review/

# Tasks moving to done:
git mv docs/tasks/review/ID-*.md docs/tasks/done/
```

## Checklist
- [ ] Task ID referenced in commit message
- [ ] docs/sprintmd/DOC_STATE.md updated if new tasks created
- [ ] Task moved to appropriate folder
- [ ] Testing criteria from task completed
- [ ] Documentation updated if needed

---
*Following the sprint.md workflow: backlog → next → doing → blocked → review → done*