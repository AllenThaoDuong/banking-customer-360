# DAX Measures — Banking Customer 360°

> Documentation cho 148 measures trong Power BI model, organized theo 7 Display Folders + 5 standalone measures.
> Mỗi folder có overview, table liệt kê, và 2-3 measures được highlight với full DAX + pattern note.

## 📊 Quick Stats

| Metric | Value |
|---|---|
| **Total measures** | **148** |
| Visible measures | 148 |
| Display Folders | 7 |
| Standalone measures | 5 |
| Longest DAX (chars) | 1,006 (`SL_KH_DTD_giam_manh`) |
| Average DAX length | 163 chars |

### Pattern Distribution

| DAX Pattern | Usage Count |
|---|---|
| `CALCULATE` | 68 |
| `VAR/RETURN` | 51 |
| `DIVIDE` | 26 |
| `ISBLANK` | 23 |
| `FILTER` | 22 |
| `SWITCH` | 21 |
| `DISTINCTCOUNT` | 17 |
| `SELECTEDVALUE` | 15 |
| `COUNTROWS` | 12 |
| `DATEADD` | 9 |
| `ALL` | 8 |
| `ALLSELECTED` | 7 |
| `ALLEXCEPT` | 5 |
| `SUMMARIZE` | 3 |
| `TOTALxTD` | 2 |

## 📑 Table of Contents

