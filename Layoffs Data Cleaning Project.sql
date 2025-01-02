-- DATA CLEANING PROJECT

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns

-- Create table to clean based on raw data table
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;


-- 1. REMOVING DUPLICATES

-- Partitioning rows
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Create CTE to locate duplicates
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- Checking example for duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Creating table with extra row "row_num" for deleteing duplicates
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Inserting data into delete table
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage,
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Deleting duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;


-- 2. STANDARDIZING DATA

-- Company column
SELECT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Industry Column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Identifying "crypto" companies 
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Updating crypto to standard
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Checking that "Crypto" was standardized
SELECT DISTINCT industry
FROM layoffs_staging2;

-- Country Column
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Updating "United States."
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Changing "date' column from text to date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update date column
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 3. REMOVING NULL AND BLANK VALUES

-- Identifying nulls and blanks
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Updating blanks to nulls
UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

-- Checking "Airbnb"
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Joining onself to identify correct data
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Translating above to update statement
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Can't update "total_laid_off", "percentage_laid_off", or "funds_raised_millions" due to insufficient information


-- 4. REMOVING COLUMNS 

-- Deleting these rows because data is inconclusive/untrusted and not needed for next project
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Removing previously added column "row_num"
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


-- FINAL CHECK ON DATASET
SELECT *
FROM layoffs_staging2;