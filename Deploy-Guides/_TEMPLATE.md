# Deployment Guide — <TICKET> <Short Title>

> Produced during development. Update as the artifact changes; commit with the code.

## Artifact(s)
- <file / object name> — <what it is: view / business rule / .srd / report / script>
- Ticket: <SA-#####>

## Target environments
- <e.g. Play (P21Play @ P21Dev.allsurfaces.com) → Prod (P21 @ P21.allsurfaces.com)>

## Dependencies & deploy order
1. <e.g. deploy the VIEW to target env FIRST>
2. <then the front-end artifact (.srd / report / rule)>
- Notes: <what must exist first; cross-env order>

## Backward-compatibility notes
- <columns/behavior an older version still relies on — keep to avoid breaking it>

## Deploy steps
1. <exact file to run> against <server> / `USE [<db>]`
2. <next step>

## Verification
- <what to run/click> → expected: <result>

## Rollback
- <how to revert — saved prior definition / previous file version>