- [Rủi ro & Gian lận — Risk & Fraud (17 measures)](#risk-fraud)
- [Điểm tín dụng — Credit Score (20 measures)](#credit-score)
- [Bài toàn thời gian — Time Intelligence (MoM/QoQ/YoY) (33 measures)](#time-intelligence-momqoqyoy)
- [KPI cơ bản — Basic KPIs (25 measures)](#basic-kpis)
- [Sản phẩm & Khách Hàng — Products & Customers (18 measures)](#products-customers)
- [Remove filter — Filter Manipulation (ALLEXCEPT/ALL) (9 measures)](#filter-manipulation-allexceptall)
- [Color — Conditional Formatting (21 measures)](#conditional-formatting)
- [Standalone Measures (5)](#standalone-measures)
- [Cross-Cutting Patterns Observed](#cross-cutting-patterns-observed)

---

## Rủi ro & Gian lận — Risk & Fraud
<a id="risk-fraud"></a>

**Purpose:** 17 measures phát hiện giao dịch bất thường, customer high-risk, ranking, và pattern fraud (kênh × loại GD).

**Count:** 17 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_GD_rui_ro` | % gd, rủi ro | `0.00%;-0.00%;0.00%` |
| 2 | `DoLech_chuan_GD_cua_KH` | Độ lệch chuẩn | `—` |
| 3 | `Hang_KH_theo_TT_GD` | Hạng kh | `0` |
| 4 | `Kenh_rui_ro_nhat` | Kênh, rủi ro | `—` |
| 5 | `La_GD_spike` | Flag, bất thường | `0` |
| 6 | `La_KH_rui_ro_cao` | Flag, rủi ro | `0` |
| 7 | `La_KH_rui_ro_cao_dynamic` | Flag, rủi ro, dynamic threshold | `0` |
| 8 | `La_KH_top10_risky` | Flag, rủi ro, top 10 | `0` |
| 9 | `MUCRR_moi_nhat` | Mức rủi ro, mới nhất | `—` |
| 10 | `SL_GD_RUI_RO` | Số lượng gd | `0` |
| 11 | `SL_GD_spike` | Số lượng gd, bất thường | `0` |
| 12 | `SL_GD_spike_dynamic` | Số lượng gd, bất thường, dynamic threshold | `0` |
| 13 | `SL_KH_co_GD_rui_ro` | Số lượng kh, rủi ro | `0` |
| 14 | `SL_KH_rui_ro_cao_dynamic` | Số lượng kh, rủi ro, dynamic threshold | `0` |
| 15 | `TB_tien_GD_cua_KH` | Trung bình | `—` |
| 16 | `TT_GD_rui_ro` | Tổng tiền gd, rủi ro | `—` |
| 17 | `TieuDe_nguong_spike` | Tiêu đề động, bất thường | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `Kenh_rui_ro_nhat`

**Purpose:** Kênh, rủi ro

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `DIVIDE`, `TOPN`, `SUMMARIZE`, `COUNTROWS`

```dax
VAR _bang =
    SUMMARIZE(
        fact_transactions,
        fact_transactions[channel],
        "pct", DIVIDE(
            CALCULATE( COUNTROWS( fact_transactions ), fact_transactions[risk_flag] = 1 ),
            COUNTROWS( fact_transactions )
        )
    )
RETURN
    MAXX(
        TOPN( 1, _bang, [pct], DESC ),
        fact_transactions[channel]
    )
```

#### `MUCRR_moi_nhat`

**Purpose:** Mức rủi ro, mới nhất

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SWITCH`, `SELECTEDVALUE`, `FILTER`

```dax
VAR _period_max =
    CALCULATE(
        MAX( fact_credit_scores[year] ) * 10
        + SWITCH(
            MAX( fact_credit_scores[quarter] ),
            "Q1", 1, "Q2", 2, "Q3", 3, "Q4", 4
        )
    )
RETURN
    CALCULATE(
        SELECTEDVALUE( fact_credit_scores[risk_level], "—" ),
        FILTER(
            fact_credit_scores,
            fact_credit_scores[year] * 10
            + SWITCH( fact_credit_scores[quarter], "Q1",1,"Q2",2,"Q3",3,"Q4",4 )
              = _period_max
        )
    )
```

#### `La_KH_top10_risky`

**Purpose:** Flag, rủi ro, top 10

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `ALL`, `RANKX`, `FILTER`

```dax
VAR _qualify = 
    IF( [SL_GD] >= 3 && [%_GD_rui_ro] >= 0.3, 1, 0 )
VAR _rank = 
    IF( _qualify = 1,
        RANKX(
            FILTER(
                ALL( dim_customers[customer_id] ),
                CALCULATE( [SL_GD] >= 3 && [%_GD_rui_ro] >= 0.3 )
            ),
            [TT_GD],
            ,
            DESC,
            Dense
        ),
        BLANK()
    )
RETURN
    IF( _rank <= 10, 1, 0 )
```

---

## Điểm tín dụng — Credit Score
<a id="credit-score"></a>

**Purpose:** 20 measures phân tích điểm tín dụng theo segment, QoQ migration, customer downgrade detection, và range/stdev cho VIP card.

**Count:** 20 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_KH_DTD_TB` | % kh theo điểm tín dụng, dtd trung bình | `0.0%;-0.0%;0.0%` |
| 2 | `%_KH_DTD_cao` | % kh theo điểm tín dụng, dtd cao | `0.0%;-0.0%;0.0%` |
| 3 | `%_KH_DTD_thap` | % kh theo điểm tín dụng, dtd thấp | `0.0%;-0.0%;0.0%` |
| 4 | `DTD_max_segment` | Điểm tín dụng, theo segment | `0` |
| 5 | `DTD_min_segment` | Điểm tín dụng, theo segment | `0` |
| 6 | `DTD_moi_nhat` | Điểm tín dụng, mới nhất | `0` |
| 7 | `DTD_moi_nhat_v2` | Điểm tín dụng, mới nhất | `0` |
| 8 | `DTD_range_segment` | Điểm tín dụng, theo segment | `0` |
| 9 | `DTD_stdev_segment` | Điểm tín dụng, theo segment | `—` |
| 10 | `Range_VIP_card` | Biên độ, vip | `0` |
| 11 | `SL_KH_DTD_TB` | Số lượng kh, dtd trung bình | `0` |
| 12 | `SL_KH_DTD_cao` | Số lượng kh, dtd cao | `0` |
| 13 | `SL_KH_DTD_giam_manh` | Số lượng kh, giảm mạnh | `0` |
| 14 | `SL_KH_DTD_thap` | Số lượng kh, dtd thấp | `0` |
| 15 | `TB_DTD_ignore_slicer` | Tb điểm tín dụng, bỏ qua slicer | `—` |
| 16 | `TB_DTD_quy_truoc` | Tb điểm tín dụng, quý trước | `—` |
| 17 | `chenhlech_DTD_QoQ` | Chênh lệch, qoq | `—` |
| 18 | `chenhlech_pct_KH_DTD_TB_QoQ` | Chênh lệch, qoq, dtd trung bình | `—` |
| 19 | `chenhlech_pct_KH_DTD_cao_QoQ` | Chênh lệch, qoq, dtd cao | `—` |
| 20 | `chenhlech_pct_KH_DTD_thap_QoQ` | Chênh lệch, qoq, dtd thấp | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `SL_KH_DTD_giam_manh`

**Purpose:** Số lượng kh, giảm mạnh

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `ALL`, `ISBLANK`, `SUMMARIZE`, `ADDCOLUMNS`, `COUNTROWS`, `FILTER`

```dax
VAR _t =
    ADDCOLUMNS(
        SUMMARIZE( fact_credit_scores,
                   fact_credit_scores[customer_id],
                   fact_credit_scores[period_num],
                   fact_credit_scores[score] ),
        "DTD_truoc",
            VAR _cust = fact_credit_scores[customer_id]
            VAR _p    = fact_credit_scores[period_num]
            VAR _y    = INT( _p / 10 )
            VAR _q    = MOD( _p, 10 )
            VAR _p_prev = IF( _q = 1, ( _y - 1 ) * 10 + 4, _p - 1 )
            RETURN
                CALCULATE(
                    MAX( fact_credit_scores[score] ),
                    FILTER(
                        ALL( fact_credit_scores ),
                        fact_credit_scores[customer_id] = _cust
                        && fact_credit_scores[period_num] = _p_prev
                    )
                )
    )
RETURN
    COUNTROWS(
        FILTER(
            _t,
            NOT ISBLANK( [DTD_truoc] )
            && ( [score] - [DTD_truoc] ) <= -50
        )
    )
```

#### `DTD_moi_nhat`

**Purpose:** Điểm tín dụng, mới nhất

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SWITCH`, `FILTER`

```dax
VAR _period_max =
    CALCULATE(
        MAX( fact_credit_scores[year] ) * 10
        + SWITCH(
            MAX( fact_credit_scores[quarter] ),
            "Q1", 1, "Q2", 2, "Q3", 3, "Q4", 4
        )
    )
RETURN
    CALCULATE(
        AVERAGE( fact_credit_scores[score] ),
        FILTER(
            fact_credit_scores,
            fact_credit_scores[year] * 10
            + SWITCH( fact_credit_scores[quarter], "Q1",1,"Q2",2,"Q3",3,"Q4",4 )
              = _period_max
        )
    )
```

#### `TB_DTD_quy_truoc`

**Purpose:** Tb điểm tín dụng, quý trước

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SELECTEDVALUE`, `FILTER`

```dax
VAR _p      = SELECTEDVALUE( fact_credit_scores[period_num] )
VAR _y      = INT( _p / 10 )
VAR _q      = MOD( _p, 10 )
VAR _p_prev = IF( _q = 1, ( _y - 1 ) * 10 + 4, _p - 1 )
RETURN
    CALCULATE(
        [TB_DTD],
        REMOVEFILTERS(
            fact_credit_scores[period_label],
            fact_credit_scores[period_num],
            fact_credit_scores[year],
            fact_credit_scores[quarter]
        ),
        fact_credit_scores[period_num] = _p_prev
    )
```

---

## Bài toàn thời gian — Time Intelligence (MoM/QoQ/YoY)
<a id="time-intelligence-momqoqyoy"></a>

**Purpose:** 33 measures so sánh kỳ trước-kỳ này (Month-over-Month, Quarter-over-Quarter, Year-over-Year, Month-to-date, Year-to-date) cho transaction, customer, và credit metrics.

**Count:** 33 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_GD_rui_ro_thang_truoc` | % gd, tháng trước, rủi ro | `0.00%;-0.00%;0.00%` |
| 2 | `%_KH_DTD_TB_quy_truoc` | % kh theo điểm tín dụng, quý trước, dtd trung bình | `—` |
| 3 | `%_KH_DTD_cao_quy_truoc` | % kh theo điểm tín dụng, quý trước, dtd cao | `—` |
| 4 | `%_KH_DTD_thap_quy_truoc` | % kh theo điểm tín dụng, quý trước, dtd thấp | `—` |
| 5 | `%_TK_HD_MoM_format` | % tk, mom, (formatted) | `—` |
| 6 | `%_TK_HD_thang_truoc` | % tk, tháng trước | `—` |
| 7 | `%_TT_GD_MoM` | % tổng tiền, mom | `—` |
| 8 | `%_TT_GD_QoQ` | % tổng tiền, qoq | `—` |
| 9 | `%_TT_GD_YoY` | % tổng tiền, yoy | `—` |
| 10 | `SL_GD_RUI_RO_thang_truoc` | Số lượng gd, tháng trước | `0` |
| 11 | `SL_GD_thang_truoc` | Số lượng gd, tháng trước | `0` |
| 12 | `SL_KH_MoM_format` | Số lượng kh, mom, (formatted) | `—` |
| 13 | `SL_KH_moi_MoM_format` | Số lượng kh, mom, (formatted) | `—` |
| 14 | `SL_KH_moi_thang_truoc` | Số lượng kh, tháng trước | `0` |
| 15 | `SL_KH_rui_ro_thang_truoc` | Số lượng kh, tháng trước, rủi ro | `0` |
| 16 | `SL_KH_thang_truoc` | Số lượng kh, tháng trước | `0` |
| 17 | `SL_TK_MoM_format` | Số lượng tk, mom, (formatted) | `—` |
| 18 | `SL_TK_thang_truoc` | Số lượng tk, tháng trước | `0` |
| 19 | `TT_GD_MTD` | Tổng tiền gd, mtd | `—` |
| 20 | `TT_GD_YTD` | Tổng tiền gd, ytd | `—` |
| 21 | `TT_GD_nam_truoc` | Tổng tiền gd, năm trước | `—` |
| 22 | `TT_GD_quy_truoc` | Tổng tiền gd, quý trước | `—` |
| 23 | `TT_GD_rui_ro_thang_truoc` | Tổng tiền gd, tháng trước, rủi ro | `—` |
| 24 | `TT_GD_thang_truoc` | Tổng tiền gd, tháng trước | `—` |
| 25 | `TT_GD_thang_truoc_N` | Tổng tiền gd, tháng trước | `—` |
| 26 | `chenhlech_SL_GD_MoM` | Chênh lệch, mom | `0` |
| 27 | `chenhlech_SL_GD_rui_ro_MoM` | Chênh lệch, mom, rủi ro | `0` |
| 28 | `chenhlech_SL_KH_MoM` | Chênh lệch, mom | `0` |
| 29 | `chenhlech_SL_KH_moi_MoM` | Chênh lệch, mom | `0` |
| 30 | `chenhlech_SL_KH_rui_ro_MoM` | Chênh lệch, mom, rủi ro | `—` |
| 31 | `chenhlech_SL_TK_MoM` | Chênh lệch, mom | `0` |
| 32 | `chenhlech_TT_GD_MoM` | Chênh lệch, mom | `—` |
| 33 | `chenhlech_pct_TK_HD_MoM` | Chênh lệch, mom | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `%_KH_DTD_thap_quy_truoc`

**Purpose:** % kh theo điểm tín dụng, quý trước, dtd thấp

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SELECTEDVALUE`, `FILTER`

```dax
VAR _p      = SELECTEDVALUE( fact_credit_scores[period_num] )
VAR _y      = INT( _p / 10 )
VAR _q      = MOD( _p, 10 )
VAR _p_prev = IF( _q = 1, ( _y - 1 ) * 10 + 4, _p - 1 )
RETURN
    CALCULATE(
        [%_KH_DTD_thap],
        REMOVEFILTERS(
            fact_credit_scores[period_label],
            fact_credit_scores[period_num],
            fact_credit_scores[year],
            fact_credit_scores[quarter]
        ),
        fact_credit_scores[period_num] = _p_prev
    )
```

#### `%_KH_DTD_cao_quy_truoc`

**Purpose:** % kh theo điểm tín dụng, quý trước, dtd cao

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SELECTEDVALUE`, `FILTER`

```dax
VAR _p      = SELECTEDVALUE( fact_credit_scores[period_num] )
VAR _y      = INT( _p / 10 )
VAR _q      = MOD( _p, 10 )
VAR _p_prev = IF( _q = 1, ( _y - 1 ) * 10 + 4, _p - 1 )
RETURN
    CALCULATE(
        [%_KH_DTD_cao],
        REMOVEFILTERS(
            fact_credit_scores[period_label],
            fact_credit_scores[period_num],
            fact_credit_scores[year],
            fact_credit_scores[quarter]
        ),
        fact_credit_scores[period_num] = _p_prev
    )
```

#### `%_KH_DTD_TB_quy_truoc`

**Purpose:** % kh theo điểm tín dụng, quý trước, dtd trung bình

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SELECTEDVALUE`, `FILTER`

```dax
VAR _p      = SELECTEDVALUE( fact_credit_scores[period_num] )
VAR _y      = INT( _p / 10 )
VAR _q      = MOD( _p, 10 )
VAR _p_prev = IF( _q = 1, ( _y - 1 ) * 10 + 4, _p - 1 )
RETURN
    CALCULATE(
        [%_KH_DTD_TB],
        REMOVEFILTERS(
            fact_credit_scores[period_label],
            fact_credit_scores[period_num],
            fact_credit_scores[year],
            fact_credit_scores[quarter]
        ),
        fact_credit_scores[period_num] = _p_prev
    )
```

---

## KPI cơ bản — Basic KPIs
<a id="basic-kpis"></a>

**Purpose:** 25 measures đếm cơ bản: số lượng KH, TK, GD, tỷ lệ active, trung bình giao dịch, mở TK mới trong kỳ.

**Count:** 25 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_TK_HD` | % tk | `0.00%;-0.00%;0.00%` |
| 2 | `%_TK_HD_v2` | % tk | `0.00%;-0.00%;0.00%` |
| 3 | `%_TK_inactive_per_type` | % tk, tk inactive, per loại | `0.00%;-0.00%;0.00%` |
| 4 | `SL_GD` | Số lượng gd | `0` |
| 5 | `SL_KH` | Số lượng kh | `0` |
| 6 | `SL_KH_co_DTD` | Số lượng kh | `0` |
| 7 | `SL_KH_co_san` | Số lượng kh, có sẵn | `0` |
| 8 | `SL_KH_co_san_v2` | Số lượng kh, có sẵn | `0` |
| 9 | `SL_KH_co_san_v3` | Số lượng kh, có sẵn | `0` |
| 10 | `SL_KH_mo_TK_trong_thang` | Số lượng kh, mở mới trong tháng | `0` |
| 11 | `SL_KH_moi_trong_ky` | Số lượng kh | `0` |
| 12 | `SL_TK` | Số lượng tk | `0` |
| 13 | `SL_TK_HD` | Số lượng tk | `0` |
| 14 | `SL_TK_HD_mo_trong_thang` | Số lượng tk, mở mới trong tháng | `0` |
| 15 | `SL_TK_co_san` | Số lượng tk, có sẵn | `0` |
| 16 | `SL_TK_inactive_per_type` | Số lượng tk, tk inactive, per loại | `0` |
| 17 | `SL_TK_mo_trong_thang` | Số lượng tk, mở mới trong tháng | `0` |
| 18 | `TB_DTD` | Tb điểm tín dụng | `0` |
| 19 | `TB_GD_rui_ro_per_KH` | Trung bình, rủi ro, per kh | `—` |
| 20 | `TB_TIEN_GD` | Trung bình | `—` |
| 21 | `TB_TK_per_KH` | Trung bình, per kh | `—` |
| 22 | `TB_TK_per_KH_v2` | Trung bình, per kh | `—` |
| 23 | `TB_amount_per_GD_rui_ro` | Trung bình, rủi ro | `—` |
| 24 | `TT_GD` | Tổng tiền gd | `—` |
| 25 | `pct_KH_co_risk` | Phần trăm | `0.00%;-0.00%;0.00%` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `SL_KH_co_san_v2`

**Purpose:** Số lượng kh, có sẵn

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `ALL`, `ISBLANK`, `DISTINCTCOUNT`, `FILTER`

```dax
VAR _max_date = MAX( dim_date[Date] )
VAR _date_cutoff = 
    IF( ISBLANK( _max_date ), DATE(2099,12,31), _max_date )
RETURN
    CALCULATE(
        DISTINCTCOUNT( dim_customers[customer_id] ),
        FILTER( 
            ALL( dim_customers ), 
            dim_customers[proxy_register_date] <= _date_cutoff 
        )
    )
```

#### `SL_KH_co_san`

**Purpose:** Số lượng kh, có sẵn

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `ALL`, `ISBLANK`, `DISTINCTCOUNT`, `FILTER`

```dax
VAR _max_date = MAX( dim_date[Date])
VAR _date_cutoff = 
    IF( ISBLANK( _max_date ), DATE(2099,12,31), _max_date )
RETURN
    CALCULATE(
        DISTINCTCOUNT( dim_accounts[customer_id] ),
        FILTER( 
            ALL( dim_accounts ), 
            dim_accounts[open_date] <= _date_cutoff 
        )
    )
```

#### `%_TK_inactive_per_type`

**Purpose:** % tk, tk inactive, per loại

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `DIVIDE`, `ISBLANK`, `COUNTROWS`

```dax
VAR _max_date = MAX( dim_date[Date] )
VAR _date_cutoff = 
    IF( ISBLANK( _max_date ), DATE(2099,12,31), _max_date )
VAR _inactive = 
    CALCULATE(
        COUNTROWS( dim_accounts ),
        dim_accounts[status] = "Inactive",
        dim_accounts[open_date] <= _date_cutoff
    )
VAR _total = 
    CALCULATE(
        COUNTROWS( dim_accounts ),
        dim_accounts[open_date] <= _date_cutoff
    )
RETURN
    DIVIDE( _inactive, _total )
```

---

## Sản phẩm & Khách Hàng — Products & Customers
<a id="products-customers"></a>

**Purpose:** 18 measures về phân khúc KH (VIP/Affluent/Mass), product mix, cảnh báo per customer, dynamic title cho Customer 360° page.

**Count:** 18 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_GD_theo_kenh` | % gd, theo kênh | `0.00%;-0.00%;0.00%` |
| 2 | `%_KH_VIP` | % kh, vip | `—` |
| 3 | `%_KH_VIP_Affluent_per_city` | % kh, vip, affluent, per thành phố | `—` |
| 4 | `%_KH_trong_PK` | % kh | `—` |
| 5 | `%_SP_trong_PK` | % sản phẩm | `—` |
| 6 | `Canhbao_spike_KH` | Cảnh báo, bất thường | `—` |
| 7 | `Canhbao_spike_KH_v2` | Cảnh báo, bất thường | `—` |
| 8 | `SL_KH_VIP` | Số lượng kh, vip | `0` |
| 9 | `SL_KH_VIP_Affluent` | Số lượng kh, vip, affluent | `0` |
| 10 | `SL_KH_dang_chon` | Số lượng kh, đang chọn | `0` |
| 11 | `SL_TK_dautu` | Số lượng tk, tk đầu tư | `0` |
| 12 | `SL_TK_tietkiem` | Số lượng tk, tk tiết kiệm | `0` |
| 13 | `SL_TK_tindung` | Số lượng tk, tk tín dụng | `0` |
| 14 | `TB_TT_GD_per_KH` | Trung bình, per kh | `—` |
| 15 | `TB_loaiSP_per_KH` | Trung bình, per kh | `—` |
| 16 | `TieuDe_KH_360` | Tiêu đề động, customer 360° | `—` |
| 17 | `TieuDe_KH_360_v2` | Tiêu đề động, customer 360° | `—` |
| 18 | `TieuDe_KH_360_v3` | Tiêu đề động, customer 360° | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `Canhbao_spike_KH_v2`

**Purpose:** Cảnh báo, bất thường

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `SWITCH`, `DISTINCTCOUNT`

```dax
VAR _sl_kh           = [SL_KH_dang_chon]
VAR _sl_spike        = [SL_GD_spike]
VAR _sl_kh_co_spike  =
    CALCULATE(
        DISTINCTCOUNT( dim_accounts[customer_id] ),
        fact_transactions[La_spike] = 1
    )
RETURN
    SWITCH( TRUE(),
        _sl_kh = 0,        "ℹ️ Chọn KH để xem cảnh báo",
        _sl_spike = 0,     "✅ Không phát hiện giao dịch bất thường",
        _sl_kh = 1,        "🚨 " & _sl_spike & " GD bất thường",
        "🚨 " & _sl_spike & " GD bất thường tại " & _sl_kh_co_spike & "/" & _sl_kh & " KH"
    )
```

#### `TieuDe_KH_360_v3`

**Purpose:** Tiêu đề động, customer 360°

**Patterns used:** `VAR/RETURN`, `TOPN`, `SWITCH`, `CONCATENATEX`

```dax
VAR _sl = [SL_KH_dang_chon]
VAR _top3_list = 
    CONCATENATEX(
        TOPN( 
            3, 
            VALUES( dim_customers[customer_id] ),
            dim_customers[customer_id], ASC 
        ),
        dim_customers[customer_id],
        ", "
    )
VAR _remainder = _sl - 3
RETURN
    SWITCH( TRUE(),
        _sl = 0,    "📋 Hồ sơ 360° — Vui lòng chọn khách hàng",
        _sl <= 3,   "📋 Hồ sơ 360° — " & _top3_list,
                    "📋 Hồ sơ 360° — " & _top3_list & " +" & _remainder & " KH khác"
    )
```

#### `SL_KH_dang_chon`

**Purpose:** Số lượng kh, đang chọn

**Patterns used:** `VAR/RETURN`, `CALCULATE`, `DISTINCTCOUNT`, `COUNTROWS`, `FILTER`

```dax
VAR _selected = COUNTROWS(VALUES(dim_customers[customer_id]))
VAR _total = CALCULATE(
    DISTINCTCOUNT(dim_customers[customer_id]),
    REMOVEFILTERS( dim_customers)
)
RETURN
    IF( _selected = _total, 0, _selected )
```

---

## Remove filter — Filter Manipulation (ALLEXCEPT/ALL)
<a id="filter-manipulation-allexceptall"></a>

**Purpose:** 9 measures so sánh against bank-wide baseline hoặc cross-segment using ALL/ALLEXCEPT — pattern khó nhất trong DAX với nhiều ứng viên trip up.

**Count:** 9 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_KH_so_voi_PK` | % kh | `—` |
| 2 | `%_dong_gop_TT_GD` | % đóng góp | `—` |
| 3 | `TB_DTD_toan_bank` | Tb điểm tín dụng, toàn bank | `—` |
| 4 | `TB_DTD_toan_bank_2` | Tb điểm tín dụng, toàn bank | `—` |
| 5 | `TB_TIEN_GD_toan_bank` | Trung bình, toàn bank | `—` |
| 6 | `TT_GD_TB_cung_PK` | Tổng tiền gd, cùng phân khúc | `—` |
| 7 | `TT_GD_toan_bank` | Tổng tiền gd, toàn bank | `—` |
| 8 | `chenhlech_DTD_so_toanbank` | Chênh lệch | `—` |
| 9 | `chenhlech_TB_so_toanbank` | Chênh lệch | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `TT_GD_toan_bank`

**Purpose:** Tổng tiền gd, toàn bank

**Patterns used:** `CALCULATE`, `FILTER`

```dax
CALCULATE(
    [TT_GD],
    REMOVEFILTERS(dim_date[Thang_text]),
    REMOVEFILTERS( dim_customers[segment], dim_customers[city] ),
    REMOVEFILTERS( fact_transactions[channel], fact_transactions[txn_type] )
)
```

#### `TB_TIEN_GD_toan_bank`

**Purpose:** Trung bình, toàn bank

**Patterns used:** `CALCULATE`, `FILTER`

```dax
CALCULATE(
    [TB_TIEN_GD],
    REMOVEFILTERS( dim_customers[segment], dim_customers[city] )
)
```

#### `TB_DTD_toan_bank`

**Purpose:** Tb điểm tín dụng, toàn bank

**Patterns used:** `CALCULATE`, `FILTER`

```dax
CALCULATE(
    [TB_DTD],
    REMOVEFILTERS( dim_customers[segment], dim_customers[city] )
)
```

---

## Color — Conditional Formatting
<a id="conditional-formatting"></a>

**Purpose:** 21 measures helper trả về mã hex màu hoặc icon for conditional formatting trên cards, tables, và charts.

**Count:** 21 measures

### Measures in this folder

| # | Measure | Brief Description | Format |
|---|---|---|---|
| 1 | `%_KH_DTD_TB_QoQ_format` | % kh theo điểm tín dụng, qoq, (formatted), dtd trung bình | `—` |
| 2 | `%_KH_DTD_cao_QoQ_format` | % kh theo điểm tín dụng, qoq, (formatted), dtd cao | `—` |
| 3 | `%_KH_DTD_thap_QoQ_format` | % kh theo điểm tín dụng, qoq, (formatted), dtd thấp | `—` |
| 4 | `%_TK_HD_color` | % tk | `—` |
| 5 | `%_TT_GD_MoM_format` | % tổng tiền, mom, (formatted) | `—` |
| 6 | `COLOR_HIGH` | Mã màu cố định | `—` |
| 7 | `COLOR_LOW` | Mã màu cố định | `—` |
| 8 | `COLOR_MEDIUM` | Mã màu cố định | `—` |
| 9 | `Color_TT_GD_top` | Helper màu | `—` |
| 10 | `Color_risk_level` | Helper màu | `—` |
| 11 | `Risk_level_icon` | Mức rủi ro | `—` |
| 12 | `SL_GD_rui_ro_MoM_format` | Số lượng gd, mom, (formatted), rủi ro | `—` |
| 13 | `SL_KH_rui_ro_MoM_format` | Số lượng kh, mom, (formatted), rủi ro | `—` |
| 14 | `TB_DTD_QoQ_format` | Tb điểm tín dụng, qoq, (formatted) | `—` |
| 15 | `TB_TK_per_KH_color` | Trung bình, per kh | `—` |
| 16 | `TT_GD_MoM_format` | Tổng tiền gd, mom, (formatted) | `—` |
| 17 | `TT_delta_%_rui_ro_MoM` | Mom, rủi ro | `—` |
| 18 | `TT_delta_SL_GD` | — | `—` |
| 19 | `TT_delta_SL_GD_RUI_RO` | — | `—` |
| 20 | `TT_delta_TT_GD_rui_ro` | Rủi ro | `—` |
| 21 | `f_DTD_QoQ` | Format dtd, qoq | `—` |

### ⭐ Highlighted Measures

3 measures phức tạp nhất trong folder này — đại diện cho DAX skill level:

#### `TB_DTD_QoQ_format`

**Purpose:** Tb điểm tín dụng, qoq, (formatted)

**Patterns used:** `VAR/RETURN`, `ISBLANK`, `SWITCH`

```dax
VAR _prev = [TB_DTD_quy_truoc]                   -- ✅ check trên _prev
VAR _v    = [chenhlech_DTD_QoQ]
RETURN
    SWITCH( TRUE(),
        ISBLANK( _prev ), "—",                   -- không có quý trước → hiển thị dash
        _v = 0,           "● Không đổi",
        _v > 0,           "▲ +" & FORMAT( _v, "0" ) & " Quý Trước",
                          "▼ −" & FORMAT( ABS( _v ), "0" ) & " Quý Trước"
    )
```

#### `%_KH_DTD_cao_QoQ_format`

**Purpose:** % kh theo điểm tín dụng, qoq, (formatted), dtd cao

**Patterns used:** `VAR/RETURN`, `ISBLANK`, `SWITCH`

```dax
VAR _prev = [%_KH_DTD_cao_quy_truoc]                   -- ✅ check trên _prev
VAR _v = [chenhlech_pct_KH_DTD_cao_QoQ]
RETURN
    SWITCH( TRUE(),
        ISBLANK (_prev), "—",
        _v >= 0, "▲ +" & FORMAT( ABS( _v ) * 100, "0.0" ) & "% Quý Trước",
        "▼ −" & FORMAT( ABS( _v ) * 100, "0.0" ) & "% Quý Trước"
    )
```

#### `SL_GD_rui_ro_MoM_format`

**Purpose:** Số lượng gd, mom, (formatted), rủi ro

**Patterns used:** `VAR/RETURN`, `ISBLANK`, `SWITCH`

```dax
VAR _prev = [SL_GD_rui_ro_thang_truoc]
VAR _v    = [chenhlech_SL_GD_rui_ro_MoM]
RETURN
    SWITCH( TRUE(),
        ISBLANK( _prev ), "—",
        _v > 0,  "▲ +" & FORMAT( _v, "0" ) & " GD (xấu đi)",
        _v < 0,  "▼ −" & FORMAT( ABS(_v), "0" ) & " GD (cải thiện)",
                 "● Không đổi"
    )
```

---

## Standalone Measures
<a id="standalone-measures"></a>

**Count:** 5 measures không thuộc folder nào — chủ yếu là what-if parameter values và display helpers.

| # | Measure | Brief Description |
|---|---|---|
| 1 | `Nguong_z_score Value` | Ngưỡng (what-if) |
| 2 | `Nguong_min_GD Value` | Ngưỡng (what-if) |
| 3 | `Nguong_%_rui_ro Value` | Ngưỡng (what-if), rủi ro |
| 4 | `Risk_level_moi_nhat` | Mức rủi ro, mới nhất |
| 5 | `Donut_center_label` | Donut helper |

### Full DAX

#### `Nguong_z_score Value`

```dax
SELECTEDVALUE('Nguong_z_score'[Nguong_z_score], 2)
```

#### `Nguong_min_GD Value`

```dax
SELECTEDVALUE('Nguong_min_GD'[Nguong_min_GD], 3)
```

#### `Nguong_%_rui_ro Value`

```dax
SELECTEDVALUE('Nguong_pct_rui_ro'[Nguong_%_rui_ro], 0.3)
```

#### `Risk_level_moi_nhat`

```dax
VAR _max_period =
    CALCULATE(
        MAX( fact_credit_scores[period_num] ),
        ALLEXCEPT( fact_credit_scores, fact_credit_scores[customer_id] )
    )
RETURN
    CALCULATE(
        SELECTEDVALUE( fact_credit_scores[risk_level] ),
        fact_credit_scores[period_num] = _max_period
    )
```

#### `Donut_center_label`

```dax
"🚨 " & FORMAT( [SL_KH_co_GD_rui_ro], "0" ) & UNICHAR(10) & "KH có GD RR"
```

---

## Cross-Cutting Patterns Observed
<a id="cross-cutting-patterns-observed"></a>

Một số DAX patterns được dùng nhiều lần trong model — đáng note để recruiter hiểu kỹ năng:

### 1. `VAR / RETURN` pattern

Dùng trong **51/148 measures**. Đây là best practice DAX để:
- Tăng readability của measure phức tạp
- Tránh re-compute (DAX cache VAR results)
- Tách logic thành steps dễ debug

### 2. `DIVIDE` thay vì `/`

Dùng trong **26 measures**. `DIVIDE(num, denom, alt_result)` an toàn hơn `/` vì auto-handle zero denominator. Defensive coding pattern cho dashboard production-ready.

### 3. `SWITCH(TRUE(), ...)` for conditional logic

Dùng trong **21 measures**. Idiomatic DAX cho if-else chains — cleaner hơn nested IF.

### 4. `FILTER(ALL(...), ...)` for cross-quarter calculations

Pattern: `CALCULATE(MAX(...), FILTER(ALL(table), [period_num] = _period_max))` — dùng để find latest period value bất kể slicer filter. Quan trọng cho measures `*_moi_nhat`.

### 5. `period_num` cross-year arithmetic

Pattern: `[year] * 10 + SWITCH([quarter], "Q1",1, "Q2",2, "Q3",3, "Q4",4)`

Dùng để compute previous period across year boundary. Without this, Q1 mỗi năm sẽ compare nhầm với Q4 cùng năm. Pattern này xuất hiện trong nhiều measures Time Intelligence.

### 6. `ALL` / `ALLEXCEPT` for baseline comparisons

`ALLEXCEPT`: 5 measures. `ALL`: 8 measures. Folder "Remove filter" dedicate riêng cho pattern này — để compute KPI cùng phân khúc, toàn bank, hoặc bỏ qua slicer.

### 7. Defensive coding với `ISBLANK`

Dùng trong **23 measures**. Production pattern — handle case không có previous period, không có row trong filter, etc. Tránh dashboard hiển thị error.

---

## 📌 Notes

**Generated from Power BI model via DAX Studio DMV query:**

```sql
SELECT [Name], [DisplayFolder], [Expression], [Description], [FormatString], [IsHidden]
FROM $SYSTEM.TMSCHEMA_MEASURES
ORDER BY [DisplayFolder]
```

**Brief descriptions** auto-decoded from Vietnamese measure naming conventions. Có thể edit thủ công để precise hơn nếu cần.

**Highlighted measures** chọn theo complexity score (DAX length + pattern count). Có thể swap ra measures khác nếu Johnny thấy measure khác representative hơn.