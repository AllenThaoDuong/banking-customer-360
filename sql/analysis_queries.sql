-- Mục đích phân tích theo các nhóm câu hỏi kinh doanh
-- 1. Khách hàng
-- 2. Sản phẩm và bán chéo sản phẩm
-- 3. Những hành vì giao dịch
-- 4. Rủi ro và gian lận trong gd
-- 5. Xu hướng tín dụng của data
USE BankingCustomer360

-- 1. Bức tranh của Khách hàng:
-- 1.1 Phần khúc khách hàng theo segment, city, gender
SELECT * FROM customers ORDER BY age ASC
SELECT
	segment,
	city,
	COUNT (*) AS SL_KH,
	CAST(AVG(age*1.0) AS decimal(5,1)) AS TUOI_TB,
	SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS n_KH_Nam,
	SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS n_KH_Nu,
	CAST(100.0 * COUNT(*) / -- Số khách trong nhóm hiện tại
		SUM(COUNT(*)) OVER () -- Tổng số khách của toàn bộ bảng.
		-- OVER () window function (không chia nhóm nữa, lấy toàn bộ)   
		AS DECIMAL(5,1)) -- Format tối đa 5 chữ số 1 chữ số thập phân
		AS pct_KH
FROM customers
GROUP BY segment, city
order by segment, SL_KH DESC;
-- 1.2 Thành phố có % KH VIP/AFFLUENT
-- Tập trung vào kênh khách hàng VIP và tiềm năng
SELECT
    city,
    COUNT(*) AS n_KH_Trong_TP,
    SUM(CASE WHEN segment IN ('VIP','Affluent') THEN 1 ELSE 0 END) AS n_KH_TIEM_NANG,
    CAST(100.0 * SUM(CASE WHEN segment IN ('VIP','Affluent') THEN 1 ELSE 0 END)
         / COUNT(*) AS DECIMAL(5,1)) AS pct_KH_TIEM_NANG
FROM   customers
GROUP BY city
ORDER BY pct_KH_TIEM_NANG DESC;
-- 1.3 Phân khúc độ tuổi và loại khách hàng -  phân bổ 18-30, 31-45, 46-60, 60+ 
-- Lựa chọn sản phẩm phù hợp cho từng độ tuổi và khoanh vùng độ tuổi khách hàng mục tiêu
SELECT
    CASE WHEN age BETWEEN 18 AND 30 THEN '18-30 Gen Z/Y'
         WHEN age BETWEEN 31 AND 45 THEN '31-45 Truong Thanh'
         WHEN age BETWEEN 46 AND 60 THEN '46-60 Trung Nien'
         ELSE                              '60+ Cao tuoi'
    END AS Phan_Khuc_Tuoi,
    segment,
    COUNT(*) AS n_KH,
    CAST(AVG(age * 1.0) AS DECIMAL(5,1)) AS Tuoi_TB
FROM   customers
GROUP BY
    CASE WHEN age BETWEEN 18 AND 30 THEN '18-30 Gen Z/Y'
         WHEN age BETWEEN 31 AND 45 THEN '31-45 Truong Thanh'
         WHEN age BETWEEN 46 AND 60 THEN '46-60 Trung Nien'
         ELSE                              '60+ Cao tuoi'
    END,
    segment
ORDER BY Phan_Khuc_Tuoi, segment;

-- 2. Sản phẩm và bán chéo sản phẩm
-- 2.1 Product mix + active rate theo từng product
-- Sản phẩm nào có tài khoản "ngủ đông" nhiều ?
SELECT
    account_type,
    count(*) AS SL_TK,
    SUM(CASE WHEN [status]='Active'   THEN 1 ELSE 0 END) AS n_active,
    SUM(CASE WHEN [status]='Inactive' THEN 1 ELSE 0 END) AS n_inactive,
    CAST(100.0 * SUM(CASE WHEN [status]='Active' THEN 1 ELSE 0 END) / COUNT(*)
         AS DECIMAL(5,1)) AS pct_Active
