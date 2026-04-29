<?php
/**
 * 對獎功能 API (Prize Checking API)
 * 使用 SQL JOIN 比對 invoices + winning_numbers
 * 支援 GET 方法，可指定期別進行對獎
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['error' => '只支援 GET 方法']);
    exit();
}

require_once 'db.php';

try {
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
        $sql .= ' AND i.period = ?';
        $params[] = $_GET['period'];
    }

    $sql .= ' ORDER BY i.period DESC, w.prize_amount DESC, i.invoice_number ASC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $winning_invoices = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $total_prize_amount = 0;
    foreach ($winning_invoices as $invoice) {
        $total_prize_amount += (int) $invoice['prize_amount'];
    }

    $winning_count = count($winning_invoices);

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
    http_response_code(500);
    echo json_encode(['error' => '對獎查詢失敗: ' . $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
?>
