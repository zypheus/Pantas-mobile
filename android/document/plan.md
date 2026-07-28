# Home Screen Book Recommendations + Profile Attendance Preview — Plan

## Overview

Two related but independent features:

1. *Course-aligned book recommendations* — shown on the mobile app's *home screen*. Fully specified below, ready to implement.
2. *Library attendance/visit preview* — shown on the mobile app's *profile screen*. Requires a new attendance data model and kiosk-ingestion design, since no such module currently exists in the system. Partially blocked — see "Open Items / Blockers" before implementation starts.

---

## Feature 1: Course-Aligned Book Recommendations

### Goal
Surface a short list of books relevant to the logged-in student's academic program on the home screen, without requiring any manual curation or borrow-history analysis.

### Matching Logic
- Match is a direct comparison: students.course (the logged-in student's program) against books.course (the book's associated program/course).
- Both fields are plain free-text (VARCHAR), *not* foreign keys into the programs`/courses` tables — this is a string match, not a relational join.
- *Important pre-implementation check:* confirm that the values stored in students.course and books.course actually use consistent formatting/codes (e.g. both consistently store "BSCS", not one storing a code and the other a full program name). If they're inconsistent, matches will silently fail or under-match. This should be verified against real data before or during implementation — not assumed.

### Endpoint
- New (or extended) endpoint under /mobile, e.g. GET /mobile/home/recommendations — or fold into the existing GET /mobile/home aggregate response as an additional key (recommended_books), consistent with how that endpoint already aggregates new arrivals, active loans, and stats.
- Query: books where course matches the authenticated student's course, filtered to availability = 'Available' (no point recommending something already borrowed out), excluding archived/deleted records.
- Cap result count for a home-screen widget (e.g. 8–10 items) — this is a preview, not a full search result.
- Sort: reasonable default is most recently added (source_date or created_at descending) so recommendations stay fresh; open to revisiting once there's real usage data.

### Caching
- Follow the existing pattern already used elsewhere in this API (new-arrivals cached 5 min, filters cached 15 min). Recommendation results per course change infrequently — a similar short-TTL cache (e.g. 10–15 min) keyed by course is reasonable, avoids recomputing the same query for every student in the same program.

### Mobile App Changes
- Home screen: new horizontal card/list section, e.g. "Recommended for [course]", positioned near existing new-arrivals section.
- Tapping a recommended book navigates to the existing /book_details screen — no new detail UI needed, reuses what's already built for catalog search results.
- Empty state: if no books match the student's course, hide the section entirely rather than showing an empty widget.

### Edge Cases
- Student has no course value set on their record → skip recommendations, don't error the whole home response.
- No books match the student's course at all → return an empty array; mobile app hides the section (see above).

---

## Feature 2: Library Attendance/Visit Preview (Profile Screen)

### Goal
Show the student a preview of their recent library visits (kiosk check-ins) plus a simple summary (e.g. total visits this month) on the *profile screen*.

### Current State
- *No attendance/visit-log table exists anywhere in the current schema.* This was confirmed against the full database schema summary (students, users, books, book_logs, ebooks, rooms, room_reservations, reservation_students, reservation_logs, fine_settings, holidays, feedback, programs/years/courses) — none of these represent a library visit/check-in event.
- The intent is for this data to originate from *existing kiosk hardware* at the library entrance, but exactly how that hardware currently operates and whether it already stores data anywhere is unconfirmed.
- The students table already has a qrcode field, which is a strong candidate for how a kiosk would identify a student on scan-in — but this is unconfirmed, not assumed as final.

### Open Items / Blockers — must be resolved before implementation

1. *Kiosk-to-backend integration method.* Does the kiosk push data to a new Laravel endpoint (to be built), or does it already write to a separate database/system that this app would need to read from (via a scheduled sync, direct query, or its own API)? This determines whether the work is "build an ingestion endpoint" or "build a read/sync integration."
2. *Student identification method at the kiosk.* Confirm whether the kiosk scans students.qrcode (already present in the schema) or uses a different identifier (RFID card, manual ID entry, etc.).
3. *Visit shape — scan-in only, or scan-in + scan-out.* This determines the data model:
   - If scan-in only: each visit is a single timestamp per record (like a counter/log entry).
   - If scan-in + scan-out: each visit needs a nullable "time out" that gets filled in on a second scan, meaning the backend needs logic to find and update the "open" visit record for a student rather than always inserting a new row.

*Action needed:* confirm these three points with whoever set up or is setting up the kiosk hardware before finalizing the data model or writing any ingestion code.

### Proposed Data Model (draft — pending confirmation above)

A new table (name TBD, e.g. library_visits or attendance_logs) capturing, at minimum:
- Which student the visit belongs to.
- A time-in value.
- A time-out value (nullable) — only if blocker #3 confirms a scan-out step exists.
- The date of the visit (can be derived from time-in, but an explicit date field simplifies day-level queries/summaries).
- Some indicator of how the record was created (kiosk vs. manual, in case staff ever need to backfill/correct a record) — optional but useful for data integrity, similar to how book_logs tracks circulation type.

This is intentionally left at the "what fields are needed" level, not exact column types/constraints — those are implementation details to finalize once the blockers above are answered.

### Mobile-Facing Endpoint (once data model exists)

- New endpoint, e.g. GET /mobile/attendance/preview (or GET /mobile/profile/attendance), returning:
  - A short list of the student's most recent visits (date, time-in, time-out if applicable).
  - A summary figure: total visit count for the current month (confirmed requirement — "recent visits + some summary").
- Should follow the same authenticated/resolved-student pattern already used by every other protected /mobile endpoint (resolveStudent()).
- Consider whether a full attendance history screen (beyond the preview) is wanted later — not required for this feature, but worth keeping the endpoint design flexible (e.g. supporting pagination later) rather than hard-coding a fixed "last N" query that would need rework.

### Mobile App Changes

- Profile screen: new section showing recent visits + monthly total, positioned within the existing /profile screen layout.
- Empty state: student with no recorded visits yet — show a simple "no visits recorded" message rather than an empty list.

---

## Summary of What's Ready vs. Blocked

| Feature | Status |
|---|---|
| Course-aligned book recommendations | Fully specified, ready for implementation |
| Attendance data model & kiosk ingestion | Blocked — needs answers on kiosk integration method, student ID method, and scan-in/out shape |
| Attendance mobile endpoint & profile UI | Depends on the above being resolved first |