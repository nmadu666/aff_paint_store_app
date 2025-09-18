import {onRequest, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import axios from "axios";
import cors from "cors";

// Khởi tạo CORS middleware
const corsHandler = cors({origin: true});

const db = admin.firestore();

// Biến toàn cục để cache access token
let cachedToken: {
  accessToken: string;
  expiresAt: number;
} | null = null;

/**
 * Lấy KiotViet API settings từ Firestore.
 */
async function getKiotVietSettings() {
  const settingsDoc = await db.collection("settings").doc("kiotvietApi").get();
  if (!settingsDoc.exists) {
    throw new HttpsError(
      "not-found",
      "KiotViet API settings not found in Firestore.",
    );
  }
  return settingsDoc.data();
}

/**
 * Lấy Access Token từ KiotViet, sử dụng cache nếu có thể.
 */
async function getAccessToken() {
  if (cachedToken && Date.now() < cachedToken.expiresAt) {
    return cachedToken.accessToken;
  }

  const settings = await getKiotVietSettings();
  if (!settings?.clientId || !settings?.clientSecret) {
    throw new HttpsError(
      "failed-precondition",
      "Missing clientId or clientSecret in settings.",
    );
  }

  const params = new URLSearchParams();
  params.append("scopes", "PublicApi.Access");
  params.append("grant_type", "client_credentials");
  params.append("client_id", settings.clientId);
  params.append("client_secret", settings.clientSecret);

  const response = await axios.post(
    "https://id.kiotviet.vn/connect/token",
    params,
    {headers: {"Content-Type": "application/x-www-form-urlencoded"}},
  );

  const accessToken = response.data.access_token;
  const expiresIn = response.data.expires_in; // seconds

  // Cache token, trừ đi 60s để an toàn
  cachedToken = {
    accessToken,
    expiresAt: Date.now() + (expiresIn - 60) * 1000,
  };

  return accessToken;
}

export const kiotVietProxy = onRequest(
  {region: "asia-southeast1", maxInstances: 10},
  (req, res) => {
    corsHandler(req, res, async () => {
      try {
        const settings = await getKiotVietSettings();
        const accessToken = await getAccessToken();

        const kiotVietUrl = `https://public.kiotapi.com${req.path}`;

        const response = await axios({
          method: req.method as "GET" | "POST" | "PUT" | "DELETE",
          url: kiotVietUrl,
          params: req.query,
          data: req.body,
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Retailer": settings?.retailer,
            "Content-Type": "application/json",
          },
          // Không throw error với status code 4xx/5xx để có thể trả về client
          validateStatus: () => true,
        });

        res.status(response.status).send(response.data);
      } catch (error: unknown) {
        logger.error("Proxy Error:", error);
        if (error instanceof HttpsError) {
          res.status(500).send({error: error.message});
        } else {
          res.status(500).send({error: "An internal proxy error occurred."});
        }
      }
    });
  },
);
