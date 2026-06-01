# Data Schema — Banking Customer 360°

> 4 CSV files representing a synthetic retail banking dataset.
> **Total:** 198 customers · 287 accounts · 800 transactions · 188 credit score records.

---

## 📋 Tables Overview

| Table | Rows | Purpose |
| --- | --- | --- |
| `customers.csv` | 198 | Customer demographics |
| `accounts.csv` | 287 | Accounts owned per customer (1:N) |
| `transactions.csv` | 800 | Transaction records (2024–2025) |
| `credit_scores.csv` | 188 | Quarterly credit scores (2023-Q1 → 2025-Q4) |

---

## 🗂️ Table: `customers.csv`

Thông tin demographic khách hàng (198 rows).

| Column | Type | Description |
| --- | --- | --- |
| `customer_id` | string (PK) | Mã KH, format `CUST####` |
| `segment` | string | VIP / Mass / Affluent |
| `gender` | char | F / M |
| `age` | int | Tuổi tại thời điểm extract |
| `city` | string | Thành phố (Hà Nội, HCM, Cần Thơ, Đồng Nai) |

---

## 🗂️ Table: `accounts.csv`

Tài khoản KH đang sở hữu (287 rows). **1 KH có thể có nhiều TK** (Savings, Credit, Investment).

| Column | Type | Description |
| --- | --- | --- |
| `account_id` | string (PK) | Mã TK, format `ACC####` |
| `customer_id` | string (FK) | Trỏ về `customers.customer_id` |
| `account_type` | string | Savings / Credit / Investment |
| `open_date` | date | Ngày mở TK |
| `status` | string | Active / Inactive |

---

## 🗂️ Table: `transactions.csv`

Giao dịch của TK trong 2024–2025 (800 rows).

| Column | Type | Description |
| --- | --- | --- |
| `txn_id` | string (PK) | Mã GD, format `TXN######` |
| `account_id` | string (FK) | Trỏ về `accounts.account_id` |
| `txn_date` | date | Ngày GD |
| `amount` | decimal | Số tiền GD (VNĐ) |
| `channel` | string | ATM / Online / POS |
| `txn_type` | string | Payment / Withdrawal / Transfer |
| `risk_flag` | int (0/1) | 1 = risky (rule-based flag) |

> ⚠️ **Critical note:** `transactions` KHÔNG có `customer_id` trực tiếp. Mọi customer-level query cần **2 lần JOIN** qua `accounts`:

```sql
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
```

Đây là pattern banking thực tế: 1 KH → nhiều TK → mỗi TK có giao dịch riêng.

---

## 🗂️ Table: `credit_scores.csv`

Điểm tín dụng KH theo quý từ 2023-Q1 đến 2025-Q4 (188 rows).

| Column | Type | Description |
| --- | --- | --- |
| `customer_id` | string (FK) | Trỏ về `customers.customer_id` |
| `year` | int | 2023 / 2024 / 2025 |
| `quarter` | string | Q1 / Q2 / Q3 / Q4 |
| `score` | int | 300–850 (chuẩn nội bộ dataset) |
| `risk_level` | string | Low (≥700) / Medium (550–699) / High (<550) |

> ⚠️ **Critical note:** Không có cột `date` thực — chỉ có `year` + `quarter`. Để dùng time intelligence DAX, build column:

```dax
period_num = [year] * 10 +
    SWITCH([quarter], "Q1", 1, "Q2", 2, "Q3", 3, "Q4", 4)
```

---

## 🌟 Star Schema

**Fact tables:**

- `fact_transactions` — granularity: 1 row = 1 transaction
  - JOIN với `dim_accounts` via `account_id`
  - JOIN với `dim_date` via `txn_date`

- `fact_credit_scores` — granularity: 1 row = 1 customer × 1 quarter
  - JOIN với `dim_customers` via `customer_id`

**Dim tables:**

- `dim_customers` — descriptive attributes của KH
- `dim_accounts` — bridge table giữa customers và transactions
- `dim_date` — generated từ Power Query M, daily grain

**Bridge pattern:**

```text
fact_transactions → dim_accounts → dim_customers
                    (bridge)
```

→ Mọi customer-level query trên transactions cần **2 JOINs**.

---

## ⚠️ Data Caveats

### 1. Risk rate quá cao

Pattern: ~42% giao dịch có `risk_flag=1`. Banking thực tế chỉ 1–5%. Đây là đặc trưng dataset synthetic, không reflect production.

### 2. Time range mismatch

| Table | Range |
| --- | --- |
| `fact_transactions` | 2024-01 → 2025-12 (24 months) |
| `fact_credit_scores` | 2023-Q1 → 2025-Q4 (12 quarters) |

→ Slicer "Year" trong Power BI restrict 2024–2025 để avoid empty visuals.

### 3. Credit scores thưa

188 records / 198 customers / 12 quarters → average ~1 record/KH/year. Nhiều KH không có quý liền kề → QoQ migration coverage limited.

### 4. Cutoff điểm tín dụng

Dataset dùng 550/700 (chuẩn nội bộ). FICO thực tế là 580/720. Khi deploy production cần align với risk policy thực.

---

## 📥 How to Load

### SQL Server

```sql
-- Create database
CREATE DATABASE BankingCustomer360;
USE BankingCustomer360;

-- Bulk insert each CSV (adjust paths)
BULK INSERT customers
FROM 'C:\path\to\data\customers.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDTERMINATOR=',', ROWTERMINATOR='\n');
-- Repeat for: accounts, transactions, credit_scores
```

### Power BI Desktop

1. **Get Data** → **Text/CSV** → Select 4 files → Load
2. Relationships auto-detect dựa trên column names match
3. Verify Star Schema trong Model view → fix relationships nếu cần (đặc biệt `accounts ↔ transactions` direction)

---

*Schema thiết kế theo Kimball dimensional modeling. Slowly Changing Dimensions không implement vì dataset không có history tracking cho customer attributes.*