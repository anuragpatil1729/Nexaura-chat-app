/* eslint-disable */const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendChatNotification = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snap, context) => {
        const message = snap.data();
        const chatId = context.params.chatId;
        const senderId = message.senderId;

        const participants = chatId.split("_");
        const recipientId = participants.find((id) => id !== senderId);

        if (!recipientId) {
            console.log("Recipient not found");
            return;
        }

        const recipientDoc = await admin
            .firestore()
            .collection("users")
            .doc(recipientId)
            .get();
        const recipientData = recipientDoc.data();
        if (!recipientData) {
            console.log("Recipient data not found");
            return;
        }
        const recipientToken = recipientData.fcmToken;

        if (!recipientToken) {
            console.log("Recipient FCM token not found");
            return;
        }

        const senderDoc = await admin
            .firestore()
            .collection("users")
            .doc(senderId)
            .get();
        const senderData = senderDoc.data();
        const senderName = senderData.displayName || "Someone";

        const payload = {
            notification: {
                title: `New message from ${senderName}`,
                body: message.text || "Sent an image",
                sound: "default",
            },
        };

        try {
            await admin.messaging().sendToDevice(recipientToken, payload);
            console.log("Notification sent successfully");
        } catch (error) {
            console.error("Error sending notification:", error);
        }
    });
