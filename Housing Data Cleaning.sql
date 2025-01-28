/*

Cleaning Data in SQL Queries (Microsoft SSMS)

*/

select *
from PortfolioProject.dbo.NashvilleHousing;

-- Standardizing Date Format to YYYY-MM-DD

select SaleDate
from PortfolioProject.dbo.NashvilleHousing;

SELECT CAST(SaleDate AS DATE) AS SaleDateOnly
FROM PortfolioProject.dbo.NashvilleHousing;

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateOnly DATE;

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateOnly = CAST(SaleDate AS DATE);

SELECT SaleDate, SaleDateOnly
FROM PortfolioProject.dbo.NashvilleHousing;

-- Populating Property Address Data

select *
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null
order by ParcelID;

-- Same parcel IDs have the same address so we will use this to populatate fields that have a parcel id but where address in null

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null;


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;


update a
set PropertyAddress= isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.UniqueID <> b.UniqueID
where a.PropertyAddress is null;

-- nulls are now populated (there are no null values in PropertyAddress column)

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing
where PropertyAddress is null;

-- Now we break down the Address into 2 separate columns (Address and City)
-- We can break it into even more columns if the State was also included in the address

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing
order by ParcelID;


select substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1) as Address
-- - 1 to get rid of the ,
, substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as Address
from PortfolioProject.dbo.NashvilleHousing;


alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update NashvilleHousing
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1);

alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update NashvilleHousing
set PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress));


select *
from PortfolioProject.dbo.NashvilleHousing;

-- Updating Owner Address now

select OwnerAddress
from PortfolioProject.dbo.NashvilleHousing;

select 
parsename (replace(OwnerAddress,',','.'), 3)
,parsename (replace(OwnerAddress,',','.'), 2)
,parsename (replace(OwnerAddress,',','.'), 1)
from PortfolioProject.dbo.NashvilleHousing;


alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

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


select *
from NashvilleHousing;

-- Changing Y and N to Yes and No respectively in 'SoldAsVacant' column

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;

SELECT 
    CASE 
        WHEN SoldAsVacant IN ('Y', 'Yes') THEN 'Yes' 
        ELSE 'No' 
    END AS SoldAsVacant
FROM PortfolioProject.dbo.NashvilleHousing;


ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(3);


UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
        WHEN SoldAsVacant IN ('Y', 'Yes') THEN 'Yes' 
        ELSE 'No'
    END;


select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;

-- Removing Duplicates

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
    FROM PortfolioProject.dbo.NashvilleHousing
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
    FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE FROM PortfolioProject.dbo.NashvilleHousing
WHERE UniqueID IN (
    SELECT UniqueID
    FROM RowNumCTE
    WHERE row_num > 1
);

-- Duplicates are now removed



-- Now we delete any unused columns (not to be done on raw data in actual practice)


alter table PortfolioProject.dbo.NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress;


select *
from PortfolioProject.dbo.NashvilleHousing;


-- The data has now been cleaned and can be used for visualizations
