const API = '/api/admin';
let metadata = {};
let currentEntity = '';
let currentReport = null;
let currentSort = '';
let currentDir = 'DESC';
let currentPage = 0;
let filters = [];

// ---- Init ----
document.addEventListener('DOMContentLoaded', async () => {
    await loadMetadata();
    await loadRankings();
    await loadDashboard();
});

// ---- Rankings ----
let rankingsList = [];

async function loadRankings() {
    try {
        const res = await fetch(API + '/rankings');
        rankingsList = await res.json();
        const select = document.getElementById('rankingSelect');
        select.innerHTML = rankingsList.map(r =>
            `<option value="${r.key}">${r.title}</option>`
        ).join('');
    } catch (e) {
        console.error('Failed to load rankings:', e);
    }
}

async function executeRanking() {
    const key = document.getElementById('rankingSelect').value;
    const limit = document.getElementById('rankingLimit').value;
    if (!key) return;

    try {
        const res = await fetch(`${API}/ranking/${key}?limit=${limit}`);
        const data = await res.json();
        renderRankingChart(data);
        renderRankingTable(data);
    } catch (e) {
        console.error('Ranking error:', e);
    }
}

function renderRankingChart(data) {
    const row = document.getElementById('rankingChartRow');
    row.style.display = 'grid';
    document.getElementById('rankingChartTitle').textContent = data.title;

    const ctx = document.getElementById('rankingChart');
    if (window.rankingChartInstance) window.rankingChartInstance.destroy();

    // Find label column (first text-like) and value column (last numeric-like)
    const labelCol = data.columns.find(c => ['username', 'full_name', 'product_name', 'category_name'].includes(c)) || data.columns[1] || data.columns[0];
    const valueCols = data.columns.filter(c => ['wins', 'total_bids', 'total_amount', 'current_price', 'total_revenue', 'auctions_sold', 'deposits', 'total_deposited', 'messages_sent', 'balance', 'reserved_balance', 'auction_count', 'total_value'].includes(c));
    const valueCol = valueCols[0] || data.columns[data.columns.length - 1];

    const labels = data.data.map(d => d[labelCol] || 'N/A');
    const values = data.data.map(d => parseFloat(d[valueCol]) || 0);

    const chartColors = [
        '#6c5ce7', '#00cec9', '#00b894', '#fdcb6e', '#e17055',
        '#a29bfe', '#74b9ff', '#55efc4', '#ffeaa7', '#fab1a0',
        '#81ecec', '#dfe6e9', '#b2bec3', '#636e72', '#2d3436'
    ];

    const chartType = data.chartType || 'bar';

    window.rankingChartInstance = new Chart(ctx, {
        type: chartType,
        data: {
            labels: labels,
            datasets: [{
                label: data.labels[data.columns.indexOf(valueCol)] || valueCol,
                data: values,
                backgroundColor: chartColors.slice(0, values.length),
                borderWidth: 0,
                borderRadius: chartType === 'bar' ? 6 : 0,
            }]
        },
        options: {
            responsive: true,
            indexAxis: chartType === 'bar' && labels.length > 5 ? 'y' : 'x',
            plugins: {
                legend: { display: chartType === 'pie' || chartType === 'doughnut', position: 'bottom', labels: { color: '#a4a6b3' } }
            },
            scales: chartType === 'bar' ? {
                x: { ticks: { color: '#6b6e7b', font: { size: 11 } }, grid: { display: false } },
                y: { ticks: { color: '#6b6e7b' }, grid: { color: 'rgba(45,49,64,0.5)' } }
            } : {}
        }
    });
}

function renderRankingTable(data) {
    const moneyCols = ['total_amount', 'current_price', 'total_revenue', 'total_deposited', 'balance', 'reserved_balance', 'total_value'];

    let html = `
        <div class="table-container">
            <div class="table-header">
                <span class="table-info">${data.title} — ${data.data.length} results</span>
            </div>
            <div style="overflow-x:auto;">
            <table>
                <thead><tr>
                    <th>#</th>
                    ${data.labels.map(l => `<th>${l}</th>`).join('')}
                </tr></thead>
                <tbody>
                    ${data.data.map((row, i) => `<tr>
                        <td style="color:${i < 3 ? 'var(--warning)' : 'var(--text-muted)'};font-weight:${i < 3 ? '700' : '400'}">
                            ${i < 3 ? ['🥇','🥈','🥉'][i] : i + 1}
                        </td>
                        ${data.columns.map(c => {
                            const val = row[c];
                            if (moneyCols.includes(c)) return `<td>${formatVND(parseFloat(val))}</td>`;
                            return `<td>${formatCell(c, val)}</td>`;
                        }).join('')}
                    </tr>`).join('')}
                </tbody>
            </table>
            </div>
        </div>
    `;
    document.getElementById('rankingTable').innerHTML = html;
}

