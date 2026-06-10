---
title: Monday.com PM My Work View Setup
type: runbook
status: stable
tags:
  - monday
  - runbook
  - project-management
created: '2026-05-01'
updated: '2026-05-07'
related:
  - '[[gunner/environment]]'
---

# Monday.com PM "My Work" View Setup

Configure the **My Work** view so project managers see their jobs correctly. All settings are in **My Work → Customize** (top right).

---

## Boards Tab

**Which boards should we show?**

| Board | Visible |
|-------|---------|
| 🚀 *Project Take off | ✅ |
| SM Ops Form Submission | ✅ |
| *PM Change Order | ✅ |

All other boards should remain hidden.

---

## Date Column Tab

| Board / Group | Column |
|---|---|
| *PM Change Order | Date Submitted |
| 🚀 *Project Take off | Install Timeline |
| Subitems of 🚀 *Project Take off | Timeline |
| Subitems of *PM Change Order | Date |
| SM Ops Form Submission | Requested Swap Date |
| Project Takeoff - | Create Date |

---

## Status Column Tab

| Board / Group | Column |
|---|---|
| *PM Change Order | CO Status |
| 🚀 *Project Take off | Status |
| Subitems of 🚀 *Project Take off | Status |
| Subitems of *PM Change Order | Status |
| SM Ops Form Submission | Form Selection |
| Project Takeoff - | State |
| Subitems of Project Takeoff - | Status |

---

## Priority Column Tab

| Board / Group | Column |
|---|---|
| *PM Change Order | No columns selected |
| 🚀 *Project Take off | Stage |
| Subitems of 🚀 *Project Take off | Measurements |
| Subitems of *PM Change Order | No columns selected |
| SM Ops Form Submission | Dumpster Time |
| Project Takeoff - | Takeoff Status |
| Subitems of Project Takeoff - | No columns selected |
