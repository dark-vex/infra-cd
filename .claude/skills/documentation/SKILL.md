---
name: documentation
description: Route documentation/notes to the right destination (Confluence, README/CLAUDE.md, Obsidian, or NetBox) based on content type, and confirm the exact destination with the user before writing anything.
---

# Documentation Routing Skill

Use this skill whenever asked to write down, document, save, or note something — before picking a destination, classify the content and confirm the exact target with the user. Never guess a destination and write silently; getting this wrong scatters knowledge across the wrong tool and is hard to undo.

## Routing table

| Content type | Destination | Mechanism |
|---|---|---|
| Runbooks, architecture decisions, postmortems | Confluence | `createConfluencePage` / `updateConfluencePage`. If the target space is ambiguous, ask which space before writing. |
| Repo usage, conventions, how-to guides | README.md / directory-level READMEs / CLAUDE.md | Direct file edit + PR, following this repo's normal git workflow (feature branch, semantic commit, never push to `main`). |
| Personal notes, ideas, journal entries | Obsidian | `obsidian_append_content` or an appropriate periodic note. |
| Infra inventory (hosts, IPs, VM/device records) | NetBox | Verify current state via the NetBox MCP tools first (**read-only** in this workflow) — writes never go through the MCP directly. Instead, author/update `terraform/netbox/*.tf` and open a PR, so NetBox state stays under GitOps/Terraform control like everything else in this repo. |

## Mixed content

If a request spans more than one row (e.g. "document this incident and also note it needs a NetBox entry for the new host"), split it and route each piece separately — don't force multi-type content into one destination.

## Before writing: confirm the destination

State the exact target before making any change, and wait for confirmation if there's any ambiguity:
- Confluence: which space and page (existing page to update vs. new page + where it should live in the page tree)
- Obsidian: which vault path / note
- File edit: which exact file path
- NetBox: which Terraform resource in `terraform/netbox/` (new resource vs. editing an existing one)

Skip the confirmation only when the user has already stated the exact destination unambiguously in their request.

## Out of scope

This skill does not cover code comments or inline documentation as part of a normal code change — that's ordinary development, not a "write documentation" request.
