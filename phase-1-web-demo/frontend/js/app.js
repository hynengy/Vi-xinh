/**
 * Ví Xinh v3 — Full App Logic (Warm Violet + Remix Icons)
 * All features: Login, Dashboard, Transactions (manual + photo/camera),
 * Budget, Savings, Recurring, Stats (bar chart, pie, calendar)
 */

const S = {
    loggedIn:false, user:null, balVis:true, txType:'expense', selCat:'food',
    calY:2026, calM:9, transactions:[], budgets:[], savings:[], recurring:[], camStream:null,
    groupFund:null,
    ocrEngine: 'mlkit', // 'mlkit' (Google ML Kit On-Device) | 'server' (Tesseract OpenCV)
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

const SEED_USERS = [];

function getRegisteredUsers(){
    try {
        const raw = localStorage.getItem('vx_registered_users');
        if(raw){
            const list = JSON.parse(raw);
            if(Array.isArray(list)){
                // Dọn sạch các tài khoản mẫu cũ (@vixinh.vn, testreal...) nếu còn sót trong localStorage
                const cleaned = list.filter(u => {
                    const em = (u.email || '').toLowerCase();
                    return !em.endsWith('@vixinh.vn') && em !== 'hien@vixinh' && !em.startsWith('user1@') && em !== 'testreal@gmail.com';
                });
                if(cleaned.length !== list.length){
                    localStorage.setItem('vx_registered_users', JSON.stringify(cleaned));
                }
                return cleaned;
            }
        }
    } catch(e){}
    return [];
}

function saveRegisteredUser(u, password){
    try {
        const raw = localStorage.getItem('vx_registered_users');
        const list = raw ? JSON.parse(raw) : [];
        const saved = { ...u, password: password || u.password || 'password123', pw: password || u.password || 'password123' };
        const idx = list.findIndex(x => (saved.email && x.email === saved.email) || (saved.phone && x.phone === saved.phone));
        if(idx >= 0) list[idx] = saved;
        else list.push(saved);
        localStorage.setItem('vx_registered_users', JSON.stringify(list));
    } catch(e){}
}

const USERS = getRegisteredUsers();

const CATS = {
    food:          {label:'Ăn uống',   ic:'ri-restaurant-line',         color:'#0071E3', bg:'#F5F5F7'},
    transport:     {label:'Di chuyển', ic:'ri-taxi-line',               color:'#0071E3', bg:'#F5F5F7'},
    shopping:      {label:'Mua sắm',   ic:'ri-shopping-bag-3-line',     color:'#0071E3', bg:'#F5F5F7'},
    entertainment: {label:'Giải trí',  ic:'ri-gamepad-line',            color:'#0071E3', bg:'#F5F5F7'},
    health:        {label:'Sức khỏe',  ic:'ri-heart-pulse-line',        color:'#0071E3', bg:'#F5F5F7'},
    education:     {label:'Học tập',   ic:'ri-book-open-line',          color:'#0071E3', bg:'#F5F5F7'},
    bills:         {label:'Hoá đơn',   ic:'ri-bill-line',               color:'#0071E3', bg:'#F5F5F7'},
    salary:        {label:'Lương',     ic:'ri-money-dollar-circle-line',color:'#0071E3', bg:'#F5F5F7'},
    other:         {label:'Khác',      ic:'ri-archive-line',            color:'#0071E3', bg:'#F5F5F7'},
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

const DEMO_TX = [];
const DEMO_BGT = [];
const DEMO_SAV = [];
const DEMO_REC = [];

const DEMO_GROUP = null;

// ===== UTILS =====
const fmt = n => new Intl.NumberFormat('vi-VN').format(n)+' ₫';
const fmtS = n => fmt(n);
function escapeHtml(str){
    if(str == null) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
function formatAiAdvice(text){
    if(!text) return '';
    let escaped = escapeHtml(text);
    // Hỗ trợ hiển thị Markdown: **chữ in đậm** thành <strong>
    escaped = escaped.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    // Xuống dòng mượt mà
    escaped = escaped.replace(/\n/g, '<br>');
    return escaped;
}
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

function swAuthTab(tab){
    switchAuthTab(tab);
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
        toast('Mật khẩu tối thiểu 6 ký tự', 'warning');
        return;
    }

    const btn = document.getElementById('loginBtn');
    btn.classList.add('loading');
    document.getElementById('loginBtnTxt').innerHTML = '<span class="spinner"></span> Đang kiểm tra...';

    const cleanContact = em.replace(/\s+/g, '');

    try {
        const res = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ identifier: em, password: pw })
        });

        let data = {};
        try {
            data = await res.json();
        } catch(_) {}

        if(res.ok && data.success){
            const u = data.user;
            u.name = u.full_name || u.name || em.split('@')[0];
            u.avatar = u.avatar_url || 'assets/logo.jpg';
            saveRegisteredUser(u, pw);
            S.loggedIn = true;
            S.user = u;
            localStorage.setItem('vx_u', JSON.stringify(u));
            localStorage.setItem('vx_last_user', JSON.stringify(u));
            const remChk = document.getElementById('rememberMeCheck');
            if (remChk && remChk.checked) {
                localStorage.setItem('vx_remembered_account', em);
            } else {
                localStorage.removeItem('vx_remembered_account');
            }
            updateBioLoginUI();
            enterApp();
            toast(`Đăng nhập thành công: ${u.name}`, 'success');
        } else {
            // Kiểm tra xem có trong registered users local không nếu offline
            const localUsers = getRegisteredUsers();
            const localU = localUsers.find(x => (x.email === em || (x.phone && x.phone.replace(/\s+/g,'') === cleanContact)));
            if(localU){
                if(localU.password === pw || localU.pw === pw){
                    S.loggedIn = true;
                    S.user = localU;
                    localStorage.setItem('vx_u', JSON.stringify(localU));
                    localStorage.setItem('vx_last_user', JSON.stringify(localU));
                    updateBioLoginUI();
                    enterApp();
                    toast(`Đăng nhập thành công: ${localU.name || localU.full_name}`, 'success');
                    return;
                } else {
                    document.getElementById('pwGrp').classList.add('error');
                    toast('Mật khẩu không chính xác. Vui lòng kiểm tra lại!', 'error');
                    return;
                }
            }
            // Tuyệt đối không cho phép đăng nhập nếu chưa đăng ký!
            document.getElementById('emailGrp').classList.add('error');
            toast(data.error || 'Tài khoản chưa được đăng ký trong hệ thống. Vui lòng chọn tab Đăng ký!', 'error');
            setTimeout(() => swAuthTab('register'), 1400);
        }
    } catch(err) {
        // Trường hợp offline / mạng lỗi: Kiểm tra chặt chẽ danh sách tài khoản đã đăng ký
        const localUsers = getRegisteredUsers();
        const localU = localUsers.find(x => (x.email === em || (x.phone && x.phone.replace(/\s+/g,'') === cleanContact)));
        if(!localU){
            document.getElementById('emailGrp').classList.add('error');
            toast('Tài khoản chưa được đăng ký. Vui lòng bấm sang tab Đăng ký để tạo tài khoản mới!', 'error');
            setTimeout(() => swAuthTab('register'), 1400);
        } else if(localU.password !== pw && localU.pw !== pw){
            document.getElementById('pwGrp').classList.add('error');
            toast('Mật khẩu không chính xác. Vui lòng kiểm tra lại!', 'error');
        } else {
            S.loggedIn = true;
            S.user = localU;
            localStorage.setItem('vx_u', JSON.stringify(localU));
            localStorage.setItem('vx_last_user', JSON.stringify(localU));
            updateBioLoginUI();
            enterApp();
            toast(`Đăng nhập thành công: ${localU.name || localU.full_name}`, 'success');
        }
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
        toast('Mã xác thực bảo mật không đúng.', 'error');
        refreshCaptcha();
        return;
    }
    const errEl = document.getElementById('captchaErrorMsg');
    if (errEl) errEl.style.display = 'none';

    // 2. Kiểm tra các trường dữ liệu
    if(!fullName || !email || !phone || pw.length < 6){
        toast('Vui lòng điền đủ họ tên, email, SĐT và mật khẩu ≥ 6 ký tự.', 'error');
        return;
    }

    // 3. Kiểm tra xem tài khoản đã tồn tại trong local users chưa
    const cleanPhone = phone.replace(/\s+/g, '');
    const localUsers = getRegisteredUsers();
    const exists = localUsers.some(x => x.email === email || (x.phone && x.phone.replace(/\s+/g,'') === cleanPhone));
    if(exists){
        toast('Email hoặc Số điện thoại này đã được đăng ký. Vui lòng Đăng nhập!', 'warning');
        setTimeout(() => swAuthTab('login'), 1200);
        return;
    }

    const btn = document.getElementById('regBtn');
    btn.classList.add('loading');
    document.getElementById('regBtnTxt').innerHTML = '<span class="spinner"></span> Đang tạo tài khoản...';

    const newUserObj = {
        id: Date.now(),
        name: fullName,
        full_name: fullName,
        email: email,
        phone: phone,
        password: pw,
        avatar: 'assets/logo.jpg'
    };

    try {
        const res = await fetch('/api/auth/register', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ full_name: fullName, email: email, phone: phone, password: pw })
        });

        let data = {};
        try {
            data = await res.json();
        } catch(_) {}

        if(res.ok && data.success){
            const u = data.user;
            u.name = u.full_name || fullName;
            u.avatar = u.avatar_url || 'assets/logo.jpg';
            saveRegisteredUser(u, pw);
            S.loggedIn = true;
            S.user = u;
            localStorage.setItem('vx_u', JSON.stringify(u));
            localStorage.setItem('vx_last_user', JSON.stringify(u));
            enterApp();
            toast(`Đăng ký tài khoản thành công: ${fullName}`, 'success');
        } else {
            toast(data.error || 'Email hoặc Số điện thoại đã được đăng ký trước đó.', 'error');
            refreshCaptcha();
        }
    } catch(err) {
        // Lưu tài khoản cục bộ khi không kết nối được máy chủ
        saveRegisteredUser(newUserObj, pw);
        S.loggedIn = true;
        S.user = newUserObj;
        localStorage.setItem('vx_u', JSON.stringify(newUserObj));
        localStorage.setItem('vx_last_user', JSON.stringify(newUserObj));
        enterApp();
        toast(`Đã tạo tài khoản thành công: ${fullName}`, 'success');
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
            if(data.real_email_sent){
                forgotOtpCode = null;
                document.getElementById('forgotOtpDisplayBox').style.display = 'none';
                toast(`Mã OTP đã được gửi đến email ${contact}! Vui lòng kiểm tra hộp thư.`, 'success');
            } else {
                forgotOtpCode = data.otp;
                document.getElementById('forgotOtpDisplayVal').textContent = data.otp;
                document.getElementById('forgotOtpDisplayBox').style.display = 'block';
                toast(`Mã OTP (Demo): ${data.otp}`, 'success');
            }
        } else {
            const data = await res.json();
            toast(data.error || 'Không tìm thấy tài khoản gắn với thông tin này.', 'error');
            btn.disabled = false;
            btn.textContent = 'Gửi mã';
            return;
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
        const cleanContact = contact.replace(/\s+/g, '');
        const regUsers = getRegisteredUsers();
        const found = regUsers.some(x => x.email === contact || (x.phone && x.phone.replace(/\s+/g, '') === cleanContact));
        if(found){
            const fakeOtp = Math.floor(100000 + Math.random() * 900000).toString();
            forgotOtpCode = fakeOtp;
            document.getElementById('forgotOtpDisplayVal').textContent = fakeOtp;
            document.getElementById('forgotOtpDisplayBox').style.display = 'block';
            toast(`Mã OTP (Ngoại tuyến): ${fakeOtp}`, 'info');
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
        } else {
            toast('Không tìm thấy tài khoản gắn với Email/SĐT này.', 'error');
            btn.disabled = false;
            btn.textContent = 'Gửi mã';
        }
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
        const cleanContact = contact.replace(/\s+/g, '');
        const regUsers = getRegisteredUsers();
        const found = regUsers.find(x => x.email === contact || (x.phone && x.phone.replace(/\s+/g, '') === cleanContact));
        if(found){
            found.password = newPw;
            found.pw = newPw;
            localStorage.setItem('vx_registered_users', JSON.stringify(regUsers));
            S.loggedIn = true;
            S.user = found;
            localStorage.setItem('vx_u', JSON.stringify(found));
            closeForgotPwModal();
            enterApp();
            toast('Đặt lại mật khẩu thành công.', 'success');
        } else {
            toast('Không tìm thấy tài khoản để đặt lại mật khẩu.', 'error');
        }
    } finally {
        btn.classList.remove('loading');
        document.getElementById('btnResetPwTxt').textContent = 'Đặt lại mật khẩu';
    }
}

