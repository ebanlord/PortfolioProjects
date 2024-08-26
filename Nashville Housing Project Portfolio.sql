select * from project_nashville.propertydata;

# --------------------fill missing property address--------------------
select * from project_nashville.propertydata
where PropertyAddress = ''
order by ParcelID;

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
	COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress) AS EffectiveAddress
from project_nashville.propertydata as a
join project_nashville.propertydata as b
	on a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID 
where a.PropertyAddress = '' OR a.PropertyAddress IS NULL;

# update the missing
UPDATE project_nashville.propertydata AS a
JOIN project_nashville.propertydata AS b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = COALESCE(NULLIF(a.PropertyAddress, ''), b.PropertyAddress)
WHERE a.PropertyAddress = '' OR a.PropertyAddress IS NULL;

# --------------------split address into columns (address, city, state)--------------------
select propertyaddress from project_nashville.propertydata;

select 				
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Street,
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) as City
from project_nashville.propertydata;

# create 2 new columns to save the split above
ALTER TABLE propertydata
	ADD Street VARCHAR(255);
UPDATE propertydata
	SET Street = SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);
ALTER TABLE propertydata
	ADD City VARCHAR(255);
UPDATE propertydata
	SET City = SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress));

# ----- owner address
select owneraddress from project_nashville.propertydata;

SELECT			
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1) AS Street_owner,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS City_owner,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1) AS State_owner
from project_nashville.propertydata;

ALTER TABLE propertydata
	ADD Street_owner VARCHAR(255);
UPDATE propertydata
	SET Street_owner = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 1), ',', -1);
ALTER TABLE propertydata
	ADD City_owner VARCHAR(255);
UPDATE propertydata
	SET City_owner = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1);
ALTER TABLE propertydata
	ADD State_owner VARCHAR(255);
UPDATE propertydata
	SET State_owner = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 3), ',', -1);
    
SELECT * FROM project_nashville.propertydata;

# --------------------Sold as Vacant (Yes, No, Y, N)--------------------
# change to Yes and No only
select distinct SoldAsVacant, count(SoldAsVacant) as Count
from project_nashville.propertydata
group by SoldAsVacant
order by 2;

select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END as SoldAsVacantCleaned
FROM project_nashville.propertydata;

# checking the replacement using CTE
WITH SoldAsVacantCleaned2 (SoldAsVacant, SoldAsVacantCleaned) as (
select SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END as SoldAsVacantCleaned
FROM project_nashville.propertydata )
select distinct SoldAsVacantCleaned FROM SoldAsVacantCleaned2;

# updating the column
UPDATE propertydata
set SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END;

# --------------------Split Owner Names--------------------
ALTER TABLE propertydata
ADD OwnerName1 VARCHAR(255),
ADD OwnerName2 VARCHAR(255);

UPDATE propertydata
SET OwnerName1 = TRIM(
        CASE WHEN INSTR(OwnerName, ' & ') > 0 THEN
                SUBSTRING_INDEX(OwnerName, ' & ', 1)
             ELSE OwnerName END ),
    OwnerName2 = TRIM(
        CASE WHEN INSTR(OwnerName, ' & ') > 0 THEN
                CONCAT(SUBSTRING_INDEX(OwnerName, ',', 1),
                    ', ',TRIM(SUBSTRING_INDEX(OwnerName, ' & ', -1)))
             ELSE '' END);

SELECT * FROM propertydata;

# --------------------REMOVE DUPLICATES--------------------
WITH RowNumCTE as (
SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
					ORDER BY UniqueID) row_num 
FROM project_nashville.propertydata )
SELECT * FROM RowNumCTE
WHERE row_num > 1;

# delete the row numbers with 2+ (they are duplicates)
DELETE FROM project_nashville.propertydata
WHERE UniqueID IN (
    SELECT UniqueID
    FROM (
        SELECT UniqueID,
               ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueID) AS row_num
        FROM project_nashville.propertydata
    ) AS subquery
    WHERE row_num > 1
);

# --------------------DELETE UNUSED COLUMNS--------------------
SELECT * FROM project_nashville.propertydata;

ALTER TABLE project_nashville.propertydata
DROP COLUMN PropertyAddress;
ALTER TABLE project_nashville.propertydata
DROP COLUMN OwnerAddress;
ALTER TABLE project_nashville.propertydata
DROP COLUMN OwnerName;

# --------------------MOVE COLUMNS TO FOLLOW ORIGINAL--------------------
CREATE TABLE propertydata_new (
    UniqueID INT,
    ParcelID VARCHAR(255),
    LandUse VARCHAR(50),
    Street VARCHAR(255),
    City VARCHAR(255),
    SaleDate DATE,
    SalePrice INT,
    LegalReference VARCHAR(50),
    SoldAsVacant VARCHAR(10),
    OwnerName1 VARCHAR(100),
    OwnerName2 VARCHAR(100),
    Street_owner VARCHAR(255),
    City_owner VARCHAR(255),
    State_owner VARCHAR(255),
    Acreage FLOAT,
    TaxDistrict VARCHAR(50),
    LandValue BIGINT,
    BuildingValue BIGINT,
    TotalValue BIGINT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

INSERT INTO propertydata_new (
    UniqueID, ParcelID, LandUse, Street, City, SaleDate, SalePrice, LegalReference, SoldAsVacant,
    OwnerName1, OwnerName2, Street_owner, City_owner, State_owner,
    Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath
)
SELECT
    UniqueID, ParcelID, LandUse, Street, City, SaleDate, SalePrice, LegalReference, SoldAsVacant,
    OwnerName1, OwnerName2, Street_owner, City_owner, State_owner,
    Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath
FROM propertydata;

select* from propertydata_new;