// Seeds the LOCAL Firebase emulators with a test admin and fake artists, so the
// admin panel can be tried without touching the real project.
//
//   firebase emulators:start --only auth,firestore,storage
//   node tool/seed_emulator.mjs
//
// The credentials below exist only inside the emulator and are not real.

const PROJECT_ID = 'makeupartistbooking-3d2da';
const AUTH = 'http://127.0.0.1:9099';
const FIRESTORE = `http://127.0.0.1:8080/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const TEST_ADMIN = { email: 'admin@example.test', password: 'Emulator-Admin-2026!' };
// Signs in fine but is NOT in the admins collection: used to check that the
// panel and the security rules turn non-admins away.
const TEST_VISITOR = { email: 'visitor@example.test', password: 'Emulator-Visitor-2026!' };

const artists = [
  {
    id: 'artist-priya',
    name: 'Priya Nair',
    city: 'Kochi',
    bio: 'Bridal and engagement makeup with ten years of experience in traditional Kerala looks.',
    serviceModes: ['home', 'studio'],
    isActive: true,
    commissionRate: 0.15,
    repeatCommissionRate: 0.05,
    // 6 AM to 8 PM so a bridal booking can start early; Sundays off.
    workingHours: { startMinute: 360, endMinute: 1200 },
    weeklyOffDays: [7],
    bufferMinutes: 15,
    travelBufferMinutes: 60,
    services: [
      { id: 's1', name: 'Bridal makeup', price: 15000, durationMinutes: 180 },
      { id: 's2', name: 'Engagement makeup', price: 8000, durationMinutes: 120 },
      { id: 's3', name: 'Party makeup', price: 4500, durationMinutes: 90 },
      {
        id: 'x1',
        name: 'Family member makeup',
        price: 2500,
        durationMinutes: 45,
        kind: 'addOn',
        maxQuantity: 3,
        allowOnSpot: false,
      },
      {
        id: 'x2',
        name: 'Saree draping',
        price: 600,
        durationMinutes: 20,
        kind: 'addOn',
        maxQuantity: 1,
        allowOnSpot: true,
      },
    ],
    contactPhone: '9876543210',
    instagram: 'priya.makeup',
    notes: 'Prefers weekday bookings.',
  },
  {
    id: 'artist-anjali',
    name: 'Anjali Menon',
    city: 'Chennai',
    bio: 'Studio artist specialising in HD and airbrush finishes.',
    serviceModes: ['studio'],
    isActive: true,
    commissionRate: 0.12,
    repeatCommissionRate: 0.04,
    workingHours: { startMinute: 600, endMinute: 1140 }, // 10 AM to 7 PM
    weeklyOffDays: [1], // Mondays off
    bufferMinutes: 30,
    travelBufferMinutes: 60,
    services: [
      { id: 's1', name: 'Airbrush bridal', price: 18000, durationMinutes: 210 },
      { id: 's2', name: 'HD party look', price: 5500, durationMinutes: 90 },
      {
        id: 'x1',
        name: 'Hair styling',
        price: 1200,
        durationMinutes: 30,
        kind: 'addOn',
        maxQuantity: 1,
        allowOnSpot: true,
      },
    ],
    contactPhone: '9123456780',
    instagram: 'anjali.glam',
    notes: '',
  },
  {
    id: 'artist-meera',
    name: 'Meera Iyer',
    city: 'Bengaluru',
    bio: '',
    serviceModes: ['home'],
    isActive: false,
    commissionRate: 0.15,
    repeatCommissionRate: 0.05,
    services: [{ id: 's1', name: 'Reception makeup', price: 9000, durationMinutes: 150 }],
    contactPhone: '',
    instagram: '',
    notes: 'Onboarding paused until photos arrive.',
  },
];

// Converts a JS value to the Firestore REST representation.
function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') {
    return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  }
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: toFields(v) } };
}

function toFields(obj) {
  return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, toValue(v)]));
}

async function setDoc(path, data) {
  // "Bearer owner" is the emulator's way of bypassing security rules.
  const res = await fetch(`${FIRESTORE}/${path}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: JSON.stringify({ fields: toFields(data) }),
  });
  if (!res.ok) throw new Error(`${path}: ${res.status} ${await res.text()}`);
}

// Creates the user in the Auth emulator, or looks it up if it already exists.
async function createUser(credentials) {
  const res = await fetch(`${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ ...credentials, returnSecureToken: true }),
  });
  const body = await res.json();
  if (body.localId) return body.localId;
  if (body.error?.message === 'EMAIL_EXISTS') {
    const login = await fetch(
      `${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...credentials, returnSecureToken: true }),
      },
    );
    return (await login.json()).localId;
  }
  throw new Error(`Could not create ${credentials.email}: ${JSON.stringify(body)}`);
}

const uid = await createUser(TEST_ADMIN);
await setDoc(`admins/${uid}`, { email: TEST_ADMIN.email });
await createUser(TEST_VISITOR);