// ---- Navigation ----
function showSection(section) {
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    document.getElementById('section-' + section).classList.add('active');
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    event.target.closest('.nav-item').classList.add('active');
}

// ---- Metadata ----
async function loadMetadata() {
    try {
        const res = await fetch(API + '/metadata');
        metadata = await res.json();
        const select = document.getElementById('entitySelect');
        Object.keys(metadata).forEach(entity => {
            const opt = document.createElement('option');
            opt.value = entity;
            opt.textContent = entity.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
            select.appendChild(opt);
        });
    } catch (e) {
        console.error('Failed to load metadata:', e);
    }
}

// ---- Dashboard ----
async function loadDashboard() {
    try {
        const res = await fetch(API + '/dashboard');
        const stats = await res.json();
        renderDashboard(stats);
    } catch (e) {
        console.error('Failed to load dashboard:', e);
    }
}

function renderDashboard(stats) {
    const grid = document.getElementById('stats-grid');
    const cards = [
        { label: 'Total Users', value: stats.totalUsers, color: 'primary' },
        { label: 'Active Users', value: stats.activeUsers, color: 'success' },
        { label: 'Total Auctions', value: stats.totalAuctions, color: 'accent' },
        { label: 'Active Auctions', value: stats.activeAuctions, color: 'warning' },
        { label: 'Total Products', value: stats.totalProducts, color: 'primary' },
        { label: 'Total Bids', value: stats.totalBids, color: 'accent' },
        { label: 'Total Deposits', value: formatVND(stats.totalDeposits), color: 'success' },
        { label: 'Total Revenue', value: formatVND(stats.totalRevenue), color: 'warning' },
        { label: 'Chat Messages', value: stats.totalMessages, color: 'primary' },
    ];

    grid.innerHTML = cards.map(c => `
        <div class="stat-card">
            <div class="stat-label">${c.label}</div>
            <div class="stat-value ${c.color}">${c.value}</div>
        </div>
    `).join('');

    // Charts
    renderAuctionChart(stats.auctionsByStatus || []);
    renderTxChart(stats.recentTransactions || []);
}

function renderAuctionChart(data) {
    const ctx = document.getElementById('auctionChart');
    if (window.auctionChartInstance) window.auctionChartInstance.destroy();

    const colors = {
        'ACTIVE': '#00cec9', 'PENDING': '#fdcb6e', 'ENDED': '#e17055',
        'CANCELLED': '#636e72', 'SETTLED': '#00b894'
    };

    window.auctionChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: data.map(d => d.status),
            datasets: [{
                data: data.map(d => d.count),
                backgroundColor: data.map(d => colors[d.status] || '#6c5ce7'),
                borderWidth: 0,
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { position: 'bottom', labels: { color: '#a4a6b3', padding: 16, font: { size: 12 } } }
            }
        }
    });
}

function renderTxChart(data) {
    const ctx = document.getElementById('txChart');
    if (window.txChartInstance) window.txChartInstance.destroy();

    const colors = {
        'DEPOSIT': '#00b894', 'WITHDRAW': '#e17055', 'BID_RESERVE': '#fdcb6e',
        'BID_RELEASE': '#00cec9', 'PAYMENT': '#6c5ce7', 'REFUND': '#a29bfe', 'PAYOUT': '#74b9ff'
    };

    window.txChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: data.map(d => d.type),
            datasets: [{
                label: 'Count',
                data: data.map(d => d.count),
                backgroundColor: data.map(d => colors[d.type] || '#6c5ce7'),
                borderRadius: 6,
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: { display: false }
            },
            scales: {
                x: { ticks: { color: '#6b6e7b', font: { size: 11 } }, grid: { display: false } },
                y: { ticks: { color: '#6b6e7b' }, grid: { color: 'rgba(45,49,64,0.5)' } }
            }
        }
    });
}

// ---- Report Builder ----
function onEntityChange() {
    currentEntity = document.getElementById('entitySelect').value;
    filters = [];
    document.getElementById('filtersContainer').innerHTML = '';
    renderFieldsPicker();
}

