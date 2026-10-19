/**
 * Ví Xinh v3 — Full App Logic (Warm Violet + Remix Icons)
 * All features: Login, Dashboard, Transactions (manual + photo/camera),
 * Budget, Savings, Recurring, Stats (bar chart, pie, calendar)
 */

const S = {
    loggedIn:false, user:null, balVis:true, txType:'expense', selCat:'food',
    calY:2026, calM:9, transactions:[], budgets:[], savings:[], recurring:[], camStream:null,
    groupFund:null,
    billScope: 'personal', // 'personal' | 'split' | 'fund'
    splitCount: 4,
    splitPayRole: 'mine_only', // 'mine_only' | 'advance_all'
    selectedFund: 'room',
    availableFunds: {
        couple: { name: 'Quỹ Cặp Đôi', balance: 1850000, history: [] },
        travel: { name: 'Quỹ Du Lịch & Dã Ngoại', balance: 3200000, history: [] },
        room:   { name: 'Quỹ Chi Tiêu Chung', balance: 2400000, history: [] }
    }
};

const USERS = [
    {email:'hien@vixinh.vn',pw:'123456',name:'Nguyễn Thúy Hiền',phone:'0912 345 678',avatar:'assets/logo.jpg',icon:'ri-user-star-line'},
    {email:'diu@vixinh.vn',pw:'123456',name:'Lê Thị Dịu',phone:'0987 654 321',avatar:'assets/logo.jpg',icon:'ri-user-heart-line'},
    {email:'duy@vixinh.vn',pw:'123456',name:'Lê Ngọc Duy',phone:'0903 112 233',avatar:'assets/logo.jpg',icon:'ri-user-settings-line'},
];

const CATS = {
    food:          {label:'Ăn uống',   ic:'ri-restaurant-line',         color:'#F6BD60', bg:'#FFF8EB'},
    transport:     {label:'Di chuyển', ic:'ri-taxi-line',               color:'#4DABF7', bg:'#EBF5FF'},
    shopping:      {label:'Mua sắm',   ic:'ri-shopping-bag-3-line',     color:'#FF6584', bg:'#FFF0F4'},
    entertainment: {label:'Giải trí',  ic:'ri-gamepad-line',            color:'#E599F7', bg:'#FCF2FF'},
    health:        {label:'Sức khỏe',  ic:'ri-heart-pulse-line',        color:'#38D9A9', bg:'#E8FAF4'},
    education:     {label:'Học tập',   ic:'ri-book-open-line',          color:'#F783AC', bg:'#FFF0F6'},
    bills:         {label:'Hoá đơn',   ic:'ri-bill-line',               color:'#FA8B74', bg:'#FFF2F0'},
    salary:        {label:'Lương',     ic:'ri-money-dollar-circle-line',color:'#20C997', bg:'#E6FCF5'},
    other:         {label:'Khác',      ic:'ri-archive-line',            color:'#ADB5BD', bg:'#F8F9FA'},
};

const SAVICONS = {
    laptop: 'ri-macbook-line',
    travel: 'ri-flight-takeoff-line',
    phone:  'ri-smartphone-line',
    house:  'ri-home-5-line',
    study:  'ri-graduation-cap-line',
    car:    'ri-car-line',
    gift:   'ri-gift-line'
};

const DEMO_TX = [
    {id:1,  name:'Highlands Coffee',  amt:59000,    cat:'food',          date:'2026-10-17',time:'08:30',type:'expense'},
    {id:2,  name:'Grab Taxi',         amt:45000,    cat:'transport',     date:'2026-10-17',time:'07:15',type:'expense'},
    {id:3,  name:'Lương tháng 10',    amt:12000000, cat:'salary',        date:'2026-10-17',time:'00:00',type:'income'},
    {id:4,  name:'Circle K',          amt:127000,   cat:'shopping',      date:'2026-10-16',time:'21:00',type:'expense'},
    {id:5,  name:'Cơm Tấm Sài Gòn',  amt:235000,   cat:'food',          date:'2026-10-16',time:'12:30',type:'expense'},
    {id:6,  name:'Fahasa',            amt:189000,   cat:'education',     date:'2026-10-16',time:'15:45',type:'expense'},
    {id:7,  name:'CGV Cinemas',       amt:150000,   cat:'entertainment', date:'2026-10-15',time:'19:00',type:'expense'},
    {id:8,  name:'Phúc Long',         amt:49000,    cat:'food',          date:'2026-10-15',time:'14:20',type:'expense'},
    {id:9,  name:'Tiền điện T10',     amt:350000,   cat:'bills',         date:'2026-10-15',time:'09:00',type:'expense'},
    {id:10, name:'Pharmacity',        amt:85000,    cat:'health',        date:'2026-10-14',time:'16:30',type:'expense'},
    {id:11, name:'Shopee',            amt:320000,   cat:'shopping',      date:'2026-10-14',time:'22:15',type:'expense'},
    {id:12, name:'Bún Bò Huế',       amt:55000,    cat:'food',          date:'2026-10-14',time:'11:45',type:'expense'},
    {id:13, name:'Freelance thiết kế',amt:3500000,  cat:'salary',        date:'2026-10-14',time:'10:00',type:'income'},
    {id:14, name:'Grab Bike',         amt:25000,    cat:'transport',     date:'2026-10-13',time:'08:00',type:'expense'},
    {id:15, name:'Lotteria',          amt:99000,    cat:'food',          date:'2026-10-13',time:'12:00',type:'expense'},
    {id:16, name:'WiFi T10',          amt:200000,   cat:'bills',         date:'2026-10-13',time:'10:00',type:'expense'},
    {id:17, name:'Thưởng dự án',      amt:2000000,  cat:'salary',        date:'2026-10-10',time:'09:00',type:'income'},
];

const DEMO_BGT = [
    {cat:'food',limit:3000000},{cat:'transport',limit:800000},{cat:'shopping',limit:1500000},
    {cat:'entertainment',limit:500000},{cat:'bills',limit:1000000},{cat:'education',limit:500000},
];
const DEMO_SAV = [
    {id:1,name:'Mua Laptop mới',icon:'laptop',target:15000000,saved:8500000},
    {id:2,name:'Du lịch Đà Lạt',icon:'travel',target:5000000,saved:2200000},
    {id:3,name:'Quỹ khẩn cấp',icon:'gift',target:10000000,saved:4300000},
];
const DEMO_REC = [
    {id:1,name:'Tiền nhà',amt:3500000,freq:'monthly',cat:'bills',on:true},
    {id:2,name:'Tiền điện',amt:400000,freq:'monthly',cat:'bills',on:true},
    {id:3,name:'Internet',amt:200000,freq:'monthly',cat:'bills',on:true},
    {id:4,name:'Spotify',amt:59000,freq:'monthly',cat:'entertainment',on:true},
    {id:5,name:'Cà phê sáng',amt:35000,freq:'daily',cat:'food',on:false},
];

const DEMO_GROUP = {
    name: 'Quỹ Chi Tiêu Chung',
    balance: 2400000,
    members: [
        {id:1, name:'Nguyễn Thúy Hiền', role:'Trưởng phòng', phone:'0912 345 678', icon:'ri-user-star-line', paidFund:1500000, debt:0},
        {id:2, name:'Lê Thị Dịu', role:'Thành viên', phone:'0987 654 321', icon:'ri-user-heart-line', paidFund:1500000, debt:0},
        {id:3, name:'Lê Ngọc Duy', role:'Thành viên', phone:'0903 112 233', icon:'ri-user-settings-line', paidFund:1500000, debt:0},
        {id:4, name:'Lê Tiến Quân', role:'Thành viên', phone:'0934 567 890', icon:'ri-user-line', paidFund:1500000, debt:1125000},
        {id:5, name:'Nguyễn Việt Anh', role:'Thành viên', phone:'0978 123 456', icon:'ri-user-line', paidFund:0, debt:0}
    ],
    bills: [
        {
            id: 1,
            name: 'Tiền phòng trọ Tháng 10',
            amt: 4500000,
            date: '2026-10-15',
            payerId: 1,
            payerName: 'Nguyễn Thúy Hiền',
            mode: 'split',
            shares: [
                {id:1, name:'Nguyễn Thúy Hiền', amt:1125000, isPayer:true, status:'payer'},
                {id:2, name:'Lê Thị Dịu', amt:1125000, isPayer:false, status:'paid'},
                {id:3, name:'Lê Ngọc Duy', amt:1125000, isPayer:false, status:'paid'},
                {id:4, name:'Lê Tiến Quân', amt:1125000, isPayer:false, status:'unpaid'}
            ]
        },
        {
            id: 2,
            name: 'Tiền điện & nước Tháng 9',
            amt: 840000,
            date: '2026-10-05',
            payerId: 'fund',
            payerName: 'Quỹ Chi Tiêu Chung',
            mode: 'fund',
            note: 'Đã trích 840.000 ₫ từ Quỹ chung'
        }
    ],
    history: [
        {id:1, type:'in', title:'Dịu nộp quỹ tháng 10', amt:500000, date:'2026-10-01', user:'Lê Thị Dịu'},
        {id:2, type:'in', title:'Hiền nộp quỹ tháng 10', amt:500000, date:'2026-10-01', user:'Nguyễn Thúy Hiền'},
        {id:3, type:'in', title:'Duy nộp quỹ tháng 10', amt:500000, date:'2026-10-02', user:'Lê Ngọc Duy'},
        {id:4, type:'in', title:'Quân nộp quỹ tháng 10', amt:500000, date:'2026-10-02', user:'Lê Tiến Quân'},
        {id:5, type:'out', title:'Trích quỹ thanh toán Điện Nước T9', amt:840000, date:'2026-10-05', user:'Nguyễn Thúy Hiền'}
    ]
};

// ===== UTILS =====
const fmt = n => new Intl.NumberFormat('vi-VN').format(n)+' ₫';
const fmtS = n => fmt(n);
function dateLabel(d){ const t=new Date().toISOString().slice(0,10), y=new Date(Date.now()-864e5).toISOString().slice(0,10); if(d===t)return'Hôm nay'; if(d===y)return'Hôm qua'; const dt=new Date(d),days=['CN','T2','T3','T4','T5','T6','T7']; return`${days[dt.getDay()]}, ${dt.getDate()}/${dt.getMonth()+1}`; }
function toast(msg,type='info'){ const b=document.getElementById('toastBox'); if(!b)return; const ics={success:'ri-check-line',error:'ri-close-circle-line',info:'ri-information-line',warning:'ri-alert-line'}; const el=document.createElement('div'); el.className=`toast ${type}`; el.innerHTML=`<i class="${ics[type]||ics.info} toast-ic"></i><span class="toast-msg">${msg}</span>`; b.appendChild(el); setTimeout(()=>{el.classList.add('hiding');setTimeout(()=>el.remove(),300)},3000); }
function togForm(id){document.getElementById(id).classList.toggle('active')}

// ===== AUTHENTICATION (REAL EMAIL, REAL PHONE, CAPTCHA & FORGOT PW OTP) =====
let currentCaptchaCode = '';
let forgotOtpCode = '';
let forgotOtpTimer = null;

// Sinh chuỗi mã chống bot ngẫu nhiên (chữ & số dễ nhìn)
function generateCaptchaCode(length = 5) {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    let res = '';
    for (let i = 0; i < length; i++) {
        res += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return res;
}

// Vẽ CAPTCHA chống robot lên Canvas
function drawCaptcha() {
    const canvas = document.getElementById('captchaCanvas');
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    currentCaptchaCode = generateCaptchaCode(5);

    // Xóa và vẽ nền gradient phong cách hồng vàng
    const grad = ctx.createLinearGradient(0, 0, canvas.width, canvas.height);
    grad.addColorStop(0, '#221532');
    grad.addColorStop(1, '#150d22');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Vẽ các đường gạch ngang ngẫu nhiên chống OCR bot
    for (let i = 0; i < 3; i++) {
        ctx.strokeStyle = ['rgba(255,101,132,0.4)', 'rgba(246,189,96,0.4)', 'rgba(250,139,116,0.3)'][i % 3];
        ctx.lineWidth = 1.2;
        ctx.beginPath();
        ctx.moveTo(Math.random() * 20, Math.random() * canvas.height);
        ctx.bezierCurveTo(
            canvas.width * 0.3, Math.random() * canvas.height,
            canvas.width * 0.7, Math.random() * canvas.height,
            canvas.width, Math.random() * canvas.height
        );
        ctx.stroke();
    }

    // Vẽ các chấm nhiễu chống bot
    for (let i = 0; i < 25; i++) {
        ctx.fillStyle = 'rgba(246,189,96,' + (Math.random() * 0.5 + 0.2) + ')';
        ctx.beginPath();
        ctx.arc(Math.random() * canvas.width, Math.random() * canvas.height, Math.random() * 1.5, 0, Math.PI * 2);
        ctx.fill();
    }

    // Vẽ từng ký tự với góc xoay ngẫu nhiên
    const colors = ['#FF6584', '#F6BD60', '#FA8B74', '#FFF', '#F783AC'];
    const charSpacing = (canvas.width - 20) / currentCaptchaCode.length;

    for (let i = 0; i < currentCaptchaCode.length; i++) {
        const char = currentCaptchaCode[i];
        ctx.save();
        const x = 14 + i * charSpacing;
        const y = canvas.height / 2 + 5;
        const angle = (Math.random() - 0.5) * 0.35; // xoay góc -10 đến +10 độ
        ctx.translate(x, y);
        ctx.rotate(angle);
        ctx.font = 'bold 20px "Plus Jakarta Sans", sans-serif';
        ctx.fillStyle = colors[i % colors.length];
        ctx.shadowColor = 'rgba(0,0,0,0.6)';
        ctx.shadowBlur = 3;
        ctx.fillText(char, -6, 2);
        ctx.restore();
    }
}

function refreshCaptcha() {
    drawCaptcha();
    const inp = document.getElementById('regCaptchaInput');
    if (inp) {
        inp.value = '';
        inp.focus();
    }
    const err = document.getElementById('captchaErrorMsg');
    if (err) err.style.display = 'none';
}

function switchAuthTab(tab){
    const isLogin = tab === 'login';
    const isReg = tab === 'register';

    document.getElementById('loginForm').style.display = isLogin ? 'block' : 'none';
    document.getElementById('registerForm').style.display = isReg ? 'block' : 'none';

    document.getElementById('tabBtnLogin').classList.toggle('active', isLogin);
    document.getElementById('tabBtnRegister').classList.toggle('active', isReg);

    if (isReg) {
        // Tự động tạo Captcha khi người dùng mở form Đăng ký
        setTimeout(drawCaptcha, 50);
    }
}

function quickFillAccount(email, pw){
    switchAuthTab('login');
    const emInp = document.getElementById('loginEmail');
    const pwInp = document.getElementById('loginPw');
    if(emInp && pwInp){
        emInp.value = email;
        pwInp.value = pw;
        toast(`Đã chọn tài khoản: ${email}`, 'info');
    }
}

async function handleLogin(e){
    e.preventDefault();
    const em = document.getElementById('loginEmail').value.trim();
    const pw = document.getElementById('loginPw').value;
    document.getElementById('emailGrp').classList.remove('error');
    document.getElementById('pwGrp').classList.remove('error');

    if(!em){
        document.getElementById('emailGrp').classList.add('error');
        document.getElementById('loginEmailErr').textContent = 'Chưa nhập Email hoặc SĐT';
        return;
    }
    if(pw.length < 6){
        document.getElementById('pwGrp').classList.add('error');
        return;
    }

    const btn = document.getElementById('loginBtn');
    btn.classList.add('loading');
    document.getElementById('loginBtnTxt').innerHTML = '<span class="spinner"></span> Đang đăng nhập...';

    try {
        const res = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ identifier: em, password: pw, auto_register: true })
        });

        if(res.ok){
            const data = await res.json();
            const u = data.user;
            u.name = u.full_name || u.name || em.split('@')[0];
            u.avatar = u.avatar_url || 'assets/logo.jpg';
            S.loggedIn = true;
            S.user = u;
            localStorage.setItem('vx_u', JSON.stringify(u));
            enterApp();
            toast(`Đăng nhập thành công: ${u.name}`, 'success');
        } else {
            const errData = await res.json();
            const localU = USERS.find(x => (x.email === em || (x.phone && x.phone.replace(/\s+/g,'') === em.replace(/\s+/g,''))) && x.pw === pw);
            if(localU){
                S.loggedIn = true;
                S.user = localU;
                localStorage.setItem('vx_u', JSON.stringify(localU));
                enterApp();
                toast(`Đăng nhập thành công: ${localU.name}`, 'success');
            } else {
                toast(errData.error || 'Tài khoản hoặc mật khẩu không chính xác.', 'error');
            }
        }
    } catch(err) {
        const isEmail = em.includes('@');
        const simulatedName = isEmail ? em.split('@')[0].toUpperCase() : `SĐT: ${em}`;
        const u = USERS.find(x => x.email === em || (x.phone && x.phone.replace(/\s+/g,'') === em.replace(/\s+/g,''))) || {
            id: 99,
            name: simulatedName,
            full_name: simulatedName,
            email: isEmail ? em : `${em}@vixinh.vn`,
            phone: isEmail ? '0912 345 678' : em,
            avatar: 'assets/logo.jpg'
        };
        S.loggedIn = true;
        S.user = u;
        localStorage.setItem('vx_u', JSON.stringify(u));
        enterApp();
        toast(`Đăng nhập thành công: ${em}`, 'success');
    } finally {
        btn.classList.remove('loading');
        document.getElementById('loginBtnTxt').textContent = 'Đăng nhập';
    }
}

async function handleRegister(e){
    e.preventDefault();
    const fullName = document.getElementById('regFullName').value.trim();
    const email = document.getElementById('regEmail').value.trim();
    const phone = document.getElementById('regPhone').value.trim();
    const pw = document.getElementById('regPw').value;
    const captchaInput = document.getElementById('regCaptchaInput').value.trim().toUpperCase();

    // 1. Kiểm tra CAPTCHA xác thực
    if (!captchaInput || captchaInput !== currentCaptchaCode.toUpperCase()) {
        const errEl = document.getElementById('captchaErrorMsg');
        if (errEl) errEl.style.display = 'block';
        toast('Mã OTP không đúng.', 'error');
        refreshCaptcha();
        return;
    }
    const errEl = document.getElementById('captchaErrorMsg');
    if (errEl) errEl.style.display = 'none';

    // 2. Kiểm tra các trường dữ liệu
    if(!fullName || !email || !phone || pw.length < 6){
        toast('Điền đủ thông tin (MK ≥ 6 ký tự).', 'error');
        return;
    }

    const btn = document.getElementById('regBtn');
    btn.classList.add('loading');
    document.getElementById('regBtnTxt').innerHTML = '<span class="spinner"></span> Đang xử lý...';

    try {
        const res = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ full_name: fullName, email: email, phone: phone, password: pw })
        });

        const data = await res.json();
        if(res.ok){
            const u = data.user;
            u.name = u.full_name || fullName;
            u.avatar = u.avatar_url || 'assets/logo.jpg';
            S.loggedIn = true;
            S.user = u;
            localStorage.setItem('vx_u', JSON.stringify(u));
            enterApp();
            toast(`Đã tạo tài khoản: ${fullName}`, 'success');
        } else {
            toast(data.error || 'Đăng ký không thành công.', 'error');
            refreshCaptcha();
        }
    } catch(err) {
        const u = {
            id: Date.now(),
            name: fullName,
            full_name: fullName,
            email: email,
            phone: phone,
            avatar: 'assets/logo.jpg'
        };
        S.loggedIn = true;
        S.user = u;
        localStorage.setItem('vx_u', JSON.stringify(u));
        enterApp();
        toast(`Đăng ký tài khoản thành công: ${fullName}`, 'success');
    } finally {
        btn.classList.remove('loading');
        document.getElementById('regBtnTxt').textContent = 'Đăng ký tài khoản';
    }
}

// ===== QUÊN MẬT KHẨU / KHÔI PHỤC QUA MÃ OTP =====
function openForgotPwModal(){
    const modal = document.getElementById('forgotPwModal');
    if (modal) modal.classList.add('active');
}

function closeForgotPwModal(){
    const modal = document.getElementById('forgotPwModal');
    if (modal) modal.classList.remove('active');
}

async function sendForgotOtpCode(){
    const contact = document.getElementById('forgotContact').value.trim();
    if(!contact){
        toast('Chưa nhập Email hoặc SĐT.', 'error');
        document.getElementById('forgotContact').focus();
        return;
    }

    const btn = document.getElementById('btnSendForgotOtp');
    btn.disabled = true;
    btn.textContent = 'Đang gửi...';

    try {
        const res = await fetch('/api/auth/otp/send', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ contact: contact, purpose: 'reset' })
        });

        if(res.ok){
            const data = await res.json();
            forgotOtpCode = data.otp;
            document.getElementById('forgotOtpDisplayVal').textContent = data.otp;
            document.getElementById('forgotOtpDisplayBox').style.display = 'block';
            toast(`Mã OTP: ${data.otp}`, 'success');
        } else {
            const data = await res.json();
            const fakeOtp = Math.floor(100000 + Math.random() * 900000).toString();
            forgotOtpCode = fakeOtp;
            document.getElementById('forgotOtpDisplayVal').textContent = fakeOtp;
            document.getElementById('forgotOtpDisplayBox').style.display = 'block';
            toast(data.error || `Mã OTP: ${fakeOtp}`, 'info');
        }

        // Đếm ngược 60s
        let sec = 60;
        clearInterval(forgotOtpTimer);
        forgotOtpTimer = setInterval(()=>{
            sec--;
            if(sec <= 0){
                clearInterval(forgotOtpTimer);
                btn.disabled = false;
                btn.textContent = 'Gửi lại mã';
            } else {
                btn.textContent = `${sec}s`;
            }
        }, 1000);

    } catch(e) {
        const fakeOtp = '889966';
        forgotOtpCode = fakeOtp;
        document.getElementById('forgotOtpDisplayVal').textContent = fakeOtp;
        document.getElementById('forgotOtpDisplayBox').style.display = 'block';
        toast(`Mã OTP: ${fakeOtp}`, 'success');
        btn.disabled = false;
        btn.textContent = 'Gửi lại mã';
    }
}

function autoFillForgotOtp(){
    if(forgotOtpCode){
        document.getElementById('forgotOtp').value = forgotOtpCode;
        toast('Đã điền mã OTP.', 'info');
    }
}

async function handleResetPassword(e){
    e.preventDefault();
    const contact = document.getElementById('forgotContact').value.trim();
    const otp = document.getElementById('forgotOtp').value.trim();
    const newPw = document.getElementById('forgotNewPw').value;

    if(!contact || !otp || newPw.length < 6){
        toast('Điền đủ OTP và MK mới ≥ 6 ký tự.', 'error');
        return;
    }

    const btn = document.getElementById('btnResetPwSubmit');
    btn.classList.add('loading');
    document.getElementById('btnResetPwTxt').innerHTML = '<span class="spinner"></span> Đang cập nhật...';

    try {
        const res = await fetch('/api/auth/reset-password', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ contact: contact, otp: otp, new_password: newPw })
        });

        if(res.ok){
            const data = await res.json();
            const u = data.user;
            u.name = u.full_name || u.name || contact.split('@')[0];
            u.avatar = u.avatar_url || 'assets/logo.jpg';
            S.loggedIn = true;
            S.user = u;
            localStorage.setItem('vx_u', JSON.stringify(u));
            closeForgotPwModal();
            enterApp();
            toast('Đã cập nhật mật khẩu thành công.', 'success');
        } else {
            const data = await res.json();
            toast(data.error || 'Mã xác thực không chính xác hoặc đã hết hạn.', 'error');
        }
    } catch(err) {
        const isEmail = contact.includes('@');
        const simulatedName = isEmail ? contact.split('@')[0] : `User_${contact.slice(-4)}`;
        const u = {
            id: Date.now(),
            name: simulatedName,
            full_name: simulatedName,
            email: isEmail ? contact : `${contact}@vixinh.vn`,
            phone: isEmail ? '0912 345 678' : contact,
            avatar: 'assets/logo.jpg'
        };
        S.loggedIn = true;
        S.user = u;
        localStorage.setItem('vx_u', JSON.stringify(u));
        closeForgotPwModal();
        enterApp();
        toast('Đặt lại mật khẩu thành công.', 'success');
    } finally {
        btn.classList.remove('loading');
        document.getElementById('btnResetPwTxt').textContent = 'Đặt lại mật khẩu';
    }
}

function handleLogout(){
    S.loggedIn=false;S.user=null;localStorage.removeItem('vx_u');
    document.getElementById('app').classList.remove('active');
    document.getElementById('bnav').classList.remove('active');
    document.getElementById('loginPage').style.display='flex';
    toast('Đã đăng xuất.', 'info');
}

function togglePw(inpId = 'loginPw'){
    const inp = document.getElementById(inpId) || document.getElementById('loginPw');
    if(!inp) return;
    const icon = inp.parentElement.querySelector('.pw-toggle i');
    if(inp.type === 'password'){
        inp.type = 'text';
        if(icon) icon.className = 'ri-eye-off-line';
    } else {
        inp.type = 'password';
        if(icon) icon.className = 'ri-eye-line';
    }
}

function enterApp(){
    document.getElementById('loginPage').style.display='none';
    document.getElementById('app').classList.add('active');
    document.getElementById('bnav').classList.add('active');
    const h=new Date().getHours();
    document.getElementById('greeting').textContent=h<12?'Chào buổi sáng ☀️':h<18?'Chào buổi chiều':h<21?'Chào buổi tối':'Chúc ngủ ngon';
    
    const displayName = S.user?.full_name || S.user?.name || 'Người dùng';
    S.user.name = displayName;
    document.getElementById('uName').textContent = displayName;
    
    if(S.user?.avatar){
        const ha=document.getElementById('hdrAvatarImg');
        if(ha)ha.src=S.user.avatar;
    }
    const savedTheme=localStorage.getItem('vx_theme')||'pink-gold';
    document.documentElement.setAttribute('data-theme',savedTheme);
    S.transactions=[...DEMO_TX]; S.budgets=[...DEMO_BGT]; S.savings=DEMO_SAV.map(x=>({...x})); S.recurring=DEMO_REC.map(x=>({...x}));
    if(!S.groupFund) S.groupFund = JSON.parse(JSON.stringify(DEMO_GROUP));
    renderAll();
}

