/**
 * Sky Cloud Functions — fan out push notifications via FCM.
 *
 * Sending a push requires a trusted server, so it lives here rather than in the
 * app. Deploy with:  firebase deploy --only functions  (needs the Blaze plan).
 *
 * Triggers:
 *   - new chat message  -> notify the other participants
 *   - new ringing call  -> notify the callee
 *
 * Tokens are read from users/{uid}.fcmTokens, which the app maintains
 * (see lib/services/firebase_notification_service.dart).
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

exports.onNewMessage = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const msg = event.data && event.data.data();
      if (!msg) return;

      const chatSnap = await db.collection("chats").doc(event.params.chatId).get();
      const chat = chatSnap.data();
      if (!chat) return;

      const recipients = (chat.participantIds || [])
          .filter((id) => id !== msg.senderId);
      const tokens = await tokensFor(recipients);
      if (tokens.length === 0) return;

      const title = chat.isGroup ?
        (chat.name || "Group") :
        senderName(chat, msg.senderId);

      await send(tokens, title, preview(msg), {
        type: "message",
        chatId: event.params.chatId,
      });
    },
);

exports.onCallRinging = onDocumentCreated(
    "calls/{callId}",
    async (event) => {
      const call = event.data && event.data.data();
      if (!call || call.status !== "ringing") return;

      const tokens = await tokensFor([call.calleeId]);
      if (tokens.length === 0) return;

      await send(
          tokens,
          "Incoming call",
          call.isVideo ? "Video call" : "Voice call",
          {type: "call", callId: event.params.callId},
      );
    },
);

/** Collect every FCM token registered for the given user ids. */
async function tokensFor(uids) {
  const tokens = [];
  for (const uid of uids) {
    const snap = await db.collection("users").doc(uid).get();
    const list = (snap.data() || {}).fcmTokens || [];
    tokens.push(...list);
  }
  return tokens;
}

/** Best-effort display name for a sender within a chat. */
function senderName(chat, senderId) {
  const p = (chat.participants || []).find((u) => u.id === senderId);
  return (p && p.name) || "New message";
}

/** Short preview text for a message of any type. */
function preview(msg) {
  switch (msg.type) {
    case "image": return "📷 Photo";
    case "voice": return "🎤 Voice message";
    case "file": return "📎 " + (msg.text || "File");
    default: return msg.text || "";
  }
}

/** Multicast a notification, pruning tokens that FCM reports as invalid. */
async function send(tokens, title, body, data) {
  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: {title, body},
    data,
  });
  res.responses.forEach((r, i) => {
    if (!r.success) {
      console.warn("FCM send failed for token", tokens[i], r.error && r.error.code);
    }
  });
}
