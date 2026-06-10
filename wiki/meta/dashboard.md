---
type: meta
title: Dashboard
created: '2026-04-14'
updated: '2026-05-15'
tags: [meta, dashboard]
status: evergreen
related:
  - '[[index]]'
  - '[[log]]'
  - '[[concepts/Compounding Knowledge]]'
---

# Gunner Vault Dashboard

Navigation: [[index]] | [[log]] | [[hot]] | [[getting-started]]

## Dataview Dashboard

Requires the Dataview community plugin (already installed).

### Recent Activity (All Sections)

```dataview
TABLE type, status, updated FROM "wiki"
WHERE file.name != "index" AND file.name != "log" AND file.name != "hot"
SORT updated DESC LIMIT 20
```

### Recent Sessions

```dataview
TABLE status, updated FROM "wiki/meta"
WHERE type = "session"
SORT updated DESC LIMIT 10
```

### Pages Needing Development

```dataview
LIST FROM "wiki"
WHERE status = "developing" OR status = "seed"
SORT updated ASC
```

### Open Gunner Items

```dataview
LIST FROM "wiki/gunner"
WHERE status = "developing" OR status = "current"
SORT updated DESC
```

### Open Questions

```dataview
LIST FROM "wiki/questions"
WHERE status = "developing" OR status = "seed"
SORT updated DESC
```

### Threat Pages

```dataview
TABLE status, updated FROM "wiki/threats"
SORT updated DESC
```

### Runbooks (Check Freshness)

```dataview
TABLE status, updated FROM "wiki/runbooks"
SORT updated ASC
```

### Vendor Pages

```dataview
TABLE status, updated FROM "wiki/vendors"
SORT updated DESC
```

### Sources Ingested

```dataview
TABLE sources, updated FROM "wiki/summaries"
SORT updated DESC
```

### Infrastructure & AWS Pages

```dataview
TABLE status, updated FROM "wiki/gunner"
WHERE contains(tags, "aws") OR contains(tags, "infrastructure") OR contains(tags, "soc2")
SORT updated DESC
```

### Pages Missing Status Field

```dataview
LIST FROM "wiki"
WHERE !status
SORT file.name ASC
```

### Comparisons

```dataview
TABLE updated FROM "wiki/comparisons"
SORT updated DESC
```