function renderFieldsPicker() {
    const picker = document.getElementById('fieldsPicker');
    if (!currentEntity || !metadata[currentEntity]) {
        picker.style.display = 'none';
        return;
    }

    const fields = metadata[currentEntity].fields;
    picker.style.display = 'flex';
    picker.innerHTML = fields.map(f => `
        <div class="field-chip selected" data-col="${f.column}" onclick="toggleField(this)">
            ✓ ${f.label}
        </div>
    `).join('');
}

function toggleField(el) {
    el.classList.toggle('selected');
    el.innerHTML = el.classList.contains('selected')
        ? '✓ ' + el.textContent.replace('✓ ', '')
        : el.dataset.col.replace(/_/g, ' ');
    // Restore label
    const field = metadata[currentEntity].fields.find(f => f.column === el.dataset.col);
    if (field) {
        el.innerHTML = (el.classList.contains('selected') ? '✓ ' : '') + field.label;
    }
}

// ---- Filters ----
function addFilter() {
    if (!currentEntity) return alert('Select an entity first');
    const fields = metadata[currentEntity].fields;
    const id = Date.now();
    filters.push({ id, column: '', value: '' });

    const container = document.getElementById('filtersContainer');
    const div = document.createElement('div');
    div.className = 'filter-item';
    div.id = 'filter-' + id;

    const colSelect = document.createElement('select');
    colSelect.innerHTML = '<option value="">Field...</option>' + fields.map(f =>
        `<option value="${f.column}" data-type="${f.type}">${f.label}</option>`
    ).join('');
    colSelect.onchange = () => updateFilterValue(id, colSelect.value);

    const valueContainer = document.createElement('span');
    valueContainer.id = 'filterVal-' + id;

    const removeBtn = document.createElement('button');
    removeBtn.className = 'filter-remove';
    removeBtn.textContent = '✕';
    removeBtn.onclick = () => { div.remove(); filters = filters.filter(f => f.id !== id); };

    div.append(colSelect, valueContainer, removeBtn);
    container.appendChild(div);
}

function updateFilterValue(filterId, column) {
    const container = document.getElementById('filterVal-' + filterId);
    const field = metadata[currentEntity].fields.find(f => f.column === column);
    const filter = filters.find(f => f.id === filterId);
    if (!field || !filter) return;

    filter.column = column;
    container.innerHTML = '';

    if (field.type === 'enum') {
        const sel = document.createElement('select');
        sel.innerHTML = '<option value="">All</option>' + field.enumValues.map(v =>
            `<option value="${v}">${v}</option>`
        ).join('');
        sel.onchange = () => { filter.value = sel.value; };
        container.appendChild(sel);
    } else if (field.type === 'date') {
        const from = document.createElement('input');
        from.type = 'date';
        const to = document.createElement('input');
        to.type = 'date';
        const update = () => {
            if (from.value && to.value) filter.value = from.value + ',' + to.value;
        };
        from.onchange = update;
        to.onchange = update;
        container.append(from, document.createTextNode(' → '), to);
    } else {
        const inp = document.createElement('input');
        inp.type = field.type === 'number' ? 'number' : 'text';
        inp.placeholder = 'Search...';
        inp.oninput = () => { filter.value = inp.value; };
        container.appendChild(inp);
    }
}

// ---- Generate Report ----
async function generateReport(page = 0) {
    if (!currentEntity) return alert('Select an entity first');
    currentPage = page;

    const selectedFields = [...document.querySelectorAll('.field-chip.selected')].map(el => el.dataset.col);

    let url = `${API}/report?entity=${currentEntity}`;
    if (selectedFields.length > 0) url += `&fields=${selectedFields.join(',')}`;
    if (currentSort) url += `&sort=${currentSort}&dir=${currentDir}`;
    url += `&page=${page}&size=20`;

    filters.forEach(f => {
        if (f.column && f.value) url += `&filter_${f.column}=${encodeURIComponent(f.value)}`;
    });

    document.getElementById('reportLoading').style.display = 'flex';
    document.getElementById('reportTable').innerHTML = '';

    try {
        const res = await fetch(url);
        currentReport = await res.json();
        renderReport(currentReport);
    } catch (e) {
        console.error('Report error:', e);
        document.getElementById('reportTable').innerHTML = '<p style="color:#e17055;padding:20px;">Error loading report</p>';
    }
    document.getElementById('reportLoading').style.display = 'none';
}

