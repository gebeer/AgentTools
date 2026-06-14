# tasks

## Purpose

Predefined Engineer **task definitions** — review and automation jobs surfaced in
the admin Tasks screen and runnable via the Engineer. Each file declares one task:
its inputs, scheduling, and the prompt the Engineer runs.

## Ownership

One PHP file per task, each `return`ing a single definition array:

- `accessibility-review.php`, `log-review.php`, `migration-review.php`,
  `seo-content-review.php`, `static-phrase-translation.php`,
  `template-security-scan.php`

## Local Contracts

- A task file is `<?php namespace ProcessWire;` and `return`s an array with at least:
  `name`, `title`, `summary`, `description`, `icon`, `mode`, `scheduleable`,
  `inputs`, `prompt`.
- `inputs` keys define admin form fields (`type`, `label`, `description`, etc.);
  `{input_name}` placeholders in `prompt` are substituted with the input values.
- File-level code may call `wire('at')` / the PW API to build dynamic input
  `options`, but the task itself runs through the Engineer prompt — keep tasks
  review-only unless the mode explicitly permits changes.
- `name` must match the filename stem and be unique across this directory.
