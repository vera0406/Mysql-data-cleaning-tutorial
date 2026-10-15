-- Exploratory Data Analysis (EDA)

-- 1. View the entire cleaned dataset to inspect all columns and rows
SELECT *
FROM layoffs_staging2;

-- 2. Find the highest single-event layoff count and maximum layoff percentage
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- 3. List all companies that laid off 100% of their workforce, ordered by total employees lost
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off;

-- 4. Calculate total layoffs per company across the entire dataset, ranked from highest to lowest
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 5. Find the earliest and latest dates to determine the full time range of the dataset
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- 6. Calculate total layoffs by year to identify macro trends over time
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

-- 7. Sum the percentage of staff laid off per company to spot multiple aggressive downsizing rounds
SELECT company, SUM(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- 8. Calculate monthly total layoffs and running cumulative total (rolling sum) over time
WITH Rolling_Total AS
(
SELECT substring(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE substring(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off, 
SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

-- 9. Rank and retrieve the top 5 companies with the highest layoffs for each individual year
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS 
(SELECT *, 
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;