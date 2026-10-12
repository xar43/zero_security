abstract class UrlConstants {
  // Confirmed Base URL from Postman
  static const String baseUrl = 'https://timetracking.hansrajinfotech.com/api';

  // --- Auth & Attendance ---
  static const String loginUrl = "$baseUrl/login";
  static const String punchInUrl = "$baseUrl/punch_in";
  static const String punchOutUrl = "$baseUrl/punch_out";

  // --- Location ---
  static const String logLocationUrl = "$baseUrl/log_location"; // Text location (JSON)
  static const String uploadLocationUrl = "$baseUrl/upload_location"; // Location with Photo (FormData)

  // --- Todos ---
  static const String todoListUrl = "$baseUrl/todo/list";
  static const String toggleTodoStatusUrl = "$baseUrl/todo/toggle_status";
  static const String respondTodoUrl = "$baseUrl/todo/respond";

  // --- Sticky Notes & Status ---
  static const String addStickyNoteUrl = "$baseUrl/add_sticky_note";
  static const String updateStatusUrl = "$baseUrl/update_status";
  
  // --- Miscellaneous ---
  static const String healthCheckUrl = "$baseUrl/health";

  // --- File Uploads (Dummy Links as requested, to be updated when live) ---
  static const String driveUploadUrl = "https://dummy-link.com/api/drive_upload"; 
  static const String uploadExtrasUrl = "https://dummy-link.com/api/upload_extras";
}
