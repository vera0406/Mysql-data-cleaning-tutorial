# 📊 Exploratory Data Analysis (EDA): World Layoffs

A comprehensive SQL study guide for performing **Exploratory Data Analysis (EDA)** on the cleaned tech layoffs dataset (`layoffs_staging2`).

---

## 🎯 What is Exploratory Data Analysis (EDA)?

In the previous project ([Data Cleaning](../README.md)), we cleaned, standardized, and prepped the raw data. 

**EDA** is the next step: exploring the dataset to uncover **patterns, trends, anomalies, and insights** to answer key business questions:
- *How severe were the layoffs?*
- *Which companies and industries were hit the hardest?*
- *Over what timeframe did this happen?*
- *How did layoffs trend month-over-month (cumulative progression)?*
- *Who were the top 5 worst-hit companies each year?*

---

## 📚 Study Notes: 9 SQL Exploratory Queries

Here is a breakdown of every query in `MySQL_data search_tutorial.sql`, designed for easy review and revision.

---

### 1. Baseline Data Inspection
```sql
SELECT *
FROM layoffs_staging2;
```
* **Purpose:** Inspect the cleaned table structure, column names, and sample values before running analytical queries.
* **Study Note:** Always check your clean table first to confirm data types and ensure no obvious anomalies remain from the cleaning phase.

---

### 2. Maximum Single Layoff Event & Percentage
```sql
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;
```
* **Purpose:** Find the peak numbers in the dataset.
* **Study Note:** 
  - `MAX(total_laid_off)` returns the single largest layoff event by head count.
  - `MAX(percentage_laid_off)` returns `1` (which represents **100% of the workforce laid off**).

---

### 3. Complete Company Shutdowns (100% Laid Off)
```sql
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;
```
* **Purpose:** Identify companies that went completely out of business (`percentage_laid_off = 1`).
* **Study Note:** Sorting by `total_laid_off DESC` places the largest shutdowns (by employee count) at the top.

---

### 4. Total Layoffs by Company
```sql
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
```
* **Purpose:** Find which companies laid off the most people in total across all layoff rounds.
* **Study Note:**
  - `GROUP BY company` groups all records belonging to the same company.
  - `SUM(total_laid_off)` adds together multiple rounds of layoffs.
  - `ORDER BY 2 DESC` orders by the 2nd column (`SUM(total_laid_off)`) in descending order.

---

### 5. Dataset Time Horizon
```sql
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;
```
* **Purpose:** Find the starting and ending dates of the dataset.
* **Study Note:** This defines the scope of analysis (e.g., from early 2020 at the onset of COVID-19 through early 2023).

---

### 6. Yearly Layoff Trend
```sql
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;
```
* **Purpose:** Measure how layoffs fluctuated year over year.
* **Study Note:** 
  - `YEAR(date)` extracts the 4-digit year from the SQL `DATE` column.
  - `ORDER BY 1 DESC` orders by year descending (most recent first).

---

### 7. Cumulative Layoff Percentage by Company
```sql
SELECT company, SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;
```
* **Purpose:** Spot companies that carried out multiple aggressive downsizing rounds.
* **Study Note:** While percentage values cannot simply be summed to represent true headcount, a sum close to or greater than `1` highlights companies that had several consecutive rounds of significant staff cuts.

---

### 8. Monthly Rolling Total of Layoffs (Cumulative Sum)

```sql
WITH Rolling_Total AS
(
    SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`, total_off, 
       SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;
```

#### 🔍 Deep Dive: How the Rolling Total Works
1. **CTE (`Rolling_Total`):**
   - `SUBSTRING(date, 1, 7)` extracts the year and month (`YYYY-MM`).
   - `SUM(total_laid_off)` calculates total layoffs for that specific month.
2. **Window Function:**
   - `SUM(total_off) OVER(ORDER BY MONTH)` computes a **running cumulative total**.
   
```
Month       Monthly Total    Rolling Total (Cumulative)
-------------------------------------------------------
2020-03     9,628            9,628
2020-04     26,710           36,338  (9,628 + 26,710)
2020-05     25,804           62,142  (36,338 + 25,804)
```

---

### 9. Top 5 Companies with Highest Layoffs Per Year

```sql
WITH Company_Year (company, years, total_laid_off) AS
(
    -- CTE 1: Aggregate total layoffs per company per year
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
), 
Company_Year_Rank AS 
(
    -- CTE 2: Rank companies within each year based on total layoffs
    SELECT *, 
           DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_Year
    WHERE years IS NOT NULL
)
-- Final Filter: Retrieve only the top 5 ranked companies for each year
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
```

#### 🔍 Deep Dive: Multi-CTE & Window Partition
- **CTE 1 (`Company_Year`):** Aggregates layoffs so each row represents `(Company, Year, Total Layoffs)`.
- **CTE 2 (`Company_Year_Rank`):** 
  - `PARTITION BY years`: Resets the ranking counter back to 1 for each year.
  - `ORDER BY total_laid_off DESC`: Ranks the company with the most layoffs as `#1`.
  - `DENSE_RANK()`: Handles ties without skipping ranking numbers.
- **Outer Query:** Filters `WHERE Ranking <= 5` to keep only the top 5 per year.

---

## 🧠 Study Guide: Ranking Functions Comparison

When ranking rows in SQL window functions:

| Function | Behavior with Ties | Example Ranking with Ties |
| :--- | :--- | :--- |
| `ROW_NUMBER()` | Assigns unique sequential numbers regardless of ties. | 1, 2, 3, 4 |
| `RANK()` | Same rank for ties, but **skips** the next ranks. | 1, 2, **2, 4** |
| `DENSE_RANK()` | Same rank for ties, **without skipping** any numbers. *(Best for Top-N)* | 1, 2, **2, 3** |

---

## 🚀 Quick Reference: Key Functions Used in EDA

| Function | Syntax | Description |
| :--- | :--- | :--- |
| `YEAR()` | `YEAR(date)` | Extracts the year (e.g. `2022`). |
| `SUBSTRING()` | `SUBSTRING(str, pos, len)` | Extracts a slice of text (e.g. `YYYY-MM`). |
| `SUM() OVER(ORDER BY ...)` | `SUM(val) OVER(ORDER BY col)` | Running / cumulative total. |
| `DENSE_RANK() OVER(PARTITION BY ... ORDER BY ...)` | Window rank partitioned by category | Ranks items within groups (e.g., top companies by year). |
| `WITH ... AS (...)` | Common Table Expression (CTE) | Creates a temporary result set for cleaner, modular queries. |
