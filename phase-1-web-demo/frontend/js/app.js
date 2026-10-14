/**
 * Ví Xinh - Client Script
 * Phụ trách: Thành viên 4 (Lê Ngọc Duy) & Thành viên 5 (Nguyễn Việt Anh)
 */

// Định dạng tiền tệ VNĐ
function formatCurrency(amount) {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
}

// 1. Tải số liệu thống kê Dashboard
async function loadDashboardStats() {
    try {
        const res = await fetch('/api/stats');
        if (!res.ok) return;
        const data = await res.json();

        const totalSpentEl = document.getElementById('stat-total-spent');
        const txCountEl = document.getElementById('stat-tx-count');

        if (totalSpentEl) totalSpentEl.textContent = formatCurrency(data.total_spent || 0);
        if (txCountEl) txCountEl.textContent = data.transaction_count || 0;
    } catch (err) {
        console.error('Lỗi khi tải thống kê:', err);
    }
}

// 2. Tải danh sách giao dịch gần đây
async function loadRecentTransactions() {
    const listEl = document.getElementById('transaction-list');
    if (!listEl) return;

    try {
        const res = await fetch('/api/transactions');
        if (!res.ok) throw new Error('Không thể tải giao dịch');
        const transactions = await res.json();

        if (transactions.length === 0) {
            listEl.innerHTML = `<tr><td colspan="5" style="text-align:center; color:var(--text-muted); padding:2rem;">Chưa có giao dịch nào. Hãy quét hóa đơn để bắt đầu!</td></tr>`;
            return;
        }

        listEl.innerHTML = transactions.map(tx => `
            <tr>
                <td style="font-weight: 500;">${tx.transaction_date}</td>
                <td><strong>${tx.merchant_name}</strong></td>
                <td><span style="color:var(--text-muted); font-size:0.85rem;">${tx.category || 'Ăn uống'}</span></td>
                <td>
                    <span class="badge ${tx.group_id ? 'badge-group' : 'badge-personal'}">
                        ${tx.group_id ? (tx.group_name || 'Ví Nhóm') : 'Cá Nhân'}
                    </span>
                </td>
                <td style="font-weight: 700; color: #dc2626;">-${formatCurrency(tx.amount)}</td>
            </tr>
        `).join('');
    } catch (err) {
        console.error('Lỗi load giao dịch:', err);
        listEl.innerHTML = `<tr><td colspan="5" style="text-align:center; color:#ef4444;">Không thể tải dữ liệu. Hãy kiểm tra server!</td></tr>`;
    }
}

// 3. Xử lý Upload file hóa đơn
async function handleFileSelect(event) {
    const file = event.target.files[0];
    if (!file) return;

    const statusEl = document.getElementById('upload-status');
    if (statusEl) statusEl.style.display = 'block';

    const formData = new FormData();
    formData.append('receipt', file);

    try {
        const response = await fetch('/api/receipts/upload', {
            method: 'POST',
            body: formData
        });

        if (!response.ok) {
            const errData = await response.json();
            throw new Error(errData.error || 'Xử lý thất bại');
        }

        const data = await response.json();
        // Lưu tạm kết quả vào sessionStorage và chuyển trang Review
        sessionStorage.setItem('ocr_result', JSON.stringify(data));
        window.location.href = '/review';
    } catch (error) {
        alert('Có lỗi khi upload và nhận diện ảnh: ' + error.message);
        if (statusEl) statusEl.style.display = 'none';
    }
}

// 4. Xử lý Lưu Giao Dịch Đã Xác Thực (Từ màn hình Review)
async function handleConfirmTransaction(event) {
    event.preventDefault();

    const ocrData = JSON.parse(sessionStorage.getItem('ocr_result') || '{}');

    const payload = {
        merchant_name: document.getElementById('verify-merchant').value,
        amount: parseFloat(document.getElementById('verify-amount').value),
        transaction_date: document.getElementById('verify-date').value,
        category: document.getElementById('verify-category').value,
        group_id: document.getElementById('verify-group-id').value ? parseInt(document.getElementById('verify-group-id').value) : null,
        notes: document.getElementById('verify-notes').value,
        receipt_image_path: ocrData.image_url || null,
        raw_ocr_text: ocrData.raw_text || null,
        user_id: 1 // Nguyễn Thúy Hiền làm mẫu mặc định
    };

    try {
        const res = await fetch('/api/transactions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            sessionStorage.removeItem('ocr_result');
            alert('🎉 Đã xác thực và lưu thành công giao dịch vào CSDL!');
            window.location.href = '/';
        } else {
            alert('Có lỗi khi lưu vào cơ sở dữ liệu!');
        }
    } catch (err) {
        alert('Lỗi kết nối tới server: ' + err.message);
    }
}

