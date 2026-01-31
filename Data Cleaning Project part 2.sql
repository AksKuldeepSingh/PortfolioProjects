-- Exploratory Data Analysis in MySQL --


SELECT * FROM layoffs_staging_2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;


SELECT * FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;
-- list of companies that went out of business ordered by the funding that they received

SELECT company, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company
ORDER BY `SUM(total_laid_off)` DESC;


SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging_2;
-- the period for which the data exists


SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY 2 DESC;

SELECT country, COUNT(country)
FROM layoffs_staging_2
GROUP BY country;
SELECT * FROM layoffs_staging_2 WHERE country = "ireland";

SELECT country, COUNT(country), COUNT(country)/ (SELECT COUNT(country)
from layoffs_staging_2) as share_of_total
FROM layoffs_staging_2
GROUP BY country
order by 3 desc;
-- US has by far the most comapnies in this dataset

SELECT COUNT(country)
from layoffs_staging_2;


SELECT * FROM layoffs_staging_2;

SELECT YEAR(`date`), SUM(total_laid_off) as laid_off
FROM layoffs_staging_2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;


SELECT stage, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY stage
ORDER BY 2 DESC;
-- Post-IPO means the period after a company has gone public and its shares are already trading on the stock market.


SELECT company, MAX(percentage_laid_off)
FROM layoffs_staging_2
GROUP BY company
ORDER BY 1 asc;
-- The point is to see the worst single layoff event each company ever had — it answers “what was the maximum damage at any one time?”


SELECT * FROM layoffs_staging_2
WHERE company = "amazon";


-- Rolling Total
SELECT * FROM layoffs_staging_2;
SELECT substring(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging_2
WHERE substring(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH` WITH ROLLUP
ORDER BY 1 ASC;
-- jan 2023 was a big month for layoffs
-- ROLLUP gives column total


WITH Rolling_Total AS
(
SELECT substring(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
WHERE substring(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_laid_off, 
SUM(total_laid_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;


SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
ORDER BY company asc, YEAR(`date`);
-- It calculates the total number of employees laid off by each company for each year and shows the results sorted by company and year.


WITH company_year (company, `year`, total_laid_off)  AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(SELECT *,
DENSE_RANK() OVER (PARTITION BY `year` ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE `year` IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE Ranking <= 5;
-- Identifies top 5 companies by total no. of people laid off in a year for each year