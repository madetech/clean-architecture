---
title: "Clean Architecture Ruby: Gateway"
---

# Gateway

The `gateway/` directory holds the IO adapters, such as adapters for files, a database, or API calls.

A Gateway constructs Domain objects for a Use Case to read. A Gateway also accepts a Domain object and saves it.