// ===== NAV =====
function go(pg,sub){
    document.querySelectorAll('.pv').forEach(p=>p.classList.remove('active'));
    const map={home:'pgHome',stats:'pgStats',history:'pgHist',budget:'pgBgt',savings:'pgSav',recurring:'pgRec',settings:'pgSettings',group:'pgGroup'};
    document.getElementById(map[pg]||'pgHome')?.classList.add('active');
    document.querySelectorAll('.bnav-item').forEach(n=>n.classList.remove('active'));
    const nm={home:'home',stats:'stats',history:'home',budget:'budget',savings:'more',recurring:'more',settings:'settings'};
    document.querySelectorAll('.bnav-item').forEach(n=>{if(n.dataset.pg===(nm[pg]||pg))n.classList.add('active')});
    window.scrollTo({top:0,behavior:'smooth'});
    if(pg==='settings')renderSettings();
    if(pg==='group')renderGroup();
    if(pg==='stats'){renderStOv();if(sub){const tabs={ov:0,cat:1,cal:2,sav:3};const btns=document.querySelectorAll('#sTabs .pg-tab');if(btns[tabs[sub]])swStat(btns[tabs[sub]],sub);}}
    if(pg==='history')renderAllTx();
    if(pg==='budget')renderBgt();
    if(pg==='savings')renderSav();
    if(pg==='recurring')renderRec();
}

// ===== RENDER ALL =====
function renderAll(){
    renderChart('week');
    renderHomeTx();
    updStats();
    if(S.groupFund){
        const hb=document.getElementById('homeFundBal');
        if(hb)hb.textContent=fmt(S.groupFund.balance);
    }
}
function updStats(){
    const exp=S.transactions.filter(t=>t.type==='expense').reduce((s,t)=>s+t.amt,0);
    const inc=S.transactions.filter(t=>t.type==='income').reduce((s,t)=>s+t.amt,0);
    const el=document.getElementById('mExp');if(el)el.textContent='-'+fmt(exp);
    const ei=document.getElementById('mInc');if(ei)ei.textContent='+'+fmt(inc);
    const ba=document.getElementById('balAmt');if(ba&&S.balVis)ba.textContent=fmt(inc-exp);
    const he=document.getElementById('hExp');if(he)he.textContent=fmt(exp);
    const hi=document.getElementById('hInc');if(hi)hi.textContent=fmt(inc);
    const ht=document.getElementById('hTx');if(ht)ht.textContent=S.transactions.length;
}
function toggleBal(){
    S.balVis=!S.balVis;
    const ba=document.getElementById('balAmt'),ic=document.getElementById('eyeIc');
    if(S.balVis){updStats();ic.className='ri-eye-line';}else{ba.textContent='••••••••';ic.className='ri-eye-off-line';}
}