function renderReport(report) {
    if (!report || !report.data) return;
    const fields = report.fields || [];
    const data = report.data || [];
    const fieldMeta = metadata[report.entity]?.fields || [];

    let html = `
        <div class="table-container">
            <div class="table-header">
                <span class="table-info">${report.total} results · Page ${report.page + 1} of ${report.totalPages}</span>
            </div>
            <div style="overflow-x:auto;">
            <table>
                <thead><tr>
                    ${fields.map(f => {
                        const meta = fieldMeta.find(m => m.column === f);
                        const label = meta ? meta.label : f;
                        const sorted = currentSort === f;
                        const icon = sorted ? (currentDir === 'ASC' ? '▲' : '▼') : '';
                        return `<th class="${sorted ? 'sorted' : ''}" onclick="sortBy('${f}')">${label} <span class="sort-icon">${icon}</span></th>`;
                    }).join('')}
                </tr></thead>
                <tbody>
                    ${data.length === 0 ? `<tr><td colspan="${fields.length}" style="text-align:center;padding:40px;color:var(--text-muted);">No data found</td></tr>` : ''}
                    ${data.map(row => `<tr>${fields.map(f => `<td>${formatCell(f, row[f])}</td>`).join('')}</tr>`).join('')}
                </tbody>
            </table>
            </div>
            ${renderPagination(report)}
        </div>
    `;

    document.getElementById('reportTable').innerHTML = html;
}

function formatCell(column, value) {
    if (value === null || value === undefined) return '<span style="color:var(--text-muted)">—</span>';

    // Status badges
    const statusCols = ['status', 'bid_status', 'is_read'];
    if (statusCols.includes(column)) {
        const cls = value === 'ACTIVE' || value === 'COMPLETED' || value === 'ACCEPTED' || value === 'Y' ? 'badge-active'
            : value === 'PENDING' ? 'badge-pending'
            : value === 'ENDED' || value === 'BANNED' || value === 'FAILED' || value === 'REJECTED' ? 'badge-ended'
            : 'badge-default';
        return `<span class="badge ${cls}">${value}</span>`;
    }

    // Money fields
    const moneyCols = ['balance', 'reserved_balance', 'starting_price', 'current_price', 'reserve_price', 'bid_increment', 'bid_amount', 'amount', 'balance_before', 'balance_after'];
    if (moneyCols.includes(column)) {
        return formatVND(parseFloat(value));
    }

    return escapeHtml(String(value));
}

function sortBy(column) {
    if (currentSort === column) {
        currentDir = currentDir === 'ASC' ? 'DESC' : 'ASC';
    } else {
        currentSort = column;
        currentDir = 'ASC';
    }
    generateReport(currentPage);
}

function renderPagination(report) {
    if (report.totalPages <= 1) return '';
    let buttons = '';
    buttons += `<button ${report.page === 0 ? 'disabled' : ''} onclick="generateReport(${report.page - 1})">‹ Prev</button>`;

    const start = Math.max(0, report.page - 2);
    const end = Math.min(report.totalPages, report.page + 3);
    for (let i = start; i < end; i++) {
        buttons += `<button class="${i === report.page ? 'active' : ''}" onclick="generateReport(${i})">${i + 1}</button>`;
    }

    buttons += `<button ${report.page >= report.totalPages - 1 ? 'disabled' : ''} onclick="generateReport(${report.page + 1})">Next ›</button>`;
    return `<div class="pagination">${buttons}</div>`;
}

// ---- Export CSV ----
function exportCSV() {
    if (!currentReport || !currentReport.data || currentReport.data.length === 0) {
        return alert('Generate a report first');
    }

    const fields = currentReport.fields;
    const fieldMeta = metadata[currentReport.entity]?.fields || [];
    const headers = fields.map(f => {
        const meta = fieldMeta.find(m => m.column === f);
        return meta ? meta.label : f;
    });

    let csv = headers.join(',') + '\n';
    currentReport.data.forEach(row => {
        csv += fields.map(f => {
            const val = row[f] ?? '';
            return `"${String(val).replace(/"/g, '""')}"`;
        }).join(',') + '\n';
    });

    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${currentReport.entity}_report.csv`;
    a.click();
    URL.revokeObjectURL(url);
}

// ---- Utils ----
function formatVND(num) {
    if (num === null || num === undefined || isNaN(num)) return '0 ₫';
    return new Intl.NumberFormat('vi-VN').format(num) + ' ₫';
}

function escapeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
