# Phase 5 Copilot Prompt: Stabilization and Cutover

You are finalizing a React-to-Blazor migration.

## Goal
Validate parity, harden reliability, and prepare safe cutover to the Blazor frontend.

## Tasks
1. Run end-to-end functional parity checks using the Phase 0 checklist.
2. Verify route protection and auth behavior across all protected and public routes.
3. Validate error handling and empty/loading states for users and series workflows.
4. Perform responsive checks for major layouts and forms.
5. Remove obsolete React frontend wiring only after parity is confirmed.
6. Update project documentation with:
   - run/build commands
   - environment configuration
   - migration notes
7. Prepare a rollback/fallback plan.

## Constraints
- Do not remove fallback options before validation is complete.
- Keep changes reviewable and low risk.
- Prefer small, verifiable cutover steps.

## Deliverables
1. Final parity report.
2. Cutover checklist and rollback plan.
3. Updated docs and run instructions.
4. Final list of residual risks.

## Output Format
Return:
1. Validation results
2. Cutover readiness status
3. Rollback steps
4. Residual risks