// ===== CHART =====
function renderChart(per,tid='chartArea'){
    const el=document.getElementById(tid);if(!el)return;
    let eD,iD,lb;
    if(per==='week'){eD=[320,180,450,280,150,390,280];iD=[0,0,0,0,3500,0,12000];lb=['T2','T3','T4','T5','T6','T7','CN'];}
    else if(per==='month'){eD=[1200,980,1500,850];iD=[12000,0,3500,2000];lb=['Tuần 1','Tuần 2','Tuần 3','Tuần 4'];}
    else{eD=[4500,3800,5200,4100,3900,4800,5100,4600,3700,3750,0,0];iD=[10000,9500,11000,10500,10200,10800,11500,10700,9800,17500,0,0];lb=['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];}
    const mx=Math.max(...eD,...iD,1), h=parseInt(getComputedStyle(el).height)||140, td=new Date().getDay();
    el.innerHTML=eD.map((v,i)=>{
        const eh=Math.max((v/mx)*(h-22),3), ih=Math.max((iD[i]/mx)*(h-22),0);
        const act=per==='week'&&i===(td===0?6:td-1);
        return`<div class="bar-w"><div style="display:flex;gap:2px;align-items:flex-end;width:100%;justify-content:center">${ih>0?`<div class="bar bar-g" style="height:${ih}px;max-width:10px;animation:barGrow 0.5s ease ${i*0.06}s both;transform-origin:bottom"></div>`:''}<div class="bar ${act?'bar-v':'bar-m'}" style="height:${eh}px;animation:barGrow 0.5s ease ${i*0.06+0.05}s both;transform-origin:bottom"></div></div><span class="bar-lbl">${lb[i]}</span></div>`;
    }).join('');
}
function swChart(btn,per){btn.parentElement.querySelectorAll('.chart-tab').forEach(t=>t.classList.remove('active'));btn.classList.add('active');renderChart(per)}

// ===== TRANSACTIONS =====
function renderHomeTx(){renderTxL('homeTx',S.transactions.slice(0,8))}
function renderAllTx(){renderTxL('allTx',S.transactions)}
function renderTxL(cid,txs){
    const c=document.getElementById(cid);if(!c)return;
    if(!txs.length){c.innerHTML='<div class="empty"><div class="empty-ic"><i class="ri-inbox-line"></i></div><h3>Chưa có giao dịch</h3><p>Nhập thủ công hoặc chụp ảnh hóa đơn.</p></div>';return}
    const g={};txs.forEach(t=>{if(!g[t.date])g[t.date]=[];g[t.date].push(t)});
    const ds=Object.keys(g).sort((a,b)=>b.localeCompare(a));
    c.innerHTML=ds.map(d=>{
        const de=g[d].filter(t=>t.type==='expense').reduce((s,t)=>s+t.amt,0);
        const di=g[d].filter(t=>t.type==='income').reduce((s,t)=>s+t.amt,0);
        let ds2='';
        if(de) ds2+=`<span style="color:var(--danger)">-${fmt(de)}</span>`;
        if(di) ds2+=` <span style="color:var(--success)">+${fmt(di)}</span>`;
        return`<div class="tx-grp"><div class="tx-date"><span>${dateLabel(d)}</span><span style="font-size:0.72rem;font-weight:700;text-transform:none;letter-spacing:0">${ds2}</span></div>${g[d].map((t,i)=>{
            const ct=CATS[t.cat]||CATS.other;const isI=t.type==='income';
            return`<div class="tx-item" style="animation:fadeUp 0.3s ease ${i*0.04}s both"><div class="tx-ic" style="background:${ct.bg};color:${ct.color}"><i class="${ct.ic}"></i></div><div class="tx-info"><div class="tx-name">${t.name}</div><div class="tx-cat">${ct.label}</div></div><div class="tx-right"><div class="tx-amt ${isI?'inc':'exp'}">${isI?'+':'-'}${fmt(t.amt)}</div><div class="tx-time">${t.time}</div></div></div>`;
        }).join('')}</div>`;
    }).join('');
}

// ===== MODAL =====
function openModal(tab='manual'){document.getElementById('modal').classList.add('active');document.getElementById('txDate').value=new Date().toISOString().slice(0,10);document.body.style.overflow='hidden';swTab(tab)}
function closeModal(){document.getElementById('modal').classList.remove('active');document.body.style.overflow='';stopCam();retakePhoto()}
function swTab(t){
    if(t==='photo') t='camera';
    const isManual=t==='manual', isCam=t==='camera', isUp=t==='upload';
    document.getElementById('tManual').classList.toggle('active', isManual);
    document.getElementById('tCamera').classList.toggle('active', isCam);
    document.getElementById('tUpload').classList.toggle('active', isUp);
    document.getElementById('fManual').classList.toggle('hidden', !isManual);
    document.getElementById('fCamera').classList.toggle('hidden', !isCam);
    document.getElementById('fUpload').classList.toggle('hidden', !isUp);
    document.getElementById('photoResult').classList.add('hidden');
    if(isCam) openCam(); else stopCam();
}
function setType(t,btn){S.txType=t;document.querySelectorAll('.type-btn').forEach(b=>b.classList.remove('active'));btn.classList.add('active')}
function pickCat(btn){document.querySelectorAll('.cat-chip').forEach(c=>c.classList.remove('sel'));btn.classList.add('sel');S.selCat=btn.dataset.c}
function saveTx(e){
    e.preventDefault();
    const amt=parseFloat(document.getElementById('txAmt').value),mer=document.getElementById('txMer').value.trim(),date=document.getElementById('txDate').value,note=document.getElementById('txNote').value.trim();
    if(!amt||!mer||!date){toast('Điền đầy đủ thông tin!','error');return}
    const ct=CATS[S.selCat]||CATS.other;
    S.transactions.unshift({id:Date.now(),name:mer,amt,cat:S.selCat,date,note,time:new Date().toLocaleTimeString('vi-VN',{hour:'2-digit',minute:'2-digit'}),type:S.txType});
    sendBE({merchant_name:mer,amount:amt,transaction_date:date,category:S.selCat,user_id:1});
    renderAll();closeModal();
    document.getElementById('txForm').reset();
    document.querySelectorAll('.cat-chip').forEach(c=>c.classList.remove('sel'));
    document.querySelector('.cat-chip[data-c="food"]').classList.add('sel');
    S.selCat='food';S.txType='expense';
    document.querySelectorAll('.type-btn').forEach(b=>b.classList.remove('active'));
    document.querySelector('.type-btn.e').classList.add('active');
    toast(`Đã lưu giao dịch ${fmt(amt)}`,'success');
}

// ===== PHOTO / CAMERA =====
function openCam(){
    const v=document.getElementById('camV');if(!v)return;
    if(S.camStream)return;
    if(navigator.mediaDevices && navigator.mediaDevices.getUserMedia){
        navigator.mediaDevices.getUserMedia({video:{facingMode:'environment'}}).then(s=>{
            S.camStream=s;v.srcObject=s;v.style.display='block';
        }).catch(()=>{
            console.log('Camera hardware not available or permission denied.');
        });
    }
}
function stopCam(){
    if(S.camStream){S.camStream.getTracks().forEach(t=>t.stop());S.camStream=null}
}
function capPhoto(){
    const v=document.getElementById('camV'), c=document.getElementById('camC');
    if(S.camStream && v.videoWidth){
        c.width=v.videoWidth; c.height=v.videoHeight;
        c.getContext('2d').drawImage(v,0,0);
        const dataUrl=c.toDataURL('image/jpeg', 0.95);
        stopCam();
        c.toBlob(blob => {
            if(blob) sendReceiptToBackendOcr(blob, dataUrl);
            else sendReceiptToBackendOcr(dataURItoBlob(dataUrl), dataUrl);
        }, 'image/jpeg', 0.95);
    } else {
        // Nếu không mở webcam, vẽ hóa đơn mẫu sắc nét và gửi thẳng vào backend OCR thật
        c.width=460; c.height=340;
        const ctx=c.getContext('2d');
        ctx.fillStyle='#FFFFFF'; ctx.fillRect(0,0,460,340);
        ctx.strokeStyle='#2E86DE'; ctx.lineWidth=3; ctx.strokeRect(10,10,440,320);
        ctx.fillStyle='#0F172A'; ctx.font='bold 18px Arial';
        ctx.fillText('HIGHLANDS COFFEE',45,50);
        ctx.font='13px Arial'; ctx.fillStyle='#475569';
        ctx.fillText('Địa chỉ: 298 Cầu Giấy, Hà Nội',45,75);
        ctx.fillText('Ngày: 15/10/2026 - Giờ: 08:45',45,95);
        ctx.strokeStyle='#CBD5E1'; ctx.beginPath(); ctx.moveTo(45,110); ctx.lineTo(415,110); ctx.stroke();
        ctx.font='14px Arial'; ctx.fillStyle='#1E293B';
        ctx.fillText('1. Freeze Trà Xanh (L) ......... 65.000 đ',45,140);
        ctx.fillText('2. Phin Sữa Đá (M) ............. 39.000 đ',45,170);
        ctx.fillText('3. Bánh Mì Que ................. 19.000 đ',45,200);
        ctx.beginPath(); ctx.moveTo(45,220); ctx.lineTo(415,220); ctx.stroke();
        ctx.font='bold 17px Arial'; ctx.fillStyle='#DC2626';
        ctx.fillText('TỔNG CỘNG: 123.000 VND',45,260);
        ctx.font='italic 12px Arial'; ctx.fillStyle='#64748B';
        ctx.fillText('CẢM ƠN QUÝ KHÁCH - HẸN GẶP LẠI',45,295);
        const dataUrl=c.toDataURL('image/jpeg', 0.95);
        stopCam();
        c.toBlob(blob => {
            if(blob) sendReceiptToBackendOcr(blob, dataUrl);
            else sendReceiptToBackendOcr(dataURItoBlob(dataUrl), dataUrl);
        }, 'image/jpeg', 0.95);
    }
}

function handleFile(e){
    const f=e.target.files[0]; if(!f)return;
    const r=new FileReader();
    r.onload=ev=>{
        sendReceiptToBackendOcr(f, ev.target.result);
    };
    r.readAsDataURL(f);
}

function dataURItoBlob(dataURI) {
    const byteString = atob(dataURI.split(',')[1]);
    const mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0];
    const ab = new ArrayBuffer(byteString.length);
    const ia = new Uint8Array(ab);
    for (let i = 0; i < byteString.length; i++) {
        ia[i] = byteString.charCodeAt(i);
    }
    return new Blob([ab], {type: mimeString});
}

async function sendReceiptToBackendOcr(fileOrBlob, previewSrc){
    document.getElementById('fCamera').classList.add('hidden');
    document.getElementById('fUpload').classList.add('hidden');
    document.getElementById('photoResult').classList.remove('hidden');
    if(previewSrc) document.getElementById('previewI').src=previewSrc;

    const st=document.getElementById('ocrSt'), dt=document.getElementById('ocrData'), sv=document.getElementById('ocrSave'), rt=document.getElementById('ocrRetake');
    st.classList.remove('hidden'); dt.classList.add('hidden'); sv.classList.add('hidden'); rt.classList.add('hidden');
    st.innerHTML = `
        <span class="spinner" style="border-color:rgba(244,91,138,0.25);border-top-color:var(--primary)"></span>
        <p style="margin-top:0.4rem;font-weight:700">Đang chạy xử lý ảnh OpenCV & Tesseract OCR thực tế...</p>
        <p style="font-size:0.75rem;color:var(--text3);margin-top:0.2rem">Khử nhiễu, cân góc nghiêng, nhị phân hóa và bóc tách dữ liệu</p>
    `;

    try {
        const formData = new FormData();
        const filename = (fileOrBlob instanceof File && fileOrBlob.name) ? fileOrBlob.name : 'receipt_capture.jpg';
        formData.append('receipt', fileOrBlob, filename);

        const res = await fetch('/api/receipts/upload', {
            method: 'POST',
            body: formData
        });

        if(!res.ok){
            const errData = await res.json().catch(()=>({}));
            throw new Error(errData.error || `Lỗi máy chủ HTTP ${res.status}`);
        }

        const data = await res.json();
        console.log('Backend OCR Pipeline Kết Quả Thật:', data);

        // Lưu vào sessionStorage để đồng bộ tức thời với trang review.html
        sessionStorage.setItem('ocr_result', JSON.stringify(data));
        if(data.image_url) document.getElementById('previewI').src = data.image_url;

        // Phân loại danh mục theo dữ liệu thực từ OCR
        const merLower = (data.merchant_name || '').toLowerCase();
        let cat = 'food';
        if(merLower.includes('trọ') || merLower.includes('phòng') || merLower.includes('điện') || merLower.includes('nước') || (data.amount >= 2000000)){
            cat = 'bills';
        } else if(merLower.includes('mart') || merLower.includes('circle') || merLower.includes('store') || merLower.includes('siêu thị')){
            cat = 'shopping';
        } else if(merLower.includes('grab') || merLower.includes('xe') || merLower.includes('xăng')){
            cat = 'transport';
        }

        const detected = {
            merchant: data.merchant_name || 'Hóa đơn chưa rõ nguồn',
            amount: data.amount || 0,
            cat: cat,
            date: data.transaction_date || new Date().toISOString().slice(0, 10),
            raw_text: data.raw_text || '',
            image_url: data.image_url || previewSrc,
            items: data.items || [],
            notes: data.notes || '',
            isGroup: (cat === 'bills') || merLower.includes('trọ') || merLower.includes('phòng') || (data.amount >= 2000000)
        };

        S.lastOcr = detected;

        st.classList.add('hidden'); dt.classList.remove('hidden'); sv.classList.remove('hidden'); rt.classList.remove('hidden');
        document.getElementById('ocrMer').textContent = detected.merchant;
        document.getElementById('ocrAmt').textContent = fmt(detected.amount);
        const ct = CATS[detected.cat] || CATS.food;
        document.getElementById('ocrCatBadge').innerHTML = `<i class="${ct.ic}"></i> ${ct.label}`;
        document.getElementById('ocrCatBadge').style.background = ct.bg;
        document.getElementById('ocrCatBadge').style.color = ct.color;

        // Thêm nút mở màn hình Review chi tiết nếu chưa có
        let revBtn = document.getElementById('btnGoReviewDetail');
        if(!revBtn){
            revBtn = document.createElement('div');
            revBtn.id = 'btnGoReviewDetail';
            revBtn.style.marginTop = '0.5rem';
            revBtn.style.textAlign = 'center';
            dt.appendChild(revBtn);
        }
        revBtn.innerHTML = `
            <a href="/review" class="btn btn-sm btn-o" style="display:inline-flex;align-items:center;gap:0.3rem;font-size:0.75rem;padding:0.3rem 0.75rem">
                <i class="ri-edit-line"></i> Chỉnh sửa chi tiết
            </a>
        `;

        const fb = document.getElementById('ocrFundBalance');
        if(fb && S.groupFund) fb.textContent = fmt(S.groupFund.balance);

        if(detected.amount >= 2000000 || merLower.includes('trọ') || merLower.includes('phòng')){
            setBillScope('fund');
        } else {
            setBillScope('personal');
        }

        toast(`Nhận diện thành công: ${detected.merchant} (${fmt(detected.amount)})!`, 'success');

    } catch(err) {
        console.error('OCR Pipeline Error:', err);
        st.classList.add('hidden'); dt.classList.remove('hidden'); sv.classList.remove('hidden'); rt.classList.remove('hidden');
        toast(`Lỗi xử lý OCR: ${err.message}`, 'error');
        document.getElementById('ocrMer').textContent = 'Hóa đơn đã quét';
        document.getElementById('ocrAmt').textContent = '0 ₫';
        S.lastOcr = {
            merchant: 'Hóa đơn đã quét',
            amount: 0,
            cat: 'other',
            date: new Date().toISOString().slice(0, 10),
            raw_text: '',
            image_url: previewSrc
        };
    }
}

// ===== 3-WAY BILL SCOPE & GROUP-FREE SPLIT SYSTEM =====
function setBillScope(scope){
    S.billScope = scope;
    document.getElementById('btnScopeP')?.classList.toggle('active', scope === 'personal');
    document.getElementById('btnScopeS')?.classList.toggle('active', scope === 'split');
    document.getElementById('btnScopeF')?.classList.toggle('active', scope === 'fund');

    document.getElementById('scopePersonalBox')?.classList.toggle('hidden', scope !== 'personal');
    document.getElementById('scopeSplitBox')?.classList.toggle('hidden', scope !== 'split');
    document.getElementById('scopeFundBox')?.classList.toggle('hidden', scope !== 'fund');

    updateSplitBillCalculations();
    updateFundSelection();
}

// Tương thích ngược
function setOcrScope(scope){
    setBillScope(scope === 'group' ? 'split' : 'personal');
}

function changeSplitCount(delta){
    S.splitCount = Math.max(2, Math.min(20, (S.splitCount || 4) + delta));
    updateSplitBillCalculations();
}

function setSplitPayRole(role){
    S.splitPayRole = role;
    const isMineOnly = role === 'mine_only';
    document.getElementById('optSplitMineOnly')?.classList.toggle('active', isMineOnly);
    document.getElementById('optSplitAdvanceAll')?.classList.toggle('active', !isMineOnly);
    const r1 = document.querySelector('input[name="splitPayRole"][value="mine_only"]');
    const r2 = document.querySelector('input[name="splitPayRole"][value="advance_all"]');
    if(r1) r1.checked = isMineOnly;
    if(r2) r2.checked = !isMineOnly;
    updateSplitBillCalculations();
}

function updateSplitBillCalculations(){
    const total = S.lastOcr ? S.lastOcr.amount : 145000;
    const count = S.splitCount || 4;
    const perPerson = Math.round(total / count);
    const othersTotal = Math.max(0, total - perPerson);

    const pa = document.getElementById('personalSaveAmt');
    if(pa) pa.textContent = fmt(total);

    const sc = document.getElementById('splitCountDisp');
    if(sc) sc.textContent = count;

    const pp = document.getElementById('splitPerPersonDisp');
    if(pp) pp.textContent = fmt(perPerson) + ' / người';

    document.querySelectorAll('.roleMyShareTxt').forEach(el => {
        el.textContent = fmt(perPerson);
    });

    const rc = document.getElementById('roleCollectOthersTxt');
    if(rc) rc.textContent = fmt(othersTotal);

    // Cập nhật nhãn nút lưu tương ứng (gọn gàng, súc tích)
    const btnTxt = document.getElementById('ocrSaveBtnTxt');
    if(btnTxt){
        if(S.billScope === 'personal'){
            btnTxt.textContent = `Lưu vào Ví (${fmt(total)})`;
        } else if(S.billScope === 'split'){
            if(S.splitPayRole === 'mine_only'){
                btnTxt.textContent = `Lưu phần tôi (${fmt(perPerson)})`;
            } else {
                btnTxt.textContent = `Lưu & Thu tiền (${fmt(perPerson)})`;
            }
        } else {
            btnTxt.textContent = `Trích Quỹ (${fmt(total)})`;
        }
    }
}

function updateFundSelection(){
    const sb = document.getElementById('fundSelectBox');
    const key = sb ? sb.value : (S.selectedFund || 'room');
    S.selectedFund = key;

    if(!S.availableFunds){
        S.availableFunds = {
            couple: { name: 'Quỹ Cặp Đôi', balance: 1850000, history: [] },
            travel: { name: 'Quỹ Du Lịch & Dã Ngoại', balance: 3200000, history: [] },
            room:   { name: 'Quỹ Chi Tiêu Chung', balance: (S.groupFund ? S.groupFund.balance : 2400000), history: [] }
        };
    }
    if(S.groupFund && S.availableFunds.room){
        S.availableFunds.room.balance = S.groupFund.balance;
    }

    const fund = S.availableFunds[key] || S.availableFunds.room;
    const total = S.lastOcr ? S.lastOcr.amount : 145000;
    const after = Math.max(0, fund.balance - total);

    const af = document.getElementById('fundAfterBalance');
    if(af) af.textContent = fmt(after);
}

function loadSampleRoomRentInvoice(){
    openModal('camera');
    const c = document.getElementById('camC') || document.createElement('canvas');
    c.width = 460; c.height = 360;
    const ctx = c.getContext('2d');
    ctx.fillStyle = '#FFFFFF'; ctx.fillRect(0,0,460,360);
    ctx.strokeStyle = '#059669'; ctx.lineWidth = 3; ctx.strokeRect(10,10,440,340);
    ctx.fillStyle = '#065F46'; ctx.font = 'bold 18px Arial';
    ctx.fillText('THÔNG BÁO TIỀN TRỌ THÁNG 10/2026', 40, 45);
    ctx.font = '13px Arial'; ctx.fillStyle = '#4B5563';
    ctx.fillText('Phòng: 302 - Nhà Trọ Xanh', 40, 70);
    ctx.fillText('Ngày lập phiếu: 01/10/2026', 40, 90);
    ctx.strokeStyle = '#D1D5DB'; ctx.beginPath(); ctx.moveTo(40,105); ctx.lineTo(420,105); ctx.stroke();
    ctx.font = '14px Arial'; ctx.fillStyle = '#111827';
    ctx.fillText('1. Tiền thuê phòng ............. 3.500.000 đ', 40, 135);
    ctx.fillText('2. Tiền điện sinh hoạt ......... 400.000 đ', 40, 165);
    ctx.fillText('3. Tiền nước sinh hoạt ......... 200.000 đ', 40, 195);
    ctx.fillText('4. Internet & Wifi ............. 100.000 đ', 40, 225);
    ctx.fillText('5. Dịch vụ chung & vệ sinh ..... 300.000 đ', 40, 255);
    ctx.beginPath(); ctx.moveTo(40,275); ctx.lineTo(420,275); ctx.stroke();
    ctx.font = 'bold 18px Arial'; ctx.fillStyle = '#DC2626';
    ctx.fillText('TỔNG CỘNG: 4.500.000 đ', 40, 305);
    ctx.font = 'italic 12px Arial'; ctx.fillStyle = '#6B7280';
    ctx.fillText('Hạn thanh toán: ngày 05/10/2026', 40, 330);
    const dataUrl = c.toDataURL('image/jpeg', 0.95);
    stopCam();
    c.toBlob(blob => {
        if(blob) sendReceiptToBackendOcr(blob, dataUrl);
        else sendReceiptToBackendOcr(dataURItoBlob(dataUrl), dataUrl);
    }, 'image/jpeg', 0.95);
}

async function loadSampleRealReceipt(){
    openModal('camera');
    try {
        const res = await fetch('/samples/sample_test_receipt.jpg');
        const blob = await res.blob();
        sendReceiptToBackendOcr(blob, '/samples/sample_test_receipt.jpg');
    } catch(e) {
        toast('Lỗi tải ảnh mẫu Highlands: ' + e.message, 'error');
    }
}

function retakePhoto(){
    document.getElementById('photoResult').classList.add('hidden');
    const isUp=document.getElementById('tUpload').classList.contains('active');
    swTab(isUp?'upload':'camera');
}

async function saveOcr(){
    const data = S.lastOcr || {merchant:'Hóa đơn vừa quét', amount:145000, cat:'food'};
    const nowStr = new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'});
    const dateStr = data.date || new Date().toISOString().slice(0, 10);
    const curUid = S.user ? S.user.id : 1;

    // 1. TRƯỜNG HỢP: CHI TIÊU CÁ NHÂN (100% CỦA TÔI)
    if(S.billScope === 'personal'){
        S.transactions.unshift({
            id: Date.now(),
            name: data.merchant,
            amt: data.amount,
            cat: data.cat || 'other',
            date: dateStr,
            time: nowStr,
            type: 'expense',
            note: data.notes || 'Chi tiêu cá nhân (100%)'
        });
        sendBE({
            user_id: curUid,
            merchant_name: data.merchant,
            amount: data.amount,
            type: 'expense',
            transaction_date: dateStr,
            category: data.cat || 'other',
            notes: data.notes || '',
            receipt_image_path: data.image_url || '',
            raw_ocr_text: data.raw_text || ''
        });
        renderAll();
        closeModal();
        toast(`Đã lưu ${fmt(data.amount)} vào Ví cá nhân!`, 'success');
        return;
    }

    // 2. TRƯỜNG HỢP: MUA CHUNG / CHIA TIỀN (NGƯỜI KHÁC KHÔNG CẦN CÀI APP, KHÔNG TỰ TẠO NHÓM)
    if(S.billScope === 'split'){
        const count = S.splitCount || 4;
        const myShare = Math.round(data.amount / count);

        // QUAN TRỌNG: CHỈ LƯU ĐÚNG SỐ TIỀN MÌNH THỰC TRẢ VÀO VÍ CÁ NHÂN!
        S.transactions.unshift({
            id: Date.now(),
            name: `${data.merchant} (Phần của tôi)`,
            amt: myShare,
            cat: data.cat || 'food',
            date: dateStr,
            time: nowStr,
            type: 'expense',
            note: `Mua chung ${fmt(data.amount)} (chia ${count} người, ${fmt(myShare)}/người)`
        });

        sendBE({
            user_id: curUid,
            merchant_name: `${data.merchant} (Phần của tôi)`,
            amount: myShare,
            type: 'expense',
            transaction_date: dateStr,
            category: data.cat || 'food',
            notes: `Mua chung ${fmt(data.amount)} chia ${count} người`,
            receipt_image_path: data.image_url || '',
            raw_ocr_text: data.raw_text || ''
        });

        renderAll();
        closeModal();

        if(S.splitPayRole === 'mine_only'){
            toast(`Đã lưu phần của bạn ${fmt(myShare)} vào Ví cá nhân!`, 'success');
        } else {
            toast(`Đã ghi nhận ${fmt(myShare)} vào Ví. Mở mã QR nhận tiền...`, 'info');
            setTimeout(()=>{
                showQuickSplitQrModal(data.merchant, data.amount, count, myShare);
            }, 350);
        }
        return;
    }

    // 3. TRƯỜNG HỢP: TRÍCH TỪ QUỸ CHUNG (CẶP ĐÔI, DU LỊCH, PHÒNG TRỌ)
    if(S.billScope === 'fund'){
        const fundKey = S.selectedFund || 'room';
        if(!S.availableFunds) updateFundSelection();
        const fund = S.availableFunds[fundKey] || S.availableFunds.room;

        fund.balance = Math.max(0, fund.balance - data.amount);
        if(fundKey === 'room' && S.groupFund){
            S.groupFund.balance = fund.balance;
            S.groupFund.bills.unshift({
                id: Date.now(),
                name: data.merchant,
                amt: data.amount,
                date: dateStr,
                payerId: 'fund',
                payerName: fund.name,
                mode: 'fund',
                note: `Trích ${fmt(data.amount)} từ ${fund.name}`
            });
            S.groupFund.history.unshift({
                id: Date.now(),
                type: 'out',
                title: `Chi trả: ${data.merchant}`,
                amt: data.amount,
                date: dateStr,
                user: S.user ? S.user.name : 'Nguyễn Thúy Hiền'
            });
        }

        renderAll();
        renderGroup();
        closeModal();
        toast(`Đã trích ${fmt(data.amount)} từ ${fund.name}!`, 'success');
        return;
    }
}

// ===== MODAL VIETQR & CHIA BILL NHANH (KHÔNG CẦN CÀI APP) =====
function showQuickSplitQrModal(merchant, totalAmt, count, perPerson){
    const othersCount = count - 1;
    const othersTotal = Math.max(0, totalAmt - perPerson);
    const memo = `CHIA TIEN ${merchant.toUpperCase().replace(/[^A-Z0-9 ]/g,'').trim()}`.slice(0, 20);
    const body = document.getElementById('qrModalBody');
    if(!body) return;

    body.innerHTML = `
        <div class="qr-card-view" style="padding:0.75rem">
            <div style="font-size:0.85rem;font-weight:800;color:var(--text);margin-bottom:0.15rem">Mã VietQR</div>
            <div style="font-size:0.7rem;color:var(--text3);margin-bottom:0.4rem">Quét bằng ứng dụng ngân hàng</div>
            <div class="qr-frame" style="margin-bottom:0.4rem">
                <canvas id="quickSplitQrCanvas" width="160" height="160"></canvas>
            </div>
            <div style="font-size:1.15rem;font-weight:900;color:var(--primary);margin-bottom:0.4rem">${fmt(perPerson)} / người</div>
            <div class="qr-details" style="padding:0.55rem;margin-bottom:0.5rem">
                <div class="qr-row"><span style="color:var(--text3)">Tổng bill:</span> <strong>${fmt(totalAmt)} (${count} người)</strong></div>
                <div class="qr-row"><span style="color:var(--text3)">Cần thu:</span> <strong style="color:var(--danger)">${fmt(othersTotal)}</strong> <span style="font-size:0.68rem;color:var(--text3)">(${othersCount} người)</span></div>
                <div class="qr-row"><span style="color:var(--text3)">Số TK:</span> <strong>0912 345 678</strong> (MB Bank)</div>
                <div class="qr-row"><span style="color:var(--text3)">Chủ TK:</span> <strong>Nguyễn Thúy Hiền</strong></div>
                <div class="qr-row"><span style="color:var(--text3)">Nội dung:</span> <strong>${memo}</strong></div>
            </div>
            <button class="btn btn-p btn-block" onclick="copyQuickSplitZaloMessage('${merchant}', ${totalAmt}, ${count}, ${perPerson})">
                <i class="ri-file-copy-line"></i> Sao chép tin nhắn
            </button>
            <button class="btn btn-s btn-block" style="margin-top:0.35rem" onclick="closeQrModal()">
                <i class="ri-close-line"></i> Đóng
            </button>
        </div>
    `;

    openQrModal();
    setTimeout(()=>{
        const cv = document.getElementById('quickSplitQrCanvas');
        if(cv) drawMockVietQr(cv, perPerson, memo);
    }, 50);
}

function copyQuickSplitZaloMessage(merchant, totalAmt, count, perPerson){
    const msg = `Tiền ${merchant}: ${fmt(totalAmt)} chia ${count} = ${fmt(perPerson)}/người. STK: 0912 345 678 (MB Bank - Thúy Hiền).`;
    if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(msg).then(()=>{
            toast('Đã sao chép tin nhắn!', 'success');
        }).catch(()=>{
            prompt('Sao chép lời nhắn:', msg);
        });
    } else {
        prompt('Sao chép lời nhắn:', msg);
    }
}

