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
| services | array<map> | services and add-ons, see below |
| isActive | bool | admins deactivate instead of deleting; customers only list `true` |
| providerId | string | the business that gets paid, see `providers` |
| workingHours | map | `{startMinute, endMinute}`, minutes after midnight, half-hour steps. Default 10:00 to 18:00 |
| weeklyOffDays | array<number> | weekdays not worked, `DateTime.weekday` (Monday = 1 ... Sunday = 7) |
| bufferMinutes | number | free time kept after a studio booking (default 15) |
| travelBufferMinutes | number | free time kept after a home visit, includes travel (default 60) |
| createdAt, updatedAt | timestamp | |

Each entry of `services`:

| Field | Type | Notes |
|---|---|---|
| id | string | stable; bookings refer to it |
| name | string | public text, must not contain contact details |
| price | number | rupees |
| durationMinutes | number | |
| kind | string | `main` (what customers book) or `addOn` (an extra offered with it) |
| maxQuantity | number | add-ons: most per booking, e.g. 3 extra family members. 1 for main services |
| allowOnSpot | bool | add-ons: whether the artist can add it at the chair |

Add-ons come from this fixed menu: customers and artists cannot type in a free
price or an unlisted extra.

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
| commissionRate | number | platform share of a customer's first booking with this provider, 0.15 = 15% |
| repeatCommissionRate | number | lower share when the customer has booked this provider before (default 0.05), so regulars stay on the app. Never above `commissionRate`. Not yet applied to bookings: the booking still copies the default from `AppConfig`; per-provider and repeat rates need server-side logic once payments exist, because a client must not choose its own commission. |
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
| serviceId | string | the main service |
| serviceName | string | short label, e.g. "Bridal makeup + 2 add-ons" |
| items | array<map> | `{serviceId, name, price, durationMinutes, quantity, isAddOn}` for the main service and every add-on |
| durationMinutes | number | total time of all items |
| bufferMinutes | number | gap kept afterwards (studio or travel) |
| mode | string | `home` or `studio` |
| address | string? | required for `home` |
| startAt | timestamp | |
| endAt | timestamp | `startAt` + `durationMinutes` |
| blockedUntil | timestamp | `endAt` + buffer, rounded up to whole 30-minute steps. The calendar is locked from `startAt` to here |
| amount | number | total of all items at booking time |
| commissionRate | number | rate in force at booking time |
| status | string | see below |
| createdAt | timestamp | server time |

Status flow: `requested` -> `confirmed` or `declined` (artist). `requested` or
`confirmed` -> `cancelled` (customer or artist). `confirmed` -> `completed`.

Commission for a booking is `amount * commissionRate`; the artist's payout is
the remainder.

## `bookingSlots/{artistId}_{yyyyMMddHHmm}`
The calendar is cut into 30-minute steps (`AppConfig.slotStepMinutes`). A
booking creates **one lock document per step** from `startAt` until
`blockedUntil`, all in the same transaction as the booking. If any step already
exists the booking fails, so two bookings can never overlap on one artist,
whatever their lengths. Cancelling a booking deletes every step it locked.

| Field | Type |
|---|---|
| artistId, bookingId, userId | string |
| dateKey | string, `yyyyMMdd` |
| startAt | timestamp, the start of this step |

The scheduling rules live in `SlotMath` (`lib/features/booking/domain`), a pure
class with its own tests.

Known limit: the customer app creates the locks itself, and the security rules
cannot force a booking to include them. Moving booking creation to the server
(with payments) closes that gap and also stops a client from choosing its own
amount or commission.

## Cancellation default
Free until 7 days before the start; 50% of the advance refunded until 48 hours
before; nothing after that; a full refund if the artist cancels or declines.
Encoded in `CancellationPolicy`. It only calculates the share; money moves once
online payments exist.
