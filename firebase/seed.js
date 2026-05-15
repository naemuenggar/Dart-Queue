/**
 * Script seed database untuk MVP. Jalankan sekali setelah Firestore aktif.
 *
 * Setup:
 *   1. Download service-account.json dari Firebase Console:
 *      Project Settings → Service Accounts → Generate new private key
 *   2. Simpan sebagai `firebase/service-account.json`
 *   3. cd firebase && node seed.js
 *
 * Yang di-seed:
 *   - 2 loket default (Loket 1 aktif, Loket 2 standby)
 *   - settings/A untuk prefix antrian "A" dengan lastNumber=0
 */
const admin = require("firebase-admin");
const path = require("path");

const serviceAccount = require(path.join(__dirname, "service-account.json"));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seed() {
  const today = new Date();
  const dateKey = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;

  console.log("Seeding counters...");
  await db.collection("counters").doc("counter-1").set({
    name: "Loket 1",
    isActive: true,
    currentNumber: 0,
    servingTicketId: null,
  });
  await db.collection("counters").doc("counter-2").set({
    name: "Loket 2",
    isActive: false,
    currentNumber: 0,
    servingTicketId: null,
  });

  console.log("Seeding settings...");
  await db.collection("settings").doc("A").set({
    prefix: "A",
    lastNumber: 0,
    date: dateKey,
  });

  console.log("✅ Done seeding");
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