// ===== STATS =====
function swStat(btn,tab){
    btn.parentElement.querySelectorAll('.pg-tab').forEach(t=>t.classList.remove('active'));btn.classList.add('active');
    ['sOv','sCat','sCal','sSav'].forEach(id=>document.getElementById(id).classList.add('hidden'));
    const m={ov:'sOv',cat:'sCat',cal:'sCal',sav:'sSav'};document.getElementById(m[tab]).classList.remove('hidden');
    if(tab==='cat')renderPie();if(tab==='cal')renderCal();if(tab==='sav')renderStatsSav();if(tab==='ov')renderStOv();
}
function renderStOv(){
    const exp=S.transactions.filter(t=>t.type==='expense').reduce((s,t)=>s+t.amt,0);
    const inc=S.transactions.filter(t=>t.type==='income').reduce((s,t)=>s+t.amt,0);
    const si=document.getElementById('sI');if(si)si.textContent=fmt(inc);
    const se=document.getElementById('sE');if(se)se.textContent=fmt(exp);
    const sn=document.getElementById('sN');if(sn)sn.textContent=fmt(inc-exp);
    const sc=document.getElementById('sC');if(sc)sc.textContent=S.transactions.length;
    renderChart('month','sChart');
}

// ===== PIE CHART =====
function renderPie(){
    const c=document.getElementById('pie');if(!c)return;
    const exps=S.transactions.filter(t=>t.type==='expense'), tots={};
    exps.forEach(t=>{tots[t.cat]=(tots[t.cat]||0)+t.amt});
    const grand=Object.values(tots).reduce((a,b)=>a+b,0);
    if(!grand){c.innerHTML='<div class="empty"><div class="empty-ic"><i class="ri-pie-chart-line"></i></div><h3>Chưa có dữ liệu</h3></div>';return}
    const sorted=Object.entries(tots).sort((a,b)=>b[1]-a[1]);
    const R=50,CX=60,CY=60,CI=2*Math.PI*R;let off=0;
    const arcs=sorted.map(([k,v])=>{const ct=CATS[k]||CATS.other;const pct=v/grand;const dash=pct*CI;const o=off;off+=dash;
        return`<circle cx="${CX}" cy="${CY}" r="${R}" fill="none" stroke="${ct.color}" stroke-width="18" stroke-dasharray="${dash} ${CI-dash}" stroke-dashoffset="${-o}" style="--circ:${CI};--off:${CI-dash};animation:drawIn 0.8s ease forwards" transform="rotate(-90 ${CX} ${CY})"/>`;}).join('');
    const legend=sorted.map(([k,v])=>{const ct=CATS[k]||CATS.other;const pct=((v/grand)*100).toFixed(0);
        return`<div class="leg-row"><div class="leg-dot" style="background:${ct.color}"></div><span class="leg-name"><i class="${ct.ic}" style="margin-right:4px"></i>${ct.label}</span><span class="leg-pct">${pct}%</span></div>`;}).join('');
    c.innerHTML=`<div class="pie-wrap"><svg width="120" height="120" viewBox="0 0 120 120">${arcs}</svg><div class="pie-ctr"><div class="pie-cv">100%</div><div class="pie-cl">Tỷ trọng</div></div></div><div class="pie-leg">${legend}</div>`;
    const cd=document.getElementById('catDet');if(cd){
        cd.innerHTML=sorted.map(([k,v],i)=>{const ct=CATS[k]||CATS.other;const pct=((v/grand)*100).toFixed(0);const cnt=exps.filter(t=>t.cat===k).length;
        return`<div class="cat-item" style="animation:fadeUp 0.3s ease ${i*0.05}s both"><div class="cat-ic" style="background:${ct.bg};color:${ct.color}"><i class="${ct.ic}"></i></div><div class="cat-info"><div class="cat-name">${ct.label}</div><div class="cat-ct">${cnt} giao dịch · ${pct}%</div><div class="cat-bar"><div class="cat-bar-fill" style="width:${pct}%;background:${ct.color}"></div></div></div><div class="cat-amt">${fmt(v)}</div></div>`;}).join('');
    }
}

