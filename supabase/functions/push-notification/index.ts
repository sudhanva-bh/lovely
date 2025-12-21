import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
// FIX: Use default import for firebase-admin
import admin from "npm:firebase-admin@11.11.1";

const serviceAccount = JSON.parse(
  Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}"
);

// Check if we have a valid project_id before initializing
if (serviceAccount.project_id) {
  // Check if already initialized to avoid "default app already exists" error
  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
}

serve(async (req) => {
  const payload = await req.json();
  const { record } = payload;

  if (!record || !record.fcm_token) {
    return new Response("No token found", { status: 200 });
  }

  try {
    const message = {
      token: record.fcm_token,
      notification: {
        title: record.title,
        body: record.body,
      },
      // Android specific settings
      android: {
        priority: "high",
        notification: {
          ...(record.image_url && { image: record.image_url }),
        }
      },
      // iOS specific settings
      apns: {
        payload: {
          aps: {
            "mutable-content": 1,
          },
        },
        ...(record.image_url && { 
            fcm_options: { image: record.image_url } 
        }),
      },
    };

    const response = await admin.messaging().send(message);

    console.log("Successfully sent message:", response);
    return new Response(JSON.stringify({ success: true, id: response }), {
      headers: { "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Error sending message:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});