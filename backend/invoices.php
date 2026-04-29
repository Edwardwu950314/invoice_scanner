<?php
/**
 * 發票管理 API (Invoice Management API)
 * 
 * 負責使用者發票紀錄的 CRUD 操作。
 * 主要使用於：
 * - Flutter App 的發票新增、編輯、刪除
 * - 後台發票列表查詢
 * 
 * 支援的 HTTP 方法：
 * - GET    /invoices.php              取得發票列表 (可依 period / invoice_number 篩選)
 * - POST   /invoices.php              新增或更新發票（以 invoice_number + period 為唯一鍵）
 * - DELETE /invoices.php              刪除發票 (依 id / invoice_number / period 刪除)
 * 
 * 資料庫表格結構：
 * - id (int): 主鍵
 * - invoice_number (varchar): 發票號碼（如 WR-73786487），與期別組成複合唯一鍵
 * - period (varchar): 發票期別（如 11502）
 * - amount (int): 發票金額（新台幣）
 * - invoice_date (date): 發票開立日期
 * - image_path (varchar): 發票圖片路徑（存儲在 App 本地或後端）
 * - created_at (timestamp): 建立時間
 * - updated_at (timestamp): 最後更新時間
 */

// ============ CORS 與內容協商設置 ============
header('Access-Control-Allow-Origin: *'); // 允許跨域請求
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS'); // 允許的 HTTP 方法
header('Access-Control-Allow-Headers: Content-Type, Authorization'); // 允許的請求頭
header('Content-Type: application/json; charset=utf-8'); // 回應格式為 JSON

// ============ 處理 OPTIONS 預檢請求 ============
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ============ 載入資料庫連接 ============
require_once 'db.php';

// ============ 主路由邏輯 ============
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        getInvoices();
        break;
    case 'POST':
        addOrUpdateInvoice();
        break;
    case 'DELETE':
        deleteInvoice();
        break;
    default:
        http_response_code(405);
        echo json_encode(['error' => '不支援的請求方法'], JSON_UNESCAPED_UNICODE);
        exit();
}

/**
 * 【GET】取得發票列表
 * 
 * 查詢參數：
 * - period (選用): 期別篩選，精確比對
 * - invoice_number (選用): 發票號碼篩選，精確比對
 * 
 * 回應：
 * - 成功：JSON 陣列，按 created_at 降序排列
 * - 錯誤：HTTP 500，包含 'error' 欄位
 * 
 * 範例：
 * GET /invoices.php
 * GET /invoices.php?period=11502
 * GET /invoices.php?invoice_number=WR-73786487
 */
function getInvoices() {
    global $pdo;

    try {
        // ============ 建立基礎 SQL 查詢 ============
        $sql = 'SELECT * FROM invoices WHERE 1=1';
        $params = [];

        // ============ 動態篩選條件 ============
        if (!empty($_GET['period'])) {
            $sql .= ' AND period = ?';
            $params[] = $_GET['period'];
        }

        if (!empty($_GET['invoice_number'])) {
            $sql .= ' AND invoice_number = ?';
            $params[] = $_GET['invoice_number'];
        }

        // ============ 排序：最新建立優先 ============
        $sql .= ' ORDER BY created_at DESC';

        // ============ 執行查詢 ============
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        $invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($invoices, JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '查詢發票失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * 【POST】新增或更新發票
 * 
 * 必填欄位（JSON body）：
 * - invoice_number (string): 發票號碼
 * - period (string): 期別
 * 
 * 選填欄位：
 * - amount (int): 發票金額
 * - invoice_date (string): 發票日期 (ISO 8601 格式)
 * - image_path (string): 圖片路徑
 * 
 * 邏輯：
 * - 若 invoice_number + period 的組合已存在，則更新
 * - 若不存在，則新增
 * 
 * 回應：
 * - 成功：HTTP 200，包含 id 和 message
 * - 失敗：HTTP 400（缺少必填欄位）或 500（資料庫錯誤）
 */
function addOrUpdateInvoice() {
    global $pdo;

    try {
        // ============ 解析 JSON 請求體 ============
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        // ============ 驗證必填欄位 ============
        if (empty($input['invoice_number']) || empty($input['period'])) {
            http_response_code(400);
            echo json_encode(['error' => '缺少必要欄位: invoice_number 或 period'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 提取欄位值，設定預設值 ============
        $invoiceNumber = (string) $input['invoice_number'];
        $period = (string) $input['period'];
        $amount = isset($input['amount']) ? (int) $input['amount'] : 0;
        $invoiceDate = $input['invoice_date'] ?? null;
        $imagePath = $input['image_path'] ?? null;

        // ============ 檢查記錄是否已存在 ============
        // 以 invoice_number + period 作為複合唯一鍵
        $checkStmt = $pdo->prepare('SELECT id FROM invoices WHERE invoice_number = ? AND period = ?');
        $checkStmt->execute([$invoiceNumber, $period]);
        $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

        if ($existing) {
            // ============ 更新現有記錄 ============
            $stmt = $pdo->prepare('UPDATE invoices SET amount = ?, invoice_date = ?, image_path = ? WHERE invoice_number = ? AND period = ?');
            $stmt->execute([$amount, $invoiceDate, $imagePath, $invoiceNumber, $period]);
            $id = (int) $existing['id'];
            $message = '發票已更新';
        } else {
            // ============ 新增新記錄 ============
            $stmt = $pdo->prepare('INSERT INTO invoices (invoice_number, period, amount, invoice_date, image_path) VALUES (?, ?, ?, ?, ?)');
            $stmt->execute([$invoiceNumber, $period, $amount, $invoiceDate, $imagePath]);
            $id = (int) $pdo->lastInsertId();
            $message = '發票已新增';
        }

        // ============ 回應成功 ============
        echo json_encode([
            'success' => true,
            'ok' => true,
            'message' => $message,
            'id' => $id,
        ], JSON_UNESCAPED_UNICODE);
    } catch (PDOException $e) {
        // ============ 處理重複鍵錯誤 ============
        if (strpos($e->getMessage(), 'UNIQUE') !== false) {
            http_response_code(409);
            echo json_encode(['error' => '該發票號碼和期別已存在'], JSON_UNESCAPED_UNICODE);
        } else {
            http_response_code(500);
            echo json_encode(['error' => '新增或更新發票失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '新增或更新發票失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * 【DELETE】刪除發票
 * 
 * 刪除參數（Query String）：
 * - id (選項 1): 按發票 ID 刪除
 * - invoice_number + period (選項 2): 按號碼和期別組合刪除
 * - invoice_number (選項 3): 按號碼刪除（會刪除所有同號碼的記錄）
 * 
 * 回應：
 * - 成功：HTTP 200，包含 affectedRows 和 success
 * - 失敗：HTTP 400（缺少參數）或 500（資料庫錯誤）
 */
function deleteInvoice() {
    global $pdo;

    try {
        // ============ 取得刪除參數 ============
        $invoiceNumber = $_GET['invoice_number'] ?? null;
        $period = $_GET['period'] ?? null;
        $id = $_GET['id'] ?? null;

        // ============ 根據提供的參數決定刪除策略 ============
        if (!empty($id)) {
            // 策略 1：按 ID 刪除單筆記錄
            $stmt = $pdo->prepare('DELETE FROM invoices WHERE id = ?');
            $stmt->execute([$id]);
        } elseif (!empty($invoiceNumber) && !empty($period)) {
            // 策略 2：按 invoice_number + period 組合刪除
            $stmt = $pdo->prepare('DELETE FROM invoices WHERE invoice_number = ? AND period = ?');
            $stmt->execute([$invoiceNumber, $period]);
        } elseif (!empty($invoiceNumber)) {
            // 策略 3：按 invoice_number 刪除所有相關記錄
            $stmt = $pdo->prepare('DELETE FROM invoices WHERE invoice_number = ?');
            $stmt->execute([$invoiceNumber]);
        } else {
            // 缺少必要參數
            http_response_code(400);
            echo json_encode(['error' => '缺少必要參數: id 或 invoice_number'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 回應成功 ============
        echo json_encode([
            'success' => true,
            'ok' => true,
            'affectedRows' => $stmt->rowCount(),
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '刪除發票失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}
?>
