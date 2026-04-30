<?php
/**
 * 對獎功能 API (Prize Checking API)
 * 使用 SQL JOIN 比對 invoices + winning_numbers
 * 支援 GET 方法，可指定期別進行對獎
 *
 * 設計重點：
 * 1. 只接受 GET，避免被誤用為資料異動接口
 * 2. 可透過 period 進行期別篩選
 * 3. 回傳完整中獎明細 + 總數與總獎金，供 App 直接顯示
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    // CORS 預檢請求直接回 200，不進入商業邏輯
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    // 此 API 僅查詢用途，禁止其他 HTTP 方法
    http_response_code(405);
    echo json_encode(['error' => '只支援 GET 方法']);
    exit();
}

require_once 'db.php';

try {
    // 主查詢：以發票號碼 + 期別與中獎號碼表進行內連接
    $sql = '
        SELECT
            i.invoice_number,
            i.period,
            i.amount AS invoice_amount,
            w.prize_type,
            w.number AS prize_number,
            w.prize_amount
        FROM invoices i
        INNER JOIN winning_numbers w
            ON i.period = w.period
           AND i.invoice_number = w.number
        WHERE 1=1
    ';

    $params = [];

    if (!empty($_GET['period'])) {
        // 若指定期別，追加條件以縮小查詢範圍
        $sql .= ' AND i.period = ?';
        $params[] = $_GET['period'];
    }

    $sql .= ' ORDER BY i.period DESC, w.prize_amount DESC, i.invoice_number ASC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    // 取得所有中獎發票明細
    $winning_invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 聚合統計：計算總獎金
    $total_prize_amount = 0;
    foreach ($winning_invoices as $invoice) {
        $total_prize_amount += (int) $invoice['prize_amount'];
    }

    // 聚合統計：中獎筆數
    $winning_count = count($winning_invoices);

    // 兼容不同前端欄位命名，回傳同義鍵
    echo json_encode([
        'success' => true,
        'winning_count' => $winning_count,
        'total_prize_amount' => $total_prize_amount,
        'winning_invoices' => $winning_invoices,
        'count' => $winning_count,
        'total_prize' => $total_prize_amount,
        'winners' => $winning_invoices,
    ], JSON_UNESCAPED_UNICODE);
} catch (Exception $e) {
    // 統一錯誤回應，避免洩漏堆疊細節
    http_response_code(500);
    echo json_encode(['error' => '對獎查詢失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
