/**
 * Mock seed data untuk testing UI.
 *
 * Yang di-generate:
 *   - 12 tiket dummy dengan status bervariasi:
 *       1 serving, 1 called, 7 waiting, 2 done, 1 skipped
 *   - settings/A di-update sesuai nomor terakhir
 *   - 1 counter aktif (counter-1) lagi melayani tiket "serving"
 *
 * Cara pakai:
 *   cd firebase
 *   node seed-mock.js          # tambah mock data
 *   node seed-mock.js --reset  # hapus semua tiket dulu, baru seed
 *
 * Catatan: jangan jalankan di production. Hanya untuk dev/staging.
 */
const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

const MOCK_NAMES = [
  "Budi Santoso",
  "Siti Aminah",
  "Andi Wijaya",
  "Dewi Lestari",
  "Rudi Hartono",
  "Maya Sari",
  "Agus Setiawan",
  "Linda Putri",
  "Bambang",
  "Rina",
  null, // anonim
  null,
];

// Definisi 12 tiket: nomor + status + offset waktu (menit dari sekarang)
const MOCK_TICKETS = [
  { number: 1, status: "done", minutesAgo: 45 },
  { number: 2, status: "done", minutesAgo: 30 },
  { number: 3, status: "skipped", minutesAgo: 25 },
  { number: 4, status: "serving", minutesAgo: 5, counterId: "counter-1" },
  { number: 5, status: "called", minutesAgo: 3, counterId: "counter-1" },
  { number: 6, status: "waiting", minutesAgo: 12 },
  { number: 7, status: "waiting", minutesAgo: 10 },
  { number: 8, status: "waiting", minutesAgo: 9 },
  { number: 9, status: "waiting", minutesAgo: 8 },
  { number: 10, status: "waiting", minutesAgo: 6 },
  { number: 11, status: "waiting", minutesAgo: 4 },
  { number: 12, status: "waiting", minutesAgo: 2 },
];

const PREFIX = "A";

function todayKey() {
  const t = new Date();
  return `${t.getFullYear()}-${String(t.getMonth() + 1).padStart(2, "0")}-${String(t.getDate()).padStart(2, "0")}`;
}

function ts(minutesAgo) {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - minutesAgo * 60_000)
  );
}

async function reset() {
  console.log("🗑️  Resetting queues collection...");
  const snap = await db.collection("queues").get();
  const batch = db.batch();
  snap.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
  console.log(`   Deleted ${snap.size} tickets.`);
}

async function seedMock() {
  const today = todayKey();
  const batch = db.batch();
  const lastNumber = MOCK_TICKETS[MOCK_TICKETS.length - 1].number;
  let servingTicketRef = null;

  console.log(`🎫 Generating ${MOCK_TICKETS.length} mock tickets...`);
  MOCK_TICKETS.forEach((mock, i) => {
    const ref = db.collection("queues").doc();
    const created = ts(mock.minutesAgo);
    const data = {
      prefix: PREFIX,
      number: mock.number,
      status: mock.status,
      customerName: MOCK_NAMES[i % MOCK_NAMES.length],
      tableNumber: String(((i % 10) + 1)),
      fcmToken: null,
      counterId: mock.counterId || null,
      createdAt: created,
      calledAt: null,
      servedAt: null,
      doneAt: null,
    };

    // Isi timestamp lanjutan sesuai status
    if (["called", "serving", "done", "skipped"].includes(mock.status)) {
      data.calledAt = ts(Math.max(mock.minutesAgo - 1, 0));
    }
    if (["serving", "done"].includes(mock.status)) {
      data.servedAt = ts(Math.max(mock.minutesAgo - 2, 0));
    }
    if (mock.status === "done") {
      data.doneAt = ts(Math.max(mock.minutesAgo - 3, 0));
    }

    batch.set(ref, data);

    if (mock.status === "serving") servingTicketRef = ref;
  });

  // Update settings/A supaya nomor berikutnya nyambung
  batch.set(db.collection("settings").doc(PREFIX), {
    prefix: PREFIX,
    lastNumber,
    date: today,
  });

  // Update counter-1 supaya kelihatan lagi melayani tiket "serving"
  batch.set(
    db.collection("counters").doc("counter-1"),
    {
      name: "Loket 1",
      isActive: true,
      currentNumber: 4,
      servingTicketId: servingTicketRef ? servingTicketRef.id : null,
    },
    { merge: true }
  );
  batch.set(
    db.collection("counters").doc("counter-2"),
    {
      name: "Loket 2",
      isActive: false,
      currentNumber: 0,
      servingTicketId: null,
    },
    { merge: true }
  );

  await batch.commit();
  console.log(`✅ Seeded ${MOCK_TICKETS.length} tickets + counters + settings.`);
  console.log(`   Next ticket number: A${String(lastNumber + 1).padStart(3, "0")}`);
}

async function main() {
  if (process.argv.includes("--reset")) {
    await reset();
  }
  await seedMock();
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
