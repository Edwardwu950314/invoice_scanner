<?php
/**
 * 資料庫連接設定 (Database Connection)
 * 使用 PDO 進行資料庫操作
 */

// 資料庫連接設定
const DB_HOST = 'localhost';
const DB_PORT = 3306;
const DB_NAME = 'invoice_db';
const DB_USER = 'root';
const DB_PASS = '';

try {
    // 建立 PDO 連接
    $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
    $pdo = new PDO($dsn, DB_USER, DB_PASS);
    
    // 設置 PDO 錯誤模式為拋出例外
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // 設置預設連接編碼
    $pdo->exec("SET NAMES utf8mb4");
    
    // 如果需要列印調試信息，取消下行註釋
    // error_log("資料庫連接成功");
    
} catch (PDOException $e) {
    // 連接失敗時返回錯誤信息
    http_response_code(500);
    echo json_encode(['error' => '資料庫連接失敗: ' . $e->getMessage()]);
    exit();
}
?>