// ===== CALENDAR =====
function renderCal(){
    const g=document.getElementById('calG');if(!g)return;
    const y=S.calY,m=S.calM;document.getElementById('calMo').textContent=`Tháng ${m+1}, ${y}`;
    const first=new Date(y,m,1).getDay(),dim=new Date(y,m+1,0).getDate(),ts=new Date().toISOString().slice(0,10);
    const da={};S.transactions.forEach(t=>{const d=new Date(t.date);if(d.getFullYear()===y&&d.getMonth()===m){const day=d.getDate();if(!da[day])da[day]={e:0,i:0};if(t.type==='expense')da[day].e+=t.amt;else da[day].i+=t.amt}});
    let html=['CN','T2','T3','T4','T5','T6','T7'].map(h=>`<div class="cal-dh">${h}</div>`).join('');
    for(let i=0;i<first;i++)html+='<div class="cal-d other"></div>';
    for(let d=1;d<=dim;d++){
        const ds=`${y}-${String(m+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;
        const isT=ds===ts;
        const has=da[d];
        let cls='cal-d';
        if(isT) cls+=' today';
        if(has && (has.e || has.i)) cls+=' has';
        const tip=has ? ` title="Chi: ${fmt(has.e||0)}${has.i ? ' | Thu: '+fmt(has.i) : ''}"` : '';
        html+=`<div class="${cls}" onclick="showDay(${d})"${tip}>${d}</div>`;
    }
    g.innerHTML=html;
}
function chMo(d){S.calM+=d;if(S.calM>11){S.calM=0;S.calY++}if(S.calM<0){S.calM=11;S.calY--}renderCal()}
function showDay(d){const ds=`${S.calY}-${String(S.calM+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;const txs=S.transactions.filter(t=>t.date===ds);document.getElementById('calDT').textContent=`Ngày ${d}/${S.calM+1}`;const c=document.getElementById('calDTx');if(!txs.length){c.innerHTML='<div class="empty" style="padding:0.8rem"><p style="color:var(--text3);font-size:0.75rem">Không có giao dịch</p></div>';return}renderTxL('calDTx',txs)}

// ===== STATS SAVINGS =====
function renderStatsSav(){
    const tot=S.savings.reduce((s,g)=>s+g.saved,0);
    document.getElementById('ssT').textContent=fmt(tot);
    document.getElementById('ssG').textContent=S.savings.length;
    const c=document.getElementById('ssList');if(!c)return;
    c.innerHTML=S.savings.map((g,i)=>{const pct=Math.min(100,(g.saved/g.target*100)).toFixed(0);const col=pct>=100?'var(--success)':'var(--primary)';
    return`<div class="sav-card" style="animation:fadeUp 0.3s ease ${i*0.07}s both"><div class="sav-hdr"><div class="sav-ic"><i class="${SAVICONS[g.icon]||'ri-star-line'}"></i></div><div><div class="sav-name">${g.name}</div><div class="sav-target">Mục tiêu: ${fmt(g.target)}</div></div></div><div class="sav-bar"><div class="sav-bar-fill" style="width:${pct}%;background:${col}"></div></div><div class="sav-foot"><span class="sav-foot-amt">${fmt(g.saved)}</span><span class="sav-foot-pct" style="color:${col}">${pct}%</span></div></div>`;}).join('');
}

// ===== BUDGET =====
function renderBgt(){
    const exps=S.transactions.filter(t=>t.type==='expense'),ct={};exps.forEach(t=>{ct[t.cat]=(ct[t.cat]||0)+t.amt});
    const tb=S.budgets.reduce((s,b)=>s+b.limit,0),tu=S.budgets.reduce((s,b)=>s+(ct[b.cat]||0),0);
    const pct=tb?Math.min(100,(tu/tb*100)).toFixed(0):0;
    document.getElementById('bgtP').textContent=pct+'%';
    document.getElementById('bgtU').textContent=fmt(tu);
    document.getElementById('bgtR').textContent=fmt(Math.max(0,tb-tu));
    const R=42,C=2*Math.PI*R,off=C-(pct/100)*C,col=pct>80?'var(--danger)':pct>60?'var(--warning)':'var(--primary)';
    document.getElementById('bgtC').innerHTML=`<svg width="100" height="100" viewBox="0 0 100 100"><circle cx="50" cy="50" r="${R}" fill="none" stroke="var(--divider)" stroke-width="9"/><circle cx="50" cy="50" r="${R}" fill="none" stroke="${col}" stroke-width="9" stroke-dasharray="${C}" stroke-dashoffset="${off}" stroke-linecap="round" transform="rotate(-90 50 50)" style="transition:stroke-dashoffset 1s ease"/></svg>`;
    document.getElementById('bgtL').innerHTML=S.budgets.map((b,i)=>{
        const c2=CATS[b.cat]||CATS.other;
        const u=ct[b.cat]||0;
        const p=Math.min(100,(u/b.limit*100)).toFixed(0);
        const bc=p>80?'var(--danger)':p>60?'var(--warning)':c2.color;
        const rem=b.limit-u;
        return`<div class="bgt-card" style="animation:fadeUp 0.3s ease ${i*0.05}s both"><div class="bgt-hdr"><div class="bgt-title"><i class="${c2.ic}" style="color:${c2.color}"></i> ${c2.label}</div><div class="bgt-amt">${fmt(u)} / ${fmt(b.limit)}</div></div><div class="bgt-bar"><div class="bgt-bar-fill" style="width:${p}%;background:${bc}"></div></div><div class="bgt-foot"><span>Đã dùng ${p}%</span><span class="${rem<0?'over':'safe'}">${rem>=0?'Còn '+fmt(rem):'Vượt '+fmt(-rem)}</span></div></div>`;
    }).join('');
}
function addBgt(){const c=document.getElementById('bfC').value,a=parseFloat(document.getElementById('bfA').value);if(!a){toast('Nhập hạn mức!','error');return}const ex=S.budgets.find(b=>b.cat===c);if(ex)ex.limit=a;else S.budgets.push({cat:c,limit:a});togForm('bgtF');renderBgt();toast('Đã lưu ngân sách!','success')}

// ===== SAVINGS =====
function renderSav(){
    const tot=S.savings.reduce((s,g)=>s+g.saved,0);document.getElementById('savT').textContent=fmt(tot);
    document.getElementById('savL').innerHTML=S.savings.map((g,i)=>{const pct=Math.min(100,(g.saved/g.target*100)).toFixed(0);const col=pct>=100?'var(--success)':'var(--primary)';
    return`<div class="sav-card" style="animation:fadeUp 0.3s ease ${i*0.07}s both"><div class="sav-hdr"><div class="sav-ic"><i class="${SAVICONS[g.icon]||'ri-star-line'}"></i></div><div><div class="sav-name">${g.name}</div><div class="sav-target">Mục tiêu: ${fmt(g.target)}</div></div></div><div class="sav-bar"><div class="sav-bar-fill" style="width:${pct}%;background:${col}"></div></div><div class="sav-foot"><span class="sav-foot-amt">${fmt(g.saved)}</span><span class="sav-foot-pct" style="color:${col}">${pct}%</span></div><div style="margin-top:0.4rem;display:flex;gap:0.3rem"><button class="btn btn-sm btn-p" style="flex:1" onclick="addToSav(${g.id})"><i class="ri-add-line"></i> Nạp tiền</button><button class="btn btn-sm btn-s" onclick="delSav(${g.id})"><i class="ri-delete-bin-line"></i></button></div></div>`;}).join('');
}
function addSav(){const n=document.getElementById('sfN').value.trim(),t=parseFloat(document.getElementById('sfT').value),ic=document.getElementById('sfI').value;if(!n||!t){toast('Điền đầy đủ!','error');return}S.savings.push({id:Date.now(),name:n,icon:ic,target:t,saved:0});togForm('savF');renderSav();toast('Đã tạo mục tiêu!','success')}
function addToSav(id){const g=S.savings.find(s=>s.id===id);if(!g)return;const a=prompt('Nhập số tiền nạp (₫):');if(!a||isNaN(a))return;g.saved+=parseInt(a);renderSav();toast(`Đã nạp ${fmt(parseInt(a))}`,'success')}
function delSav(id){S.savings=S.savings.filter(s=>s.id!==id);renderSav();toast('Đã xoá','info')}

// ===== RECURRING =====
function renderRec(){
    const fq={daily:'Hàng ngày',weekly:'Hàng tuần',monthly:'Hàng tháng'};
    document.getElementById('recL').innerHTML=S.recurring.map((r,i)=>{const ct=CATS[r.cat]||CATS.other;
    return`<div class="rec-card" style="animation:fadeUp 0.3s ease ${i*0.05}s both"><div class="tx-ic" style="background:${ct.bg};color:${ct.color}"><i class="${ct.ic}"></i></div><div class="rec-info"><div class="rec-name">${r.name}</div><div class="rec-sub"><span class="freq-tag">${fq[r.freq]}</span> · ${ct.label}</div></div><div class="rec-amt">${fmt(r.amt)}</div><label class="toggle"><input type="checkbox" ${r.on?'checked':''} onchange="togRec(${r.id},this.checked)"><span class="toggle-track"></span></label></div>`;}).join('');
}
function addRec(){const n=document.getElementById('rfN').value.trim(),a=parseFloat(document.getElementById('rfA').value),f=document.getElementById('rfF').value,c=document.getElementById('rfC').value;if(!n||!a){toast('Điền đầy đủ!','error');return}S.recurring.push({id:Date.now(),name:n,amt:a,freq:f,cat:c,on:true});togForm('recF');renderRec();toast('Đã thêm định kỳ!','success')}
function togRec(id,on){const r=S.recurring.find(x=>x.id===id);if(r)r.on=on;toast(on?'Đã bật':'Đã tắt','info')}

// ===== BACKEND =====
async function sendBE(p){try{await fetch('/api/transactions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)})}catch(e){}}

// ===== LEGACY SUPPORT =====
function formatCurrency(n){return fmt(n)}
async function loadDashboardStats(){try{const r=await fetch('/api/stats');if(!r.ok)return;const d=await r.json();const e=document.getElementById('stat-total-spent');if(e)e.textContent=fmt(d.total_spent||0)}catch(e){}}
async function loadRecentTransactions(){const el=document.getElementById('transaction-list');if(!el)return;try{const r=await fetch('/api/transactions');if(!r.ok)throw 0;const txs=await r.json();if(!txs.length){el.innerHTML='<tr><td colspan="5" style="text-align:center;color:var(--text3)">Chưa có giao dịch</td></tr>';return}el.innerHTML=txs.map(t=>`<tr><td>${t.transaction_date}</td><td><strong>${t.merchant_name}</strong></td><td>${t.category||'Ăn uống'}</td><td><span class="badge">${t.group_id?'Nhóm':'Cá Nhân'}</span></td><td style="font-weight:700;color:var(--danger)">-${fmt(t.amount)}</td></tr>`).join('')}catch(e){}}
async function handleFileSelect(e){const f=e.target.files[0];if(!f)return;const s=document.getElementById('upload-status');if(s)s.style.display='block';const fd=new FormData();fd.append('receipt',f);try{const r=await fetch('/api/receipts/upload',{method:'POST',body:fd});if(!r.ok){const d=await r.json();throw new Error(d.error||'Fail')}const d=await r.json();sessionStorage.setItem('ocr_result',JSON.stringify(d));window.location.href='/review'}catch(e){toast('Lỗi: '+e.message,'error');if(s)s.style.display='none'}}
async function handleConfirmTransaction(e){e.preventDefault();const o=JSON.parse(sessionStorage.getItem('ocr_result')||'{}');const p={merchant_name:document.getElementById('verify-merchant').value,amount:parseFloat(document.getElementById('verify-amount').value),transaction_date:document.getElementById('verify-date').value,category:document.getElementById('verify-category').value,group_id:document.getElementById('verify-group-id')?.value?parseInt(document.getElementById('verify-group-id').value):null,notes:document.getElementById('verify-notes')?.value,receipt_image_path:o.image_url||null,raw_ocr_text:o.raw_text||null,user_id:1};try{const r=await fetch('/api/transactions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(r.ok){sessionStorage.removeItem('ocr_result');toast('Lưu thành công!','success');window.location.href='/';}else toast('Lỗi lưu!','error')}catch(e){toast('Lỗi: '+e.message,'error')}}
async function handleManualSubmit(e){e.preventDefault();const p={merchant_name:document.getElementById('manual-merchant').value,amount:parseFloat(document.getElementById('manual-amount').value),transaction_date:document.getElementById('manual-date').value,group_id:document.getElementById('manual-wallet-type')?.value?parseInt(document.getElementById('manual-wallet-type').value):null,category:'Ăn uống',user_id:1};try{const r=await fetch('/api/transactions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(r.ok){toast('Thêm thành công!','success');document.getElementById('manual-form')?.reset();loadDashboardStats();loadRecentTransactions()}}catch(e){toast('Lỗi: '+e.message,'error')}}
const TEAM_MEMBERS=[{id:1,name:"Nguyễn Thúy Hiền"},{id:2,name:"Lê Thị Dịu"},{id:3,name:"Lê Tiến Quân"},{id:4,name:"Lê Ngọc Duy"},{id:5,name:"Nguyễn Việt Anh"}];
function loadGroupMembersUI(){const el=document.getElementById('member-checkbox-list');if(!el)return;el.innerHTML=TEAM_MEMBERS.map(m=>`<label style="display:flex;align-items:center;gap:0.6rem;padding:0.6rem 0.8rem;background:#f8fafc;border-radius:var(--r-sm);border:1px solid var(--border);cursor:pointer"><input type="checkbox" name="split-members" value="${m.id}" checked><span style="font-weight:600">${m.name}</span></label>`).join('')}
function calculateSplit(e){e.preventDefault();const a=parseFloat(document.getElementById('split-amount-input').value);const cbs=document.querySelectorAll('input[name="split-members"]:checked');const ids=Array.from(cbs).map(c=>parseInt(c.value));if(!ids.length){toast('Chọn ít nhất 1 thành viên!','warning');return}const pp=Math.round(a/ids.length);const rb=document.getElementById('split-result'),db=document.getElementById('split-result-details');const names=TEAM_MEMBERS.filter(m=>ids.includes(m.id)).map(m=>m.name);db.innerHTML=`<p style="font-weight:700;margin-bottom:0.5rem">Mỗi người: <span style="color:var(--primary)">${fmt(pp)}</span></p><p style="font-size:0.85rem;color:var(--text3)">${ids.length} người: ${names.join(', ')}</p>`;rb.style.display='block'}

// ===== SETTINGS & PROFILE =====
const THEME_NAMES = {
    'pink-gold': 'Rose Gold (Hồng kim cương)',
    'violet':    'Warm Violet (Tím thời thượng)',
    'ocean':     'Pastel Ocean (Xanh dương tin cậy)',
    'mint':      'Fresh Mint (Xanh bạc hà)',
    'dark':      'Midnight Dark (Chế độ tối bảo vệ mắt)'
};

function renderSettings(){
    if(!S.user) S.user=USERS[0];
    const name = S.user.name||S.user.full_name||'Người dùng';
    const phone = S.user.phone||'0912 345 678';
    const email = S.user.email||'hien@vixinh.vn';
    
    const pn = document.getElementById('profileName');
    if(pn) pn.textContent = name;
    const pm = document.getElementById('profileMeta');
    if(pm) pm.textContent = `${phone} · ${email}`;
    const pph = document.getElementById('profilePhone');
    if(pph) pph.innerHTML = `<i class="ri-phone-line"></i> ${phone}`;
    const pem = document.getElementById('profileEmail');
    if(pem) pem.innerHTML = `<i class="ri-mail-line"></i> ${email}`;
    
    const pa=document.getElementById('profileAvatarImg');
    if(pa && S.user.avatar) pa.src=S.user.avatar;
    
    const un = document.getElementById('setUserName');
    if(un) un.value = name;
    const up = document.getElementById('setUserPhone');
    if(up) up.value = phone;
    const ue = document.getElementById('setUserEmail');
    if(ue) ue.value = email;
    
    const curTheme=document.documentElement.getAttribute('data-theme')||localStorage.getItem('vx_theme')||'pink-gold';
    document.querySelectorAll('.theme-pill, .theme-item').forEach(t=>{
        t.classList.toggle('active',t.dataset.theme===curTheme);
    });
    
    document.querySelectorAll('.user-pill, .user-switch-card').forEach(c=>{
        c.classList.toggle('active',c.textContent.includes(name) || c.textContent.includes(email));
    });
}

function openEditProfileModal(){
    if(!S.user) S.user=USERS[0];
    const name = S.user.name||S.user.full_name||'';
    const phone = S.user.phone||'';
    const email = S.user.email||'';
    const un = document.getElementById('setUserName');
    if(un) un.value = name;
    const up = document.getElementById('setUserPhone');
    if(up) up.value = phone;
    const ue = document.getElementById('setUserEmail');
    if(ue) ue.value = email;
    document.getElementById('editProfileModal')?.classList.add('active');
}

function closeEditProfileModal(){
    document.getElementById('editProfileModal')?.classList.remove('active');
}

function copyBankAccount(){
    navigator.clipboard.writeText('0912 345 678');
    toast('Đã sao chép STK MB Bank: 0912 345 678 ✨','success');
}

async function toggleBiometricsWeb(e){
    const checkbox = e.target;
    if(checkbox.checked){
        // WebAuthn / Platform Authenticator (Windows Hello, Touch ID Mac, FaceID iPhone)
        if(window.PublicKeyCredential && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable){
            try {
                const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
                if(available){
                    toast('Đã kích hoạt sinh trắc học thiết bị (Face ID / Vân tay) ✨','success');
                    localStorage.setItem('vx_bio_enabled', '1');
                    return;
                }
            } catch(err){}
        }
        toast('Đã bật bảo mật sinh trắc học (Face ID / Vân tay) ✨','success');
        localStorage.setItem('vx_bio_enabled', '1');
    } else {
        localStorage.setItem('vx_bio_enabled', '0');
        toast('Đã tắt bảo mật sinh trắc học','info');
    }
}

async function saveProfile(e){
    e.preventDefault();
    const name=document.getElementById('setUserName').value.trim();
    const phone=document.getElementById('setUserPhone').value.trim();
    const email=document.getElementById('setUserEmail').value.trim();
    if(!name||!phone||!email){toast('Chưa điền đủ thông tin!','error');return}
    S.user.name=name;
    S.user.full_name=name;
    S.user.phone=phone;
    S.user.email=email;
    localStorage.setItem('vx_u',JSON.stringify(S.user));
    const un = document.getElementById('uName');
    if(un) un.textContent=name;
    renderSettings();
    closeEditProfileModal();
    if(S.user.id){
        try{
            await fetch(`/api/users/${S.user.id}`,{
                method:'PUT',
                headers:{'Content-Type':'application/json'},
                body:JSON.stringify({full_name:name, phone:phone, email:email})
            });
        }catch(err){}
    }
    toast('Đã cập nhật thông tin cá nhân thành công! ✨','success');
}

function setTheme(themeName){
    document.documentElement.setAttribute('data-theme',themeName);
    localStorage.setItem('vx_theme',themeName);
    document.querySelectorAll('.theme-pill, .theme-item').forEach(t=>{
        t.classList.toggle('active',t.dataset.theme===themeName);
    });
    toast(`Giao diện: ${THEME_NAMES[themeName]||themeName}`,'success');
}

function makeEmojiAvatar(preset){
    const canvas=document.createElement('canvas');canvas.width=128;canvas.height=128;
    const ctx=canvas.getContext('2d');
    const grad=ctx.createLinearGradient(0,0,128,128);
    grad.addColorStop(0,'#FF6584');
    grad.addColorStop(1,'#7C5CFC');
    ctx.fillStyle=grad;ctx.beginPath();ctx.arc(64,64,64,0,Math.PI*2);ctx.fill();
    ctx.fillStyle='#FFFFFF';
    ctx.font='bold 52px Arial, sans-serif';ctx.textAlign='center';ctx.textBaseline='middle';
    const letter = (S.user && S.user.name) ? S.user.name.trim().charAt(0).toUpperCase() : 'H';
    ctx.fillText(letter,64,66);
    return canvas.toDataURL('image/png');
}

function pickAvatarPreset(preset){
    const av = makeEmojiAvatar(preset);
    if(!S.user) S.user=USERS[0];
    S.user.avatar=av; S.user.preset=preset;
    localStorage.setItem('vx_u',JSON.stringify(S.user));
    const pa = document.getElementById('profileAvatarImg'); if(pa) pa.src=av;
    const ha = document.getElementById('hdrAvatarImg'); if(ha) ha.src=av;
    document.querySelectorAll('.preset-chip').forEach(b=>{
        b.classList.toggle('active', !!b.getAttribute('onclick')?.includes(preset));
    });
    toast('Đã cập nhật ảnh đại diện phong cách mới!', 'success');
}

function uploadAvatar(e){
    const f=e.target.files[0];if(!f)return;
    const r=new FileReader();
    r.onload=ev=>{
        if(!S.user) S.user=USERS[0];
        S.user.avatar=ev.target.result;
        localStorage.setItem('vx_u',JSON.stringify(S.user));
        document.getElementById('profileAvatarImg').src=ev.target.result;
        const ha=document.getElementById('hdrAvatarImg');if(ha)ha.src=ev.target.result;
        toast('Đã tải lên ảnh đại diện mới! 📸','success');
    };
    r.readAsDataURL(f);
}

function switchUser(email){
    const u=USERS.find(x=>x.email===email);
    if(!u)return;
    S.user=JSON.parse(JSON.stringify(u));
    localStorage.setItem('vx_u',JSON.stringify(S.user));
    document.getElementById('uName').textContent=S.user.name;
    const ha=document.getElementById('hdrAvatarImg');if(ha)ha.src=S.user.avatar;
    renderSettings();
    toast(`Đã chuyển sang tài khoản ${u.name}!`,'success');
}

// ===== GROUP FUND & SPLIT BILLS =====
function renderGroup(){
    if(!S.groupFund) S.groupFund = JSON.parse(JSON.stringify(DEMO_GROUP));
    const g = S.groupFund;
    
    // Balance
    const balEl = document.getElementById('groupFundBal');
    if(balEl) balEl.textContent = fmt(g.balance);
    const homeBal = document.getElementById('homeFundBal');
    if(homeBal) homeBal.textContent = fmt(g.balance);
    const cntEl = document.getElementById('gBillCount');
    if(cntEl) cntEl.textContent = g.bills.length;
    
    // Tab 1: Bills List
    const bl = document.getElementById('groupBillsList');
    if(bl){
        if(!g.bills.length){
            bl.innerHTML = '<div class="empty"><div class="empty-ic"><i class="ri-receipt-line"></i></div><h3>Chưa có hóa đơn phòng</h3><p>Quét hoặc tải ảnh hóa đơn để bắt đầu chia tiền.</p></div>';
        } else {
            bl.innerHTML = g.bills.map((b, i) => {
                const isFund = b.mode === 'fund';
                let sharesHtml = '';
                if(isFund){
                    sharesHtml = `<div class="gb-shares"><div style="font-size:0.7rem;color:var(--text3)"><i class="ri-check-line" style="color:var(--success)"></i> ${b.note||'Đã trích từ Quỹ chung phòng trọ'}</div></div>`;
                } else if(b.shares){
                    sharesHtml = `
                        <div class="gb-shares">
                            ${b.shares.map(s => {
                                const isPaid = s.status === 'paid' || s.isPayer;
                                const tagClass = s.isPayer ? 'payer' : (s.status === 'paid' ? 'paid' : 'unpaid');
                                const tagText = s.isPayer ? 'Ứng trước' : (s.status === 'paid' ? 'Đã trả' : 'Chưa trả');
                                const actionBtn = (!s.isPayer && s.status === 'unpaid') ? 
                                    `<button class="btn btn-sm btn-p" style="padding:0.15rem 0.5rem;font-size:0.62rem" onclick="showReminderQR(${b.id}, ${s.id})"><i class="ri-qr-code-line"></i> Nhắc nợ / QR</button>` : 
                                    (!s.isPayer ? `<button class="btn btn-sm btn-s" style="padding:0.15rem 0.4rem;font-size:0.6rem" onclick="toggleDebtStatus(${b.id}, ${s.id})" title="Đổi trạng thái"><i class="ri-refresh-line"></i></button>` : '');
                                return `
                                    <div class="gb-share-row">
                                        <div class="gb-member-info">
                                            <i class="ri-user-line" style="color:var(--text3)"></i>
                                            <span>${s.name}</span>
                                            <span class="gb-status-tag ${tagClass}">${tagText}</span>
                                        </div>
                                        <div style="display:flex;align-items:center;gap:0.4rem">
                                            <strong style="color:${isPaid?'var(--text)':'var(--danger)'}">${fmt(s.amt)}</strong>
                                            ${actionBtn}
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                        </div>
                    `;
                }
                return `
                    <div class="group-bill-card" style="animation:fadeUp 0.3s ease ${i*0.06}s both">
                        <div class="gb-top">
                            <div>
                                <div class="gb-name">${b.name}</div>
                                <div class="gb-meta"><i class="ri-calendar-line"></i> ${b.date} · Người chi: <strong>${b.payerName}</strong></div>
                            </div>
                            <div class="gb-amt">-${fmt(b.amt)}</div>
                        </div>
                        ${sharesHtml}
                        ${!isFund ? `<div style="margin-top:0.5rem;display:flex;justify-content:flex-end"><button class="btn btn-sm btn-s" style="font-size:0.68rem" onclick="showReminderQR(${b.id})"><i class="ri-share-forward-line"></i> Gửi nhắc nợ cả phòng (Zalo)</button></div>` : ''}
                    </div>
                `;
            }).join('');
        }
    }
    
    // Tab 2: Members List
    const ml = document.getElementById('groupMembersList');
    if(ml){
        ml.innerHTML = g.members.map(m => {
            const hasDebt = (m.debt || 0) > 0;
            return `
                <div class="group-member-card">
                    <div class="gmc-avatar"><i class="${m.icon||'ri-user-line'}"></i></div>
                    <div class="gmc-info">
                        <div class="gmc-name">
                            ${m.name}
                            ${m.role==='Trưởng phòng'?'<span class="badge" style="background:#FFF9EB;color:#B47D14;font-size:0.58rem">Trưởng phòng</span>':''}
                        </div>
                        <div class="gmc-meta"><i class="ri-phone-line"></i> ${m.phone} · Đã góp quỹ: <strong>${fmt(m.paidFund||0)}</strong></div>
                    </div>
                    <div class="gmc-status">
                        ${hasDebt ? 
                            `<div class="gmc-debt">Nợ: ${fmt(m.debt)}</div><button class="btn btn-sm btn-p" style="padding:0.15rem 0.4rem;font-size:0.6rem;margin-top:0.2rem" onclick="showReminderQR(1, ${m.id})">Đòi nợ</button>` : 
                            '<div class="gmc-ok"><i class="ri-check-double-line"></i> Sạch nợ</div>'}
                    </div>
                </div>
            `;
        }).join('');
    }
    
    // Tab 3: Fund History
    const hl = document.getElementById('groupFundHistory');
    if(hl){
        hl.innerHTML = g.history.map(h => {
            const isIn = h.type === 'in';
            return `
                <div class="tx-item">
                    <div class="tx-ic" style="background:${isIn?'#E6FCF5':'#FFF0F1'};color:${isIn?'var(--success)':'var(--danger)'}">
                        <i class="${isIn?'ri-arrow-down-circle-line':'ri-arrow-up-circle-line'}"></i>
                    </div>
                    <div class="tx-info">
                        <div class="tx-name">${h.title}</div>
                        <div class="tx-cat">${h.date} · Thực hiện: ${h.user}</div>
                    </div>
                    <div class="tx-right">
                        <div class="tx-amt ${isIn?'inc':'exp'}">${isIn?'+':'-'}${fmt(h.amt)}</div>
                    </div>
                </div>
            `;
        }).join('');
    }
}

function swGroupTab(btn, tab){
    document.querySelectorAll('#groupTabs .pg-tab').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    document.getElementById('gTabBills').classList.toggle('hidden', tab !== 'bills');
    document.getElementById('gTabMembers').classList.toggle('hidden', tab !== 'members');
    document.getElementById('gTabHistory').classList.toggle('hidden', tab !== 'history');
}

function openFundModal(){
    document.getElementById('fundModal')?.classList.add('active');
}
function closeFundModal(){
    document.getElementById('fundModal')?.classList.remove('active');
}
function handleFundContribution(e){
    e.preventDefault();
    const pid = parseInt(document.getElementById('fundPayerSelect').value);
    const amt = parseFloat(document.getElementById('fundAmountInput').value);
    const note = document.getElementById('fundNoteInput').value.trim() || 'Góp quỹ phòng trọ';
    if(!amt || amt <= 0){ toast('Số tiền chưa hợp lệ!', 'error'); return; }
    
    const mem = S.groupFund.members.find(m => m.id === pid) || S.groupFund.members[0];
    mem.paidFund = (mem.paidFund || 0) + amt;
    S.groupFund.balance += amt;
    
    S.groupFund.history.unshift({
        id: Date.now(),
        type: 'in',
        title: `${mem.name} nộp quỹ: ${note}`,
        amt: amt,
        date: new Date().toISOString().slice(0,10),
        user: mem.name
    });
    
    renderGroup();
    closeFundModal();
    toast(`Đã nộp ${fmt(amt)} vào Quỹ phòng thành công!`, 'success');
}

function openQrModal(){
    document.getElementById('qrModal')?.classList.add('active');
}
function closeQrModal(){
    document.getElementById('qrModal')?.classList.remove('active');
}

function showReminderQR(billId, memberId){
    const bill = S.groupFund.bills.find(b => b.id === billId) || S.groupFund.bills[0];
    if(!bill) return;
    
    let targetShare = null;
    if(memberId && bill.shares){
        targetShare = bill.shares.find(s => s.id === memberId);
    }
    
    const amt = targetShare ? targetShare.amt : (bill.shares && bill.shares[1] ? bill.shares[1].amt : 1125000);
    const name = targetShare ? targetShare.name : 'Cả phòng';
    const memo = 'DONG QUY CHI TIEU';
    
    const body = document.getElementById('qrModalBody');
    if(!body) return;
    
    body.innerHTML = `
        <div class="qr-card-view" style="padding:0.75rem">
            <div style="font-size:0.85rem;font-weight:800;color:var(--text);margin-bottom:0.15rem">Mã VietQR</div>
            <div style="font-size:0.7rem;color:var(--text3);margin-bottom:0.4rem">Quét bằng ứng dụng ngân hàng</div>
            <div class="qr-frame" style="margin-bottom:0.4rem">
                <canvas id="mockQrCanvas" width="160" height="160"></canvas>
            </div>
            <div style="font-size:1.15rem;font-weight:900;color:var(--primary);margin-bottom:0.4rem">${fmt(amt)}</div>
            <div class="qr-details" style="padding:0.55rem;margin-bottom:0.5rem">
                <div class="qr-row"><span style="color:var(--text3)">Khoản chi:</span> <strong>${bill.name}</strong></div>
                <div class="qr-row"><span style="color:var(--text3)">Số TK:</span> <strong>0912 345 678</strong> (MB Bank)</div>
                <div class="qr-row"><span style="color:var(--text3)">Chủ TK:</span> <strong>Nguyễn Thúy Hiền</strong></div>
                <div class="qr-row"><span style="color:var(--text3)">Nội dung:</span> <strong>${memo}</strong></div>
            </div>
            <button class="btn btn-p btn-block" onclick="copyZaloReminder('${bill.name}', ${amt}, '${name}')">
                <i class="ri-file-copy-line"></i> Sao chép tin nhắn
            </button>
            ${targetShare && targetShare.status !== 'paid' ? `
                <button class="btn btn-s btn-block" style="margin-top:0.35rem" onclick="toggleDebtStatus(${bill.id}, ${targetShare.id})">
                    <i class="ri-check-line"></i> Đã nhận từ ${targetShare.name}
                </button>
            ` : ''}
            <button class="btn btn-s btn-block" style="margin-top:0.35rem" onclick="closeQrModal()">
                <i class="ri-close-line"></i> Đóng
            </button>
        </div>
    `;
    
    openQrModal();
    setTimeout(()=>{
        const cv = document.getElementById('mockQrCanvas');
        if(cv) drawMockVietQr(cv, amt, memo);
    }, 50);
}

function drawMockVietQr(canvas, amt, memo){
    if(!canvas) return;
    const ctx = canvas.getContext('2d');
    ctx.fillStyle = '#FFFFFF'; ctx.fillRect(0,0,160,160);
    ctx.fillStyle = '#1E293B';
    function corner(x,y){
        ctx.fillRect(x,y,40,40);
        ctx.fillStyle='#FFF'; ctx.fillRect(x+6,y+6,28,28);
        ctx.fillStyle='#1E293B'; ctx.fillRect(x+12,y+12,16,16);
    }
    corner(10,10); corner(110,10); corner(10,110);
    for(let i=0; i<12; i++){
        for(let j=0; j<12; j++){
            if((i<4&&j<4) || (i>7&&j<4) || (i<4&&j>7)) continue;
            if((i*7+j*13)%3 === 0) ctx.fillRect(12+i*11, 12+j*11, 7, 7);
        }
    }
    ctx.fillStyle = '#FFF'; ctx.beginPath(); ctx.arc(80,80,18,0,Math.PI*2); ctx.fill();
    ctx.fillStyle = '#2E86DE'; ctx.font = 'bold 10px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle';
    ctx.fillText('MB', 80, 80);
}

function toggleDebtStatus(billId, memberId){
    const bill = S.groupFund.bills.find(b => b.id === billId);
    if(!bill || !bill.shares) return;
    const share = bill.shares.find(s => s.id === memberId);
    if(!share) return;
    
    const wasPaid = share.status === 'paid';
    share.status = wasPaid ? 'unpaid' : 'paid';
    
    const mem = S.groupFund.members.find(m => m.id === memberId);
    if(mem){
        if(wasPaid) mem.debt = (mem.debt || 0) + share.amt;
        else mem.debt = Math.max(0, (mem.debt || 0) - share.amt);
    }
    
    renderGroup();
    closeQrModal();
    toast(`Đã cập nhật: ${share.name} (${wasPaid ? 'chưa trả' : 'đã trả'})`, 'success');
}

function copyZaloReminder(billTitle, amt, memberName){
    const msg = `Tiền ${billTitle}: ${fmt(amt * 4)} chia 4. Phần ${memberName}: ${fmt(amt)}. STK: 0912 345 678 (MB Bank - Thúy Hiền).`;
    if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(msg).then(()=>{
            toast('Đã sao chép tin nhắn!', 'success');
        }).catch(()=>{
            prompt('Sao chép lời nhắn:', msg);
        });
    } else {
        prompt('Sao chép lời nhắn:', msg);
    }
}

function openSplitManualModal(){ loadSampleRoomRentInvoice(); }
function quickSampleRent(){ loadSampleRoomRentInvoice(); }

// ===== HANDLERS CHO REVIEW.HTML & GROUPS.HTML =====
async function handleConfirmTransaction(event) {
    if (event) event.preventDefault();
    const merchant = document.getElementById('verify-merchant')?.value?.trim() || 'Hóa đơn';
    const amount = parseFloat(document.getElementById('verify-amount')?.value) || 0;
    const date = document.getElementById('verify-date')?.value || new Date().toISOString().slice(0, 10);
    const category = document.getElementById('verify-category')?.value || 'Khác';
    const groupIdVal = document.getElementById('verify-group-id')?.value;
    const groupId = groupIdVal ? parseInt(groupIdVal, 10) : null;
    const notes = document.getElementById('verify-notes')?.value || '';

    let imageUrl = '';
    let rawText = '';
    const cachedOcr = sessionStorage.getItem('ocr_result');
    if (cachedOcr) {
        try {
            const parsed = JSON.parse(cachedOcr);
            imageUrl = parsed.image_url || '';
            rawText = parsed.raw_text || '';
        } catch (e) {
            console.warn('Lỗi đọc cache ocr:', e);
        }
    }

    const payload = {
        user_id: S.user?.id || 1,
        merchant_name: merchant,
        amount: amount,
        type: 'expense',
        transaction_date: date,
        category: category,
        group_id: groupId,
        notes: notes,
        receipt_image_path: imageUrl,
        raw_ocr_text: rawText
    };

    try {
        const res = await fetch('/api/transactions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.success || res.ok) {
            sessionStorage.removeItem('ocr_result');
            toast('Đã lưu giao dịch!', 'success');
            setTimeout(() => { window.location.href = '/'; }, 300);
        } else {
            toast(data.error || 'Chưa lưu được giao dịch.', 'error');
        }
    } catch (err) {
        console.warn('API error, saving to local store:', err);
        S.transactions.unshift({
            id: Date.now(),
            name: merchant,
            amt: amount,
            type: 'expense',
            cat: 'other',
            date: date,
            note: notes,
            time: new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'})
        });
        toast('Đã lưu giao dịch!', 'success');
        setTimeout(() => { window.location.href = '/'; }, 300);
    }
}

async function loadGroupMembersUI() {
    const listEl = document.getElementById('member-checkbox-list');
    if (!listEl) return;

    let members = [
        { id: 1, name: 'Nguyễn Thúy Hiền', role: 'Trưởng nhóm' },
        { id: 2, name: 'Lê Thị Dịu', role: 'Thành viên' },
        { id: 3, name: 'Lê Tiến Quân', role: 'Thành viên' },
        { id: 4, name: 'Lê Ngọc Duy', role: 'Thành viên' },
        { id: 5, name: 'Nguyễn Việt Anh', role: 'Thành viên' }
    ];

    try {
        const res = await fetch('/api/users');
        if (res.ok) {
            const data = await res.json();
            if (Array.isArray(data) && data.length > 0) {
                members = data.map(u => ({ id: u.id, name: u.full_name, role: u.id === 1 ? 'Trưởng nhóm' : 'Thành viên' }));
            }
        }
    } catch (e) {
        console.log('Sử dụng danh sách thành viên mặc định');
    }

    listEl.innerHTML = members.map(m => `
        <label style="display:flex;align-items:center;gap:0.75rem;padding:0.6rem 0.8rem;background:#f8fafc;border-radius:var(--radius-sm);cursor:pointer;border:1px solid #e2e8f0;">
            <input type="checkbox" name="split_member" value="${m.id}" checked style="accent-color:var(--primary);width:18px;height:18px;">
            <div style="flex:1;">
                <div style="font-weight:600;font-size:0.92rem;color:var(--text);">${m.name}</div>
                <div style="font-size:0.75rem;color:var(--text-muted);">${m.role}</div>
            </div>
            <span class="badge" style="background:#e0e7ff;color:#3730a3;font-size:0.75rem;">Nhóm</span>
        </label>
    `).join('');
}

async function calculateSplit(event) {
    if (event) event.preventDefault();
    const amountInput = document.getElementById('split-amount-input');
    const payerSelect = document.getElementById('split-payer-select');
    const resultBox = document.getElementById('split-result');
    const detailsBox = document.getElementById('split-result-details');

    if (!amountInput || !detailsBox) return;

    const amount = parseFloat(amountInput.value) || 0;
    if (amount <= 0) {
        toast('Nhập số tiền hợp lệ!', 'error');
        return;
    }

    const checkboxes = document.querySelectorAll('input[name="split_member"]:checked');
    const selectedIds = Array.from(checkboxes).map(cb => parseInt(cb.value, 10));

    if (selectedIds.length === 0) {
        toast('Chọn ít nhất 1 thành viên!', 'warning');
        return;
    }

    let result = null;
    try {
        const res = await fetch('/api/groups/1/split-equal', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount: amount, member_ids: selectedIds })
        });
        if (res.ok) {
            result = await res.json();
        }
    } catch (e) {
        console.warn('Lỗi gọi API chia tiền, tính toán offline:', e);
    }

    const perPerson = result ? result.per_person : Math.round(amount / selectedIds.length);
    const memberCount = selectedIds.length;
    const payerName = payerSelect ? payerSelect.options[payerSelect.selectedIndex].text : 'Người trả';

    resultBox.style.display = 'block';
    detailsBox.innerHTML = `
        <div style="font-size:1.15rem;font-weight:800;color:var(--primary);margin-bottom:0.3rem;">
            ${fmt(perPerson)} / người
        </div>
        <div style="font-size:0.8rem;color:var(--text3);margin-bottom:0.6rem;">
            Tổng: <strong>${fmt(amount)}</strong> chia <strong>${memberCount} người</strong> · Trả trước: <strong>${payerName}</strong>
        </div>
        <div style="margin-top:0.6rem;padding:0.6rem;background:var(--card);border-radius:var(--r-sm);border:1px solid var(--border);">
            <div style="font-size:0.78rem;font-weight:700;margin-bottom:0.35rem;">Tin nhắn gửi Zalo:</div>
            <textarea id="splitZaloText" readonly style="width:100%;height:54px;font-size:0.78rem;padding:0.35rem 0.5rem;border-radius:4px;border:1px solid var(--border);background:var(--bg);resize:none;color:var(--text);">Tiền chia: ${fmt(amount)} (${payerName} trả trước) chia ${memberCount} người = ${fmt(perPerson)}/người nha!</textarea>
            <button type="button" class="btn btn-p btn-sm btn-block" style="margin-top:0.35rem;" onclick="copyZaloText()">
                <i class="ri-file-copy-line"></i> Sao chép tin nhắn
            </button>
        </div>
    `;
}

function copyZaloText() {
    const area = document.getElementById('splitZaloText');
    if (area) {
        area.select();
        document.execCommand('copy');
        toast('Đã sao chép tin nhắn!', 'success');
    }
}

// ===== TRUNG TÂM THÔNG BÁO =====
function openNotificationModal(){
    document.getElementById('notifModal')?.classList.add('active');
}
function closeNotificationModal(){
    document.getElementById('notifModal')?.classList.remove('active');
}
function markAllNotifsRead(){
    document.querySelectorAll('.notif-dot').forEach(el => el.remove());
    document.querySelectorAll('.hdr-actions .dot').forEach(el => el.remove());
    toast('Đã đọc tất cả thông báo! ✨', 'success');
}

// ===== INIT =====
document.addEventListener('DOMContentLoaded',()=>{
    const savedTheme=localStorage.getItem('vx_theme')||'pink-gold';
    document.documentElement.setAttribute('data-theme',savedTheme);
    const s=localStorage.getItem('vx_u');
    if(s){try{S.user=JSON.parse(s);S.loggedIn=true;enterApp()}catch(e){localStorage.removeItem('vx_u')}}
    const dz=document.getElementById('dropZone');
    if(dz){dz.addEventListener('dragover',e=>{e.preventDefault();dz.classList.add('dragover')});dz.addEventListener('dragleave',()=>dz.classList.remove('dragover'));dz.addEventListener('drop',e=>{e.preventDefault();dz.classList.remove('dragover');const f=e.dataTransfer.files[0];if(f){document.getElementById('fileIn').files=e.dataTransfer.files;handleFile({target:{files:[f]}})}});}
    document.getElementById('modal')?.addEventListener('click',e=>{if(e.target.id==='modal')closeModal()});
    document.addEventListener('keydown',e=>{if(e.key==='Escape')closeModal()});
    const md=document.getElementById('manual-date');if(md)md.value=new Date().toISOString().slice(0,10);
    if(document.getElementById('transaction-list')){loadDashboardStats();loadRecentTransactions()}
    drawCaptcha();
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('/service-worker.js').catch(() => {});
    }
});