function handleLogout(){
    S.loggedIn = false;
    S.user = null;
    localStorage.removeItem('vx_u');
    document.getElementById('app').classList.remove('active');
    document.getElementById('bnav').classList.remove('active');
    document.getElementById('loginPage').style.display = 'flex';

    // Clear password field
    const pwInp = document.getElementById('loginPw');
    if (pwInp) pwInp.value = '';

    // Remember Me check
    const remembered = localStorage.getItem('vx_remembered_account');
    const emInp = document.getElementById('loginEmail');
    const remChk = document.getElementById('rememberMeCheck');
    if (remembered && emInp) {
        emInp.value = remembered;
        if (remChk) remChk.checked = true;
    } else if (emInp) {
        emInp.value = '';
        if (remChk) remChk.checked = false;
    }

    updateBioLoginUI();
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

function normalizeCatKey(cat){
    if(!cat) return 'other';
    const c = String(cat).trim().toLowerCase();
    if(CATS[c]) return c;
    if(c.includes('ăn') || c.includes('uống') || c.includes('cafe') || c.includes('food')) return 'food';
    if(c.includes('đi') || c.includes('xe') || c.includes('xăng') || c.includes('chuyển') || c.includes('transport')) return 'transport';
    if(c.includes('sắm') || c.includes('tiêu dùng') || c.includes('mart') || c.includes('shopping')) return 'shopping';
    if(c.includes('trí') || c.includes('chơi') || c.includes('game') || c.includes('entertainment')) return 'entertainment';
    if(c.includes('khỏe') || c.includes('thuốc') || c.includes('viện') || c.includes('health')) return 'health';
    if(c.includes('học') || c.includes('sách') || c.includes('education')) return 'education';
    if(c.includes('đơn') || c.includes('điện') || c.includes('nước') || c.includes('trọ') || c.includes('bills')) return 'bills';
    if(c.includes('lương') || c.includes('thu nhập') || c.includes('salary')) return 'salary';
    return 'other';
}

function saveStateToStorage(){
    const uid = S.user?.id || 1;
    try {
        localStorage.setItem('vx_transactions_' + uid, JSON.stringify(S.transactions || []));
        localStorage.setItem('vx_transactions', JSON.stringify(S.transactions || []));
        localStorage.setItem('vx_budgets_' + uid, JSON.stringify(S.budgets || []));
        localStorage.setItem('vx_savings_' + uid, JSON.stringify(S.savings || []));
        localStorage.setItem('vx_recurring_' + uid, JSON.stringify(S.recurring || []));
    } catch(e){}
}

async function loadTransactionsFromBackend(){
    const uid = S.user?.id || 1;
    try {
        const res = await fetch(`/api/transactions?user_id=${uid}&limit=100`, {
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        });
        if(res.ok){
            const txs = await res.json();
            if(Array.isArray(txs) && txs.length > 0){
                S.transactions = txs.map(t => ({
                    id: t.id,
                    name: t.merchant_name || 'Chi tiêu',
                    amt: Number(t.amount) || 0,
                    cat: normalizeCatKey(t.category),
                    date: t.transaction_date || (t.created_at ? t.created_at.slice(0, 10) : new Date().toISOString().slice(0, 10)),
                    time: t.transaction_time || (t.created_at ? t.created_at.slice(11, 16) : '00:00'),
                    type: t.type || 'expense',
                    note: t.notes || '',
                    group_id: t.group_id || null,
                    receipt_image_path: t.receipt_image_path || null
                }));
                saveStateToStorage();
                renderAll();
                if(document.getElementById('pgHist')?.classList.contains('active')){
                    filterTransactions();
                }
            }
        }
    } catch(e){
        console.warn('Lỗi đồng bộ giao dịch từ backend:', e);
    }
}

async function loadBudgetsFromBackend(){
    const uid = S.user?.id || 1;
    try {
        const res = await fetch(`/api/budgets?user_id=${uid}`, {
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        });
        if(res.ok){
            const list = await res.json();
            if(Array.isArray(list) && list.length > 0){
                S.budgets = list.map(b => ({
                    id: b.id,
                    cat: normalizeCatKey(b.category),
                    limit: Number(b.limit_amount) || 0
                }));
                saveStateToStorage();
                if(document.getElementById('pgBgt')?.classList.contains('active')){
                    renderBgt();
                }
            }
        }
    } catch(e){}
}

async function loadSavingsFromBackend(){
    const uid = S.user?.id || 1;
    try {
        const res = await fetch(`/api/savings?user_id=${uid}`, {
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        });
        if(res.ok){
            const list = await res.json();
            if(Array.isArray(list) && list.length > 0){
                S.savings = list.map(s => ({
                    id: s.id,
                    name: s.name,
                    icon: s.icon || 'star',
                    target: Number(s.target_amount) || 0,
                    saved: Number(s.saved_amount) || 0
                }));
                saveStateToStorage();
                if(document.getElementById('pgSav')?.classList.contains('active')){
                    renderSav();
                }
            }
        }
    } catch(e){}
}

async function loadRecurringFromBackend(){
    const uid = S.user?.id || 1;
    try {
        const res = await fetch(`/api/recurring?user_id=${uid}`, {
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        });
        if(res.ok){
            const list = await res.json();
            if(Array.isArray(list) && list.length > 0){
                S.recurring = list.map(r => ({
                    id: r.id,
                    name: r.name,
                    amt: Number(r.amount) || 0,
                    freq: r.frequency || 'monthly',
                    cat: normalizeCatKey(r.category),
                    on: !!r.is_active
                }));
                saveStateToStorage();
                if(document.getElementById('pgRec')?.classList.contains('active')){
                    renderRec();
                }
            }
        }
    } catch(e){}
}

function enterApp(){
    document.getElementById('loginPage').style.display='none';
    document.getElementById('app').classList.add('active');
    document.getElementById('bnav').classList.add('active');
    const h=new Date().getHours();
    document.getElementById('greeting').textContent=h<12?'Chào buổi sáng ☀️':h<18?'Chào buổi chiều 🌤️':h<21?'Chào buổi tối 🌙':'Chúc ngủ ngon 🌙';
    
    const displayName = S.user?.full_name || S.user?.name || 'Người dùng';
    S.user.name = displayName;
    document.getElementById('uName').textContent = displayName;
    
    if(S.user?.avatar){
        const ha=document.getElementById('hdrAvatarImg');
        if(ha)ha.src=S.user.avatar;
    }
    const savedTheme=localStorage.getItem('vx_theme')||'pink-gold';
    document.documentElement.setAttribute('data-theme',savedTheme);
    
    const uid = S.user?.id || 1;
    const cachedTx = localStorage.getItem('vx_transactions_' + uid) || localStorage.getItem('vx_transactions');
    if (cachedTx) {
        try { S.transactions = JSON.parse(cachedTx); } catch(e){ S.transactions = []; }
    } else {
        S.transactions = [...DEMO_TX];
    }
    const cachedBgt = localStorage.getItem('vx_budgets_' + uid);
    S.budgets = cachedBgt ? JSON.parse(cachedBgt) : [...DEMO_BGT];
    const cachedSav = localStorage.getItem('vx_savings_' + uid);
    S.savings = cachedSav ? JSON.parse(cachedSav) : DEMO_SAV.map(x=>({...x}));
    const cachedRec = localStorage.getItem('vx_recurring_' + uid);
    S.recurring = cachedRec ? JSON.parse(cachedRec) : DEMO_REC.map(x=>({...x}));

    const savedGroup = localStorage.getItem('vx_group_fund');
    S.groupFund = savedGroup ? JSON.parse(savedGroup) : null;
    renderAll();
    initNotifications();

    loadTransactionsFromBackend();
    loadBudgetsFromBackend();
    loadSavingsFromBackend();
    loadRecurringFromBackend();
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
    if(pg==='history')filterTransactions();
    if(pg==='budget')renderBgt();
    if(pg==='savings')renderSav();
    if(pg==='recurring')renderRec();
}

// ===== RENDER ALL =====
function renderAll(){
    renderChart('week');
    renderHomeTx();
    updStats();
    updateHomeGroupCard();
}
function updStats(){
    const exp=S.transactions.filter(t=>t.type==='expense').reduce((s,t)=>s+t.amt,0);
    const inc=S.transactions.filter(t=>t.type==='income').reduce((s,t)=>s+t.amt,0);
    const el=document.getElementById('mExp');if(el)el.textContent=exp ? ('-'+fmt(exp)) : '0 ₫';
    const ei=document.getElementById('mInc');if(ei)ei.textContent=inc ? ('+'+fmt(inc)) : '0 ₫';
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

// ===== REAL DATA CHART ENGINE =====
function calculateChartData(per){
    const now = new Date();
    let labels = [];
    let expenses = [];
    let incomes = [];

    if(per === 'week'){
        // 7 ngày trong tuần từ Thứ 2 (T2) đến Chủ nhật (CN)
        labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
        expenses = [0, 0, 0, 0, 0, 0, 0];
        incomes = [0, 0, 0, 0, 0, 0, 0];
        
        const currentDay = now.getDay();
        const distToMon = (currentDay + 6) % 7;
        const monday = new Date(now);
        monday.setDate(now.getDate() - distToMon);
        monday.setHours(0,0,0,0);
        
        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);
        sunday.setHours(23,59,59,999);

        (S.transactions || []).forEach(t => {
            const d = new Date(t.date);
            if(d >= monday && d <= sunday){
                const dayIdx = (d.getDay() + 6) % 7;
                if(t.type === 'expense') expenses[dayIdx] += t.amt;
                else incomes[dayIdx] += t.amt;
            }
        });
    } else if(per === 'month'){
        // 4 tuần trong tháng hiện tại
        labels = ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
        expenses = [0, 0, 0, 0];
        incomes = [0, 0, 0, 0];
        const curY = now.getFullYear();
        const curM = now.getMonth();

        (S.transactions || []).forEach(t => {
            const d = new Date(t.date);
            if(d.getFullYear() === curY && d.getMonth() === curM){
                const day = d.getDate();
                const weekIdx = Math.min(3, Math.floor((day - 1) / 7));
                if(t.type === 'expense') expenses[weekIdx] += t.amt;
                else incomes[weekIdx] += t.amt;
            }
        });
    } else {
        // 12 tháng trong năm hiện tại
        labels = ['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];
        expenses = new Array(12).fill(0);
        incomes = new Array(12).fill(0);
        const curY = now.getFullYear();

        (S.transactions || []).forEach(t => {
            const d = new Date(t.date);
            if(d.getFullYear() === curY){
                const mIdx = d.getMonth();
                if(t.type === 'expense') expenses[mIdx] += t.amt;
                else incomes[mIdx] += t.amt;
            }
        });
    }

    const totalExp = expenses.reduce((a, b) => a + b, 0);
    const totalInc = incomes.reduce((a, b) => a + b, 0);
    return { labels, expenses, incomes, totalExp, totalInc };
}

function renderChart(per, tid='chartArea'){
    S.currentChartPer = per;
    const el = document.getElementById(tid);
    if(!el) return;

    const data = calculateChartData(per);
    const eD = data.expenses;
    const iD = data.incomes;
    const lb = data.labels;

    // Cập nhật số liệu chi tiết bên dưới biểu đồ
    const he = document.getElementById('hExp'); if(he) he.textContent = fmt(data.totalExp);
    const hi = document.getElementById('hInc'); if(hi) hi.textContent = fmt(data.totalInc);
    
    // Đếm số lượng giao dịch trong kỳ
    let txCount = 0;
    const now = new Date();
    if(per === 'week'){
        const dist = (now.getDay() + 6) % 7;
        const mon = new Date(now); mon.setDate(now.getDate() - dist); mon.setHours(0,0,0,0);
        const sun = new Date(mon); sun.setDate(mon.getDate() + 6); sun.setHours(23,59,59,999);
        txCount = (S.transactions || []).filter(t => { const d = new Date(t.date); return d >= mon && d <= sun; }).length;
    } else if(per === 'month'){
        txCount = (S.transactions || []).filter(t => { const d = new Date(t.date); return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth(); }).length;
    } else {
        txCount = (S.transactions || []).filter(t => { const d = new Date(t.date); return d.getFullYear() === now.getFullYear(); }).length;
    }
    const ht = document.getElementById('hTx'); if(ht) ht.textContent = txCount;

    const mx = Math.max(...eD, ...iD, 100000);
    const h = parseInt(getComputedStyle(el).height) || 140;
    const td = (now.getDay() + 6) % 7;

    el.innerHTML = eD.map((v, i) => {
        const eh = Math.max((v / mx) * (h - 24), v > 0 ? 5 : 2);
        const ih = Math.max((iD[i] / mx) * (h - 24), 0);
        const act = per === 'week' && i === td;
        const tooltip = `${lb[i]}: Chi ${fmt(v)}${iD[i] > 0 ? ' | Thu ' + fmt(iD[i]) : ''}`;
        return `
            <div class="bar-w" title="${tooltip}">
                <div style="display:flex;gap:2px;align-items:flex-end;width:100%;justify-content:center">
                    ${ih > 0 ? `<div class="bar bar-g" style="height:${ih}px;max-width:10px;animation:barGrow 0.4s ease ${i*0.05}s both;transform-origin:bottom"></div>` : ''}
                    <div class="bar ${act ? 'bar-v' : (v > 0 ? 'bar-v' : 'bar-m')}" style="height:${eh}px;animation:barGrow 0.4s ease ${i*0.05+0.04}s both;transform-origin:bottom"></div>
                </div>
                <span class="bar-lbl" style="${act ? 'color:var(--primary);font-weight:800' : ''}">${lb[i]}</span>
            </div>
        `;
    }).join('');
}

function swChart(btn, per){
    btn.parentElement.querySelectorAll('.chart-tab').forEach(t => t.classList.remove('active'));
    btn.classList.add('active');
    renderChart(per);
}

// ===== TRANSACTIONS & MODAL CHI TIẾT =====
function renderHomeTx(){
    renderTxL('homeTx', (S.transactions || []).slice(0, 8));
}

function deleteTx(id){
    const tx = S.transactions.find(t => t.id === id);
    if(!tx) return;
    if(confirm(`Bạn có chắc muốn xóa giao dịch "${tx.name}" (${fmt(tx.amt)})?`)){
        S.transactions = S.transactions.filter(t => t.id !== id);
        saveStateToStorage();
        renderAll();
        filterTransactions();
        fetch(`/api/transactions/${id}`, {
            method: 'DELETE',
            headers: { 'Bypass-Tunnel-Reminder': 'true' }
        }).catch(e => console.warn('Lỗi xóa backend:', e));
        const now = new Date();
        const delTimeStr = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')} ngày ${String(now.getDate()).padStart(2,'0')}/${String(now.getMonth()+1).padStart(2,'0')}/${now.getFullYear()}`;
        addAppNotification({
            title: 'Đã xóa giao dịch',
            body: `Đã xóa giao dịch ${tx.name} (${fmt(tx.amt)}).`,
            type: 'expense',
            actionUrl: 'history',
            actionText: 'Xem sổ giao dịch →'
        });
        toast('Đã xóa giao dịch!', 'info');
    }
}

function formatTxCardSubtitle(t, ct){
    const baseCat = ct ? ct.label : 'Chi tiêu';
    if(!t.note) return baseCat;

    // 1. Kiểm tra nếu là hóa đơn nhiều món: "Gồm X món: ..." hoặc "Gồm X món"
    const countMatch = t.note.match(/Gồm\s+(\d+)\s+món/i);
    if(countMatch){
        const count = countMatch[1];
        return `${baseCat} · <span class="tx-badge-count"><i class="ri-shopping-basket-line"></i> ${count} món</span>`;
    }

    // 2. Nếu là ghi chú dài thông thường, chỉ lấy tối đa 26 ký tự để tuyệt đối không tràn
    let shortNote = t.note.trim();
    if(shortNote.length > 26){
        shortNote = shortNote.substring(0, 24) + '...';
    }
    return `${baseCat} · ${shortNote}`;
}

function openTxDetailModal(id){
    const tx = S.transactions.find(t => t.id === id);
    if(!tx) return;
    S.currentDetailTxId = id;
    const isI = tx.type === 'income';
    const ct = CATS[tx.cat] || CATS.other;

    const da = document.getElementById('tdAmt');
    if(da){
        da.textContent = `${isI ? '+' : '-'}${fmt(tx.amt)}`;
        da.style.color = isI ? 'var(--success)' : 'var(--danger)';
    }
    const dn = document.getElementById('tdName'); if(dn) dn.textContent = tx.name;
    const db = document.getElementById('tdCatBadge');
    if(db){
        db.innerHTML = `<i class="${ct.ic}"></i> ${ct.label}`;
        db.style.background = ct.bg;
        db.style.color = ct.color;
    }
    const dt = document.getElementById('tdTime'); if(dt) dt.textContent = `${tx.date} lúc ${tx.time || '10:00'}`;
    const ds = document.getElementById('tdScope'); if(ds) ds.textContent = tx.name.includes('phần') ? 'Chia tiền bạn bè' : (tx.name.includes('Quỹ') ? 'Quỹ chi tiêu chung' : 'Ví cá nhân');
    const dnt = document.getElementById('tdNote');

    // Bóc tách danh sách món nếu có (khi người dùng bấm vào xem chi tiết)
    const itemsBox = document.getElementById('tdItemsBox');
    const itemsList = document.getElementById('tdItemsList');
    let items = [];

    if(tx.items && Array.isArray(tx.items) && tx.items.length > 0){
        items = tx.items.map(it => ({ name: it.name, qty: it.quantity || 1, amt: it.amount || 0 }));
    } else if(tx.note && /Gồm\s+\d+\s+món:/i.test(tx.note)){
        const afterColon = tx.note.split(/Gồm\s+\d+\s+món:\s*/i)[1] || '';
        const rawParts = afterColon.split(/,\s*/);
        items = rawParts.map(p => {
            const qMatch = p.match(/(.*?)\s*\(x(\d+)\)/);
            if(qMatch){
                return { name: qMatch[1].trim(), qty: qMatch[2], amt: 0 };
            }
            return { name: p.trim(), qty: 1, amt: 0 };
        }).filter(it => it.name);
    }

    if(itemsBox && itemsList){
        if(items.length > 0){
            itemsBox.style.display = 'block';
            itemsList.innerHTML = items.map((it, idx) => `
                <div style="display:flex;align-items:center;justify-content:space-between;padding:0.35rem 0;border-bottom:1px dashed var(--divider)">
                    <div style="display:flex;align-items:center;gap:0.4rem;overflow:hidden">
                        <span style="width:18px;height:18px;border-radius:50%;background:rgba(82,134,232,0.12);color:var(--primary);font-size:0.65rem;display:inline-flex;align-items:center;justify-content:center;font-weight:700;flex-shrink:0">${idx+1}</span>
                        <span style="color:var(--text);font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:210px" title="${it.name}">${it.name}</span>
                    </div>
                    <span style="color:var(--primary);font-weight:700;font-size:0.75rem;white-space:nowrap;margin-left:0.5rem">SL: x${it.qty}${it.amt > 0 ? ` · ${fmt(it.amt)}` : ''}</span>
                </div>
            `).join('');
            if(dnt) dnt.textContent = `Hóa đơn bóc tách (${items.length} món)`;
        } else {
            itemsBox.style.display = 'none';
            itemsList.innerHTML = '';
            if(dnt) dnt.textContent = tx.note || 'Giao dịch chi tiêu thường nhật';
        }
    } else {
        if(dnt) dnt.textContent = tx.note || 'Giao dịch chi tiêu thường nhật';
    }

    document.getElementById('txDetailModal')?.classList.add('active');
}

function closeTxDetailModal(){
    document.getElementById('txDetailModal')?.classList.remove('active');
}

function confirmDeleteCurrentTx(){
    if(!S.currentDetailTxId) return;
    const id = S.currentDetailTxId;
    closeTxDetailModal();
    deleteTx(id);
}

function renderSingleTxCard(t, i){
    const ct = CATS[t.cat] || CATS.other;
    const isI = t.type === 'income';
    const subHtml = formatTxCardSubtitle(t, ct);
    return `
        <div class="tx-item" style="animation:fadeUp 0.3s ease ${i*0.03}s both" onclick="openTxDetailModal(${t.id})">
            <div class="tx-ic" style="background:${ct.bg};color:${ct.color}"><i class="${ct.ic}"></i></div>
            <div class="tx-info">
                <div class="tx-name" title="${t.name}">${t.name}</div>
                <div class="tx-cat">${subHtml}</div>
            </div>
            <div class="tx-right">
                <div class="tx-amt ${isI ? 'inc' : 'exp'}">${isI ? '+' : '-'}${fmt(t.amt)}</div>
                <div style="display:flex;align-items:center;justify-content:flex-end;gap:0.35rem">
                    <span class="tx-time">${t.time || ''}</span>
                    <button type="button" style="background:none;border:none;color:var(--text3);cursor:pointer;padding:0 2px;font-size:0.78rem;opacity:0.6" onclick="event.stopPropagation();deleteTx(${t.id})" title="Xóa giao dịch"><i class="ri-delete-bin-line"></i></button>
                </div>
            </div>
        </div>
    `;
}

function toggleTxGroup(groupId, btn, count){
    const el = document.getElementById('txGrp_' + groupId);
    if(!el) return;
    const isHidden = el.classList.contains('hidden');
    if(isHidden){
        el.classList.remove('hidden');
        btn.innerHTML = `<i class="ri-arrow-up-s-line"></i> Thu gọn ${count} giao dịch`;
    } else {
        el.classList.add('hidden');
        btn.innerHTML = `<i class="ri-arrow-down-s-line"></i> Xem thêm ${count} giao dịch khác`;
    }
}

function renderTxL(cid, txs){
    const c = document.getElementById(cid); if(!c) return;
    if(!txs || !txs.length){
        c.innerHTML = '<div class="empty" style="padding:2rem 1rem"><div class="empty-ic"><i class="ri-inbox-line"></i></div><h3>Chưa có giao dịch</h3><p>Nhập thủ công hoặc quét ảnh hóa đơn.</p></div>';
        return;
    }
    const g = {}; txs.forEach(t => { if(!g[t.date]) g[t.date] = []; g[t.date].push(t); });
    const ds = Object.keys(g).sort((a,b) => b.localeCompare(a));
    c.innerHTML = ds.map(d => {
        const dayTxs = g[d];
        const de = dayTxs.filter(t => t.type === 'expense').reduce((s,t) => s + t.amt, 0);
        const di = dayTxs.filter(t => t.type === 'income').reduce((s,t) => s + t.amt, 0);
        let ds2 = '';
        if(de) ds2 += `<span style="color:var(--danger)">-${fmt(de)}</span>`;
        if(di) ds2 += ` <span style="color:var(--success)">+${fmt(di)}</span>`;

        // Nếu ngày đó có nhiều hơn 3 giao dịch: bo gọn lại, chỉ hiện 3 giao dịch đầu, phần còn lại ẩn đi kèm nút mở rộng
        const cleanDateKey = `${cid}_${d.replace(/[^a-zA-Z0-9]/g, '')}`;
        const hasOverflow = dayTxs.length > 3;
        const visibleTxs = hasOverflow ? dayTxs.slice(0, 3) : dayTxs;
        const hiddenTxs = hasOverflow ? dayTxs.slice(3) : [];

        return `
            <div class="tx-grp">
                <div class="tx-date">
                    <span>${dateLabel(d)}</span>
                    <span style="font-size:0.72rem;font-weight:700;text-transform:none;letter-spacing:0">${ds2}</span>
                </div>
                ${visibleTxs.map((t, i) => renderSingleTxCard(t, i)).join('')}
                ${hasOverflow ? `
                    <div class="tx-collapsed-group hidden" id="txGrp_${cleanDateKey}">
                        ${hiddenTxs.map((t, i) => renderSingleTxCard(t, 3 + i)).join('')}
                    </div>
                    <button type="button" class="btn-tx-toggle" onclick="toggleTxGroup('${cleanDateKey}', this, ${hiddenTxs.length})">
                        <i class="ri-arrow-down-s-line"></i> Xem thêm ${hiddenTxs.length} giao dịch khác
                    </button>
                ` : ''}
            </div>
        `;
    }).join('');
}

// ===== TÌM KIẾM & BỘ LỌC LỊCH SỬ GIAO DỊCH =====
function setHistFilterType(type, btn){
    S.histFilterType = type;
    document.querySelectorAll('.hist-filter-pill').forEach(p => p.classList.remove('active'));
    btn.classList.add('active');
    filterTransactions();
}

function clearTxSearch(){
    const inp = document.getElementById('txSearchInput');
    if(inp) inp.value = '';
    const btn = document.getElementById('btnClearTxSearch');
    if(btn) btn.style.display = 'none';
    filterTransactions();
}

function filterTransactions(){
    const input = document.getElementById('txSearchInput');
    const query = input ? input.value.trim().toLowerCase() : '';
    const btnClear = document.getElementById('btnClearTxSearch');
    if(btnClear) btnClear.style.display = query ? 'block' : 'none';

    const filterType = S.histFilterType || 'all';
    const catSel = document.getElementById('histCatSelect');
    const filterCat = catSel ? catSel.value : 'all';

    let list = S.transactions || [];

    if(filterType !== 'all'){
        list = list.filter(t => t.type === filterType);
    }
    if(filterCat !== 'all'){
        list = list.filter(t => t.cat === filterCat);
    }
    if(query){
        list = list.filter(t => {
            const nameMatch = (t.name || '').toLowerCase().includes(query);
            const noteMatch = (t.note || '').toLowerCase().includes(query);
            const amtMatch = String(t.amt).includes(query);
            return nameMatch || noteMatch || amtMatch;
        });
    }

    const exp = list.filter(t => t.type === 'expense').reduce((s,t) => s + t.amt, 0);
    const inc = list.filter(t => t.type === 'income').reduce((s,t) => s + t.amt, 0);
    const cntTxt = document.getElementById('histCountTxt');
    if(cntTxt) cntTxt.textContent = `${list.length} giao dịch`;
    const amtTxt = document.getElementById('histAmtTxt');
    const expStr = exp ? `-${fmt(exp)}` : '0 ₫';
    const incStr = inc ? `+${fmt(inc)}` : '0 ₫';
    if(amtTxt) amtTxt.innerHTML = `Chi: <strong style="color:var(--danger)">${expStr}</strong> · Thu: <strong style="color:var(--success)">${incStr}</strong>`;

    renderTxL('allTx', list);
}

function renderAllTx(){
    filterTransactions();
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
    const isInc = S.txType === 'income';
    const curUid = S.user?.id || 1;
    S.transactions.unshift({id:Date.now(),name:mer,amt,cat:S.selCat,date,note,time:new Date().toLocaleTimeString('vi-VN',{hour:'2-digit',minute:'2-digit'}),type:S.txType});
    saveStateToStorage();
    sendBE({merchant_name:mer,amount:amt,transaction_date:date,category:S.selCat,type:S.txType,notes:note,user_id:curUid});
    renderAll();closeModal();
    document.getElementById('txForm').reset();
    document.querySelectorAll('.cat-chip').forEach(c=>c.classList.remove('sel'));
    document.querySelector('.cat-chip[data-c="food"]').classList.add('sel');
    S.selCat='food';S.txType='expense';
    document.querySelectorAll('.type-btn').forEach(b=>b.classList.remove('active'));
    document.querySelector('.type-btn.e').classList.add('active');

    const now = new Date();
    const curTimeStr = now.toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'});
    const dParts = date ? date.split('-') : [];
    const dateFormatted = dParts.length === 3 ? `${dParts[2]}/${dParts[1]}/${dParts[0]}` : date;
    const fullTimeStr = `${curTimeStr} ngày ${dateFormatted}`;

    if(!isInc){
        addAppNotification({
            title: 'Chi tiêu',
            body: `-${fmt(amt)} tại ${mer} (${ct.label}).`,
            type: 'expense',
            actionUrl: 'history',
            actionText: 'Xem sổ giao dịch →'
        });
        checkBudgetAlerts(S.selCat);
    } else {
        addAppNotification({
            title: 'Thu nhập',
            body: `+${fmt(amt)} (${mer}).`,
            type: 'income',
            actionUrl: 'history',
            actionText: 'Xem chi tiết →'
        });
    }

    toast(`Đã lưu giao dịch ${fmt(amt)}`,'success');
}

// ===== PHOTO / CAMERA ("Chụp Toàn Cảnh 16:9 Panoramic") =====
function openCam(){
    const v=document.getElementById('camV');if(!v)return;
    const fb=document.getElementById('camFallbackBox');
    const hint=document.getElementById('camHint');
    const frame=document.getElementById('camFrame');

    if(S.camStream) return;

    if(navigator.mediaDevices && navigator.mediaDevices.getUserMedia){
        // Yêu cầu camera sau (environment) chất lượng cao, tự động tối ưu hóa theo hướng dọc của điện thoại
        const constraints = {
            video: {
                facingMode: { ideal: 'environment' },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
            }
        };
        navigator.mediaDevices.getUserMedia(constraints).catch(() => {
            // Fallback nếu thiết bị không hỗ trợ độ phân giải cao
            return navigator.mediaDevices.getUserMedia({ video: { facingMode: { ideal: 'environment' } } });
        }).then(s=>{
            S.camStream=s;
            v.srcObject=s;
            v.style.display='block';
            if(fb) fb.style.display='none';
            if(hint) hint.style.display='block';
            if(frame) frame.style.display='block';
        }).catch(err=>{
            console.warn('Camera getUserMedia not available (Safari iOS / non-HTTPS):', err);
            showCamFallback();
        });
    } else {
        showCamFallback();
    }
}

function stopCam(){
    if(S.camStream){S.camStream.getTracks().forEach(t=>t.stop());S.camStream=null}
}

function showCamFallback(){
    const v=document.getElementById('camV');
    const fb=document.getElementById('camFallbackBox');
    const hint=document.getElementById('camHint');
    const frame=document.getElementById('camFrame');
    if(v) v.style.display='none';
    if(fb) fb.style.display='flex';
    if(hint) hint.style.display='none';
    if(frame) frame.style.display='none';
}

function triggerNativeCamera(){
    const input = document.getElementById('mobileCamIn');
    if(input){
        input.value = '';
        input.click();
    } else {
        const fileIn = document.getElementById('fileIn');
        if(fileIn) fileIn.click();
    }
}

function handleCamBoxClick(){
    if(!S.camStream){
        triggerNativeCamera();
    }
}

function capPhoto(){
    const v=document.getElementById('camV'), c=document.getElementById('camC');
    if(S.camStream && v && v.videoWidth){
        c.width=v.videoWidth; c.height=v.videoHeight;
        const ctx=c.getContext('2d');
        ctx.imageSmoothingEnabled = true;
        ctx.imageSmoothingQuality = 'high';
        ctx.drawImage(v, 0, 0, v.videoWidth, v.videoHeight);
        const dataUrl=c.toDataURL('image/jpeg', 0.95);
        stopCam();
        c.toBlob(blob => {
            if(blob) sendReceiptToBackendOcr(blob, dataUrl);
            else sendReceiptToBackendOcr(dataURItoBlob(dataUrl), dataUrl);
        }, 'image/jpeg', 0.95);
    } else {
        // Mở trực tiếp camera native của điện thoại (iPhone / Android) để chụp ảnh thật
        triggerNativeCamera();
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
    if(previewSrc) document.getElementById('previewI').src = previewSrc;

    const st=document.getElementById('ocrSt'), dt=document.getElementById('ocrData'), sv=document.getElementById('ocrSave'), rt=document.getElementById('ocrRetake');
    st.classList.remove('hidden'); dt.classList.add('hidden'); sv.classList.add('hidden'); rt.classList.add('hidden');

    const fillEl = document.getElementById('ocrProgressFill');
    const statEl = document.getElementById('ocrLoadingStatusText');
    const subEl = document.getElementById('ocrLoadingSubText');

    if (subEl) subEl.textContent = 'Mô hình Google Vision OCR Cloud';
    if (fillEl) fillEl.style.width = '35%';
    if (statEl) statEl.textContent = 'Đang tải hóa đơn lên Google Vision Cloud...';

    try {
        const formData = new FormData();
        const filename = (fileOrBlob instanceof File && fileOrBlob.name) ? fileOrBlob.name : 'receipt_capture.jpg';
        formData.append('receipt', fileOrBlob, filename);

        if (fillEl) fillEl.style.width = '65%';
        if (statEl) statEl.textContent = 'Google Vision đang bóc tách ký tự và bảng giá...';

        const res = await fetch('/api/receipts/upload', { method: 'POST', body: formData });
        if (!res.ok) {
            let errMsg = `Lỗi máy chủ HTTP ${res.status}`;
            try {
                const errJson = await res.json();
                if (errJson && errJson.error) errMsg = errJson.error;
            } catch (_) {}
            throw new Error(errMsg);
        }
        const data = await res.json();

        if (fillEl) fillEl.style.width = '100%';
        console.log('Kết Quả Bóc Tách Hóa Đơn (Google Vision):', data);

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
            amount: Number(data.amount) || 0,
            subtotal: Number(data.subtotal) || Number(data.amount) || 0,
            discount: Number(data.discount) || 0,
            vat: Number(data.vat) || 0,
            cat: cat,
            date: data.transaction_date || new Date().toISOString().slice(0, 10),
            raw_text: data.raw_text || '',
            image_url: data.image_url || previewSrc,
            items: Array.isArray(data.items) ? data.items : [],
            notes: data.notes || '',
            isGroup: (cat === 'bills') || merLower.includes('trọ') || merLower.includes('phòng') || (data.amount >= 2000000),
            engine: data.engine || 'google_vision_cloud'
        };

        S.lastOcr = detected;

        st.classList.add('hidden'); 
        dt.classList.remove('hidden'); 
        sv.classList.remove('hidden'); 
        if(rt) rt.classList.remove('hidden');

        // Điền tên nơi bán vào tiêu đề
        const ocrMer = document.getElementById('ocrMer');
        if(ocrMer) ocrMer.textContent = detected.merchant;
        const ocrMer2 = document.getElementById('ocrMer2');
        if(ocrMer2) ocrMer2.textContent = detected.merchant;

        // 3 Badge / Pill Chips
        const ocrAmtChip = document.getElementById('ocrAmtChip');
        if(ocrAmtChip) ocrAmtChip.textContent = fmt(detected.amount);

        const ocrDateChip = document.getElementById('ocrDateChip');
        if(ocrDateChip){
            const dParts = (detected.date || '').split('-');
            ocrDateChip.textContent = dParts.length === 3 ? `${dParts[2]}/${dParts[1]}/${dParts[0]}` : (detected.date || 'Hôm nay');
        }

        const ocrItemsCountChip = document.getElementById('ocrItemsCountChip');
        if(ocrItemsCountChip) ocrItemsCountChip.textContent = `${detected.items.length || 1} sản phẩm`;

        // Tiền thanh toán và badge danh mục
        const ocrAmt = document.getElementById('ocrAmt');
        if(ocrAmt) ocrAmt.textContent = fmt(detected.amount);
        const ct = CATS[detected.cat] || CATS.food;
        const ocrCatBadge = document.getElementById('ocrCatBadge');
        if(ocrCatBadge){
            ocrCatBadge.textContent = ct.label;
            ocrCatBadge.style.background = ct.bg;
            ocrCatBadge.style.color = ct.color;
        }

        // Cập nhật nhãn mô hình Gemini LLM (Hướng 3)
        const engineTag = document.getElementById('ocrEngineTag');
        if (engineTag) {
            const mName = data.model_name || 'Gemini 1.5 Flash';
            engineTag.innerHTML = `<i class="ri-sparkling-fill" style="color:#f59e0b"></i> ${mName}`;
            engineTag.title = 'Gemini Multimodal LLM API (Hướng 3)';
        }

        const latEl = document.getElementById('ocrLatencyDisp');
        if(latEl){
            const lat = data.latency_ms || data.execution_time_ms || 950;
            latEl.textContent = `${(lat / 1000).toFixed(1)}s (${lat}ms)`;
        }

        const tokEl = document.getElementById('ocrTokensDisp');
        if(tokEl){
            const tok = data.token_usage?.total_tokens || 430;
            tokEl.textContent = `~${tok} tokens`;
        }

        const costEl = document.getElementById('ocrCostDisp');
        if(costEl){
            const costStr = data.cost_estimate?.formatted || '~3.5 ₫';
            costEl.textContent = costStr;
        }

        // Hiển thị Số HĐ / Bill nếu có
        const invRow = document.getElementById('ocrInvoiceRow');
        const invEl = document.getElementById('ocrInvoiceNo');
        if(invRow){
            if(data.invoice_no){
                invRow.style.display = 'flex';
                if(invEl) invEl.textContent = data.invoice_no;
            } else {
                invRow.style.display = 'none';
            }
        }

        // Hiển thị Thời gian (Ngày & Giờ)
        const dtRow = document.getElementById('ocrDateTimeRow');
        const dtEl = document.getElementById('ocrDateTime');
        if(dtRow){
            const dStr = data.transaction_date || '';
            const tStr = data.transaction_time || '';
            if(dStr || tStr){
                dtRow.style.display = 'flex';
                if(dtEl) dtEl.textContent = `${dStr}${tStr ? ' lúc ' + tStr : ''}`;
            } else {
                dtRow.style.display = 'none';
            }
        }

        // Hiển thị Hotline nếu bóc tách được
        const hlEl = document.getElementById('ocrHotline');
        const hlRow = document.getElementById('ocrHotlineRow');
        if(hlRow){
            if(data.hotline || data.phone){
                hlRow.style.display = 'flex';
                if(hlEl) hlEl.textContent = data.hotline || data.phone;
            } else {
                hlRow.style.display = 'none';
            }
        }

        // Hiển thị Địa chỉ cửa hàng
        const addrRow = document.getElementById('ocrAddressRow');
        const addrEl = document.getElementById('ocrAddress');
        if(addrRow){
            if(data.address){
                addrRow.style.display = 'flex';
                if(addrEl) {
                    addrEl.textContent = data.address;
                    addrEl.title = data.address;
                }
            } else {
                addrRow.style.display = 'none';
            }
        }

        // Hiển thị Tiền Giảm Giá và Tạm Tính nếu có ưu đãi
        const discEl = document.getElementById('ocrDiscount');
        const discRow = document.getElementById('ocrDiscountRow');
        const subEl = document.getElementById('ocrSubtotal');
        const subRow = document.getElementById('ocrSubtotalRow');
        if(discRow && discEl){
            if(data.discount && data.discount > 0){
                discRow.style.display = 'flex';
                discEl.textContent = `-${fmt(data.discount)}`;
                if(subRow && subEl && data.subtotal && data.subtotal > data.amount){
                    subRow.style.display = 'flex';
                    subEl.textContent = fmt(data.subtotal);
                } else if(subRow) {
                    subRow.style.display = 'none';
                }
            } else {
                discRow.style.display = 'none';
                if(subRow) subRow.style.display = 'none';
            }
        }

        // Hiển thị Thuế VAT
        const vatRow = document.getElementById('ocrVatRow');
        const vatEl = document.getElementById('ocrVat');
        if(vatRow){
            if(data.vat && data.vat > 0){
                vatRow.style.display = 'flex';
                if(vatEl) vatEl.textContent = `+${fmt(data.vat)}`;
            } else {
                vatRow.style.display = 'none';
            }
        }

        // Hiển thị Hình thức thanh toán (PTTT)
        const pmRow = document.getElementById('ocrPaymentMethodRow');
        const pmEl = document.getElementById('ocrPaymentMethod');
        if(pmRow){
            if(data.payment_method){
                pmRow.style.display = 'flex';
                if(pmEl) pmEl.textContent = data.payment_method;
            } else {
                pmRow.style.display = 'none';
            }
        }

        // Mặc định chuyển sang xem Tab 1: Từng sản phẩm
        switchOcrViewTab('items');

        // Hiển thị danh sách từng món và toàn văn văn bản OCR
        renderOcrItemsAndRawText(detected);

        const fb = document.getElementById('ocrFundBalance');
        if(fb && S.groupFund) fb.textContent = fmt(S.groupFund.balance);

        if(detected.amount >= 2000000 || merLower.includes('trọ') || merLower.includes('phòng')){
            setBillScope('fund');
        }
        // Kiểm tra xem đã cấu hình Google Cloud Vision API Key chưa
        if(data.success === false || data.error_code === 'not_configured'){
            showApiKeyConfigBanner(data.error);
        } else {
            hideApiKeyConfigBanner();
            toast(`Nhận diện thành công: ${detected.merchant} (${fmt(detected.amount)})!`, 'success');
        }

    } catch(err) {
        console.error('OCR Pipeline Error:', err);
        st.classList.add('hidden'); dt.classList.remove('hidden'); sv.classList.remove('hidden'); if(rt) rt.classList.remove('hidden');
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

// ===== HIỂN THỊ CHI TIẾT TỪNG MÓN & TOÀN VĂN HÓA ĐƠN OCR =====
function renderOcrItemsAndRawText(detected){
    // 1. Toàn văn văn bản OCR gốc ("không thiếu 1 chữ")
    const rawEl = document.getElementById('ocrRawTextContent');
    if(rawEl){
        const fullTxt = detected.raw_text ? detected.raw_text.trim() : `${detected.merchant}\nNgày: ${detected.date}\nTổng tiền: ${fmt(detected.amount)}`;
        rawEl.textContent = fullTxt;
    }

    // 2. Danh sách chi tiết từng món / sản phẩm bóc tách được
    let items = (detected.items && detected.items.length) ? detected.items : [];

    // Nếu là hóa đơn không bóc tách được từng dòng con, tạo mặc định 1 món chính
    if(!items.length && detected.amount > 0){
        items = [{
            name: detected.merchant || 'Khoản chi hóa đơn',
            amount: detected.amount,
            quantity: 1
        }];
    }

    // Gán dữ liệu cho bảng Từng Sản Phẩm (4 Cột chuẩn theo thiết kế)
    S.ocrItems = items.map((it, idx) => {
        const q = Number(it.quantity) || 1;
        const a = Number(it.amount) || 0;
        return {
            id: idx,
            selected: true,
            name: it.name || `Sản phẩm ${idx + 1}`,
            quantity: q,
            unit_price: Number(it.unit_price) || (a > 0 ? Math.round(a / q) : 0),
            amount: a
        };
    });

    // Render bảng sản phẩm & tính toán tổng số tiền
    renderOcrProductsTable();
    updateOcrItemsTableSummary();

    // Hỗ trợ chia tiền theo món nếu người dùng chuyển tab sang Chia theo món
    const defaultNames = ['Tôi', 'Bạn 1', 'Bạn 2', 'Bạn 3'];
    S.currentBillItems = items.map((it, idx) => ({
        id: idx,
        name: it.name || `Món ${idx + 1}`,
        amount: Number(it.amount) || 0,
        assignedTo: defaultNames[idx % defaultNames.length]
    }));
    renderItemizedSplit();
}

function switchOcrViewTab(tab){
    S.ocrCurrentViewTab = tab;
    const tabItems = document.getElementById('tabItemsView');
    const tabOverall = document.getElementById('tabOverallView');
    const viewItems = document.getElementById('ocrViewItems');
    const viewOverall = document.getElementById('ocrViewOverall');

    if(tab === 'items'){
        tabItems?.classList.add('active');
        tabOverall?.classList.remove('active');
        viewItems?.classList.remove('hidden');
        viewOverall?.classList.add('hidden');
    } else {
        tabItems?.classList.remove('active');
        tabOverall?.classList.add('active');
        viewItems?.classList.add('hidden');
        viewOverall?.classList.remove('hidden');
    }
}

function renderOcrProductsTable(){
    const tbody = document.getElementById('ocrProductsTableBody');
    if(!tbody) return;
    const items = S.ocrItems || [];
    if(!items.length){
        tbody.innerHTML = `<tr><td colspan="4" style="text-align:center;padding:1rem;color:var(--text3);font-size:0.8rem">Không có sản phẩm nào</td></tr>`;
        return;
    }

    tbody.innerHTML = items.map((it, idx) => {
        const hasSubUnitPrice = it.quantity > 1 && it.unit_price > 0 && Math.abs(it.unit_price - it.amount) > 1;
        return `
        <tr data-idx="${idx}">
            <td style="width:36px;text-align:center;vertical-align:middle">
                <input type="checkbox" class="ocr-custom-chk item-chk" data-idx="${idx}" ${it.selected ? 'checked' : ''} onchange="onItemCheckChanged(${idx}, this.checked)" title="Chọn sản phẩm">
            </td>
            <td style="padding-right:0.25rem">
                <input type="text" class="ocr-cell-name" value="${it.name.replace(/"/g, '&quot;')}" oninput="onItemFieldEdited(${idx}, 'name', this.value)" placeholder="Tên sản phẩm">
            </td>
            <td style="width:58px;text-align:center;padding:0 0.2rem">
                <input type="text" class="ocr-cell-qty" value="x${it.quantity}" onchange="onItemFieldEdited(${idx}, 'quantity', this.value)" placeholder="SL">
            </td>
            <td style="width:115px;text-align:right">
                <input type="text" class="ocr-cell-price" value="${fmt(it.amount)}" onchange="onItemFieldEdited(${idx}, 'amount', this.value)" placeholder="0 ₫">
                <div class="ocr-cell-unit-hint" style="font-size:0.68rem;color:var(--text3);text-align:right;margin-top:2px;font-weight:500;display:${hasSubUnitPrice ? 'block' : 'none'}">(${fmt(it.unit_price)}/đv)</div>
            </td>
        </tr>
        `;
    }).join('');
}

function updateOcrItemsTableSummary(){
    const items = S.ocrItems || [];
    const totalCount = items.length;
    const selectedItems = items.filter(it => it.selected);
    const selectedCount = selectedItems.length;
    const itemsSum = selectedItems.reduce((acc, it) => acc + (Number(it.amount) || 0), 0);

    const discount = (S.lastOcr && Number(S.lastOcr.discount)) || 0;
    const vat = (S.lastOcr && Number(S.lastOcr.vat)) || 0;

    // Tính toán tổng thanh toán thực tế (Đồng bộ 100% giữa Tab 1 và Tab 2)
    let finalAmount = itemsSum;
    if(discount > 0 || vat > 0){
        finalAmount = Math.max(0, itemsSum - discount + vat);
    }

    // Cập nhật tỷ lệ đã chọn (e.g. 7/7)
    const ratioEl = document.getElementById('ocrSelectedRatio');
    if(ratioEl) ratioEl.textContent = `${selectedCount}/${totalCount}`;

    // Nút Bỏ chọn / Chọn tất cả
    const toggleBtn = document.getElementById('btnToggleAllItems');
    if(toggleBtn){
        toggleBtn.textContent = (selectedCount === totalCount && totalCount > 0) ? 'Bỏ chọn' : 'Chọn tất cả';
    }

    // Checkbox master trên header
    const topChk = document.getElementById('chkSelectAllTop');
    if(topChk){
        topChk.checked = (selectedCount === totalCount && totalCount > 0);
        topChk.indeterminate = (selectedCount > 0 && selectedCount < totalCount);
    }

    // Summary box dưới bảng (Tab 1: Từng sản phẩm)
    const cntEl = document.getElementById('ocrSelectedItemsCount');
    if(cntEl) cntEl.textContent = selectedCount;

    const totalAmtEl = document.getElementById('ocrSelectedTotalAmt');
    if(totalAmtEl) totalAmtEl.textContent = fmt(finalAmount);

    // Cập nhật 3 Pill Chips trên đầu
    const amtChip = document.getElementById('ocrAmtChip');
    if(amtChip) amtChip.textContent = fmt(finalAmount);

    const countChip = document.getElementById('ocrItemsCountChip');
    if(countChip) countChip.textContent = `${totalCount} sản phẩm`;

    // Cập nhật Tab 2: "Tổng đơn" -> Thanh toán thực tế (ĐỒNG BỘ 100% VỚI TAB 1)
    const ocrAmt = document.getElementById('ocrAmt');
    if(ocrAmt) ocrAmt.textContent = fmt(finalAmount);

    const subEl = document.getElementById('ocrSubtotal');
    if(subEl) subEl.textContent = fmt(itemsSum);

    // Cập nhật nhãn nút Lưu vào Ví
    const saveTxt = document.getElementById('ocrSaveBtnTxt');
    if(saveTxt) saveTxt.textContent = `Lưu vào Ví (${fmt(finalAmount)})`;

    const pa = document.getElementById('personalSaveAmt');
    if(pa) pa.textContent = fmt(finalAmount);

    if(S.lastOcr){
        S.lastOcr.amount = finalAmount;
        S.lastOcr.subtotal = itemsSum;
        S.lastOcr.selectedAmount = finalAmount;
        S.lastOcr.selectedItems = selectedItems;
    }

    updateSplitBillCalculations();
}

function toggleSelectAllReceiptItems(){
    const items = S.ocrItems || [];
    if(!items.length) return;
    const allSelected = items.every(it => it.selected);
    const newStatus = !allSelected;
    items.forEach(it => { it.selected = newStatus; });
    document.querySelectorAll('.item-chk').forEach(chk => { chk.checked = newStatus; });
    updateOcrItemsTableSummary();
}

function onItemCheckChanged(idx, isChecked){
    if(S.ocrItems && S.ocrItems[idx]){
        S.ocrItems[idx].selected = isChecked;
        updateOcrItemsTableSummary();
    }
}

function onItemFieldEdited(idx, field, value){
    if(!S.ocrItems || !S.ocrItems[idx]) return;
    if(field === 'name'){
        S.ocrItems[idx].name = value.trim();
    } else if(field === 'quantity'){
        const num = parseFloat(value.replace(/[^0-9.]/g, '')) || 1;
        const oldQty = S.ocrItems[idx].quantity || 1;
        S.ocrItems[idx].quantity = num;
        // Nếu người dùng thay đổi số lượng, tự động cập nhật lại thành tiền tương ứng:
        if(num !== oldQty && S.ocrItems[idx].amount > 0){
            const unitPrice = S.ocrItems[idx].unit_price || Math.round(S.ocrItems[idx].amount / oldQty);
            S.ocrItems[idx].unit_price = unitPrice;
            S.ocrItems[idx].amount = Math.round(unitPrice * num);
            const priceInput = document.querySelector(`tr[data-idx="${idx}"] .ocr-cell-price`);
            if(priceInput) priceInput.value = fmt(S.ocrItems[idx].amount);
        }
    } else if(field === 'amount'){
        const amt = parseFloat(value.replace(/[^0-9]/g, '')) || 0;
        S.ocrItems[idx].amount = amt;
        if(S.ocrItems[idx].quantity > 0){
            S.ocrItems[idx].unit_price = Math.round(amt / S.ocrItems[idx].quantity);
        }
        const el = document.querySelector(`tr[data-idx="${idx}"] .ocr-cell-price`);
        if(el && document.activeElement !== el) el.value = fmt(amt);
    }
    const hintEl = document.querySelector(`tr[data-idx="${idx}"] .ocr-cell-unit-hint`);
    if(hintEl){
        const it = S.ocrItems[idx];
        if(it.quantity > 1 && it.unit_price > 0 && Math.abs(it.unit_price - it.amount) > 1){
            hintEl.textContent = `(${fmt(it.unit_price)}/đv)`;
            hintEl.style.display = 'block';
        } else {
            hintEl.style.display = 'none';
        }
    }
    updateOcrItemsTableSummary();
}

async function saveReceiptData(){
    const ocr = S.lastOcr || {};
    const selectedItems = (S.ocrItems || []).filter(it => it.selected);
    const saveAmt = (typeof ocr.selectedAmount === 'number') 
        ? ocr.selectedAmount 
        : (selectedItems.reduce((acc, it) => acc + (Number(it.amount) || 0), 0) || ocr.amount || 0);

    if(saveAmt <= 0 && selectedItems.length > 0){
        toast('Vui lòng kiểm tra lại giá tiền của các món đã chọn!', 'warning');
        return;
    }

    // Cập nhật S.lastOcr trước khi lưu
    ocr.amount = saveAmt;
    if(selectedItems.length > 0){
        ocr.items = selectedItems;
        ocr.notes = `Gồm ${selectedItems.length} món: ` + selectedItems.map(it => `${it.name} (x${it.quantity})`).join(', ');
    }

    await saveOcr();
}

function copyFullOcrText(){
    const text = document.getElementById('ocrRawTextContent')?.textContent || '';
    if(!text) return;
    if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(text).then(()=>{
            toast('Đã sao chép toàn bộ chữ trên hóa đơn!', 'success');
        });
    } else {
        prompt('Toàn văn hóa đơn:', text);
    }
}

// ===== QUẢN LÝ GOOGLE CLOUD VISION API KEY =====
function showApiKeyConfigBanner(errMsg){
    const banner = document.getElementById('ocrApiKeyBanner');
    if(banner) banner.classList.remove('hidden');
    toast(errMsg || 'Chưa có GOOGLE_API_KEY. Vui lòng nhập API Key để quét trên Google Cloud!', 'warning');
}

function hideApiKeyConfigBanner(){
    const banner = document.getElementById('ocrApiKeyBanner');
    if(banner) banner.classList.add('hidden');
}

async function saveGoogleApiKeyFromUi(){
    const input = document.getElementById('inputGoogleApiKey');
    const val = input ? input.value.trim() : '';
    if(!val){
        toast('Vui lòng dán GOOGLE_API_KEY hợp lệ!', 'warning');
        return;
    }
    try {
        const res = await fetch('/api/ocr/config', {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ google_api_key: val })
        });
        const d = await res.json();
        if(res.ok && d.success){
            toast('Đã lưu GOOGLE_API_KEY thành công! Hãy chọn lại ảnh để quét.', 'success');
            hideApiKeyConfigBanner();
            if(input) input.value = '';
        } else {
            toast(d.error || 'Lỗi khi lưu API Key', 'error');
        }
    } catch(e){
        toast('Lỗi kết nối máy chủ khi lưu API Key', 'error');
    }
}

// ===== CHẾ ĐỘ CHIA TIỀN: CHIA ĐỀU HOẶC CHIA THEO MÓN =====
function setSplitMode(mode){
    S.splitMode = mode;
    const isEq = mode === 'equal';
    const bEq = document.getElementById('btnSplitModeEqual');
    const bIt = document.getElementById('btnSplitModeItem');
    if(bEq) bEq.className = `btn btn-sm ${isEq ? 'btn-p' : 'btn-s'}`;
    if(bIt) bIt.className = `btn btn-sm ${!isEq ? 'btn-p' : 'btn-s'}`;

    document.getElementById('splitEqualContainer')?.classList.toggle('hidden', !isEq);
    document.getElementById('splitItemContainer')?.classList.toggle('hidden', isEq);
    document.getElementById('splitRoleCards')?.classList.toggle('hidden', !isEq);

    if(!isEq){
        renderItemizedSplit();
    } else {
        updateSplitBillCalculations();
    }
}

function renderItemizedSplit(){
    const listEl = document.getElementById('splitItemsAssignList');
    if(!listEl) return;

    const items = S.currentBillItems || [];
    const members = ['Tôi', 'Bạn 1', 'Bạn 2', 'Bạn 3', 'Chia đều món này'];

    if(!items.length){
        listEl.innerHTML = `<div style="text-align:center;color:var(--text3);font-size:0.72rem;padding:0.5rem">Chưa có danh sách món.</div>`;
        return;
    }

    listEl.innerHTML = items.map((it, idx) => `
        <div style="display:flex;justify-content:space-between;align-items:center;padding:0.35rem 0.5rem;background:var(--bg);border-radius:var(--r-sm);font-size:0.72rem">
            <div style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;margin-right:0.4rem">
                <strong>${it.name}</strong> <span style="color:var(--primary);font-weight:700">(${fmt(it.amount)})</span>
            </div>
            <select class="fc" style="width:115px;padding:0.2rem 0.3rem;font-size:0.7rem;height:28px" onchange="onItemAssignChange(${idx}, this.value)">
                ${members.map(m => `<option value="${m}" ${it.assignedTo === m ? 'selected' : ''}>${m}</option>`).join('')}
            </select>
        </div>
    `).join('');

    updateItemizedMemberSummary();
}

function onItemAssignChange(itemIdx, memberName){
    if(S.currentBillItems && S.currentBillItems[itemIdx]){
        S.currentBillItems[itemIdx].assignedTo = memberName;
        updateItemizedMemberSummary();
    }
}

function updateItemizedMemberSummary(){
    const sumEl = document.getElementById('splitItemsMemberSummary');
    if(!sumEl) return;

    const items = S.currentBillItems || [];
    const totals = {};
    let sharedPool = 0;

    items.forEach(it => {
        if(it.assignedTo === 'Chia đều món này'){
            sharedPool += it.amount;
        } else {
            totals[it.assignedTo] = (totals[it.assignedTo] || 0) + it.amount;
        }
    });

    const activeMembers = Object.keys(totals);
    if(activeMembers.length > 0 && sharedPool > 0){
        const sharePerPerson = Math.round(sharedPool / activeMembers.length);
        activeMembers.forEach(m => totals[m] += sharePerPerson);
    } else if(sharedPool > 0){
        totals['Tôi'] = (totals['Tôi'] || 0) + sharedPool;
    }

    S.itemizedTotals = totals;

    sumEl.innerHTML = Object.entries(totals).map(([m, amt]) => `
        <div style="display:flex;justify-content:space-between;align-items:center;font-size:0.75rem;padding:0.15rem 0">
            <span style="color:var(--text2)"><i class="ri-user-line" style="color:var(--primary)"></i> <strong>${m}</strong>:</span>
            <strong style="color:var(--primary)">${fmt(amt)}</strong>
        </div>
    `).join('');

    const btnTxt = document.getElementById('ocrSaveBtnTxt');
    if(btnTxt && S.billScope === 'split' && S.splitMode === 'item'){
        const myAmt = totals['Tôi'] || 0;
        btnTxt.textContent = `Lưu phần tôi (${fmt(myAmt)})`;
    }
}

function openItemizedSplitQrModal(){
    const totals = S.itemizedTotals || {};
    const members = Object.keys(totals).filter(m => m !== 'Tôi' && totals[m] > 0);

    if(!members.length){
        toast('Tất cả món đang gán cho "Tôi". Hãy chọn bạn khác cho các món để tạo mã QR chia tiền!', 'info');
        return;
    }

    showItemizedQrForMember(members[0]);
}

function showItemizedQrForMember(targetMember){
    const totals = S.itemizedTotals || {};
    const amt = totals[targetMember] || 0;
    const memo = `TIEN NUOC ${targetMember.toUpperCase().replace(/\s+/g,'')}`;
    const members = Object.keys(totals).filter(m => m !== 'Tôi' && totals[m] > 0);

    const body = document.getElementById('qrModalBody');
    if(!body) return;

    body.innerHTML = `
        <div class="qr-card-view" style="padding:0.75rem">
            <div style="font-size:0.88rem;font-weight:800;color:var(--text);margin-bottom:0.4rem">Mã VietQR Cho Từng Người</div>
            
            <!-- Tabs chọn người -->
            <div style="display:flex;gap:0.3rem;justify-content:center;margin-bottom:0.7rem;overflow-x:auto;padding-bottom:0.2rem">
                ${members.map(m => `
                    <button type="button" class="btn btn-sm ${m === targetMember ? 'btn-p' : 'btn-s'}" style="font-size:0.72rem;padding:0.3rem 0.55rem" onclick="showItemizedQrForMember('${m}')">
                        ${m} (${fmt(totals[m])})
                    </button>
                `).join('')}
            </div>

            <div style="background:#FFF;padding:12px;border-radius:12px;display:inline-block;box-shadow:0 4px 14px rgba(0,0,0,0.06);margin-bottom:0.5rem">
                <canvas id="itemizedQrCanvas" width="160" height="160" style="display:block"></canvas>
            </div>
            
            <div style="font-size:1.2rem;font-weight:900;color:var(--primary);margin-bottom:0.15rem">${fmt(amt)}</div>
            <div style="font-size:0.75rem;color:var(--text2);margin-bottom:0.5rem">${targetMember} quét mã trả đúng tiền món đã gọi</div>

            <div style="background:var(--bg);padding:0.6rem;border-radius:8px;font-size:0.72rem;text-align:left;margin-bottom:0.6rem">
                ${S.user?.bank_account ? `
                    <div><strong>Ngân hàng:</strong> ${S.user.bank_name || 'Ngân hàng'}</div>
                    <div><strong>Số tài khoản:</strong> ${S.user.bank_account}</div>
                ` : `
                    <div><strong>Phương thức:</strong> Quét mã VietQR hoặc chuyển khoản trực tiếp</div>
                `}
                <div><strong>Người nhận:</strong> ${S.user?.name || S.user?.full_name || 'Trưởng nhóm'}</div>
                <div><strong>Nội dung:</strong> ${memo}</div>
            </div>

            <button type="button" class="btn btn-p btn-block" style="font-size:0.78rem" onclick="copyItemizedZaloMessage('${targetMember}', ${amt})">
                <i class="ri-file-copy-line"></i> Sao chép tin nhắn Zalo cho ${targetMember}
            </button>
        </div>
    `;

    openQrModal();
    setTimeout(() => {
        const cv = document.getElementById('itemizedQrCanvas');
        if(cv) drawMockVietQr(cv, amt, memo);
    }, 50);
}

function copyItemizedZaloMessage(memberName, amt){
    const bankInfo = S.user?.bank_account ? ` STK: ${S.user.bank_account} (${S.user.bank_name || ''}), ` : ' ';
    const msg = `Tiền nước của ${memberName}: ${fmt(amt)}. Bạn quét QR hoặc chuyển khoản vào${bankInfo}cú pháp: TIEN NUOC ${memberName.toUpperCase()} nhé!`;
    if(navigator.clipboard && navigator.clipboard.writeText){
        navigator.clipboard.writeText(msg).then(()=>{
            toast(`Đã sao chép tin nhắn cho ${memberName}!`, 'success');
        });
    } else {
        prompt('Sao chép tin nhắn:', msg);
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

async function loadSampleReceipt(filename, label){
    openModal('upload');
    toast(`Đang nạp ảnh ${label}...`, 'info');
    try {
        const res = await fetch('/samples/' + filename);
        if(!res.ok) throw new Error('Không thể tải ảnh mẫu từ máy chủ');
        const blob = await res.blob();
        sendReceiptToBackendOcr(blob, '/samples/' + filename);
    } catch(e) {
        toast('Lỗi tải ảnh mẫu: ' + e.message, 'error');
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
        saveStateToStorage();
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
        const now = new Date();
        const dParts = dateStr ? dateStr.split('-') : [];
        const dateFormatted = dParts.length === 3 ? `${dParts[2]}/${dParts[1]}/${dParts[0]}` : dateStr;
        const scanFullTime = `${nowStr || now.toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'})} ngày ${dateFormatted}`;

        addAppNotification({
            title: 'Quét hóa đơn',
            body: `Đã lưu ${data.merchant} (${fmt(data.amount)}).`,
            type: 'expense',
            actionUrl: 'history',
            actionText: 'Xem giao dịch →'
        });
        checkBudgetAlerts(data.cat);
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
        saveStateToStorage();
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

        const now = new Date();
        const dParts = dateStr ? dateStr.split('-') : [];
        const dateFormatted = dParts.length === 3 ? `${dParts[2]}/${dParts[1]}/${dParts[0]}` : dateStr;
        const splitTimeFull = `${nowStr || now.toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'})} ngày ${dateFormatted}`;

        addAppNotification({
            title: 'Chia tiền hóa đơn',
            body: `${data.merchant} (${fmt(data.amount)}) chia ${count} người. Phần bạn: ${fmt(myShare)}.`,
            type: 'split',
            actionUrl: 'history',
            actionText: 'Xem chi tiết →'
        });

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
                user: S.user ? S.user.name : 'Thành viên 1'
            });
        }

        renderAll();
        renderGroup();
        closeModal();

        const now = new Date();
        const dParts = dateStr ? dateStr.split('-') : [];
        const dateFormatted = dParts.length === 3 ? `${dParts[2]}/${dParts[1]}/${dParts[0]}` : dateStr;
        const fundTimeFull = `${nowStr || now.toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'})} ngày ${dateFormatted}`;

        addAppNotification({
            title: 'Trích chi quỹ nhóm',
            body: `Trích ${fmt(data.amount)} từ ${fund.name} trả ${data.merchant}.`,
            type: 'fund',
            actionUrl: 'group',
            actionText: 'Xem quỹ phòng →'
        });

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
                ${S.user?.bank_account ? `<div class="qr-row"><span style="color:var(--text3)">Số TK:</span> <strong>${S.user.bank_account}</strong> (${S.user.bank_name || 'Ngân hàng'})</div>` : ''}
                <div class="qr-row"><span style="color:var(--text3)">Người nhận:</span> <strong>${S.user?.name || S.user?.full_name || 'Trưởng nhóm'}</strong></div>
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
    const bankInfo = S.user?.bank_account ? ` STK: ${S.user.bank_account} (${S.user.bank_name || 'Ngân hàng'} - ${S.user.name || 'Trưởng nhóm'}).` : '';
    const msg = `Tiền ${merchant}: ${fmt(totalAmt)} chia ${count} = ${fmt(perPerson)}/người.${bankInfo}`;
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
function addBgt(){
    const c=document.getElementById('bfC').value,a=parseFloat(document.getElementById('bfA').value);
    if(!a){toast('Nhập hạn mức!','error');return}
    const ex=S.budgets.find(b=>b.cat===c);
    if(ex)ex.limit=a;else S.budgets.push({cat:c,limit:a});
    saveStateToStorage();
    fetch('/api/budgets', {
        method: 'POST',
        headers: {'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
        body: JSON.stringify({ user_id: S.user?.id || 1, category: c, limit_amount: a })
    }).catch(()=>{});
    togForm('bgtF');renderBgt();
    const c2 = CATS[c] || CATS.other;
    addAppNotification({
        title: 'Thiết lập ngân sách',
        body: `Hạn mức ${c2.label}: ${fmt(a)}.`,
        type: 'budget',
        actionUrl: 'budget',
        actionText: 'Xem ngân sách →'
    });
    toast('Đã lưu ngân sách!','success');
}

// ===== SAVINGS =====
function renderSav(){
    const tot=S.savings.reduce((s,g)=>s+g.saved,0);document.getElementById('savT').textContent=fmt(tot);
    document.getElementById('savL').innerHTML=S.savings.map((g,i)=>{const pct=Math.min(100,(g.saved/g.target*100)).toFixed(0);const col=pct>=100?'var(--success)':'var(--primary)';
    return`<div class="sav-card" style="animation:fadeUp 0.3s ease ${i*0.07}s both"><div class="sav-hdr"><div class="sav-ic"><i class="${SAVICONS[g.icon]||'ri-star-line'}"></i></div><div><div class="sav-name">${g.name}</div><div class="sav-target">Mục tiêu: ${fmt(g.target)}</div></div></div><div class="sav-bar"><div class="sav-bar-fill" style="width:${pct}%;background:${col}"></div></div><div class="sav-foot"><span class="sav-foot-amt">${fmt(g.saved)}</span><span class="sav-foot-pct" style="color:${col}">${pct}%</span></div><div style="margin-top:0.4rem;display:flex;gap:0.3rem"><button class="btn btn-sm btn-p" style="flex:1" onclick="addToSav(${g.id})"><i class="ri-add-line"></i> Nạp tiền</button><button class="btn btn-sm btn-s" onclick="delSav(${g.id})"><i class="ri-delete-bin-line"></i></button></div></div>`;}).join('');
}

function addSav(){
    const n=document.getElementById('sfN').value.trim(),t=parseFloat(document.getElementById('sfT').value),ic=document.getElementById('sfI').value;
    if(!n||!t){toast('Điền đầy đủ!','error');return}
    const newSav = {id:Date.now(),name:n,icon:ic,target:t,saved:0};
    S.savings.push(newSav);
    saveStateToStorage();
    fetch('/api/savings', {
        method: 'POST',
        headers: {'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
        body: JSON.stringify({ user_id: S.user?.id || 1, name: n, icon: ic, target_amount: t })
    }).then(r=>r.json()).then(d=>{if(d.saving_id)newSav.id=d.saving_id;saveStateToStorage();}).catch(()=>{});
    togForm('savF');renderSav();
    addAppNotification({
        title: 'Mục tiêu tiết kiệm mới',
        body: `Mục tiêu "${n}", kế hoạch: ${fmt(t)}.`,
        type: 'savings',
        actionUrl: 'savings',
        actionText: 'Xem heo đất →'
    });
    toast('Đã tạo mục tiêu!','success');
}

function addToSav(id){
    const g = S.savings.find(s => s.id === id);
    if(!g) return;
    S.currentSavingsGoalId = id;
    const nameEl = document.getElementById('sdGoalName'); if(nameEl) nameEl.textContent = g.name;
    const targetEl = document.getElementById('sdGoalTarget'); if(targetEl) targetEl.textContent = fmt(g.target);
    const curEl = document.getElementById('sdGoalCurrent'); if(curEl) curEl.textContent = `Đã có: ${fmt(g.saved)}`;
    const pct = Math.min(100, Math.round((g.saved / g.target) * 100));
    const pctEl = document.getElementById('sdGoalPercent'); if(pctEl) pctEl.textContent = `${pct}%`;
    const barEl = document.getElementById('sdGoalBar'); if(barEl) barEl.style.width = `${pct}%`;
    const icEl = document.getElementById('sdGoalIcon'); if(icEl) icEl.innerHTML = `<i class="${SAVICONS[g.icon]||'ri-star-line'}"></i>`;
    const inEl = document.getElementById('sdAmountInput'); if(inEl) inEl.value = '200000';

    document.getElementById('savingsDepositModal')?.classList.add('active');
}

function closeSavingsDepositModal(){
    document.getElementById('savingsDepositModal')?.classList.remove('active');
}

function setQuickDepositAmt(amt){
    const inEl = document.getElementById('sdAmountInput');
    if(inEl) inEl.value = amt;
}

function confirmSavingsDeposit(){
    if(!S.currentSavingsGoalId) return;
    const g = S.savings.find(s => s.id === S.currentSavingsGoalId);
    if(!g) return;
    const inEl = document.getElementById('sdAmountInput');
    const amt = parseFloat(inEl?.value);
    if(!amt || amt <= 0){
        toast('Vui lòng nhập số tiền hợp lệ!', 'error');
        return;
    }
    g.saved += amt;
    saveStateToStorage();
    fetch(`/api/savings/${g.id}`, {
        method: 'PUT',
        headers: {'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
        body: JSON.stringify({ saved_amount: g.saved })
    }).catch(()=>{});
    const pct = Math.min(100, Math.round((g.saved / g.target) * 100));
    renderSav();
    renderStatsSav();
    closeSavingsDepositModal();
    addAppNotification({
        title: 'Tích lũy tiết kiệm',
        body: `Nạp ${fmt(amt)} vào "${g.name}". Tiến độ: ${pct}%.`,
        type: 'savings',
        actionUrl: 'savings',
        actionText: 'Xem heo đất →'
    });
    toast(`Đã nạp ${fmt(amt)} vào "${g.name}" thành công!`, 'success');
}

function delSav(id){
    const g=S.savings.find(s=>s.id===id);
    S.savings=S.savings.filter(s=>s.id!==id);
    saveStateToStorage();
    renderSav();
    fetch(`/api/savings/${id}`, { method: 'DELETE', headers: {'Bypass-Tunnel-Reminder':'true'} }).catch(()=>{});
    if(g){
        addAppNotification({
            title: 'Xóa mục tiêu tiết kiệm',
            body: `Đã gỡ mục tiêu "${g.name}".`,
            type: 'savings',
            actionUrl: 'savings',
            actionText: 'Xem tiết kiệm →'
        });
    }
    toast('Đã xoá','info');
}

// ===== RECURRING =====
function executeRecurring(id){
    const r = S.recurring.find(x => x.id === id);
    if(!r) return;
    const nowStr = new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'});
    const todayStr = new Date().toISOString().slice(0, 10);
    const newTx = {
        id: Date.now(),
        name: r.name,
        amt: r.amt,
        cat: r.cat,
        date: todayStr,
        time: nowStr,
        type: 'expense',
        note: `Khoản định kỳ (${r.freq === 'monthly' ? 'Hàng tháng' : (r.freq === 'weekly' ? 'Hàng tuần' : 'Hàng ngày')})`
    };
    S.transactions.unshift(newTx);
    saveStateToStorage();
    sendBE({
        merchant_name: r.name,
        amount: r.amt,
        transaction_date: todayStr,
        category: r.cat,
        user_id: S.user?.id || 1,
        type: 'expense',
        notes: newTx.note
    });

    renderAll();
    checkBudgetAlerts(r.cat);

    addAppNotification({
        title: 'Chi tiêu định kỳ',
        body: `-${fmt(r.amt)} cho "${r.name}".`,
        type: 'expense',
        actionUrl: 'history',
        actionText: 'Xem giao dịch →'
    });

    toast(`Đã ghi nhận ${r.name} (${fmt(r.amt)}) vào sổ!`, 'success');
}

function renderRec(){
    const fq={daily:'Hàng ngày',weekly:'Hàng tuần',monthly:'Hàng tháng'};
    document.getElementById('recL').innerHTML=S.recurring.map((r,i)=>{const ct=CATS[r.cat]||CATS.other;
    return`
        <div class="rec-card" style="animation:fadeUp 0.3s ease ${i*0.05}s both">
            <div class="tx-ic" style="background:${ct.bg};color:${ct.color}"><i class="${ct.ic}"></i></div>
            <div class="rec-info">
                <div class="rec-name">${r.name}</div>
                <div class="rec-sub"><span class="freq-tag">${fq[r.freq]}</span> · ${ct.label}</div>
            </div>
            <div class="rec-amt">${fmt(r.amt)}</div>
            <button type="button" class="btn btn-sm btn-o" style="font-size:0.68rem;padding:0.25rem 0.55rem;margin-left:0.5rem;margin-right:0.3rem" onclick="executeRecurring(${r.id})" title="Ghi nhận vào sổ thu chi ngay"><i class="ri-play-circle-line"></i> Ghi ngay</button>
            <label class="toggle"><input type="checkbox" ${r.on?'checked':''} onchange="togRec(${r.id},this.checked)"><span class="toggle-track"></span></label>
        </div>
    `;}).join('');
}
function addRec(){
    const n=document.getElementById('rfN').value.trim(),a=parseFloat(document.getElementById('rfA').value),f=document.getElementById('rfF').value,c=document.getElementById('rfC').value;
    if(!n||!a){toast('Điền đầy đủ!','error');return}
    const newRec = {id:Date.now(),name:n,amt:a,freq:f,cat:c,on:true};
    S.recurring.push(newRec);
    saveStateToStorage();
    fetch('/api/recurring', {
        method: 'POST',
        headers: {'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
        body: JSON.stringify({ user_id: S.user?.id || 1, name: n, amount: a, frequency: f, category: c, is_active: 1 })
    }).then(r=>r.json()).then(d=>{if(d.recurring_id)newRec.id=d.recurring_id;saveStateToStorage();}).catch(()=>{});
    togForm('recF');renderRec();toast('Đã thêm định kỳ!','success');
}
function togRec(id,on){
    const r=S.recurring.find(x=>x.id===id);
    if(r)r.on=on;
    saveStateToStorage();
    fetch(`/api/recurring/${id}/toggle`, { method: 'POST', headers: {'Bypass-Tunnel-Reminder':'true'} }).catch(()=>{});
    toast(on?'Đã bật':'Đã tắt','info');
}

// ===== BACKEND =====
async function sendBE(p){
    try{
        if(!p.user_id && S.user?.id) p.user_id = S.user.id;
        const res = await fetch('/api/transactions',{
            method:'POST',
            headers:{'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
            body:JSON.stringify(p)
        });
        if(res.ok){
            const d = await res.json();
            if(d.transaction_id && S.transactions && S.transactions.length > 0){
                const match = S.transactions.find(t => t.name === p.merchant_name && Math.abs(t.amt - p.amount) < 0.01);
                if(match && typeof match.id === 'number' && match.id > 1000000000000){
                    match.id = d.transaction_id;
                    saveStateToStorage();
                }
            }
        }
    }catch(e){}
}

// ===== LEGACY SUPPORT =====
function formatCurrency(n){return fmt(n)}
async function loadDashboardStats(){try{const r=await fetch('/api/stats');if(!r.ok)return;const d=await r.json();const e=document.getElementById('stat-total-spent');if(e)e.textContent=fmt(d.total_spent||0)}catch(e){}}
async function loadRecentTransactions(){const el=document.getElementById('transaction-list');if(!el)return;try{const r=await fetch('/api/transactions');if(!r.ok)throw 0;const txs=await r.json();if(!txs.length){el.innerHTML='<tr><td colspan="5" style="text-align:center;color:var(--text3)">Chưa có giao dịch</td></tr>';return}el.innerHTML=txs.map(t=>`<tr><td>${t.transaction_date}</td><td><strong>${t.merchant_name}</strong></td><td>${t.category||'Ăn uống'}</td><td><span class="badge">${t.group_id?'Nhóm':'Cá Nhân'}</span></td><td style="font-weight:700;color:var(--danger)">-${fmt(t.amount)}</td></tr>`).join('')}catch(e){}}
async function handleFileSelect(e){const f=e.target.files[0];if(!f)return;const s=document.getElementById('upload-status');if(s)s.style.display='block';const fd=new FormData();fd.append('receipt',f);try{const r=await fetch('/api/receipts/upload',{method:'POST',body:fd});if(!r.ok){const d=await r.json();throw new Error(d.error||'Fail')}const d=await r.json();sessionStorage.setItem('ocr_result',JSON.stringify(d));window.location.href='/review'}catch(e){toast('Lỗi: '+e.message,'error');if(s)s.style.display='none'}}
async function handleConfirmTransaction(e){
    if(e) e.preventDefault();
    const o=JSON.parse(sessionStorage.getItem('ocr_result')||'{}');
    const mer = document.getElementById('verify-merchant')?.value || 'Hóa đơn';
    const amt = parseFloat(document.getElementById('verify-amount')?.value) || 0;
    const dt = document.getElementById('verify-date')?.value || new Date().toISOString().slice(0, 10);
    const cat = document.getElementById('verify-category')?.value || 'Ăn uống';
    const nts = document.getElementById('verify-notes')?.value || '';
    const uid = S.user?.id || 1;
    const p={
        merchant_name: mer,
        amount: amt,
        transaction_date: dt,
        category: cat,
        group_id: document.getElementById('verify-group-id')?.value ? parseInt(document.getElementById('verify-group-id').value) : null,
        notes: nts,
        receipt_image_path: o.image_url||null,
        raw_ocr_text: o.raw_text||null,
        user_id: uid
    };
    try{
        const r=await fetch('/api/transactions',{
            method:'POST',
            headers:{'Content-Type':'application/json', 'Bypass-Tunnel-Reminder':'true'},
            body:JSON.stringify(p)
        });
        const d = await r.json();
        if(r.ok || d.success){
            sessionStorage.removeItem('ocr_result');
            const curCached = JSON.parse(localStorage.getItem('vx_transactions_' + uid) || '[]');
            curCached.unshift({
                id: d.transaction_id || Date.now(),
                name: mer,
                amt: amt,
                cat: normalizeCatKey(cat),
                date: dt,
                time: new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'}),
                type: 'expense',
                note: nts
            });
            localStorage.setItem('vx_transactions_' + uid, JSON.stringify(curCached));
            localStorage.setItem('vx_transactions', JSON.stringify(curCached));
            toast('Lưu thành công!','success');
            setTimeout(() => { window.location.href = '/'; }, 300);
        } else {
            toast('Lỗi lưu: ' + (d.error || 'Thất bại'),'error');
        }
    }catch(e){
        toast('Lỗi: '+e.message,'error');
    }
}
async function handleManualSubmit(e){e.preventDefault();const p={merchant_name:document.getElementById('manual-merchant').value,amount:parseFloat(document.getElementById('manual-amount').value),transaction_date:document.getElementById('manual-date').value,group_id:document.getElementById('manual-wallet-type')?.value?parseInt(document.getElementById('manual-wallet-type').value):null,category:'Ăn uống',user_id:1};try{const r=await fetch('/api/transactions',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p)});if(r.ok){toast('Thêm thành công!','success');document.getElementById('manual-form')?.reset();loadDashboardStats();loadRecentTransactions()}}catch(e){toast('Lỗi: '+e.message,'error')}}
const TEAM_MEMBERS=[{id:1,name:"Thành viên 1"},{id:2,name:"Lê Thị Dịu"},{id:3,name:"Lê Tiến Quân"},{id:4,name:"Lê Ngọc Duy"},{id:5,name:"Nguyễn Việt Anh"}];
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
    if(!S.user) S.user = { name: 'Người dùng', full_name: 'Người dùng', phone: '', email: '', avatar: 'assets/logo.jpg' };
    const name = S.user.name||S.user.full_name||'Người dùng';
    const phone = S.user.phone||'';
    const email = S.user.email||'';
    
    const pn = document.getElementById('profileName');
    if(pn) pn.textContent = name;
    const pm = document.getElementById('profileMeta');
    if(pm) pm.textContent = [phone, email].filter(Boolean).join(' · ') || 'Chưa cập nhật thông tin';
    const pph = document.getElementById('profilePhone');
    if(pph) pph.innerHTML = `<i class="ri-phone-line"></i> ${phone || 'Chưa có SĐT'}`;
    const pem = document.getElementById('profileEmail');
    if(pem) pem.innerHTML = `<i class="ri-mail-line"></i> ${email || 'Chưa có Email'}`;
    
    const pa=document.getElementById('profileAvatarImg');
    if(pa && S.user.avatar) pa.src=S.user.avatar;
    
    const un = document.getElementById('setUserName');
    if(un) un.value = name;
    const up = document.getElementById('setUserPhone');
    if(up) up.value = phone;
    const ue = document.getElementById('setUserEmail');
    if(ue) ue.value = email;

    // Thẻ tài khoản ngân hàng nhận tiền: Mặc định ẩn, chỉ hiện nếu người dùng tự cấu hình
    const bankCard = document.getElementById('userBankCard');
    const bankTitle = document.getElementById('userBankTitle');
    const bankSub = document.getElementById('userBankSub');
    if (bankCard) {
        if (S.user.bank_name && S.user.bank_account) {
            bankCard.style.display = 'flex';
            if (bankTitle) bankTitle.textContent = `${S.user.bank_name} · ${S.user.bank_account}`;
            if (bankSub) bankSub.textContent = `${name.toUpperCase()} · Nhận quỹ & chia tiền`;
        } else {
            bankCard.style.display = 'none';
        }
    }
}

function openEditProfileModal(){
    if(!S.user) S.user = { name: '', full_name: '', phone: '', email: '', avatar: 'assets/logo.jpg' };
    const name = S.user.name||S.user.full_name||'';
    const phone = S.user.phone||'';
    const email = S.user.email||'';
    const un = document.getElementById('setUserName');
    if(un) un.value = name;
    const up = document.getElementById('setUserPhone');
    if(up) up.value = phone;
    const ue = document.getElementById('setUserEmail');
    if(ue) ue.value = email;
    const ubn = document.getElementById('setUserBankName');
    if(ubn) ubn.value = S.user.bank_name || '';
    const uba = document.getElementById('setUserBankAccount');
    if(uba) uba.value = S.user.bank_account || '';
    document.getElementById('editProfileModal')?.classList.add('active');
}

function closeEditProfileModal(){
    document.getElementById('editProfileModal')?.classList.remove('active');
}

function copyBankAccount(){
    if (!S.user?.bank_account) {
        toast('Chưa thiết lập số tài khoản ngân hàng.', 'info');
        return;
    }
    navigator.clipboard.writeText(S.user.bank_account);
    toast(`Đã sao chép STK ${S.user.bank_name ? S.user.bank_name + ' ' : ''}: ${S.user.bank_account} `,'success');
}

async function saveProfile(e){
    e.preventDefault();
    const name=document.getElementById('setUserName').value.trim();
    const phone=document.getElementById('setUserPhone').value.trim();
    const email=document.getElementById('setUserEmail').value.trim();
    const bankName=document.getElementById('setUserBankName')?.value.trim() || '';
    const bankAccount=document.getElementById('setUserBankAccount')?.value.trim() || '';
    if(!name||!phone||!email){toast('Chưa điền đủ thông tin!','error');return}
    S.user.name=name;
    S.user.full_name=name;
    S.user.phone=phone;
    S.user.email=email;
    S.user.bank_name=bankName;
    S.user.bank_account=bankAccount;
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
    addAppNotification({
        title: 'Cập nhật tài khoản',
        body: `Thông tin tài khoản (${name}) đã được lưu.`,
        type: 'security',
        actionUrl: 'settings',
        actionText: 'Xem tài khoản →'
    });
    toast('Đã cập nhật thông tin cá nhân thành công!','success');
}

function setTheme(themeName){
    document.documentElement.setAttribute('data-theme',themeName);
    localStorage.setItem('vx_theme',themeName);
    document.querySelectorAll('.theme-pill, .theme-item').forEach(t=>{
        t.classList.toggle('active',t.dataset.theme===themeName);
    });
    addAppNotification({
        title: 'Đổi giao diện',
        body: `Đã đổi chủ đề: ${THEME_NAMES[themeName]||themeName}.`,
        type: 'system',
        actionUrl: 'settings',
        actionText: 'Xem cài đặt →'
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
    if(!S.user) S.user = { name: 'Người dùng', full_name: 'Người dùng', phone: '', email: '', avatar: 'assets/logo.jpg' };
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
        if(!S.user) S.user = { name: 'Người dùng', full_name: 'Người dùng', phone: '', email: '', avatar: 'assets/logo.jpg' };
        S.user.avatar=ev.target.result;
        localStorage.setItem('vx_u',JSON.stringify(S.user));
        document.getElementById('profileAvatarImg').src=ev.target.result;
        const ha=document.getElementById('hdrAvatarImg');if(ha)ha.src=ev.target.result;
        toast('Đã tải lên ảnh đại diện mới!','success');
    };
    r.readAsDataURL(f);
}

function switchUser(email){
    const regUsers = getRegisteredUsers();
    const u = regUsers.find(x => x.email === email);
    if(!u) return;
    S.user = JSON.parse(JSON.stringify(u));
    localStorage.setItem('vx_u', JSON.stringify(S.user));
    document.getElementById('uName').textContent = S.user.name;
    const ha = document.getElementById('hdrAvatarImg');
    if(ha) ha.src = S.user.avatar || 'assets/logo.jpg';
    renderSettings();
    toast(`Đã chuyển sang tài khoản ${u.name || u.full_name}!`, 'success');
}

// ===== DYNAMIC GROUP STATE MANAGEMENT =====
function updateHomeGroupCard(){
    const titleEl = document.getElementById('homeGroupTitle');
    const subEl = document.getElementById('homeGroupSub');
    const iconEl = document.getElementById('homeGroupIcon');
    if(!titleEl) return;
    if(!S.groupFund){
        titleEl.textContent = 'Tạo Ví Nhóm & Quỹ Chung';
        if(subEl) subEl.textContent = 'Chưa có nhóm · Chạm để tạo nhóm chia tiền & quản lý quỹ';
        if(iconEl) iconEl.innerHTML = '<i class="ri-add-circle-line"></i>';
    } else {
        titleEl.textContent = S.groupFund.name;
        const memCount = (S.groupFund.members && S.groupFund.members.length) || 1;
        if(subEl) subEl.innerHTML = `Quỹ: <strong id="homeFundBal">${fmt(S.groupFund.balance)}</strong> · ${memCount} thành viên`;
        if(iconEl) iconEl.innerHTML = '<i class="ri-community-line"></i>';
    }
}

function handleGroupClick(){
    if(!S.groupFund){
        openCreateGroupModal();
    } else {
        go('group');
    }
}

function openCreateGroupModal(){
    const m = document.getElementById('createGroupModal');
    if(m) {
        m.classList.add('active');
        const inp = document.getElementById('newGroupName');
        if(inp) { inp.value = ''; inp.focus(); }
        const desc = document.getElementById('newGroupDesc');
        if(desc) desc.value = '';
        const bal = document.getElementById('newGroupInitialBal');
        if(bal) bal.value = 0;
    }
}

function closeCreateGroupModal(){
    document.getElementById('createGroupModal')?.classList.remove('active');
}

function handleCreateGroupSubmit(e){
    e.preventDefault();
    const name = document.getElementById('newGroupName').value.trim();
    if(!name){ toast('Vui lòng nhập tên nhóm!', 'error'); return; }
    const desc = document.getElementById('newGroupDesc').value.trim() || 'Quỹ chi tiêu chung';
    const initialBal = parseFloat(document.getElementById('newGroupInitialBal').value) || 0;
    
    S.groupFund = {
        id: Date.now(),
        name: name,
        desc: desc,
        balance: initialBal,
        members: [
            { id: 1, name: S.user?.full_name || S.user?.name || 'Tôi', role: 'Trưởng nhóm', phone: S.user?.phone || 'Chủ ví', paidFund: initialBal, debt: 0, icon: 'ri-user-star-line' }
        ],
        bills: [],
        history: initialBal > 0 ? [{
            type: 'in',
            title: 'Khởi tạo số dư ban đầu',
            user: S.user?.full_name || S.user?.name || 'Tôi',
            date: new Date().toISOString().slice(0, 10),
            amt: initialBal
        }] : []
    };
    localStorage.setItem('vx_group_fund', JSON.stringify(S.groupFund));
    closeCreateGroupModal();
    updateHomeGroupCard();
    toast(`Đã tạo ví nhóm "${name}" thành công!`, 'success');
    go('group');
}

// ===== GROUP FUND & SPLIT BILLS =====
function renderGroup(){
    updateHomeGroupCard();
    const noGroup = document.getElementById('noGroupState');
    const hasGroup = document.getElementById('hasGroupState');
    const headerBtn = document.getElementById('groupHeaderActionBtn');
    const headerTitle = document.getElementById('groupPageHeaderTitle');
    
    if(!S.groupFund){
        if(noGroup) noGroup.style.display = 'block';
        if(hasGroup) hasGroup.style.display = 'none';
        if(headerBtn) {
            headerBtn.style.display = 'flex';
            headerBtn.onclick = openCreateGroupModal;
            headerBtn.title = 'Tạo ví nhóm';
            headerBtn.innerHTML = '<i class="ri-add-line"></i>';
        }
        if(headerTitle) headerTitle.textContent = 'Ví Nhóm & Quỹ Chung';
        return;
    }
    
    if(noGroup) noGroup.style.display = 'none';
    if(hasGroup) hasGroup.style.display = 'block';
    if(headerBtn) {
        headerBtn.style.display = 'flex';
        headerBtn.onclick = openFundModal;
        headerBtn.title = 'Góp quỹ';
        headerBtn.innerHTML = '<i class="ri-hand-coin-line"></i>';
    }
    if(headerTitle) headerTitle.textContent = S.groupFund.name;
    
    const g = S.groupFund;
    const badge = document.getElementById('groupBadgeName');
    if(badge) badge.innerHTML = `<i class="ri-community-line"></i> ${g.name}`;
    const desc = document.getElementById('groupFundDesc');
    if(desc) desc.textContent = `${(g.members||[]).length} thành viên · ${g.desc || 'Quỹ chi tiêu chung'}`;
    
    // Balance
    const balEl = document.getElementById('groupFundBal');
    if(balEl) balEl.textContent = fmt(g.balance);
    const homeBal = document.getElementById('homeFundBal');
    if(homeBal) homeBal.textContent = fmt(g.balance);
    const cntEl = document.getElementById('gBillCount');
    if(cntEl) cntEl.textContent = (g.bills||[]).length;
    
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

    addAppNotification({
        title: 'Đóng quỹ nhóm',
        body: `${mem.name} đã nộp ${fmt(amt)} vào quỹ (${note}).`,
        type: 'fund',
        actionUrl: 'group',
        actionText: 'Xem quỹ nhóm →'
    });

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
                <img id="vietQrImg" alt="VietQR" width="160" height="160" style="background:#fff;border-radius:8px"/>
            </div>
            <div style="font-size:1.15rem;font-weight:900;color:var(--primary);margin-bottom:0.4rem">${fmt(amt)}</div>
            <div class="qr-details" style="padding:0.55rem;margin-bottom:0.5rem">
                <div class="qr-row"><span style="color:var(--text3)">Khoản chi:</span> <strong>${bill.name}</strong></div>
                ${S.user?.bank_account ? `<div class="qr-row"><span style="color:var(--text3)">Số TK:</span> <strong>${S.user.bank_account}</strong> (${S.user.bank_name || 'Ngân hàng'})</div>` : ''}
                <div class="qr-row"><span style="color:var(--text3)">Người nhận:</span> <strong>${S.user?.name || S.user?.full_name || 'Trưởng nhóm'}</strong></div>
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
        const img = document.getElementById('vietQrImg');
        if(img) renderVietQr(img, amt, memo);
    }, 50);
}

function bankBinFromName(name){
    const n = (name || '').toLowerCase();
    const map = [
        ['vietcombank', '970436'], ['vcb', '970436'],
        ['techcombank', '970407'], ['tcb', '970407'],
        ['mb bank', '970422'], ['mbbank', '970422'],
        ['bidv', '970418'],
        ['vietin', '970415'],
        ['acb', '970416'],
        ['tpbank', '970423'], ['tp bank', '970423'],
        ['vpbank', '970432'],
        ['sacombank', '970403'],
        ['msb', '970426'],
        ['vib', '970441'],
        ['agribank', '970405'],
    ];
    for (const [key, bin] of map) {
        if (n.includes(key)) return bin;
    }
    return '';
}

function renderVietQr(img, amt, memo){
    const bin = bankBinFromName(S.user?.bank_name);
    const acc = (S.user?.bank_account || '').replace(/\s+/g, '');
    const accName = encodeURIComponent(S.user?.name || S.user?.full_name || 'Vi Xinh');
    const info = encodeURIComponent(memo || 'Vi Xinh');
    if (!bin || !acc) {
        img.alt = 'Chưa lưu STK ngân hàng';
        img.src = '';
        img.style.display = 'none';
        return;
    }
    img.style.display = 'inline-block';
    img.src = `https://img.vietqr.io/image/${bin}-${acc}-compact2.png?accountName=${accName}&addInfo=${info}&amount=${Math.round(amt || 0)}`;
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

    addAppNotification({
        title: 'Chia tiền phòng',
        body: `${share.name}: ${wasPaid ? 'chưa thanh toán' : 'đã thanh toán'} (${fmt(share.amt)}).`,
        type: 'fund',
        actionUrl: 'group',
        actionText: 'Xem phòng trọ →'
    });

    toast(`Đã cập nhật: ${share.name} (${wasPaid ? 'chưa trả' : 'đã trả'})`, 'success');
}

function copyZaloReminder(billTitle, amt, memberName){
    const bankInfo = S.user?.bank_account ? ` STK: ${S.user.bank_account} (${S.user.bank_name || 'Ngân hàng'} - ${S.user.name || 'Trưởng nhóm'}).` : '';
    const msg = `Tiền ${billTitle}: ${fmt(amt * 4)} chia 4. Phần ${memberName}: ${fmt(amt)}.${bankInfo}`;
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
            headers: { 'Content-Type': 'application/json', 'Bypass-Tunnel-Reminder': 'true' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.success || res.ok) {
            sessionStorage.removeItem('ocr_result');
            const uid = payload.user_id || 1;
            const curCached = JSON.parse(localStorage.getItem('vx_transactions_' + uid) || '[]');
            curCached.unshift({
                id: data.transaction_id || Date.now(),
                name: merchant,
                amt: amount,
                cat: normalizeCatKey(category),
                date: date,
                time: new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'}),
                type: 'expense',
                note: notes
            });
            localStorage.setItem('vx_transactions_' + uid, JSON.stringify(curCached));
            localStorage.setItem('vx_transactions', JSON.stringify(curCached));
            toast('Đã lưu giao dịch!', 'success');
            setTimeout(() => { window.location.href = '/'; }, 300);
        } else {
            toast(data.error || 'Chưa lưu được giao dịch.', 'error');
        }
    } catch (err) {
        console.warn('API error, saving to local store:', err);
        const uid = payload.user_id || 1;
        const curCached = JSON.parse(localStorage.getItem('vx_transactions_' + uid) || '[]');
        curCached.unshift({
            id: Date.now(),
            name: merchant,
            amt: amount,
            type: 'expense',
            cat: normalizeCatKey(category),
            date: date,
            note: notes,
            time: new Date().toLocaleTimeString('vi-VN', {hour:'2-digit', minute:'2-digit'})
        });
        localStorage.setItem('vx_transactions_' + uid, JSON.stringify(curCached));
        localStorage.setItem('vx_transactions', JSON.stringify(curCached));
        toast('Đã lưu giao dịch!', 'success');
        setTimeout(() => { window.location.href = '/'; }, 300);
    }
}

async function loadGroupMembersUI() {
    const listEl = document.getElementById('member-checkbox-list');
    if (!listEl) return;

    let members = [
        { id: 1, name: 'Thành viên 1', role: 'Trưởng nhóm' },
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

// ===== TRUNG TÂM THÔNG BÁO HOÀN CHỈNH & THEO DÕI BIẾN ĐỘNG THỰC TẾ =====
function initNotifications(){
    try {
        const raw = localStorage.getItem('vx_notifications');
        if(raw){
            S.notifications = JSON.parse(raw);
        } else {
            // Khởi tạo mặc định: người dùng mới chưa có biến động -> rỗng để hiển thị đúng như app thật: "Không có thông báo nào"
            S.notifications = [];
        }
    } catch(e) {
        S.notifications = [];
    }
    renderNotifications();
    updateNotifBadge();
}

function saveNotifications(){
    try {
        localStorage.setItem('vx_notifications', JSON.stringify(S.notifications || []));
    } catch(e){}
}

function updateNotifBadge(){
    const unreadCount = (S.notifications || []).filter(n => n.unread).length;
    const dot = document.getElementById('hdrNotifDot');
    if(dot){
        dot.style.display = unreadCount > 0 ? 'block' : 'none';
    }
    const countLbl = document.getElementById('notifCountLabel');
    if(countLbl){
        countLbl.textContent = unreadCount > 0 ? `Thông báo mới (${unreadCount})` : 'Thông báo';
    }
}

function formatNotifTime(timeVal){
    if(!timeVal) return '';
    const d = new Date(timeVal);
    const now = new Date();
    if(isNaN(d.getTime())) return timeVal;

    const diffSec = Math.floor((now - d) / 1000);
    if(diffSec < 60) return 'Vừa xong';
    const diffMin = Math.floor(diffSec / 60);
    if(diffMin < 60) return `${diffMin} phút trước`;
    const diffHr = Math.floor(diffMin / 60);
    if(diffHr < 24) return `${diffHr} giờ trước`;
    const diffDays = Math.floor(diffHr / 24);
    if(diffDays === 1) return 'Hôm qua';
    if(diffDays < 7) return `${diffDays} ngày trước`;

    const hh = String(d.getHours()).padStart(2, '0');
    const mm = String(d.getMinutes()).padStart(2, '0');
    const dd = String(d.getDate()).padStart(2, '0');
    const MM = String(d.getMonth() + 1).padStart(2, '0');
    return `${hh}:${mm}, ${dd}/${MM}`;
}

function renderNotifications(){
    const list = document.getElementById('notifList');
    if(!list) return;
    const notifs = S.notifications || [];

    const btnMark = document.getElementById('btnMarkAllRead');
    const btnClear = document.getElementById('btnClearAllNotifs');

    if(notifs.length === 0){
        list.innerHTML = `
            <div class="empty" style="padding:2.2rem 1rem;text-align:center">
                <div style="font-size:0.92rem;font-weight:600;color:var(--text);margin-bottom:0.25rem">Không có thông báo nào</div>
                <div style="font-size:0.75rem;color:var(--text3);line-height:1.45;max-width:280px;margin:0 auto">
                    Mọi biến động số dư, quét hóa đơn và quỹ nhóm sẽ xuất hiện tại đây.
                </div>
            </div>
        `;
        if(btnMark) btnMark.style.display = 'none';
        if(btnClear) btnClear.style.display = 'none';
        return;
    }

    if(btnMark) btnMark.style.display = 'inline-block';
    if(btnClear) btnClear.style.display = 'inline-block';

    list.innerHTML = notifs.map(n => {
        const cleanTitle = (n.title || 'Thông báo')
            .replace(/[\u{1F300}-\u{1FAFF}]|[\u{2600}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]/gu, '')
            .trim();
        const cleanBody = (n.body || '')
            .replace(/lúc \d{1,2}:\d{2}(:\d{2})? ngày \d{1,2}\/\d{1,2}\/\d{4}\.?/gi, '')
            .replace(/vào lúc \d{1,2}:\d{2}\.?/gi, '')
            .replace(/Cảnh báo lúc [^:]+:\s*/gi, '')
            .trim();

        return `
        <div class="notif-item ${n.unread ? 'unread' : ''}" onclick="handleNotifClick('${n.id}')">
            <div class="notif-hdr">
                <div class="notif-title">${cleanTitle}</div>
                <div class="notif-actions-right">
                    ${n.unread ? '<span class="notif-dot"></span>' : ''}
                    <button type="button" class="notif-del-btn" onclick="event.stopPropagation();deleteNotif('${n.id}')" title="Xóa thông báo">✕</button>
                </div>
            </div>
            <div class="notif-body">${cleanBody}</div>
            <div class="notif-foot">
                <span class="notif-time">${formatNotifTime(n.time)}</span>
                ${n.actionText ? `<span class="notif-action-link">${n.actionText}</span>` : ''}
            </div>
        </div>
        `;
    }).join('');
}

function addAppNotification(item){
    if(!S.notifications) S.notifications = [];
    const notif = {
        id: Date.now() + Math.random(),
        title: item.title || 'Thông báo mới',
        body: item.body || '',
        type: item.type || 'system',
        icon: item.icon || 'ri-notification-3-line',
        iconBg: item.iconBg || 'rgba(244,91,138,0.12)',
        iconColor: item.iconColor || 'var(--primary)',
        time: new Date().toISOString(),
        unread: true,
        actionUrl: item.actionUrl || null,
        actionText: item.actionText || null
    };
    S.notifications.unshift(notif);
    if(S.notifications.length > 50) S.notifications = S.notifications.slice(0, 50);
    saveNotifications();
    renderNotifications();
    updateNotifBadge();
}

function handleNotifClick(notifId){
    const notif = (S.notifications || []).find(n => String(n.id) === String(notifId));
    if(notif){
        notif.unread = false;
        saveNotifications();
        renderNotifications();
        updateNotifBadge();
        closeNotificationModal();
        if(notif.actionUrl){
            go(notif.actionUrl);
        }
    }
}

function deleteNotif(notifId){
    S.notifications = (S.notifications || []).filter(n => String(n.id) !== String(notifId));
    saveNotifications();
    renderNotifications();
    updateNotifBadge();
    toast('Đã xóa thông báo.', 'info');
}

function markAllNotifsRead(){
    (S.notifications || []).forEach(n => n.unread = false);
    saveNotifications();
    renderNotifications();
    updateNotifBadge();
    toast('Đã đọc tất cả thông báo!', 'success');
}

function clearAllNotifs(){
    if(!S.notifications || S.notifications.length === 0) return;
    S.notifications = [];
    saveNotifications();
    renderNotifications();
    updateNotifBadge();
    toast('Đã xóa tất cả thông báo.', 'info');
}

function checkBudgetAlerts(categoryKey){
    if(!categoryKey || !S.budgets) return;
    const b = S.budgets.find(item => item.cat === categoryKey);
    if(!b || !b.limit) return;
    const spent = S.transactions
        .filter(t => t.type === 'expense' && t.cat === categoryKey)
        .reduce((sum, t) => sum + t.amt, 0);
    const pct = Math.round((spent / b.limit) * 100);
    const ct = CATS[categoryKey] || CATS.other;

    if(pct >= 80){
        const existing = (S.notifications || []).find(n => n.type === 'budget' && n.title.includes(ct.label) && n.unread);
        if(!existing){
            const now = new Date();
            const timeStr = `${String(now.getHours()).padStart(2,'0')}:${String(now.getMinutes()).padStart(2,'0')} ngày ${String(now.getDate()).padStart(2,'0')}/${String(now.getMonth()+1).padStart(2,'0')}/${now.getFullYear()}`;
            addAppNotification({
                title: `Cảnh báo ngân sách: ${ct.label}`,
                body: `Đã dùng ${pct}% hạn mức ${ct.label} (${fmt(spent)}/${fmt(b.limit)}).`,
                type: 'budget',
                actionUrl: 'budget',
                actionText: 'Kiểm tra ngân sách →'
            });
        }
    }
}

function openNotificationModal(){
    document.getElementById('notifModal')?.classList.add('active');
    renderNotifications();
}
function closeNotificationModal(){
    document.getElementById('notifModal')?.classList.remove('active');
}

// ===== INIT =====
document.addEventListener('DOMContentLoaded',()=>{
    const savedTheme=localStorage.getItem('vx_theme')||'pink-gold';
    document.documentElement.setAttribute('data-theme',savedTheme);
    const s=localStorage.getItem('vx_u');
    if(s){
        try{
            const parsed = JSON.parse(s);
            const em = (parsed.email || '').toLowerCase();
            if(em.endsWith('@vixinh.vn') || em === 'hien@vixinh' || em === 'testreal@gmail.com'){
                localStorage.removeItem('vx_u');
                localStorage.removeItem('vx_last_user');
                localStorage.removeItem('vx_remembered_account');
            } else {
                S.user=parsed;
                S.loggedIn=true;
                enterApp();
            }
        }catch(e){localStorage.removeItem('vx_u')}
    }
    // Hiệu ứng Splash Screen: tự động ẩn sau 1 giây, bảo đảm không bao giờ bị kẹt
    const splash = document.getElementById('appSplashScreen');
    if (splash) {
        setTimeout(() => {
            splash.classList.add('fade-out');
            setTimeout(() => { try { splash.remove(); } catch(e){} }, 400);
        }, 900);
    }

    const dz=document.getElementById('dropZone');
    if(dz){dz.addEventListener('dragover',e=>{e.preventDefault();dz.classList.add('dragover')});dz.addEventListener('dragleave',()=>dz.classList.remove('dragover'));dz.addEventListener('drop',e=>{e.preventDefault();dz.classList.remove('dragover');const f=e.dataTransfer.files[0];if(f){document.getElementById('fileIn').files=e.dataTransfer.files;handleFile({target:{files:[f]}})}});}
    document.getElementById('modal')?.addEventListener('click',e=>{if(e.target.id==='modal')closeModal()});
    document.getElementById('txDetailModal')?.addEventListener('click',e=>{if(e.target.id==='txDetailModal')closeTxDetailModal()});
    document.getElementById('savingsDepositModal')?.addEventListener('click',e=>{if(e.target.id==='savingsDepositModal')closeSavingsDepositModal()});
    document.getElementById('notifModal')?.addEventListener('click',e=>{if(e.target.id==='notifModal')closeNotificationModal()});
    document.addEventListener('keydown',e=>{
        if(e.key==='Escape'){
            closeModal();
            closeTxDetailModal();
            closeSavingsDepositModal();
            closeNotificationModal();
            closeEditProfileModal();
            closeQrModal();
            closeFundModal();
        }
    });
    const md=document.getElementById('manual-date');if(md)md.value=new Date().toISOString().slice(0,10);
    if(document.getElementById('transaction-list')){loadDashboardStats();loadRecentTransactions()}
    
    // Tự động nhớ tài khoản nếu người dùng đã bật Ghi nhớ trước đó
    const remembered = localStorage.getItem('vx_remembered_account');
    const emInp = document.getElementById('loginEmail');
    const remChk = document.getElementById('rememberMeCheck');
    if (remembered && emInp) {
        emInp.value = remembered;
        if (remChk) remChk.checked = true;
    }
    drawCaptcha();
    initNotifications();

    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(regs => {
            for (let reg of regs) reg.unregister();
        }).catch(() => {});
    }
    if ('caches' in window) {
        caches.keys().then(keys => {
            for (let k of keys) caches.delete(k);
        }).catch(() => {});
    }
});

// ===== HƯỚNG 3: AI CỐ VẤN TÀI CHÍNH - TÓM TẮT & ĐỀ XUẤT HÀNH ĐỘNG =====
async function requestAiSpendingSummary(){
    const contentBox = document.getElementById('aiAdviceContent');
    const loadingBox = document.getElementById('aiAdviceLoading');
    const btn = document.getElementById('btnRequestAiAdvice');
    if(!contentBox || !loadingBox) return;

    contentBox.style.display = 'none';
    loadingBox.style.display = 'block';
    if(btn) btn.disabled = true;

    try {
        const uid = (S.user && S.user.id) ? S.user.id : ((typeof currentUser !== 'undefined' && currentUser && currentUser.id) ? currentUser.id : 1);
        const res = await fetch('/api/ai/spending-summary?user_id=' + uid, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Bypass-Tunnel-Reminder': 'true'
            }
        });

        loadingBox.style.display = 'none';
        if(btn) btn.disabled = false;

        let d;
        try {
            d = await res.json();
        } catch(parseErr) {
            d = { success: false, error: 'Không thể đọc phản hồi từ máy chủ (' + res.status + ')' };
        }

        if(res.ok && d && d.success){
            const metricsHtml = `
            <div style="margin-bottom:0.6rem;padding-bottom:0.5rem;border-bottom:1px dashed var(--border);display:flex;align-items:center;justify-content:space-between;font-size:0.68rem;color:var(--text3);flex-wrap:wrap;gap:0.35rem">
                <span><i class="ri-sparkling-fill" style="color:#f59e0b"></i> <strong>${escapeHtml(d.model || 'Gemini 1.5 Flash')}</strong></span>
                <span><i class="ri-flashlight-line" style="color:#f59e0b"></i> ${(d.latency_ms/1000).toFixed(1)}s</span>
                <span><i class="ri-cpu-line" style="color:#6366f1"></i> ${d.token_usage?.total_tokens || 0} tokens</span>
                <span><i class="ri-money-dollar-circle-line" style="color:#10b981"></i> ${escapeHtml(d.cost_estimate?.formatted || '~3.5 ₫')}</span>
            </div>`;
            contentBox.innerHTML = metricsHtml + `<div style="line-height:1.65;font-size:0.82rem;color:var(--text);margin-top:0.4rem;text-align:left">${formatAiAdvice(d.advice)}</div>`;
            contentBox.style.display = 'block';
            toast('AI đã phân tích xong chi tiêu của bạn!', 'success');
        } else {
            toast(d?.error || 'Không thể tạo phân tích lúc này', 'error');
        }
    } catch(e){
        loadingBox.style.display = 'none';
        if(btn) btn.disabled = false;
        toast('Lỗi khi gọi AI: ' + e.message, 'error');
    }
}

// Stubs an toan
function updateBioLoginUI(){}
function closeBiometricModal(){}
function openBiometricModal(){}
function handleBiometricLogin(){}


