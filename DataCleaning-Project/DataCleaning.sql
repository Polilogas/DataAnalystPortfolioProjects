/*

Cleaning Data in SQL Queries

*/

Select *
FROM ..NashvilleHousing

---------------------------------------------------------------------------------
---------------------------- STANDARIZE DATE FORMAT -----------------------------

-- Add a new column named SaleDateConverted to the NashvilleHousing table.
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Update the SaleDateConverted column in the NashvilleHousing table with converted values.
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

-- Showing the converted dates
Select SaleDate, SaleDateConverted
FROM ..NashvilleHousing


---------------------------------------------------------------------------------
------------------------ POPULATE PROPERTY ADDRESS DATA -------------------------

-- View the PropertyAddress with the NULL values before, and after
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ..NashvilleHousing a
JOIN ..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Update the PropertyAddress to populate the NULL values
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM ..NashvilleHousing a
JOIN ..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


---------------------------------------------------------------------------------
--------- BREAKING OUT ADDRESS INTO INTIVIDUAL COLUMNS (Address, City) ----------

-- View the Desired Address  
WITH CTE_CommaIndex AS (
	SELECT PropertyAddress, CHARINDEX(',', PropertyAddress)+1 AS comma_index
	FROM ..NashvilleHousing
)
SELECT PropertyAddress,  SUBSTRING(PropertyAddress, comma_index -51, 50) AS Address,
SUBSTRING(PropertyAddress, comma_index, LEN(PropertyAddress)) AS City
FROM CTE_CommaIndex


-- Add the new columns
ALTER TABLE NashvilleHousing
ADD PropertyStreetAddress NVARCHAR(255)

ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(255)


-- Update property street address
WITH CTE_CommaIndex AS (
	SELECT PropertyAddress, CHARINDEX(',', PropertyAddress)+1 AS comma_index
	FROM ..NashvilleHousing
)
UPDATE NH
SET NH.PropertyStreetAddress = TRIM(SUBSTRING(CI.PropertyAddress, comma_index -51, 50))
FROM NashvilleHousing AS NH
INNER JOIN CTE_CommaIndex AS CI
	ON NH.PropertyAddress = CI.PropertyAddress


-- Update property city

WITH CTE_CommaIndex AS (
	SELECT PropertyAddress, CHARINDEX(',', PropertyAddress)+1 AS comma_index
	FROM ..NashvilleHousing
)
UPDATE NH
SET NH.PropertyCity = TRIM(SUBSTRING(CI.PropertyAddress, comma_index, LEN(CI.PropertyAddress)))
FROM NashvilleHousing AS NH
INNER JOIN CTE_CommaIndex AS CI
	ON NH.PropertyAddress = CI.PropertyAddress


-- View the result
SELECT PropertyAddress, PropertyStreetAddress, PropertyCity
FROM ..NashvilleHousing


---------------------------------------------------------------------------------
------------- BREAKING OUT OWNER'S ADDRESS INTO INTIVIDUAL COLUMNS --------------

-- View
SELECT OwnerAddress
FROM NashvilleHousing

-- View the Desired Address  
SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

-- Add the new columns
ALTER TABLE NashvilleHousing
ADD OwnerStreetAddress NVARCHAR(250)

ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(250)

ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(250)

-- Update OwnerStreetAddress
UPDATE NashvilleHousing
SET OwnerStreetAddress = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3))

-- Update OwnerStreetAddress
UPDATE NashvilleHousing
SET OwnerCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2))

-- Update OwnerStreetAddress
UPDATE NashvilleHousing
SET OwnerState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))

-- View the result
SELECT OwnerAddress, OwnerStreetAddress, OwnerCity, OwnerState
FROM NashvilleHousing


---------------------------------------------------------------------------------
------------ CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD -------------

-- View the desired output  
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
		END
FROM NashvilleHousing

-- Update the values
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
		END

-- View the result
SELECT SoldAsVacant
FROM NashvilleHousing 


---------------------------------------------------------------------------------
---------------------------- REMOVE THE DUPLICATES ------------------------------

WITH CTE_RowNum AS (
	SELECT *, 
	ROW_NUMBER() OVER ( PARTITION BY 
						ParcelID, 
						PropertyAddress, 
						SalePrice, 
						SaleDate, 
						LegalReference
						ORDER BY UniqueID
					) RowNum
FROM NashvilleHousing
)
DELETE
FROM CTE_RowNum
WHERE RowNum > 1


---------------------------------------------------------------------------------
----------------------------  DELETE UNUSED COLUMNS -----------------------------

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress,  SaleDate, TaxDistrict
