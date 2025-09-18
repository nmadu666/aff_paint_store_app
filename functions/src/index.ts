import * as admin from "firebase-admin";

/**
 * Khởi tạo Firebase Admin SDK.
 * Phải được gọi một lần trước khi sử dụng các dịch vụ Firebase.
 */
admin.initializeApp();

/**
 * Tệp chính để export tất cả các Cloud Functions.
 * Cấu trúc này giúp giữ cho code gọn gàng và dễ quản lý.
 */

// Export các function liên quan đến proxy
export {kiotVietProxy} from "./proxy";

// Export các function liên quan đến quản lý người dùng
export {deleteAuthUser} from "./users";
