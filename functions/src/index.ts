import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// Cloud Function that triggers when a new notification document is created
// Listens to: users/{userId}/notifications/{notificationId}
export const sendUserNotification = onDocumentCreated(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const notificationData = snapshot.data();
    const recipientUid = event.params.userId;

    const recipientDoc = await admin
      .firestore()
      .doc(`users/${recipientUid}`)
      .get();

    const recipientData = recipientDoc.data();

    if (recipientData && recipientData.token) {
      let title = notificationData.username;
      let body = notificationData.description;

      if (notificationData.type === "friend_request") {
        title = "New Friend Request";
        body = `${notificationData.username} sent you a friend request`;
      } else if (notificationData.type === "message") {
        title = notificationData.username;
        body = notificationData.description;
      } else if (notificationData.type === "group_message") {
        title = notificationData.groupName || "Group Message";
        body =
          `${notificationData.username}: ` +
          notificationData.description;
      }

      const message = {
        token: recipientData.token,
        notification: {title, body},
        data: {
          uid: notificationData.uid || "",
          notificationId: event.params.notificationId,
          chatId: notificationData.chatId || "",
          type: notificationData.type || "message",
          groupId: notificationData.groupId || "",
          groupName: notificationData.groupName || "",
        },
        android: {
          priority: "high" as const,
          notification: {
            sound: "default",
            channelId: "chat_messages_channel",
            icon: "ic_launcher",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      try {
        await admin.messaging().send(message);
        console.log("Notification sent successfully:", title);
      } catch (error) {
        console.error("Error sending notification", error);
      }
    } else {
      console.log("No device token for recipient");
    }
  }
);
