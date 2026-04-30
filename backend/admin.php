<?php
/**
 * 中獎號碼管理頁面
 *
 * 放在 XAMPP htdocs 的 invoice_scanner 目錄下後，可直接用瀏覽器開啟：
 * http://localhost/invoice_scanner/admin.php
 *
 * 備註：
 * - 此頁面本身不直接操作資料庫
 * - 所有資料異動都透過同目錄的 winning.php API 完成
 */
?>
<!DOCTYPE html>
<html lang="zh-Hant">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>中獎號碼管理</title>
  <style>
    :root {
      --bg: #f5f7fb;
      --card: #ffffff;
      --text: #182233;
      --muted: #64748b;
      --primary: #2563eb;
      --primary-2: #14b8a6;
      --danger: #dc2626;
      --border: #dbe3ee;
      --shadow: 0 16px 40px rgba(15, 23, 42, 0.08);
      --radius: 18px;
    }

    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Segoe UI", "Noto Sans TC", sans-serif;
      background:
        radial-gradient(circle at top left, rgba(37, 99, 235, 0.14), transparent 30%),
        radial-gradient(circle at top right, rgba(20, 184, 166, 0.12), transparent 28%),
        var(--bg);
      color: var(--text);
    }

    .wrap {
      max-width: 1100px;
      margin: 0 auto;
      padding: 28px 18px 40px;
    }

    .hero {
      display: flex;
      justify-content: space-between;
      align-items: end;
      gap: 16px;
      margin-bottom: 18px;
    }

    .title h1 {
      margin: 0;
      font-size: 32px;
      letter-spacing: 0.5px;
    }

    .title p {
      margin: 8px 0 0;
      color: var(--muted);
    }

    .badge {
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(37, 99, 235, 0.1);
      color: var(--primary);
      font-weight: 700;
      border: 1px solid rgba(37, 99, 235, 0.12);
      white-space: nowrap;
    }

    .grid {
      display: grid;
      grid-template-columns: 360px 1fr;
      gap: 18px;
    }

    .card {
      background: var(--card);
      border: 1px solid rgba(148, 163, 184, 0.16);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
    }

    .card-header {
      padding: 18px 18px 0;
    }

    .card-title {
      margin: 0;
      font-size: 18px;
    }

    .card-body {
      padding: 18px;
    }

    .field {
      margin-bottom: 14px;
    }

    label {
      display: block;
      margin-bottom: 6px;
      font-weight: 700;
      color: #334155;
    }

    input, select {
      width: 100%;
      padding: 12px 14px;
      border: 1px solid var(--border);
      border-radius: 14px;
      background: #fff;
      color: var(--text);
      outline: none;
      font-size: 15px;
      transition: border-color 0.15s ease, box-shadow 0.15s ease;
    }

    input:focus, select:focus {
      border-color: rgba(37, 99, 235, 0.55);
      box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.1);
    }

    .row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 12px;
    }

    .actions {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      margin-top: 18px;
    }

    button {
      border: none;
      border-radius: 14px;
      padding: 12px 16px;
      font-size: 15px;
      font-weight: 700;
      cursor: pointer;
      transition: transform 0.12s ease, opacity 0.12s ease, box-shadow 0.12s ease;
    }

    button:hover { transform: translateY(-1px); }
    button:active { transform: translateY(0); opacity: 0.95; }

    .btn-primary {
      color: #fff;
      background: linear-gradient(135deg, var(--primary), var(--primary-2));
      box-shadow: 0 12px 24px rgba(37, 99, 235, 0.2);
    }

    .btn-secondary {
      color: var(--text);
      background: #eef2ff;
      border: 1px solid #dbe4ff;
    }

    .btn-danger {
      color: #fff;
      background: linear-gradient(135deg, #ef4444, #f97316);
    }

    .toolbar {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 14px;
    }

    .toolbar .left,
    .toolbar .right {
      display: flex;
      gap: 10px;
      flex-wrap: wrap;
      align-items: center;
    }

    .stats {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
      margin-bottom: 14px;
    }

    .stat {
      background: linear-gradient(180deg, rgba(37, 99, 235, 0.06), rgba(20, 184, 166, 0.06));
      border: 1px solid rgba(148, 163, 184, 0.16);
      border-radius: 16px;
      padding: 14px;
    }

    .stat .label {
      color: var(--muted);
      font-size: 13px;
      font-weight: 600;
    }

    .stat .value {
      margin-top: 6px;
      font-size: 22px;
      font-weight: 800;
    }

    table {
      width: 100%;
      border-collapse: collapse;
      overflow: hidden;
      border-radius: 16px;
    }

    thead th {
      text-align: left;
      font-size: 13px;
      color: #475569;
      background: #f8fafc;
      border-bottom: 1px solid var(--border);
      padding: 14px 12px;
      position: sticky;
      top: 0;
      z-index: 1;
    }

    tbody td {
      border-bottom: 1px solid #eef2f7;
      padding: 14px 12px;
      vertical-align: top;
    }

    tbody tr:hover {
      background: #fafcff;
    }

    .pill {
      display: inline-flex;
      align-items: center;
      padding: 6px 10px;
      border-radius: 999px;
      background: rgba(37, 99, 235, 0.1);
      color: var(--primary);
      font-weight: 700;
      font-size: 13px;
    }

    .muted { color: var(--muted); }

    .row-actions {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }

    .empty {
      padding: 42px 18px;
      text-align: center;
      color: var(--muted);
    }

    .message {
      margin-top: 12px;
      padding: 12px 14px;
      border-radius: 14px;
      display: none;
      font-weight: 600;
      line-height: 1.5;
    }

    .message.success {
      display: block;
      background: rgba(20, 184, 166, 0.12);
      color: #0f766e;
      border: 1px solid rgba(20, 184, 166, 0.18);
    }

    .message.error {
      display: block;
      background: rgba(220, 38, 38, 0.08);
      color: #b91c1c;
      border: 1px solid rgba(220, 38, 38, 0.16);
    }

    .table-wrap {
      max-height: 68vh;
      overflow: auto;
      border-radius: 16px;
      border: 1px solid rgba(148, 163, 184, 0.14);
    }

    .modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(15, 23, 42, 0.5);
      display: none;
      justify-content: center;
      align-items: center;
      z-index: 1000;
      padding: 18px;
    }

    .modal-overlay.open {
      display: flex;
    }

    .modal-dialog {
      background: var(--card);
      border-radius: var(--radius);
      box-shadow: 0 24px 48px rgba(15, 23, 42, 0.2);
      max-width: 420px;
      width: 100%;
      max-height: 80vh;
      overflow-y: auto;
    }

    .modal-header {
      padding: 18px;
      border-bottom: 1px solid rgba(148, 163, 184, 0.16);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .modal-header h3 {
      margin: 0;
      font-size: 18px;
    }

    .modal-close {
      background: none;
      border: none;
      cursor: pointer;
      color: var(--muted);
      font-size: 20px;
      padding: 0;
      width: 28px;
      height: 28px;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: color 0.15s ease;
    }

    .modal-close:hover {
      color: var(--text);
    }

    .modal-body {
      padding: 18px;
    }

    .modal-footer {
      padding: 18px;
      border-top: 1px solid rgba(148, 163, 184, 0.16);
      display: flex;
      gap: 10px;
      justify-content: flex-end;
    }

    @media (max-width: 960px) {
      .grid { grid-template-columns: 1fr; }
      .stats { grid-template-columns: 1fr; }
      .hero { align-items: start; flex-direction: column; }
    }
  </style>
</head>
<body>
  <!-- 編輯彈窗：用於修改既有中獎號碼記錄 -->
  <div id="editModal" class="modal-overlay">
    <div class="modal-dialog">
      <div class="modal-header">
        <h3>編輯中獎號碼</h3>
        <button type="button" class="modal-close" id="editModalClose">&times;</button>
      </div>
      <form id="editForm">
        <div class="modal-body">
          <div class="field">
            <label for="editPeriod">期別</label>
            <input id="editPeriod" name="period" type="text" required>
          </div>
          <div class="field">
            <label for="editPrizeType">獎別</label>
            <input id="editPrizeType" name="prizeType" type="text" required>
          </div>
          <div class="field">
            <label for="editNumber">號碼</label>
            <input id="editNumber" name="number" type="text" required>
          </div>
          <div class="field">
            <label for="editPrizeAmount">獎金</label>
            <input id="editPrizeAmount" name="prizeAmount" type="number" min="0" step="1" required>
          </div>
          <div id="editMessage" class="message"></div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn-secondary" id="editModalCancel">取消</button>
          <button type="submit" class="btn-primary">儲存</button>
        </div>
      </form>
    </div>
  </div>

  <div class="wrap">
    <div class="hero">
      <div class="title">
        <h1>中獎號碼管理</h1>
        <p>在瀏覽器中新增、刪除與查詢中獎號碼，供 App 對獎使用。</p>
      </div>
      <div class="badge">API: winning.php</div>
    </div>

    <div class="grid">
      <section class="card">
        <div class="card-header">
          <h2 class="card-title">新增中獎號碼</h2>
        </div>
        <div class="card-body">
          <form id="createForm">
            <div class="field">
              <label for="period">期別</label>
              <input id="period" name="period" type="text" placeholder="例如 11502" required>
            </div>
            <div class="field">
              <label for="prizeType">獎別</label>
              <input id="prizeType" name="prizeType" type="text" placeholder="例如 特別獎 / 六獎" required>
            </div>
            <div class="field">
              <label for="number">號碼</label>
              <input id="number" name="number" type="text" placeholder="例如 WR-73786487" required>
            </div>
            <div class="field">
              <label for="prizeAmount">獎金</label>
              <input id="prizeAmount" name="prizeAmount" type="number" min="0" step="1" placeholder="例如 2000000" required>
            </div>
            <div class="actions">
              <button type="submit" class="btn-primary">新增</button>
              <button type="button" class="btn-secondary" id="resetBtn">清空</button>
            </div>
          </form>
          <div id="message" class="message"></div>
        </div>
      </section>

      <section class="card">
        <div class="card-header">
          <div class="toolbar">
            <div class="left">
              <h2 class="card-title" style="margin-right: 6px;">資料列表</h2>
              <span class="pill" id="countPill">0 筆</span>
            </div>
            <div class="right">
              <input id="filterPeriod" type="text" placeholder="篩選期別，例如 11502" style="width: 220px;">
              <button class="btn-secondary" id="filterBtn">查詢</button>
              <button class="btn-secondary" id="reloadBtn">重新整理</button>
            </div>
          </div>
          <div class="stats">
            <div class="stat">
              <div class="label">總筆數</div>
              <div class="value" id="statCount">0</div>
            </div>
            <div class="stat">
              <div class="label">最新期別</div>
              <div class="value" id="statLatest">-</div>
            </div>
            <div class="stat">
              <div class="label">目前篩選</div>
              <div class="value" id="statFilter">全部</div>
            </div>
          </div>
        </div>
        <div class="card-body" style="padding-top: 0;">
          <div class="table-wrap">
            <table>
              <thead>
                <tr>
                  <th style="width: 110px;">期別</th>
                  <th style="width: 120px;">獎別</th>
                  <th>號碼</th>
                  <th style="width: 140px;">獎金</th>
                  <th style="width: 150px;">建立時間</th>
                  <th style="width: 140px;">操作</th>
                </tr>
              </thead>
              <tbody id="tbody">
                <tr><td colspan="6" class="empty">載入中...</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  </div>

  <script>
    /**
     * 中獎號碼管理頁面 - JavaScript 邏輯
     * 
     * 功能：
     * 1. 與 winning.php API 互動 (GET/POST/PUT/DELETE)
     * 2. 顯示中獎號碼列表，支援期別篩選
     * 3. 新增、編輯、刪除中獎號碼功能
     * 4. 即時更新統計資訊（總筆數、最新期別）
     * 5. 模態框用於編輯已存在的號碼
     */

    // ============ DOM 元素參照 ============
    const apiBase = 'winning.php'; // API 基礎路徑
    const form = document.getElementById('createForm'); // 新增表單
    const tbody = document.getElementById('tbody'); // 表格主體
    const messageBox = document.getElementById('message'); // 新增成功/失敗訊息
    const filterPeriod = document.getElementById('filterPeriod'); // 篩選期別輸入框
    const statCount = document.getElementById('statCount'); // 統計：總筆數
    const statLatest = document.getElementById('statLatest'); // 統計：最新期別
    const statFilter = document.getElementById('statFilter'); // 統計：目前篩選
    const countPill = document.getElementById('countPill'); // 卡片標籤：顯示筆數
    const resetBtn = document.getElementById('resetBtn'); // 新增表單清空按鈕
    const reloadBtn = document.getElementById('reloadBtn'); // 重新整理按鈕
    const filterBtn = document.getElementById('filterBtn'); // 篩選查詢按鈕
    const editModal = document.getElementById('editModal'); // 編輯模態框容器
    const editForm = document.getElementById('editForm'); // 編輯表單
    const editModalClose = document.getElementById('editModalClose'); // 編輯模態框關閉按鈕
    const editModalCancel = document.getElementById('editModalCancel'); // 編輯模態框取消按鈕
    const editMessage = document.getElementById('editMessage'); // 編輯成功/失敗訊息

    // ============ 全域狀態 ============
    let editingRowId = null; // 目前正在編輯的行 ID

    /**
     * 顯示成功或失敗訊息
     * @param {string} text - 要顯示的訊息文字
     * @param {string} type - 訊息類型：'success' 或 'error'，預設 'success'
     */
    function showMessage(text, type = 'success') {
      messageBox.className = `message ${type}`;
      messageBox.textContent = text;
      messageBox.style.display = 'block';
      // 3.5 秒後自動隱藏訊息
      window.clearTimeout(showMessage._timer);
      showMessage._timer = window.setTimeout(() => {
        messageBox.style.display = 'none';
      }, 3500);
    }

    /**
     * 轉義 HTML 特殊字元，防止 XSS 攻擊
     * @param {*} value - 要轉義的值（自動轉為字串）
     * @returns {string} - 轉義後的字串
     */
    function escapeHtml(value) {
      return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
    }

    /**
     * 格式化時間戳記為可讀格式 (YYYY-MM-DD HH:mm:ss)
     * @param {string} value - ISO 8601 時間戳記（如 2025-04-30T10:30:45）
     * @returns {string} - 格式化後的時間字串，若無效則返回 '-'
     */
    function formatDateTime(value) {
      if (!value) return '-';
      return String(value).replace('T', ' ').slice(0, 19);
    }

    /**
     * 從後端加載中獎號碼資料
     * 
     * 流程：
     * 1. 讀取篩選框中的期別值
     * 2. 向 winning.php 發送 GET 請求（若有期別則加上查詢參數）
     * 3. 將返回的 JSON 資料傳遞給 renderRows() 進行表格渲染
     */
    async function loadData() {
      const period = filterPeriod.value.trim();
      const url = period ? `${apiBase}?period=${encodeURIComponent(period)}` : apiBase;
      statFilter.textContent = period || '全部';
      tbody.innerHTML = '<tr><td colspan="6" class="empty">載入中...</td></tr>';

      try {
        const response = await fetch(url, { method: 'GET' });
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        renderRows(Array.isArray(data) ? data : []);
      } catch (error) {
        tbody.innerHTML = `<tr><td colspan="6" class="empty">讀取失敗：${escapeHtml(error.message)}</td></tr>`;
      }
    }

    /**
     * 將中獎號碼資料渲染為表格行
     * 
     * 功能：
     * 1. 更新統計資訊（總筆數、最新期別）
     * 2. 生成表格行（包含編輯和刪除按鈕）
     * 3. 為編輯按鈕綁定點擊事件（開啟模態框）
     * 4. 為刪除按鈕綁定點擊事件（確認後刪除）
     * 
     * @param {Array} rows - 中獎號碼物件陣列，每個物件包含 {id, period, prize_type, number, prize_amount, created_at}
     */
    function renderRows(rows) {
      statCount.textContent = rows.length;
      countPill.textContent = `${rows.length} 筆`;
      statLatest.textContent = rows.length > 0 ? rows[0].period : '-';

      if (!rows.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty">目前沒有資料</td></tr>';
        return;
      }

      // 生成表格行 HTML
      tbody.innerHTML = rows.map((row) => `
        <tr>
          <td><span class="pill">${escapeHtml(row.period)}</span></td>
          <td>${escapeHtml(row.prize_type)}</td>
          <td><strong>${escapeHtml(row.number)}</strong></td>
          <td>${escapeHtml(row.prize_amount)}</td>
          <td class="muted">${escapeHtml(formatDateTime(row.created_at))}</td>
          <td>
            <div class="row-actions">
              <button class="btn-secondary" type="button" data-edit="${escapeHtml(row.id)}" data-row='${JSON.stringify(row)}'>編輯</button>
              <button class="btn-danger" type="button" data-delete="${escapeHtml(row.id)}">刪除</button>
            </div>
          </td>
        </tr>
      `).join('');

      // 為編輯按鈕綁定事件監聽
      document.querySelectorAll('[data-edit]').forEach((button) => {
        button.addEventListener('click', () => {
          const rowData = JSON.parse(button.getAttribute('data-row'));
          openEditModal(rowData);
        });
      });

      // 為刪除按鈕綁定事件監聽
      document.querySelectorAll('[data-delete]').forEach((button) => {
        button.addEventListener('click', async () => {
          const id = button.getAttribute('data-delete');
          const target = rows.find((row) => String(row.id) === String(id));
          if (!target) return;
          // 顯示確認對話框
          if (!confirm(`確定刪除 ${target.number}（${target.prize_type}）嗎？`)) return;

          try {
            const response = await fetch(`${apiBase}?id=${encodeURIComponent(id)}`, {
              method: 'DELETE',
            });
            if (!response.ok) {
              throw new Error(`HTTP ${response.status}`);
            }
            showMessage('已刪除中獎號碼');
            await loadData();
          } catch (error) {
            showMessage(`刪除失敗：${error.message}`, 'error');
          }
        });
      });
    }

    /**
     * 新增中獎號碼表單提交事件
     * 
     * 流程：
     * 1. 讀取表單欄位值
     * 2. 驗證必填欄位
     * 3. 向 winning.php 發送 POST 請求
     * 4. 成功後清空表單並重新加載列表
     */
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const payload = {
        period: document.getElementById('period').value.trim(),
        prize_type: document.getElementById('prizeType').value.trim(),
        number: document.getElementById('number').value.trim(),
        prize_amount: Number(document.getElementById('prizeAmount').value.trim()),
      };

      if (!payload.period || !payload.prize_type || !payload.number || Number.isNaN(payload.prize_amount)) {
        showMessage('請完整填寫所有欄位', 'error');
        return;
      }

      try {
        const response = await fetch(apiBase, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await response.json();
        if (!response.ok) {
          throw new Error(data.error || `HTTP ${response.status}`);
        }

        showMessage('已新增中獎號碼');
        form.reset();
        await loadData();
      } catch (error) {
        showMessage(`新增失敗：${error.message}`, 'error');
      }
    });

    /**
     * 控制按鈕事件
     */
    resetBtn.addEventListener('click', () => {
      form.reset();
      document.getElementById('period').focus();
    });

    reloadBtn.addEventListener('click', loadData);
    filterBtn.addEventListener('click', loadData);
    filterPeriod.addEventListener('keydown', (event) => {
      // 篩選框中按 Enter 鍵也能觸發查詢
      if (event.key === 'Enter') {
        event.preventDefault();
        loadData();
      }
    });

    /**
     * 開啟編輯模態框並填入現有資料
     * @param {Object} rowData - 中獎號碼物件 {id, period, prize_type, number, prize_amount, ...}
     */
    function openEditModal(rowData) {
      editingRowId = rowData.id;
      document.getElementById('editPeriod').value = rowData.period;
      document.getElementById('editPrizeType').value = rowData.prize_type;
      document.getElementById('editNumber').value = rowData.number;
      document.getElementById('editPrizeAmount').value = rowData.prize_amount;
      editMessage.className = 'message';
      editModal.classList.add('open');
      document.getElementById('editPeriod').focus();
    }

    /**
     * 關閉編輯模態框
     */
    function closeEditModal() {
      editModal.classList.remove('open');
      editingRowId = null;
      editForm.reset();
    }

    /**
     * 編輯模態框事件監聽
     */
    editModalClose.addEventListener('click', closeEditModal);
    editModalCancel.addEventListener('click', closeEditModal);
    // 點擊背景也能關閉模態框
    editModal.addEventListener('click', (event) => {
      if (event.target === editModal) closeEditModal();
    });

    /**
     * 編輯表單提交事件
     * 
     * 流程：
     * 1. 讀取編輯模態框中的欄位值
     * 2. 驗證必填欄位
     * 3. 向 winning.php 發送 PUT 請求（帶上行 ID）
     * 4. 成功後關閉模態框並重新加載列表
     */
    editForm.addEventListener('submit', async (event) => {
      event.preventDefault();
      if (!editingRowId) return;

      const payload = {
        period: document.getElementById('editPeriod').value.trim(),
        prize_type: document.getElementById('editPrizeType').value.trim(),
        number: document.getElementById('editNumber').value.trim(),
        prize_amount: Number(document.getElementById('editPrizeAmount').value.trim()),
      };

      if (!payload.period || !payload.prize_type || !payload.number || Number.isNaN(payload.prize_amount)) {
        editMessage.className = 'message error';
        editMessage.textContent = '請完整填寫所有欄位';
        return;
      }

      try {
        editMessage.className = 'message';
        const response = await fetch(`${apiBase}?id=${encodeURIComponent(editingRowId)}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        const data = await response.json();
        if (!response.ok) {
          throw new Error(data.error || `HTTP ${response.status}`);
        }

        closeEditModal();
        showMessage('已更新中獎號碼');
        await loadData();
      } catch (error) {
        editMessage.className = 'message error';
        editMessage.textContent = `更新失敗：${error.message}`;
      }
    });

    // 頁面載入時自動加載中獎號碼列表
    loadData();
  </script>
</body>
</html>
