<?php
/**
 * 資料庫連接設定 (Database Connection)
 * 使用 PDO 進行資料庫操作
 *
 * 用法：
 * - 被其他 API 檔案透過 require_once 載入
 * - 成功時提供全域變數 $pdo
 * - 失敗時直接回傳 500 JSON 並終止
 */

// ============ 資料庫連接設定 ============
// 若部署到正式環境，請改為讀取環境變數，避免硬編碼帳密。
const DB_HOST = 'localhost';
const DB_PORT = 3306;
const DB_NAME = 'invoice_db';
const DB_USER = 'root';
const DB_PASS = '';

try {
    // 建立 PDO DSN，指定 utf8mb4 以完整支援中文與 emoji 字元
    $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS);
    
    // 錯誤採例外模式，讓上層 API 可統一用 try/catch 處理
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // 明確設定連線字元集，避免中文亂碼
    $pdo->exec("SET NAMES utf8mb4");
    
    // 若需要診斷連線狀態，可暫時開啟下列紀錄
    // error_log("資料庫連接成功");
    
} catch (PDOException $e) {
    // 連線失敗時立即回傳 500，避免 API 在無 DB 狀態下繼續執行
    http_response_code(500);
    echo json_encode(['error' => '資料庫連接失敗: ' . $e->getMessage()]);
    exit();
}
?>
