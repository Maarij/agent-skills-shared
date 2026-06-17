---
name: implement
description: Implement an approved PRD or requested feature with branch discipline, mockup review when needed, tests, and visual verification. Use when the user invokes /implement or asks to implement planned work.
---

If $ARGUMENTS is empty, ask the user what to implement before proceeding.

Create a branch from main and title the branch what the PRD is (or name appropriately). Do not commit/push until the user confirms they have reviewed and are satisfied. Always ask for confirmation before committing/pushing code.

Before implementation, check to see if mock-ups already exists. If so, use as reference. If not, create mock-up under 'designs/prd##' as static html/css. If there are decisions between two options, make sure both mock ups are shown for both options. Wait for approval of mock-up before continuing.

When implementing a new feature or bug fix, always write tests to ensure that code works as expected. Consider a TDD approach to begin with if applicable.

After implementation and testing is complete, determine what should be thoroughly visually tested. Use chrome-devtools to perform the tests. Outline what you tested in a summarized table. The end output summarized table should also include any before and afters summarized in simpler terms.
