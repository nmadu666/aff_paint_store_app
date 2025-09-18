import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

// Cloud function để xóa một người dùng khỏi Firebase Authentication.
export const deleteAuthUser = onCall(
  {region: "asia-southeast1"},
  async (request) => {
    logger.info("Bắt đầu yêu cầu xóa người dùng với dữ liệu:", {
      data: request.data,
      authContext: request.auth,
    });

    // 1. Kiểm tra xem người gọi đã được xác thực chưa.
    if (!request.auth) {
      logger.warn("Yêu cầu xóa người dùng chưa được xác thực.");
      throw new HttpsError(
        "unauthenticated",
        "Chức năng này yêu cầu xác thực."
      );
    }

    const callerUid = request.auth.uid;
    const uidToDelete = request.data.uid;

    // 2. Kiểm tra tính hợp lệ của UID đầu vào.
    if (typeof uidToDelete !== "string" || uidToDelete.length === 0) {
      logger.error("UID không hợp lệ được cung cấp:", uidToDelete);
      throw new HttpsError(
        "invalid-argument",
        "UID của người dùng cần xóa không hợp lệ."
      );
    }

    // 3. Không cho phép admin tự xóa chính mình.
    if (callerUid === uidToDelete) {
      logger.warn(`Quản trị viên ${callerUid} đã cố gắng tự xóa.`);
      throw new HttpsError(
        "permission-denied",
        "Quản trị viên không thể tự xóa chính mình."
      );
    }

    try {
      // 4. Kiểm tra xem người gọi có phải là admin không.
      const db = admin.firestore();
      const callerDoc = await db.collection("users").doc(callerUid).get();

      if (!callerDoc.exists || callerDoc.data()?.role !== "admin") {
        logger.error(
          `Người dùng ${callerUid} không có quyền admin để xóa người dùng.`,
        );
        throw new HttpsError(
          "permission-denied",
          "Chỉ có quản trị viên mới có thể thực hiện hành động này.",
        );
      }

      // 5. Thực hiện xóa người dùng khỏi Authentication.
      logger.info(
        `Tiến hành xóa người dùng ${uidToDelete} bởi admin ${callerUid}.`,
      );
      await admin.auth().deleteUser(uidToDelete);
      logger.info(`Xóa thành công người dùng: ${uidToDelete}`);
      return {success: true};
    } catch (error) {
      logger.error(`Lỗi khi xóa người dùng ${uidToDelete}:`, error);
      // Ném lại lỗi HttpsError đã được xử lý hoặc tạo lỗi mới
      // cho các trường hợp khác.
      if (error instanceof HttpsError) throw error;
      throw new HttpsError("internal", "Lỗi máy chủ nội bộ.");
    }
  },
);
