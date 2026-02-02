-- Housing Data Cleaning in SSMS --

use portfolio_project;

select UniqueID, count(UniqueID) as count
from dbo.NashvilleHousing
group by UniqueID
having count(UniqueID) != 1;

select count(distinct UniqueID) as unique_count
from dbo.NashvilleHousing;
-- all 56477 rows have unique id


-- Standardizing Date Format

select SaleDate
from portfolio_project.dbo.NashvilleHousing;


--SELECT SaleDate, convert(date, SaleDate) AS SaleDate
--FROM portfolio_project.dbo.NashvilleHousing;

SELECT SaleDate, CAST(SaleDate AS DATE)
FROM portfolio_project.dbo.NashvilleHousing;


--UPDATE portfolio_project.dbo.NashvilleHousing
--SET SaleDate = CAST(SaleDate AS DATE);


--SELECT SaleDate
--FROM dbo.NashvilleHousing;

ALTER TABLE dbo.NashvilleHousing
ADD SaleDateConverted DATE;

select * from dbo.NashvilleHousing;
-- Column has been added

UPDATE dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate);


select SaleDate, SaleDateConverted
from dbo.NashvilleHousing;
-- date format has been standardized


-- Populating Property Address Data

select *
from portfolio_project.dbo.NashvilleHousing
where PropertyAddress is null;


select PropertyAddress
from portfolio_project.dbo.NashvilleHousing
where PropertyAddress is null;
-- we have 29 NULL values in PropertyAddress column


-- Same ParcelID means same address so we can use that to populate null values in PropertyAddress column wherever possible
-- SELF JOIN

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from portfolio_project.dbo.NashvilleHousing a
join portfolio_project.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null
-- ISNULL() is used to replace NULL with a specified value

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from portfolio_project.dbo.NashvilleHousing a
join portfolio_project.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;
-- all 29 null values in PropertyAddress column have now been populated. Magic of SELF JOIN


-- Breaking Address into Individual Columns

select PropertyAddress
from portfolio_project.dbo.NashvilleHousing
order by ParcelID;


SELECT SUBSTRING('1808  FOX CHASE DR, GOODLETTSVILLE', 1, 4)  
-- SUBSTRING() extracts part of a string

SELECT CHARINDEX(',', '1808  FOX CHASE DR, GOODLETTSVILLE')

SELECT SUBSTRING('1808  FOX CHASE DR, GOODLETTSVILLE', 1, CHARINDEX(',', '1808  FOX CHASE DR, GOODLETTSVILLE') - 1)
-- CHARINDEX() finds the position of a substring inside a string.

select len('1808  FOX CHASE DR, GOODLETTSVILLE')

select substring('1808  FOX CHASE DR, GOODLETTSVILLE', CHARINDEX(',', '1808  FOX CHASE DR, GOODLETTSVILLE') + 1, 
len('1808  FOX CHASE DR, GOODLETTSVILLE'));
--LEN() returns the number of characters in a string


select 
substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1) as Address
, substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as Address
from portfolio_project.dbo.NashvilleHousing;


alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

select * from NashvilleHousing;

update NashvilleHousing
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1);

alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress));


-- Updating Owner Address

select OwnerAddress
from portfolio_project.dbo.NashvilleHousing;


SELECT  PARSENAME('7532  OAKHAVEN TRCE. NASHVILLE. TN', 1)
-- PARSENAME() splits a dot-separated string and returns a specific part, counting from the right.

select 
parsename (replace(OwnerAddress,',','.'), 3)
,parsename (replace(OwnerAddress,',','.'), 2)
,parsename (replace(OwnerAddress,',','.'), 1)
from portfolio_project.dbo.NashvilleHousing;


alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

SELECT * FROM NashvilleHousing
where OwnerSplitState = 'TN';
-- we need to trim it


update NashvilleHousing
set OwnerSplitAddress = parsename (replace(OwnerAddress,',','.'), 3);

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update NashvilleHousing
set OwnerSplitCity = parsename (replace(OwnerAddress,',','.'), 2);

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update NashvilleHousing
set OwnerSplitState = parsename (replace(OwnerAddress,',','.'), 1);


-- TRIM
select OwnerSplitState, TRIM(OwnerSplitState) from NashvilleHousing;

update NashvilleHousing
SET OwnerSplitState = TRIM(OwnerSplitState);

SELECT * FROM NashvilleHousing
where OwnerSplitState = 'TN';

SELECT DISTINCT OwnerSplitCity from NashvilleHousing;

select trim('OLD HICKORY');

UPDATE NashvilleHousing
SET OwnerSplitCity = TRIM(OwnerSplitCity);

SELECT * FROM NashvilleHousing
where OwnerSplitCity = 'Old Hickory';

UPDATE NashvilleHousing
SET PropertySplitCity = TRIM(PropertySplitCity);

SELECT * FROM NashvilleHousing
where PropertySplitCity = 'Old Hickory';

select trim('100  WARREN DR');

UPDATE NashvilleHousing
SET PropertySplitAddress = TRIM(PropertySplitAddress);

SELECT * FROM NashvilleHousing
where PropertySplitAddress = '100  WARREN DR';

SELECT * FROM NashvilleHousing
where OwnerSplitAddress = '100  WARREN DR';

select * from NashvilleHousing;

-- Changing Y and N to Yes and No respectively in 'SoldAsVacant' column

select distinct(SoldAsVacant), count(SoldAsVacant)
from portfolio_project.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;


SELECT 
    CASE 
        WHEN SoldAsVacant IN ('Y', 'Yes') THEN 'Yes' 
        ELSE 'No' 
    END AS SoldAsVacant
FROM portfolio_project.dbo.NashvilleHousing;
-- CASE lets you apply conditional logic in SQL


ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(3);


UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
        WHEN SoldAsVacant IN ('Y', 'Yes') THEN 'Yes' 
        ELSE 'No' 
    END;


select distinct(SoldAsVacant), count(SoldAsVacant)
from portfolio_project.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;


-- Removing Duplicates

-- CTE
-- ROW_NUMBER() assigns a unique sequential number to each row within a result set.
WITH RowNumCTE AS (
    SELECT *, 
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM portfolio_project.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;


WITH RowNumCTE AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SalePrice,
                         SaleDate,
                         LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM portfolio_project.dbo.NashvilleHousing
)
DELETE FROM portfolio_project.dbo.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);
-- This deletes the 104 duplicates that we had


-- Deleting Unnecessary Columns

alter table NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress;


alter table NashvilleHousing
drop column SaleDate;

select *
from NashvilleHousing;

-- The data is ready for visualization
