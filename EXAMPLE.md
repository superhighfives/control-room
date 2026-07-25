# Example review

This is what a review looks like in practice. It is not a template to fill in
mechanically — it shows the shape, the density, and how the pieces fit. Read it
alongside [`REVIEW.md`](REVIEW.md).

A submitted review has two parts:

1. **Inline comments** on the ⛔ / ⚠️ findings that sit on lines the diff
   touched. Each is anchored to its line and starts with its severity label.
2. **The summary body** — the block below — which carries the marker, the
   overall verdict, the category table, and the per-category rollups.

Both go up in one `POST .../reviews` call (see the workflow). The `event` is
`REQUEST_CHANGES`, `COMMENT`, or `APPROVE`, chosen from the overall verdict.

---

## The summary body

The exact string that goes in the review's `body` field. This is a round-two
review: one blocker from round one was fixed, one observation was answered.

```markdown
<!-- control-room:review -->
## 🔴 Changes requested

| Category | Verdict |
| --- | --- |
| 🔒 Security | 🔴 Blocked |
| 🧹 Code Quality | 🟡 Comments |
| ⚡ Performance | 🟢 Approved |
| 📝 Docs | 🟢 Approved |
| 🤖 Agents | 🟡 Comments |

### 🔒 Security — 🔴 Blocked
- ⛔ **[BLOCKING]** `src/routes/upload.ts:31` — the uploaded filename is joined
  onto the storage path without normalising `..`, so a crafted name escapes the
  upload dir. Inline comment on the line. (BASELINE.md: never interpolate
  untrusted input into a path.)
- ✅ **[RESOLVED]** `src/db/users.ts:88` — the SQL string-concat flagged last
  round is now a parameterised query. Confirmed.

### 🧹 Code Quality — 🟡 Comments
- ⚠️ **[WARNING]** `src/cache.ts:12` — the cache map is module-scope and shared
  across requests, so entries leak between users. Can't corrupt data here since
  values are per-key immutable, so it doesn't block — but confirm that holds.
- 💡 **[SUGGESTION]** `src/util/date.ts:7` — this duplicates `formatDay` in
  `src/report/format.ts:44`; worth collapsing.

### ⚡ Performance — 🟢 Approved
Nothing. The new query in `src/db/users.ts` is indexed on `org_id`.

### 📝 Docs — 🟢 Approved
Nothing.

### 🤖 Agents — 🟡 Comments
- ⚠️ **[WARNING]** `src/agent/tools.ts:53` — the `run_query` tool passes its
  `sql` argument straight to the DB with no allowlist or read-only guard; a
  model can issue writes. Not dangerous today (the tool runs against a replica),
  so not blocking — but the replica boundary is the only thing holding it.
- 💬 `src/agent/prompt.ts:20` — you replied that the terse system prompt is
  intentional for latency. Fair; leaving it.
- ❓ `src/agent/index.ts:14` — model ID moved from `claude-sonnet-5` to a env
  var with no default. Intentional? If the env var is unset in CI the agent
  constructs with `undefined`.
```

---

## Notes on the example

- **The overall verdict is the worst category.** Security is 🔴, so the whole
  review is 🔴 / `REQUEST_CHANGES`, even though three categories are clean or
  advisory.
- **✅ and 💬 do the round-to-round bookkeeping.** The resolved SQL blocker gets
  one ✅ line and is not restated; the answered prompt observation gets a 💬 and
  is dropped, not re-argued.
- **A ⚠️ can sit on either side of the line.** The cache one and the `run_query`
  one are both ⚠️, both judged not-dangerous, so both approve-with-comments
  rather than block. Had the `run_query` tool pointed at the primary DB, it
  would be ⛔ and Agents would be 🔴.
- **Clean categories get one line, not silence.** "Nothing" plus what you
  checked beats an omitted section that reads as "didn't look."
