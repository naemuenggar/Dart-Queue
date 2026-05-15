/**
 * Cloud Functions untuk Resto Queue.
 *
 * Trigger: saat dokumen tiket di /queues/{id} di-update menjadi `called`,
 * kirim FCM push ke fcmToken yang disimpan di tiket.
 *
 * Deploy:
 *   cd firebase
 *   npm install
 *   firebase deploy --only functions
 */
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.onTicketCalled = onDocumentUpdated(
  "queues/{ticketId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    // Hanya kirim saat status berubah ke 'called'
    if (before.status === after.status) return;
    if (after.status !== "called") return;
    if (!after.fcmToken) return;

    const display =
      `${after.prefix}${String(after.number).padStart(3, "0")}`;
    const counter = after.counterId || "loket";

    await getMessaging().send({
      token: after.fcmToken,
      notification: {
        title: "Giliran Anda!",
        body: `Nomor ${display} dipanggil. Silakan menuju ${counter}.`,
      },
      android: {
        priority: "high",
        notification: { channelId: "queue_calls", sound: "default" },
      },
      apns: {
        payload: { aps: { sound: "default" } },
      },
    });
  }
);
