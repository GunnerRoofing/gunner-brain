---
type: meta
title: Dashboard
updated: '2026-06-13'
tags:
  - meta
status: active
---

# Wiki Dashboard

**Last lint:** [[meta/lint/lint-report-2026-06-13]] (2026-06-13) — 31 issues, 0 auto-fixed

## Recent Activity
```dataview
TABLE type, status, updated FROM "wiki" SORT updated DESC LIMIT 15
```

## Seed Pages (Need Development)
```dataview
LIST FROM "wiki" WHERE status = "seed" SORT updated ASC
```

## Entities Missing Sources
```dataview
LIST FROM "wiki/shared/entities" WHERE !sources OR length(sources) = 0
```

## Open Questions
```dataview
LIST FROM "wiki/tyler/questions" WHERE answer_quality = "draft" SORT created DESC
```

## Lint History
- [[meta/lint/lint-report-2026-06-13]] — 2026-06-13: 31 issues (6 orphans, 13 dead links, 2 root strays, 10 frontmatter gaps)
- [[meta/lint/lint-report-2026-06-10]] — 2026-06-10
