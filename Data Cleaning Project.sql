-- Data Cleaning Project in MySQL --

USE world_layoffs;

SELECT * FROM layoffs;

-- In this project I carry out the following:
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Deal with Null/Blank values
-- 4. Remove any unnecessary columns/rows

-- Creating staging table
-- Staging table is important because raw data contains many inconsistencies and it needs to be cleaned and transformed into the desired format
-- before being moved to the production tables. The data is separated from the main database until its ready to be incorporated. 

CREATE TABLE layoffs_staging LIKE layoffs;


SELECT * FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT * From layoffs;

SELECT * FROM layoffs_staging;


WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;
-- It assigns a row number to each duplicate row (based on those listed columns), restarting from 1 for each identical group.


SELECT * FROM layoffs_staging
WHERE company= 'Casper';

SELECT * FROM layoffs_staging
WHERE percentage_laid_off LIKE "_.____";


CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` INT DEFAULT NULL,
  `percentage_laid_off` DECIMAL(5, 4),
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` INT DEFAULT NULL, 
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging_2;
-- table has been created

INSERT INTO layoffs_staging_2 
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * FROM layoffs_staging_2
WHERE row_num > 1;


DELETE FROM layoffs_staging_2
WHERE company = "casper" AND row_num > 1;
SELECT * FROM layoffs_staging_2 WHERE company = "casper";


DELETE FROM layoffs_staging_2
WHERE row_num > 1;
SELECT * FROM layoffs_staging_2
WHERE row_num > 1;
-- Duplicate rows have been deleted


delete from layoffs_staging_2 where company = "casper" and total_laid_off IS NULL;
SELECT * FROM layoffs_staging_2 where company = "casper";


-- Standardizing Data


SELECT company, TRIM(company)
FROM layoffs_staging_2;


UPDATE layoffs_staging_2
SET company = TRIM(company);


SELECT * FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';


UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'crypto%';
SELECT distinct industry
FROM layoffs_staging_2
where industry LIKE "crypto%";


SELECT distinct country FROM layoffs_staging_2 where country like "United states%";
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_2
ORDER BY country asc;
-- Trailing means something that comes at the end of a value or string (the opposite of leading).

UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
SELECT distinct country FROM layoffs_staging_2 where country like "United states%";


-- Converting text to date

SELECT * FROM layoffs_staging_2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET `date`=STR_TO_DATE (`date`, '%m/%d/%Y');

SELECT `date` FROM layoffs_staging_2;

ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;


SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging_2 WHERE industry = '';
-- finds companies for which industry value is blank

UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry ='';

SELECT * FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';


SELECT * FROM layoffs_staging_2
WHERE company LIKE 'bally%';


SELECT * FROM layoffs_staging_2 WHERE company IS NULL OR location IS NULL;

-- SELF JOIN
SELECT t1.industry, t2.industry
FROM layoffs_staging_2 as t1
JOIN layoffs_staging_2 as t2
ON t1.company = t2.company
AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry ='') 
AND t2.industry IS NOT NULL;


UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;


SELECT * FROM layoffs_staging_2
WHERE industry IS NULL;


SELECT * FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


DELETE FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging_2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;


ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;

SELECT * FROM layoffs_staging_2;
-- The data has been cleaned and is now ready for EDA