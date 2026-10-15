# 🧹 MySQL Data Cleaning: World Layoffs Dataset

A comprehensive SQL data cleaning project demonstrating real-world techniques to transform messy, unformatted company layoff data into an analysis-ready dataset.

---

## 📌 Project Overview

Raw real-world datasets often contain duplicates, typos, inconsistent categories, unformatted dates, and null values. This project showcases the standard **4-step data cleaning pipeline** in MySQL using window functions, string manipulation, self-joins for data imputation, and schema modifications.

### 🛡️ Golden Rule: Protect the Raw Data
> **Never modify raw data directly.**  
> Always create a duplicate **staging table** (`layoffs_staging`) before performing modifications. This ensures you can always recover or compare against the original data.

---

## 🛠️ The 4 Steps of Data Cleaning

```
Raw Data ➔ [1. Remove Duplicates] ➔ [2. Standardize Data] ➔ [3. Handle Nulls/Blanks] ➔ [4. Clean Up Columns] ➔ Ready for EDA
```

---

### Step 1: Remove Duplicates

#### **Why?**
Duplicate records artificially inflate metrics like company counts, total layoffs, and funds raised.

#### **The Challenge in MySQL:**
We use `ROW_NUMBER()` with a `PARTITION BY` across all relevant columns to identify duplicate entries (`row_num > 1`). However, in MySQL, **you cannot delete directly from a CTE with window functions** (e.g., `DELETE FROM duplicate_cte WHERE row_num > 1` triggers an error).

#### **The Solution:**
1. Create a second staging table (`layoffs_staging2`) with an added column: `row_num INT`.
2. Insert data along with the calculated row number.
3. Delete rows where `row_num > 1`.

```sql
-- 1. Identify duplicates using a CTE & ROW_NUMBER()
WITH duplicate_cte AS
(
    SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte WHERE row_num > 1;

-- 2. Insert into staging table with row_num column and delete duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```

---

### Step 2: Standardize the Data

#### **Why?**
Inconsistent naming, extra whitespaces, and wrong data types cause grouped queries (`GROUP BY`) and filters to fail or produce fragmented summaries.

#### **Key Techniques Used:**

1. **Remove Extra Whitespace (`TRIM`):**
   ```sql
   UPDATE layoffs_staging2
   SET company = TRIM(company);
   ```

2. **Normalize Categorical Labels (`LIKE` & `UPDATE`):**
   Entries like `CryptoCurrency`, `Crypto Currency`, and `Crypto` refer to the same industry.
   ```sql
   UPDATE layoffs_staging2
   SET industry = 'Crypto'
   WHERE industry LIKE 'Crypto%';
   ```

3. **Remove Trailing Punctuation (`TRIM(TRAILING ...)`):**
   Fix entries like `United States.` so they match `United States`.
   ```sql
   UPDATE layoffs_staging2
   SET country = TRIM(TRAILING '.' FROM country)
   WHERE country LIKE 'United States%';
   ```

4. **Convert Text to Proper Date (`STR_TO_DATE` & `MODIFY COLUMN`):**
   The `date` column was originally stored as text formatted as `%m/%d/%Y`.
   ```sql
   -- Convert text strings into valid SQL date format
   UPDATE layoffs_staging2
   SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

   -- Alter column data type from text to DATE
   ALTER TABLE layoffs_staging2
   MODIFY COLUMN `date` DATE;
   ```

---

### Step 3: Handle Null and Blank Values

#### **Why?**
Blank strings (`''`) and `NULL` values behave differently in SQL. Unhandled nulls can cause miscalculations, while blanks can be populated if duplicate company records already have the missing details.

#### **Key Techniques Used:**

1. **Convert Blanks to NULLs for Consistency:**
   ```sql
   UPDATE layoffs_staging2
   SET industry = NULL
   WHERE industry = '';
   ```

2. **Data Imputation via Self-Join:**
   If Company A has an entry with `industry = NULL` but another record for the same company has `industry = 'Travel'`, we copy the known industry over.
   ```sql
   UPDATE layoffs_staging2 t1
   JOIN layoffs_staging2 t2
       ON t1.company = t2.company
   SET t1.industry = t2.industry
   WHERE t1.industry IS NULL
     AND t2.industry IS NOT NULL;
   ```

3. **Delete Irrelevant / Unusable Rows:**
   Rows missing both `total_laid_off` and `percentage_laid_off` cannot be used to analyze layoffs and have no recovery value.
   ```sql
   DELETE
   FROM layoffs_staging2
   WHERE total_laid_off IS NULL
     AND percentage_laid_off IS NULL;
   ```

---

### Step 4: Remove Unnecessary Helper Columns

#### **Why?**
Columns created strictly to facilitate the cleaning pipeline (like `row_num`) are no longer needed and should be dropped to keep the dataset clean and compact.

```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

---

## 🧠 Quick Reference: SQL Functions Cheat Sheet

| Function / Clause | Purpose in Data Cleaning | Example |
| :--- | :--- | :--- |
| `ROW_NUMBER() OVER(PARTITION BY ...)` | Flags duplicate rows with an incrementing integer. | Finding rows where `row_num > 1` |
| `TRIM(str)` | Strips leading and trailing spaces. | `TRIM(company)` |
| `TRIM(TRAILING '.' FROM str)` | Removes specific trailing characters (like stray periods). | `TRIM(TRAILING '.' FROM country)` |
| `STR_TO_DATE(str, format)` | Parses string text into date format. | `STR_TO_DATE(date, '%m/%d/%Y')` |
| `ALTER TABLE ... MODIFY COLUMN` | Modifies the data type of an existing column. | Converting text column to `DATE` |
| `UPDATE ... JOIN ... ON` | Populates missing data across rows using a self-join. | Imputing missing industry data |
| `ALTER TABLE ... DROP COLUMN` | Removes temporary helper columns. | Dropping `row_num` |

---

## 🚀 How to Run the Project

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vera0406/Mysql-data-cleaning-tutorial.git
   cd Mysql-data-cleaning-tutorial
   ```

2. **Import the Dataset:**
   - Open **MySQL Workbench** and connect to your database instance.
   - Create a database schema (e.g., `CREATE DATABASE world_layoffs; USE world_layoffs;`).
   - Right-click **Tables** in the schema navigator and select **Table Data Import Wizard**.
   - Browse to `layoffs.csv` in this repository and import it into a table named `layoffs`.

3. **Run the Cleaning Script:**
   - Open and execute `MySQL_data cleaning_tutorial.sql` sequentially.

4. **Query the Cleaned Data:**
   ```sql
   SELECT * FROM layoffs_staging2;
   ```
