# FieldtypePageEngineer

## Purpose

Custom ProcessWire Fieldtype + Inputfield that stores the **Page Engineer**
conversation field — the per-page chat history that powers the admin Page Engineer.
Loaded by the AgentTools module; usable as a standalone field on any template.

## Ownership

- `FieldtypePageEngineer.module.php` — Fieldtype/Inputfield module entry point
- `PageEngineerField.php` — the field value object (settings: `scope`, `instructions`, `backup`)
- `PageEngineerItems.php` — conversation history (collection of items)
- `PageEngineerItem.php` — one conversation message (`from`, `when`, `text`)
- `PageEngineerField.css` / `PageEngineerField.js` — admin Inputfield UI
- `words.php` — whimsical "thinking" status-word list
- `API.md` — field API reference

## Local Contracts

- Conversation data is a `PageEngineerItems` collection of `PageEngineerItem`
  objects (`from` / `when` / `text`); preserve that shape and keep `when` ISO-8601.
- Preserve `require_once` include order: `Items` → `Item`, `Field` → `Items`,
  module → `Field`. Reordering breaks class loading.
- Field settings (`scope`, `instructions`, `backup`) are persisted Fieldtype
  config; changing their names/semantics is a schema change — update `API.md` too.
