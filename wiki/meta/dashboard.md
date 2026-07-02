---
type: meta
title: Dashboard
created: '2026-06-10'
updated: '2026-07-02'
tags:
  - meta
status: active
---

# Wiki Dashboard

**Last lint:** [[meta/lint-report-2026-07-02]] (2026-07-02) — 46 issues (6 auto-fixable, 37 in one repeat cluster pending review)

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
- [[meta/lint-report-2026-07-02]] — 2026-07-02: 46 issues (2 stale claims, 1 orphan, 1 broken self-link, 37 ambiguous-basename links in one cluster, 5 content frontmatter gaps)
- [[meta/lint-report-2026-06-24]] — 2026-06-24: 32 issues (1 dead link, 4 stale claims, 4 orphans, 15 frontmatter gaps, fragile prefix links)
- [[meta/lint-report-2026-06-19]] — 2026-06-19
- [[meta/lint/lint-report-2026-06-13]] — 2026-06-13: 31 issues
- [[meta/lint/lint-report-2026-06-10]] — 2026-06-10
