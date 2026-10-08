# Firestore schema

Source of truth for the data model. Keep `firestore.rules` and the models in
`lib/features/*/data` in sync with this file.

## `users/{uid}`
Customer profile. `uid` is the Firebase Auth uid.

| Field | Type | Notes |
|---|---|---|
| name | string | |
| phone | string | from phone login |
| createdAt | timestamp | |

## `artists/{artistId}`
Public catalogue entry, written by the admin panel.

| Field | Type | Notes |
|---|---|---|
| name | string | |
| bio | string | |
| city | string | used for filtering |
| imageUrl | string | Firebase Storage download URL |
| rating | number | average, maintained from reviews |
| reviewCount | number | |
| serviceModes | array<string> | any of `home`, `studio` |
| services | array<map> | `{id, name, price, durationMinutes}` |
| isActive | bool | admins deactivate instead of deleting; customers only list `true` |
| providerId | string | the business that gets paid, see `providers` |
| createdAt, updatedAt | timestamp | |

`rating` and `reviewCount` are written only by the review system, never by the
admin form (`ArtistModel.toEditableMap` leaves them out).

Prototype documents (`image`, `price`, string-only `services`) still parse; see
`ArtistModel.fromDoc`. They have no `isActive`, so customers do not see them
until they are re-entered through the admin panel.

## `providers/{providerId}`
The business behind one or more artists. Admin-only: it holds commercial terms.
Phase 1 creates one provider per individual artist, automatically. Salons
(phase 2) are providers of type `salon` with several artists.

| Field | Type | Notes |
|---|---|---|
| type | string | `individual` (phase 1) or `salon` (phase 2) |
| name, city | string | kept in sync with the artist for individuals |
| commissionRate | number | platform share, 0.15 = 15% |
| ownerUid | string? | Auth uid allowed to manage this provider's bookings |
| createdAt, updatedAt | timestamp | |

## `artistPrivate/{artistId}`
Admin-only artist details. Kept out of `artists` because that collection is
readable by every customer.

| Field | Type |
|---|---|
| contactPhone, instagram, notes | string |
| updatedAt | timestamp |

## `admins/{uid}`
Presence of a document makes that Auth user an admin of the admin panel. Read
by the user themselves only; no client can write it. Add an admin in the
Firebase console: document id = the user's uid, any field (e.g. `email`).

### `artists/{artistId}/portfolio/{itemId}`
`{imageUrl, title, category}`. This subcollection is the only portfolio store
(the old embedded `portfolio` array is no longer read).

## `bookings/{bookingId}`

| Field | Type | Notes |
|---|---|---|
| userId | string | customer uid |
| artistId | string | |
| artistName | string | denormalised for list screens |
| serviceId / serviceName | string | |
| durationMinutes | number | |
| mode | string | `home` or `studio` |
| address | string? | required for `home` |
| startAt | timestamp | |
| amount | number | service price at booking time |
| commissionRate | number | rate in force at booking time |
| status | string | see below |
| createdAt | timestamp | server time |

Status flow: `requested` -> `confirmed` or `declined` (artist). `requested` or
`confirmed` -> `cancelled` (customer or artist). `confirmed` -> `completed`.

Commission for a booking is `amount * commissionRate`; the artist's payout is
the remainder.

## `bookingSlots/{artistId}_{yyyyMMddHHmm}`
Lock document created in the same transaction as the booking. If it already
exists the booking fails, which prevents double booking. Delete it when a
booking is declined or cancelled (not implemented yet).

| Field | Type |
|---|---|
| artistId, bookingId, userId | string |
| dateKey | string, `yyyyMMdd` |
| startAt | timestamp |

Known limitation: only the start time is locked, so a 3-hour service does not
block the slot after it. Needs duration-aware availability when artists manage
their own calendars.
