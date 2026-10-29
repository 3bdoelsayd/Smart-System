const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

initializeApp({ credential: applicationDefault() });
const db = getFirestore();
const auth = getAuth();

const DOMAIN = "@smart.com";

function formatEmail(input) {
  const t = (input || '').toString().trim().toLowerCase();
  if (!t) return '';
  return t.includes('@') ? t : `${t}.college${DOMAIN}`;
}

function resolveUserEmail(d) {
  const e = (d.email || '').toString().trim().toLowerCase();
  if (e && e.includes('@') && !e.endsWith('@smart.edu')) return e;
  return formatEmail(d.id || d.code || '');
}

// email -> { code, name, roles:Set, places:Set }
const people = new Map();

function addPerson(doc, role, place) {
  const d = doc.data();
  const email = resolveUserEmail(d);
  if (!email) return;
  if (!people.has(email)) {
    people.set(email, {
      code: d.id || d.code || doc.id,
      name: d.name || 'Unknown',
      roles: new Set(),
      places: new Set(),
    });
  }
  const p = people.get(email);
  p.roles.add(role);
  p.places.add(place);
}

async function readCol(ref, role, place) {
  try {
    const snap = await ref.get();
    snap.docs.forEach(doc => addPerson(doc, role, place));
  } catch (e) {
    console.error(`Error reading ${place}:`, e.message);
  }
}

async function main() {
  const cols = ['students', 'doctors', 'tas', 'managers', 'super_admins'];

  // Root collections
  for (const c of cols) {
    await readCol(db.collection(c), c.slice(0, -1), c);
  }

  // Colleges + levels
  const colleges = await db.collection('colleges').get();
  for (const cd of colleges.docs) {
    for (const c of cols) {
      await readCol(cd.ref.collection(c), c.slice(0, -1), `colleges/${cd.id}/${c}`);
    }
    const levels = await cd.ref.collection('levels').get();
    for (const ld of levels.docs) {
      await readCol(
        ld.ref.collection('students'),
        'student',
        `colleges/${cd.id}/levels/${ld.id}/students`
      );
    }
  }

  // Check Auth in batches of 100
  const emails = [...people.keys()];
  const status = new Map(); // email -> 'true' | 'false' | 'error'
  for (let i = 0; i < emails.length; i += 100) {
    const batch = emails.slice(i, i + 100);
    try {
      const res = await auth.getUsers(batch.map(email => ({ email })));
      const found = new Set(res.users.map(u => (u.email || '').toLowerCase()));
      batch.forEach(e => status.set(e, found.has(e) ? 'true' : 'false'));
    } catch (e) {
      console.error('Batch failed:', e.message);
      batch.forEach(e2 => status.set(e2, 'error'));
    }
  }

  // CSV (stdout)
  const q = s => `"${String(s).replace(/"/g, '""')}"`;
  console.log('code,name,roles,places,existsInAuth');
  for (const [email, p] of people) {
    console.log([
      q(p.code),
      q(p.name),
      q([...p.roles].join('|')),
      q([...p.places].join('|')),
      status.get(email),
    ].join(','));
  }

  // Summary (stderr, so it does not go into the CSV file)
  const total = people.size;
  const missingList = [...people.entries()].filter(([e]) => status.get(e) === 'false');
  const errors = [...status.values()].filter(v => v === 'error').length;
  console.error(`\nTOTAL unique users: ${total} | MISSING in Auth: ${missingList.length} | ERRORS: ${errors}`);
  console.error('First 5 missing codes: ' +
    missingList.slice(0, 5).map(([, p]) => p.code).join(', '));
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });