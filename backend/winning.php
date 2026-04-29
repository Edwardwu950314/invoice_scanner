<?php
/**
 * 中獎號碼維護 API (Winning Numbers Admin API)
 * 
 * 負責中獎號碼的完整 CRUD 操作。
 * 主要使用於：
 * - Flutter App 內的對獎功能（check.php 會呼叫此 API 查詢）
 * - 後台管理頁面（admin.php 的新增、編輯、刪除操作）
 * 
 * 支援的 HTTP 方法：
 * - GET    /winning.php              取得中獎號碼 (可依 period / prize_type 篩選)
 * - POST   /winning.php              新增中獎號碼
 * - PUT    /winning.php?id={id}      修改中獎號碼
 * - DELETE /winning.php?id={id}      刪除中獎號碼
 * 
 * 資料庫表格結構：
 * - id (int): 主鍵
 * - period (varchar): 發票期別（如 11502）
 * - prize_type (varchar): 獎別（如 特別獎、六獎等）
 * - number (varchar): 中獎號碼（自動轉為大寫）
 * - prize_amount (int): 獎金金額（新台幣）
 * - created_at (timestamp): 建立時間（自動設為當前時間）
 */

// ============ CORS 與內容協商設置 ============
header('Access-Control-Allow-Origin: *'); // 允許跨域請求
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS'); // 允許的 HTTP 方法
header('Access-Control-Allow-Headers: Content-Type, Authorization'); // 允許的請求頭
header('Content-Type: application/json; charset=utf-8'); // 回應格式為 JSON（UTF-8 編碼）

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
        getWinningNumbers();
        break;
    case 'POST':
        createWinningNumber();
        break;
    case 'PUT':
        updateWinningNumber();
        break;
    case 'DELETE':
        deleteWinningNumber();
        break;
    default:
        http_response_code(405);
        echo json_encode(['error' => '不支援的請求方法'], JSON_UNESCAPED_UNICODE);
        break;
}

/**
 * 【GET】取得中獎號碼列表
 * 
 * 查詢參數：
 * - period (選用): 期別篩選，精確比對
 * - prize_type (選用): 獎別篩選，精確比對
 * 
 * 回應：
 * - 成功：JSON 陣列，按 period 降序、prize_type 升序排列
 * - 錯誤：HTTP 500，包含 'error' 欄位
 * 
 * 範例：
 * GET /winning.php
 * GET /winning.php?period=11502
 * GET /winning.php?prize_type=特別獎
 * GET /winning.php?period=11502&prize_type=特別獎
 */
function getWinningNumbers() {
    global $pdo;

    try {
        // ============ 建立基礎 SQL 查詢 ============
        $sql = 'SELECT id, period, prize_type, number, prize_amount, created_at FROM winning_numbers WHERE 1=1';
        $params = [];

        // ============ 動態篩選條件 ============
        if (!empty($_GET['period'])) {
            $sql .= ' AND period = ?';
            $params[] = $_GET['period'];
        }

        if (!empty($_GET['prize_type'])) {
            $sql .= ' AND prize_type = ?';
            $params[] = $_GET['prize_type'];
        }

        // ============ 排序：期別降序、獎別升序、ID降序 ============
        $sql .= ' ORDER BY period DESC, prize_type ASC, id DESC';

        // ============ 執行查詢 ============
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        $winningNumbers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($winningNumbers, JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '查詢中獎號碼失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * 【POST】新增中獎號碼
 * 
 * 必填欄位（JSON body）：
 * - period (string): 期別（如 11502）
 * - prize_type (string): 獎別（如 特別獎、六獎）
 * - number (string): 號碼（會自動轉為大寫）
 * - prize_amount (int): 獎金金額
 * 
 * 回應：
 * - 成功：HTTP 200，包含 id 和 success 訊息
 * - 失敗：HTTP 400（缺少欄位）或 500（資料庫錯誤）
 */
function createWinningNumber() {
    global $pdo;

    try {
        // ============ 解析 JSON 請求體 ============
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        // ============ 驗證必填欄位 ============
        if (empty($input['period']) || empty($input['prize_type']) || empty($input['number']) || !isset($input['prize_amount'])) {
            http_response_code(400);
            echo json_encode(['error' => '缺少必要欄位: period, prize_type, number, prize_amount'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 插入新記錄 ============
        // 號碼自動轉為大寫（如 WR-73786487）
        $stmt = $pdo->prepare(
            'INSERT INTO winning_numbers (period, prize_type, number, prize_amount) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([
            (string) $input['period'],
            (string) $input['prize_type'],
            strtoupper((string) $input['number']),
            (int) $input['prize_amount'],
        ]);

        // ============ 回應成功 ============
        echo json_encode([
            'success' => true,
            'id' => (int) $pdo->lastInsertId(),
            'message' => '中獎號碼已新增',
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '新增中獎號碼失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * 【PUT】更新中獎號碼
 * 
 * 必要參數：
 * - id (query): 要更新的記錄 ID
 * 
 * 可更新欄位（JSON body）：
 * - period, prize_type, number, prize_amount
 * （只需傳入要變更的欄位，其他欄位保持不變）
 * 
 * 回應：
 * - 成功：HTTP 200，包含 affectedRows 和 success
 * - 失敗：HTTP 400（缺少 ID）或 500（資料庫錯誤）
 */
function updateWinningNumber() {
    global $pdo;

    try {
        // ============ 取得欲更新的記錄 ID ============
        $id = $_GET['id'] ?? null;
        if (empty($id)) {
            http_response_code(400);
            echo json_encode(['error' => '缺少必要參數: id'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 解析 JSON 請求體 ============
        $input = json_decode(file_get_contents('php://input'), true) ?? [];

        // ============ 動態建立 UPDATE 語句 ============
        // 只更新請求中包含的欄位
        $fields = [];
        $params = [];

        if (isset($input['period'])) {
            $fields[] = 'period = ?';
            $params[] = (string) $input['period'];
        }
        if (isset($input['prize_type'])) {
            $fields[] = 'prize_type = ?';
            $params[] = (string) $input['prize_type'];
        }
        if (isset($input['number'])) {
            $fields[] = 'number = ?';
            $params[] = strtoupper((string) $input['number']);
        }
        if (isset($input['prize_amount'])) {
            $fields[] = 'prize_amount = ?';
            $params[] = (int) $input['prize_amount'];
        }

        // ============ 檢查是否有欄位要更新 ============
        if (empty($fields)) {
            http_response_code(400);
            echo json_encode(['error' => '沒有可更新的欄位'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 執行更新 ============
        $params[] = (int) $id;
        $sql = 'UPDATE winning_numbers SET ' . implode(', ', $fields) . ' WHERE id = ?';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);

        // ============ 回應成功 ============
        echo json_encode([
            'success' => true,
            'affectedRows' => $stmt->rowCount(),
            'message' => '中獎號碼已更新',
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '更新中獎號碼失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}

/**
 * 【DELETE】刪除中獎號碼
 * 
 * 必要參數：
 * - id (query): 要刪除的記錄 ID
 * 
 * 回應：
 * - 成功：HTTP 200，包含 affectedRows 和 success
 * - 失敗：HTTP 400（缺少 ID）或 500（資料庫錯誤）
 */
function deleteWinningNumber() {
    global $pdo;

    try {
        // ============ 取得欲刪除的記錄 ID ============
        $id = $_GET['id'] ?? null;
        if (empty($id)) {
            http_response_code(400);
            echo json_encode(['error' => '缺少必要參數: id'], JSON_UNESCAPED_UNICODE);
            return;
        }

        // ============ 執行刪除 ============
        $stmt = $pdo->prepare('DELETE FROM winning_numbers WHERE id = ?');
        $stmt->execute([(int) $id]);

        // ============ 回應成功 ============
        echo json_encode([
            'success' => true,
            'affectedRows' => $stmt->rowCount(),
            'message' => '中獎號碼已刪除',
        ], JSON_UNESCAPED_UNICODE);
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['error' => '刪除中獎號碼失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
    }
}
?>
