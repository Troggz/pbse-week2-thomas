Week 2 Notes — Badminton Court Booking

Practice system: a badminton court booking service with paid time slots.


Checkpoint 1 — the screen-shaped endpoint (Section 2.2)

The address I would have designed is `GET /my-bookings` a dashboard screen that
shows the customer's upcoming booking, the courts still free for the slot they
want, and whether their payment went through, all in one reply.

It should be split into the real resources it is built from:
- `GET /bookings?status=reserved` — the customer's active booking
- `GET /courts?available=true` — the courts they could still book
- payment status is read off the booking, not a resource of its own


Checkpoint 2 — a status change, named with Rule 5 (Section 2.3)

Status change: cancelling a booking.
- Rule-5 address: `POST /bookings/{id}/cancellation`
- Verb version: `POST /cancelBooking` (or `PATCH /bookings/{id}` with `{"status":"cancelled"}`)

The verb version is worse because a client may change the verb
into anything which may make it unclear later down the road, 
and it does not let it record "why" the booking was
cancelled.


Checkpoint 3 — safe to repeat? (Section 2.4)
For each operation, "if the network drops and the client sends this again, what
does the user lose?":
- `GET /courts` — nothing. Safe as it is.
- `GET /bookings/{id}` — nothing. Safe as it is.
- `POST /bookings` — a duplicate booking and a second payment. This one needs
  the idempotency-key protection in Section 2.5.



Self-check (5 questions)
  
1. Reject `POST /v1/orders/{id}/markReady`
- Reason 1: it puts a verb in the path. Rule 5 says a status change gets its own
  noun address; `markReady` names an action, so it cannot carry a body
  and cannot be fetched later with GET.
- Reason 2: an action endpoint invites clients to think they can drive the status
  to any value, and it records nothing about the transition (reason, timestamp).
  It also breaks the "one sub-resource per status change" pattern, so the API
  drifts into inconsistency.
- Right address: `POST /v1/orders/{id}/readiness`.

2. `PUT /v1/menu-items/itm_3Bn` with the complete item, resent after a timeout
  Two different properties, answered separately:
- Read-only (safe)? **No.** PUT writes the item's fields; it changes the
  resource. Only GET would be read-only.
- Safe to repeat (idempotent)? **Yes.** PUT means "make this thing look exactly
  like this." Sending the same full representation twice leaves the resource in
  the same state as sending it once, so retrying after a timeout is harmless and
  needs no idempotency key.

3. Shop sold out of an item — code, kind, and what's wrong with 500 / 200
- Code: **409 Conflict** (422 is also defensible). Kind: **a business rule said
  no — a domain rejection.** The request was well-formed; the rule "item is
  unavailable" refused it. This is a normal answer, not a bug.
- Wrong with 500: 500 means "our service broke," which tells every client to
  retry (with backoff) something that can never succeed — the item is sold out,
  retrying changes nothing — and it buries a normal business event inside the
  service's error alerts.
- Wrong with 200: `200 {"success": false}` looks like success to everything in
  between (retries, monitoring, caching, the other team's error handler). Every
  client must then check a field inside the body of every reply, forever; forget
  once, and a failure is silently counted as a success.

4. My dangerous operation
`POST /bookings`(booking a court) must never happen twice. Asked out loud: if
the customer taps Book outside the hall with one bar of signal, the confirmation
never arrives, and the app resends, she could be charged a second time and end up
holding two bookings for the same slot.

The four "do this only once" sentences, from the `Idempotency-Key` description in
my `openapi.yaml`:
1. Header name + value shape: "Idempotency-Key, a version-4 UUID with hyphens."
2. Which operations: "Required on POST /bookings; ignored on every other operation."
3. How long remembered: "The server keeps each key for 24 hours; a key reused
   after that is treated as new."
4. Same key, different body: "Reusing a key with a different body returns 409
   idempotency-key-reuse."
All four are present in the file.

  5. One thing I'm genuinely unsure about
I am unsure if no_show and cancelled should be the same or a seperate status.
This is because a customer who did book but did not come is not exactly the same as
a customer who cancels. This can be significant if a refund system were to be added,
but as for right now, it is unsure if it is needed to be seperate in the interface.