from accounts
GROUP BY account_type
ORDER BY SL_TK DESC;
-- 2.2 Top Khách hàng sử dụng nhiều SP
WITH product_count AS (
    SELECT
        a.customer_id,
        COUNT(DISTINCT a.account_type) AS n_product_types,
        SUM(CASE WHEN a.account_type='Savings'    THEN 1 ELSE 0 END) AS savings,
        SUM(CASE WHEN a.account_type='Credit'     THEN 1 ELSE 0 END) AS credit,
        SUM(CASE WHEN a.account_type='Investment' THEN 1 ELSE 0 END) AS investment
    FROM accounts a
    GROUP BY a.customer_id
)
SELECT 
    pc.customer_id, c.segment, c.city, c.age,
    pc.n_product_types,
    pc.savings, pc.credit, pc.investment
FROM   product_count pc
JOIN   customers c ON c.customer_id = pc.customer_id
WHERE  pc.n_product_types >= 2
ORDER BY c.segment, pc.n_product_types DESC, c.age ASC;
-- 2.3 Lổ hổng bán chéo SP - KH VIP/Affluent chưa có sử dụng Invesment
WITH cust_products AS (
    SELECT customer_id,
           MAX(CASE WHEN account_type='Savings'    THEN 1 ELSE 0 END) AS savings,
           MAX(CASE WHEN account_type='Credit'     THEN 1 ELSE 0 END) AS credit,
           MAX(CASE WHEN account_type='Investment' THEN 1 ELSE 0 END) AS investment
    FROM   accounts
    GROUP BY customer_id
) -- Mỗi khách hàng có sản phẩm gì
SELECT 
       c.customer_id, c.segment, c.city, c.age,
       cp.savings, cp.credit, cp.investment,
       SUM(t.amount) AS total_amount,
       COUNT(t.txn_id) AS n_GD
FROM   customers c
LEFT   JOIN cust_products cp ON cp.customer_id = c.customer_id
LEFT   JOIN accounts a   ON a.customer_id  = c.customer_id        -- bridge: customer → account
LEFT   JOIN transactions t ON t.account_id = a.account_id        -- bridge: account → txn
WHERE  c.segment IN ('VIP','Affluent')
  AND  ISNULL(cp.investment, 0) = 0
GROUP BY c.customer_id, c.segment, c.city, c.age,
         cp.savings, cp.credit, cp.investment