for (const a of artists) {
  const providerId = `provider-${a.id}`;
  const now = new Date();

  await setDoc(`providers/${providerId}`, {
    type: 'individual',
    name: a.name,
    city: a.city,
    commissionRate: a.commissionRate,
    repeatCommissionRate: a.repeatCommissionRate,
    createdAt: now,
    updatedAt: now,
  });

  await setDoc(`artists/${a.id}`, {
    name: a.name,
    bio: a.bio,
    city: a.city,
    imageUrl: '',
    serviceModes: a.serviceModes,
    services: a.services,
    isActive: a.isActive,
    // Artists without their own hours get the same defaults the app uses.
    workingHours: a.workingHours ?? { startMinute: 600, endMinute: 1080 },
    weeklyOffDays: a.weeklyOffDays ?? [],
    bufferMinutes: a.bufferMinutes ?? 15,
    travelBufferMinutes: a.travelBufferMinutes ?? 60,
    providerId,
    rating: 0,
    reviewCount: 0,
    createdAt: now,
    updatedAt: now,
  });

  await setDoc(`artistPrivate/${a.id}`, {
    contactPhone: a.contactPhone,
    instagram: a.instagram,
    notes: a.notes,
    updatedAt: now,
  });
}

// ---- Customers and bookings -------------------------------------------------
// Dates are relative to "now" so the sample data is always current. Each
// booking that still holds the calendar also gets its lock documents, one per
// 30-minute step, exactly like the customer app creates them.

const STEP_MINUTES = 30;
const customers = [
  { id: 'customer-1', phone: '+919000000001' },
  { id: 'customer-2', phone: '+919000000002' },
];

function at(daysFromNow, hour, minute = 0) {
  const d = new Date();
  d.setDate(d.getDate() + daysFromNow);
  d.setHours(hour, minute, 0, 0);
  return d;
}

const addMinutes = (date, minutes) => new Date(date.getTime() + minutes * 60000);
const pad = (n) => String(n).padStart(2, '0');
const dateKey = (d) => `${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}`;

const bookings = [
  {
    id: 'seed-booking-1', userId: 'customer-1', artistId: 'artist-priya', artistName: 'Priya Nair',
    serviceName: 'Bridal makeup + 1 add-on', start: at(2, 10), duration: 200, buffer: 15,
    mode: 'studio', amount: 15600, commissionRate: 0.15, status: 'requested', locks: true,
  },
  {
    id: 'seed-booking-2', userId: 'customer-2', artistId: 'artist-anjali', artistName: 'Anjali Menon',
    serviceName: 'Airbrush bridal', start: at(3, 11), duration: 210, buffer: 30,
    mode: 'home', address: '12 Lake View Road, Chennai', amount: 18000, commissionRate: 0.12,
    status: 'requested', locks: true,
  },
  {
    id: 'seed-booking-3', userId: 'customer-1', artistId: 'artist-priya', artistName: 'Priya Nair',
    serviceName: 'Party makeup', start: at(4, 15), duration: 90, buffer: 15,
    mode: 'studio', amount: 4500, commissionRate: 0.15, status: 'confirmed', locks: true,
  },
  {
    // Confirmed and already finished, so "Mark completed" is on offer.
    id: 'seed-booking-4', userId: 'customer-2', artistId: 'artist-priya', artistName: 'Priya Nair',
    serviceName: 'Engagement makeup', start: at(-1, 11), duration: 120, buffer: 15,
    mode: 'studio', amount: 8000, commissionRate: 0.15, status: 'confirmed', locks: false,
  },
  {
    id: 'seed-booking-5', userId: 'customer-1', artistId: 'artist-anjali', artistName: 'Anjali Menon',
    serviceName: 'HD party look', start: at(-6, 14), duration: 90, buffer: 30,
    mode: 'studio', amount: 5500, commissionRate: 0.12, status: 'completed', locks: false,
  },
  {
    id: 'seed-booking-6', userId: 'customer-2', artistId: 'artist-priya', artistName: 'Priya Nair',
    serviceName: 'Party makeup', start: at(6, 12), duration: 90, buffer: 15,
    mode: 'studio', amount: 4500, commissionRate: 0.15, status: 'cancelled', locks: false,
  },
];

for (const customer of customers) {
  await setDoc(`users/${customer.id}`, { phone: customer.phone, createdAt: new Date() });
}

for (const b of bookings) {
  const steps = Math.ceil((b.duration + b.buffer) / STEP_MINUTES);
  const blockedUntil = addMinutes(b.start, steps * STEP_MINUTES);

  await setDoc(`bookings/${b.id}`, {
    userId: b.userId,
    artistId: b.artistId,
    artistName: b.artistName,
    serviceName: b.serviceName,
    durationMinutes: b.duration,
    bufferMinutes: b.buffer,
    mode: b.mode,
    address: b.address ?? null,
    startAt: b.start,
    endAt: addMinutes(b.start, b.duration),
    blockedUntil,
    amount: b.amount,
    commissionRate: b.commissionRate,
    status: b.status,
    createdAt: addMinutes(new Date(), -90),
  });

  if (!b.locks) continue;
  for (let i = 0; i < steps; i++) {
    const step = addMinutes(b.start, i * STEP_MINUTES);
    const id = `${b.artistId}_${dateKey(step)}${pad(step.getHours())}${pad(step.getMinutes())}`;
    await setDoc(`bookingSlots/${id}`, {
      artistId: b.artistId,
      bookingId: b.id,
      userId: b.userId,
      dateKey: dateKey(step),
      startAt: step,
    });
  }
}

console.log(
  `Seeded 1 admin, 1 non-admin, ${artists.length} artists and ${bookings.length} bookings into the emulators.`,
);
