-- Data Cleaning in MySQL --

-- The layoffs table contains layoffs data for various companies from all over the world. It includes information such as industry, total and percentage of 
-- people laid off, date laid off, funds raised by the company and the stage. 

SELECT *
FROM layoffs
;

-- In this project I carry out the following:
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Deal with Null/Blank values
-- 4. Remove any unnecessary columns/rows

-- Creating staging table
-- Staging table is important because raw data contains many inconsistencies and it needs to be cleaned and transformed into the desired format
-- before being moved to the production tables. The data is separated from the main database until its ready to be incorporated. 

CREATE TABLE layoffs_staging 
LIKE layoffs
;

-- The staging table was created but it reamins empty until data is loaded into it. 

SELECT *
FROM layoffs_staging
;

INSERT layoffs_staging
SELECT *
From layoffs
;

-- Now the staging table has been populated using the data from layoffs

SELECT *
FROM layoffs_staging
;

-- CTE is used to create a temporary result set without altering the staging data. The result displays duplicate rows. 

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num>1
;

SELECT *
FROM layoffs_staging
WHERE company='Casper'
;

-- Creating a second staging table to filter duplicate rows --

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` DECIMAL(5,4),
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL, 
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
;

INSERT INTO layoffs_staging2 
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
;

SELECT *
FROM layoffs_staging2
WHERE row_num>1
;

-- Deleting the duplicate rows --

DELETE
FROM layoffs_staging2
WHERE row_num>1
;

-- Duplicates have been removed --

SELECT *
FROM layoffs_staging2
;

-- Standardizing Data --

-- TRIM removes extra spaces at the start or end --

SELECT company, TRIM(company)
FROM layoffs_staging2
;

-- Updating the staging table with the trimmed column --

UPDATE layoffs_staging2
SET company=TRIM(company)
;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
;

-- Crypto, CryptoCurrency and Crpyto Currency are the same. We need to standardize so that we it doesn't cause problems in exploratory analysis --

SELECT DISTINCT industry
FROM layoffs_staging2;
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'
;

-- All are now named Crypto --

-- USA. becomes USA --
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1
;

-- Only updates the rows where the country column starts with United States --

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'
;


SELECT *
FROM layoffs_staging2
;

-- Converts the date column which was stored as a text to date type --

SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_staging2
;

UPDATE layoffs_staging2
SET `date`=STR_TO_DATE (`date`, '%m/%d/%Y')
;

SELECT `date`
FROM layoffs_staging2
;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE
;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

UPDATE layoffs_staging2
SET industry=NULL
WHERE industry=''
;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = ''
;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'
;

-- Self-join to match rows based on the same company and location --

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company=t2.company
AND t1.location=t2.location
WHERE (t1.industry IS NULL OR t1.industry='') 
AND t2.industry IS NOT NULL
;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company=t2.company
SET t1.industry=t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL
;

-- Successfully matched 3 rows --

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

-- Deleting rows where both variables of interest are NULL --

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
;

SELECT *
FROM layoffs_staging2
;

-- Removing the row_num column we created to identify duplicates --

ALTER TABLE layoffs_staging2
DROP COLUMN row_num
;

SELECT *
FROM layoffs_staging2
;

-- The data is ready for exploratory analysis --
