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
    services: [
      { id: 's1', name: 'Bridal makeup', price: 15000, durationMinutes: 180 },
      { id: 's2', name: 'Engagement makeup', price: 8000, durationMinutes: 120 },
      { id: 's3', name: 'Party makeup', price: 4500, durationMinutes: 90 },
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
    services: [
      { id: 's1', name: 'Airbrush bridal', price: 18000, durationMinutes: 210 },
      { id: 's2', name: 'HD party look', price: 5500, durationMinutes: 90 },
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

console.log(`Seeded 1 admin, 1 non-admin and ${artists.length} artists into the emulators.`);
