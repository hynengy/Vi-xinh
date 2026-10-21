# 🗄️ THIẾT KẾ CƠ SỞ DỮ LIỆU "VÍ XINH"

Hệ thống sử dụng cơ sở dữ liệu quan hệ chuẩn hóa (SQLite trên Web Backend và `sqflite` trên Mobile Local Storage).

---

## 1. Sơ Đồ Thực Thể Liên Kết (ERD)

```mermaid
erDiagram
    USERS ||--o{ TRANSACTIONS : "thực hiện"
    USERS ||--o{ GROUP_MEMBERS : "tham gia"
    GROUPS ||--o{ GROUP_MEMBERS : "chứa"
    GROUPS ||--o{ TRANSACTIONS : "thuộc ví nhóm"
    TRANSACTIONS ||--o{ EXPENSE_SPLITS : "phân bổ chi tiêu"
    USERS ||--o{ EXPENSE_SPLITS : "chịu chi phí"

    USERS {
        int id PK
        string username
        string full_name
        string email
    }

    GROUPS {
        int id PK
        string name
        int created_by FK
        datetime created_at
    }

    GROUP_MEMBERS {
        int id PK
        int group_id FK
        int user_id FK
        string role
    }

    TRANSACTIONS {
        int id PK
        int user_id FK
        int group_id FK
        string merchant_name
        double amount
        datetime transaction_date
        string receipt_image_url
        string raw_ocr_text
    }

    EXPENSE_SPLITS {
        int id PK
        int transaction_id FK
        int user_id FK
        double split_amount
        boolean is_settled
    }
```

---

## 2. Đặc Tả Các Bảng Dữ Liệu Chính

| Tên Bảng | Ý Nghĩa | Các Trường Quan Trọng |
|:---|:---|:---|
| **`users`** | Tài khoản người dùng | `id`, `username`, `full_name`, `email`, `created_at` |
| **`groups`** | Ví nhóm / Quỹ phòng trọ | `id`, `name`, `created_by`, `created_at` |
| **`group_members`**| Danh sách thành viên ví nhóm | `id`, `group_id` (FK), `user_id` (FK), `role` (`admin`/`member`) |
| **`transactions`** | Giao dịch thu / chi | `id`, `user_id` (FK), `group_id` (FK, nullable), `merchant_name`, `amount`, `transaction_date`, `raw_ocr_text` |
| **`expense_splits`**| Phân bổ công nợ chia tiền | `id`, `transaction_id` (FK), `user_id` (FK), `split_amount`, `is_settled` (boolean) |