ORDER BY total_amount DESC;
-- 3. Những hành vi giao dịch 
-- 3.1 Trend giao dịch mỗi tháng - Tổng tiền, sl giao dịch, trung bình gd
SELECT
    FORMAT(txn_date, 'yyyy-MM') AS [month],
    COUNT(*) AS n_GD,
    SUM(amount) AS total_amount,
    CAST(AVG(amount)        AS DECIMAL(12,2)) AS avg_amount,
    CAST(SUM(CASE WHEN risk_flag=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
         AS DECIMAL(5,1)) AS pct_GD_RR
FROM   transactions
GROUP BY FORMAT(txn_date, 'yyyy-MM')
ORDER BY [month];
-- 3.2 Kênh và loại giao dịch
-- kênh nào dùng nhiều loại giao dịch gì 
SELECT * FROM transactions
SELECT
    channel,
    SUM(CASE WHEN txn_type='Payment'    THEN 1 ELSE 0 END) AS n_payment,
    SUM(CASE WHEN txn_type='Withdrawal' THEN 1 ELSE 0 END) AS n_withdrawal,
    SUM(CASE WHEN txn_type='Transfer'   THEN 1 ELSE 0 END) AS n_transfer,
    COUNT(*)AS Tong_GD,
    CAST(AVG(amount) AS DECIMAL(12,2)) AS avg_amount,
    SUM(amount) AS total_amount
FROM   transactions
GROUP BY channel
ORDER BY Tong_GD DESC;
-- 3.3 Nhóm Khách hàng chi tiêu mạnh - Bao nhiêu % khách hàng tạo ra 80% doanh thu 
-- 20% khách hàng đóng gióp 80% doanh thu
-- Top spending customers — Pareto 80/20 check
-- % khách đóng góp 80% revenue?
-- Note: phải JOIN qua accounts để có customer_id (transactions không có).
WITH ranked AS (
    SELECT
        a.customer_id,
        SUM(t.amount) AS total_spend, -- Tổng tiền khách đã giao dịch
        COUNT(*) AS n_txns, -- Tổng số lần giao dịch
        SUM(SUM(t.amount)) OVER () AS grand_total, -- tổng tiền của tất cả khách (không chia nhóm)
        SUM(SUM(t.amount)) OVER (ORDER BY SUM(t.amount) DESC ROWS UNBOUNDED PRECEDING) AS running_total
        -- Sắp xếp khách theo total_spend giảm dần
        -- Cộng dồn từ trên xuống
    FROM   transactions t
    JOIN   accounts      a ON a.account_id = t.account_id
    GROUP BY a.customer_id
)
SELECT 
    customer_id, total_spend, n_txns,
    CAST(100.0 * total_spend / grand_total AS DECIMAL(5,2)) AS pct_of_total,
    -- Tỷ trọng của từng khách trong toàn hệ thống
    CAST(100.0 * running_total / grand_total AS DECIMAL(5,2))   AS cumulative_pct
    -- Tổng % cộng dồn
FROM ranked
ORDER BY total_spend DESC;
-- 4. Rủi ro và gian lận trong gd
-- 4.1 Tỷ lệ rủi ro thông qua kênh và loại GD
SELECT
    channel, txn_type,
    COUNT(*) AS n_txns,
    SUM(CAST(risk_flag AS INT)) AS n_risky,
    CAST(100.0 * SUM(CAST(risk_flag AS INT)) / COUNT(*)
         AS DECIMAL(5,1)) AS risk_rate_pct
FROM   transactions
GROUP BY channel, txn_type
ORDER BY risk_rate_pct DESC;
-- 4.2 Phát hiện giao dịch tăng đột biến theo từng khách hàng (Z-score)
-- Định nghĩa: Z - SCORE PER customer
-- Fraud: xác định các giao dịch bất thường vượt khỏi hành vi chi tiêu thông thường
-- Baseline được tính theo từng khách hàng → cần JOIN qua accounts để lấy customer_id
WITH txn_with_cust AS (
    SELECT t.txn_id, t.account_id, a.customer_id,
           t.txn_date, t.amount, t.channel, t.txn_type, t.risk_flag
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
), -- Giao dịch với từng khách hàng
stats AS (
    SELECT
        customer_id,
        AVG(amount) AS avg_amt, -- Trung bình số tiền giao dịch bình thường
        STDEVP(amount) AS std_amt -- Độ lệch chuẩn (standard deviation population amount), Đo mức độ biến động chi tiêu
    FROM txn_with_cust
    GROUP BY customer_id
), -- baseline hành vi chi tiêu của từng khách (hành vi bình thường)
z_scored AS (
    SELECT
        tc.txn_id, tc.customer_id, tc.txn_date, tc.amount,
        tc.channel, tc.txn_type, tc.risk_flag,
        s.avg_amt, s.std_amt,
        CASE WHEN s.std_amt > 0
             THEN CAST((tc.amount - s.avg_amt) / s.std_amt AS DECIMAL(8,2)) -- Công thức Z-score = (x (giá trị hiện tại (amount)) - μ (trung bình (avg_amt))) / σ (độ lệch chuẩn (std_amt))
             ELSE 0 END AS z_score
    FROM txn_with_cust tc
    JOIN stats s ON s.customer_id = tc.customer_id
) -- Z-score (chuẩn hóa dữ liệu): = o (bình thường), > 2 (cao bất thường), < -2 (thấp bất thường)
SELECT *
FROM   z_scored
WHERE  ABS(z_score) > 2
ORDER BY ABS(z_score) DESC;
-- 4.3 Những khách hàng high risk
SELECT 
    a.customer_id,
    c.segment, c.city,
    COUNT(*) AS n_txns,
    SUM(CAST(t.risk_flag AS INT)) AS n_risky,
    CAST(100.0 * SUM(CAST(t.risk_flag AS INT)) / COUNT(*)
         AS DECIMAL(5,1)) AS risk_rate_pct,
    SUM(t.amount) AS total_amount
FROM   transactions t
JOIN   accounts      a ON a.account_id  = t.account_id
JOIN   customers     c ON c.customer_id = a.customer_id
GROUP BY a.customer_id, c.segment, c.city
HAVING COUNT(*) >= 3
ORDER BY n_risky DESC, risk_rate_pct DESC;
GO
-- 5. Xu hướng tín dụng của data
-- 5.1 Trung bình DTD (điểm tín dụng) theo quý + segment
SELECT
    cs.[year], cs.[quarter],
    c.segment,
    COUNT(*) AS n_customers,
    CAST(AVG(cs.score * 1.0) AS DECIMAL(6,1)) AS avg_score,
    CAST(100.0 * SUM(CASE WHEN cs.risk_level='High' THEN 1 ELSE 0 END) / COUNT(*)
         AS DECIMAL(5,1)) AS pct_high_risk
FROM   credit_scores cs
JOIN   customers c ON c.customer_id = cs.customer_id
GROUP BY cs.[year], cs.[quarter], c.segment
ORDER BY cs.[year], cs.[quarter], c.segment;
-- 5.2 Trạng thái rủi ro tín dụng hiện tại
-- Tổng quan mức độ rủi ro của khách hàng tại thời điểm hiện tại
WITH latest AS (
    SELECT
        customer_id,
        score, risk_level,
        ROW_NUMBER() OVER (PARTITION BY customer_id
                           ORDER BY [year] DESC, [quarter] DESC) AS rn
    FROM credit_scores
)
SELECT
    c.segment,
    l.risk_level,
    COUNT(*) AS n_customers,
    CAST(AVG(l.score * 1.0) AS DECIMAL(6,1)) AS avg_score
FROM   latest l
JOIN   customers c ON c.customer_id = l.customer_id
WHERE  l.rn = 1
GROUP BY c.segment, l.risk_level
ORDER BY c.segment,
         CASE l.risk_level WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END;
-- 5.3 Cảnh báo khách hàng bị giảm hạng tín dụng theo quý
-- Phát hiện sớm khách hàng có dấu hiệu suy giảm tín dụng để can thiệp kịp thời
DECLARE @target_year    INT          = 2023;
DECLARE @target_quarter VARCHAR(2)   = NULL;   -- 'Q1' | 'Q2' | 'Q3' | 'Q4' | NULL

WITH score_history AS (
    SELECT
        customer_id, [year], [quarter], score, risk_level,
        [year] * 10 +
            CASE [quarter] WHEN 'Q1' THEN 1 WHEN 'Q2' THEN 2
                            WHEN 'Q3' THEN 3 ELSE 4 END    AS period_int,
        LAG(risk_level) OVER (PARTITION BY customer_id
                              ORDER BY [year], [quarter])  AS prev_risk_level,
        LAG(score)      OVER (PARTITION BY customer_id
                              ORDER BY [year], [quarter])  AS prev_score
    FROM   credit_scores
)
SELECT
    sh.customer_id, c.segment, c.city,
    sh.[year], sh.[quarter],
    sh.prev_risk_level, sh.prev_score,
    sh.risk_level   AS current_risk_level,
    sh.score        AS current_score,
    sh.score - sh.prev_score AS score_delta
FROM   score_history sh
JOIN   customers c ON c.customer_id = sh.customer_id
WHERE  sh.prev_risk_level IS NOT NULL
  AND  sh.[year]    = @target_year
  AND  (@target_quarter IS NULL OR sh.[quarter] = @target_quarter)
  AND  ((sh.prev_risk_level = 'Low'    AND sh.risk_level IN ('Medium','High'))
   OR   (sh.prev_risk_level = 'Medium' AND sh.risk_level = 'High'))
ORDER BY score_delta ASC;  -- giảm điểm mạnh nhất lên đầu