// 5. Thêm thủ công giao dịch
async function handleManualSubmit(event) {
    event.preventDefault();

    const payload = {
        merchant_name: document.getElementById('manual-merchant').value,
        amount: parseFloat(document.getElementById('manual-amount').value),
        transaction_date: document.getElementById('manual-date').value,
        group_id: document.getElementById('manual-wallet-type').value ? parseInt(document.getElementById('manual-wallet-type').value) : null,
        category: 'Ăn uống',
        user_id: 1
    };

    try {
        const res = await fetch('/api/transactions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        if (res.ok) {
            alert('✅ Đã thêm giao dịch thành công!');
            document.getElementById('manual-form').reset();
            // Set default date to today
            document.getElementById('manual-date').value = new Date().toISOString().split('T')[0];
            loadDashboardStats();
            loadRecentTransactions();
        }
    } catch (err) {
        alert('Lỗi: ' + err.message);
    }
}

// 6. Hiển thị thành viên nhóm & Tính năng chia tiền
const TEAM_MEMBERS = [
    { id: 1, name: "Nguyễn Thúy Hiền (Nhóm trưởng)" },
    { id: 2, name: "Lê Thị Dịu" },
    { id: 3, name: "Lê Tiến Quân" },
    { id: 4, name: "Lê Ngọc Duy" },
    { id: 5, name: "Nguyễn Việt Anh" }
];

function loadGroupMembersUI() {
    const listEl = document.getElementById('member-checkbox-list');
    if (!listEl) return;

    listEl.innerHTML = TEAM_MEMBERS.map(m => `
        <label style="display: flex; align-items: center; gap: 0.6rem; padding: 0.6rem 0.8rem; background: #f8fafc; border-radius: var(--radius-sm); border: 1px solid var(--border-color); cursor: pointer;">
            <input type="checkbox" name="split-members" value="${m.id}" checked>
            <span style="font-weight: 600; font-size: 0.95rem;">${m.name}</span>
        </label>
    `).join('');
}

function calculateSplit(event) {
    event.preventDefault();
    const amount = parseFloat(document.getElementById('split-amount-input').value);
    const checkboxes = document.querySelectorAll('input[name="split-members"]:checked');
    const selectedIds = Array.from(checkboxes).map(cb => parseInt(cb.value));

    if (selectedIds.length === 0) {
        alert('Vui lòng chọn ít nhất 1 thành viên để chia tiền!');
        return;
    }

    const perPerson = Math.round(amount / selectedIds.length);
    const resultBox = document.getElementById('split-result');
    const detailsBox = document.getElementById('split-result-details');

    const selectedNames = TEAM_MEMBERS.filter(m => selectedIds.includes(m.id)).map(m => m.name);

    detailsBox.innerHTML = `
        <p style="font-size: 1.1rem; font-weight: 700; color: #1e1b4b; margin-bottom: 0.5rem;">
            Mỗi người cần đóng: <span style="color: #ec4899;">${formatCurrency(perPerson)}</span>
        </p>
        <p style="font-size: 0.85rem; color: var(--text-muted);">
            Áp dụng cho ${selectedIds.length} thành viên: ${selectedNames.join(', ')}
        </p>
    `;
    resultBox.style.display = 'block';
}

// Khởi chạy khi load trang
document.addEventListener('DOMContentLoaded', () => {
    // Nếu có form manual thì set ngày hôm nay
    const manualDateInput = document.getElementById('manual-date');
    if (manualDateInput) {
        manualDateInput.value = new Date().toISOString().split('T')[0];
    }

    loadDashboardStats();
    loadRecentTransactions();
});
