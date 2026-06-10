---
title: "Gunner Assistant — AI Knowledge Base Project"
type: gunner
tags: [gunner, project, ai, claude, knowledge-base, roofing, gunner-forms]
created: 2026-04-16
updated: 2026-04-16
sources: []
related:
  - "[[gunner/gunner-forms-app]]"
  - "[[vendors/hubspot]]"
status: developing
---

# Gunner Assistant — AI Knowledge Base Project

A proposed AI-powered roofing knowledge base for Gunner field employees. Goal: employees ask roofing questions on their phones and get answers sourced from Gunner's PDF library (installation manuals, manufacturer specs, job procedures).

## Options Evaluated

### Option 1 — Claude Projects (Fastest)

- Upload roofing PDFs to a Claude Project on claude.ai
- Write a system prompt scoping responses to roofing only
- Share with the team — accessible via claude.ai or the Claude iOS/Android app
- **Setup time:** ~30 minutes
- **Cost:** Included in existing Claude Team plan (per-seat, not pooled tokens)
- **Cons:** Employees get full Claude access outside the project; Anthropic branding, not Gunner branding; no way to lock users inside the project

### Option 2 — Custom App via Claude API (Most Control)

- Add a "Gunner Assistant" tab to the [[gunner/gunner-forms-app|GunnerForms app]]
- App sends employee questions to Claude API with roofing PDF context injected via RAG
- System prompt restricts answers to roofing topics only
- Gunner-branded, scoped experience
- **Setup time:** Weeks (requires RAG backend + Swift chat UI)
- **Cost:** Claude Team plan (existing) + Claude API pay-as-you-go (~$10–40/month at Gunner's scale)
- **Cons:** Requires development work; PDF-to-vector pipeline needed; determined user could circumvent restrictions

### Option 3 — No-Code RAG Platform

- Tools like Dify, Botpress, Stack AI — wrap Claude API with document search
- Share via link or embed
- **Cons:** Additional vendor, monthly cost, not a native app

## Architecture (Option 2)

RAG flow:
```
Employee question
→ App searches vector DB for relevant PDF chunks
→ Chunks injected into Claude API call with system prompt
→ Claude answers from that context
→ Response displayed in app
```

**Vector DB options:** Supabase + pgvector (free tier), Pinecone (managed, free tier)  
**Embedding:** Voyage AI or OpenAI embeddings (one-time per document, cheap)  
**Backend:** Thin API endpoint (Cloudflare Worker or $5/mo VPS) — app sends question, gets answer back. Keeps app thin and PDF logic server-side. Knowledge base updates don't require app update.

## Topic Scoping

Primary control: system prompt on every query:
> "You are the Gunner Roofing field assistant. Only answer questions about roofing materials, installation, repairs, inspections, and job site procedures. If a question is not about roofing, respond with: 'I can only help with roofing questions.'"

Optional second layer: classifier check before query hits Claude (is this roofing-related? yes/no). Adds ~$0.001/query, makes scoping essentially bulletproof.

## Knowledge Base Quality

Answer quality depends entirely on PDF quality. Priority documents:
- Installation manuals
- Manufacturer specs
- Gunner-specific SOPs and job procedures
- Common defect guides

## Status

- Boss shown demo — impressed
- Email sent outlining Option 1 vs Option 2 tradeoffs
- **Decision pending** — boss preference for Gunner-branded scoped experience suggests Option 2
- Development approach: `feature/gunner-assistant` branch on `gunner-ios` GitHub repo; separate Xcode target for testing without affecting App Store submission

## HubSpot AI (Evaluated, Rejected)

HubSpot Breeze AI is oriented around CRM data (deals, contacts, tickets) — not custom PDF knowledge bases. Wrong tool for this use case.

## Related

- [[gunner/gunner-forms-app]] — GunnerForms iOS app; planned host for Gunner Assistant tab
- [[vendors/hubspot]] — HubSpot AI evaluated and rejected for this use case
