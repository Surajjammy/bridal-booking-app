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
| isActive | bool | admins deactivate instead of deleting |
| ownerUid | string? | Auth uid of the artist's login, set when the artist is onboarded |

Prototype documents (`image`, `price`, string-only `services`) still parse; see
`ArtistModel.fromDoc`. Migrate them through the admin panel.

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
