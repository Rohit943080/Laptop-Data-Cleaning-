USE sql_task;

# Creating backup
CREATE TABLE laptop_clean LIKE laptop_backup;
INSERT INTO laptop_clean (SELECT * FROM laptop_backup);

# ----------------- RENAME COLUMN 'UNnamed: 0 -------------------------'
ALTER TABLE laptop_clean RENAME COLUMN `Unnamed: 0` TO Id;

# ----------------- Creating Cpu brand column -------------------------
ALTER TABLE laptop_clean 
ADD COLUMN Cpu_brand VARCHAR(25) AFTER Cpu;

# ----------------- Updating Cpu_brand -------------------------------
UPDATE laptop_clean
SET Cpu_brand = SUBSTRING_INDEX(Cpu, ' ', 1);

#------------------------ Creating Cpu Series  column ------------------
ALTER TABLE laptop_clean
ADD COLUMN Cpu_series VARCHAR(25) AFTER Cpu_brand;

#------------------------  Updating Cpu_series -----------------------
UPDATE laptop_clean
SET Cpu_series = SUBSTRING_INDEX(SUBSTRING_INDEX(Cpu, ' ', 3), ' ', -1)
WHERE Cpu LIKE '%Intel%';

UPDATE laptop_clean
SET Cpu_series = SUBSTRING_INDEX(SUBSTRING_INDEX(Cpu, ' ', 2), ' ', -1)
WHERE Cpu LIKE '%AMD%';

#----------------------  Creating processor name column --------------------
ALTER TABLE laptop_clean
ADD COLUMN Processor_name VARCHAR(25) AFTER Cpu_series;

#------------------------ Updating Processor_name -----------------------------
UPDATE laptop_clean
SET Processor_name = CASE
	WHEN cpu LIKE '%Intel%' AND SUBSTRING_INDEX(SUBSTRING_INDEX(cpu, ' ', 4),' ', -1) NOT LIKE '%Ghz%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(cpu, ' ', 4),' ', -1)
	WHEN cpu LIKE  '%AMD%'THEN SUBSTRING_INDEX(SUBSTRING_INDEX(cpu, ' ', 3),' ', -1)
    ELSE 'N/A'
END;



# ------------------------ Creating Cpu_speed column -----------------------
ALTER TABLE laptop_clean
ADD COLUMN Cpu_speed DECIMAL(2,1) AFTER Processor_name ;

# ------------------------- Updating Cpu_speed ------------------------
UPDATE laptop_clean
SET Cpu_speed = SUBSTRING_INDEX(SUBSTRING_INDEX(cpu, ' ',-1),'G',1);

# -------------------- Dropping Cpu column -------------------
ALTER TABLE laptop_clean
DROP cpu;


# ----------------------- Updating Ram column ---------------
UPDATE laptop_clean
SET Ram = Ram + 0;

# -------------------- Updating Memory column -------------
UPDATE laptop_clean
SET Memory = CASE 
WHEN Memory LIKE '%1TB%' THEN REPLACE(Memory, '1TB', '1000GB')
WHEN Memory LIKE '%2TB%' THEN REPLACE(Memory, '2TB', '2000GB')
WHEN Memory LIKE '%1.0TB%' THEN REPLACE(Memory, '1.0TB', '1000GB')
ELSE Memory
END;

#-------------------------- Creating Memory type column ------------------
ALTER TABLE  laptop_clean
ADD COLUMN Memory_type VARCHAR(10) AFTER Memory;

# --------------------- Updating Memory Type -------------------
UPDATE laptop_clean
SET Memory_type = CASE
	WHEN Memory LIKE '%SSD%'AND Memory NOT LIKE '%HDD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' AND Memory NOT LIKE '%SSD%' THEN 'HDD'
    WHEN Memory LIKE '%HDD%' AND Memory  LIKE '%SSD%' THEN 'Dual'
    WHEN Memory LIKE '%Flash%' THEN 'Flash'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
END;

# ------------------ Creating ssd_gb, hdd_gb, flash_gb Column -----------------
ALTER TABLE laptop_clean
ADD  Ssd_gb INT AFTER Memory_type,
ADD Hdd_gb INT AFTER Ssd_gb ,
ADD Flash_gb INT AFTER Hdd_gb;

# ------------------------------- Updating ssd_gb ---------------------------
UPDATE laptop_clean
SET ssd_gb = CASE
	WHEN Memory  LIKE '%SSD%'  THEN SUBSTRING_INDEX(Memory, 'GB',1)
    WHEN Memory LIKE '%SSD%' AND Memory LIKE '%Hybrid%' THEN SUBSTRING_INDEX(Memory, 'GB',1)
    ELSE 0
END;

UPDATE laptop_clean
SET ssd_gb = SUBSTRING_INDEX(Memory, 'GB',1)+ SUBSTRING_INDEX(SUBSTRING_INDEX(Memory, '+',-1), 'GB',1)
WHERE Memory NOT  LIKE '%HDD%' AND Memory LIKE '%+%'AND Memory NOT LIKE '%Hybrid%';

# ------------------------ Updating Flash_gb -----------------------
UPDATE laptop_clean
SET Flash_gb = CASE
	WHEN Memory LIKE '%flash%' THEN SUBSTRING_INDEX(Memory, 'GB',1)
    ELSE 0
END;

# ----------------------- Updating Hdd_gb ------------------
UPDATE laptop_clean
SET Hdd_gb = CASE
	WHEN Memory LIKE '%HDD%' AND memory NOT LIKE '%+%' THEN SUBSTRING_INDEX(Memory, 'GB',1)
    WHEN Memory LIKE '%HDD%' AND memory  LIKE '%+%' THEN SUBSTRING_INDEX(SUBSTRING_INDEX(Memory, '+',-1), 'GB',1)
ELSE 0
END;

# --------------------------- Dropping Memory column ------------------
ALTER TABLE laptop_clean DROP COLUMN Memory;

# -------------------------- Updating Weight column --------------------
UPDATE laptop_clean
SET Weight = SUBSTRING_INDEX(Weight,'kg',1);


# ----------------------- Creating gpu_brand, gpu_series, gpu_model, gpu_type  columns ------------------------
ALTER TABLE laptop_clean
ADD gpu_brand VARCHAR(25) AFTER GPU,
ADD gpu_series VARCHAR(25) AFTER gpu_brand,
ADD gpu_model VARCHAR(25) AFTER gpu_series,
ADD gpu_type VARCHAR(25) AFTER gpu_model
;

#-------------------------------- Updating gpu_brand --------------------
UPDATE laptop_clean
SET gpu_brand = SUBSTRING_INDEX(GPU, ' ', 1);

# ------------------------------- Updating gpu_series -------------------
UPDATE laptop_clean
SET gpu_series = CASE
	WHEN GPU LIKE '%Intel%' THEN CASE
							WHEN GPU LIKE '%Iris%' THEN 'Iris Plus'
							ELSE SUBSTRING_INDEX(SUBSTRING_INDEX(GPU, ' ', 2),' ',-1)
							END 
	WHEN GPU LIKE '%AMD%' THEN CASE
							WHEN GPU LIKE '%Pro%' THEN 'Pro'
							WHEN GPU LIKE '%Radeon R%' THEN REGEXP_SUBSTR(GPU , 'RX|R[0-9]')
							ELSE 'N/A'
							END 
	WHEN GPU LIKE '%Nvidia%' THEN REGEXP_SUBSTR(GPU, '[A-Z0-9]+X')
							ELSE 'N/A'
END;

# ------------------------------ Updating gpu_model ---------------
UPDATE laptop_clean
SET gpu_model = CASE 
	WHEN GPU LIKE '%Intel%' THEN REGEXP_SUBSTR(GPU, '([0-9]{3,4})') 
    WHEN GPU LIKE '%AMD%' THEN  REGEXP_SUBSTR(GPU, '([0-9]{3,4})')
	WHEN GPU LIKE '%Nvidia%' THEN REGEXP_SUBSTR(GPU, '([0-9]{3,4})')
    ELSE Null
    END;
    
# ---------------------- Updating gpu_type --------------
UPDATE laptop_clean
SET gpu_type = CASE
	WHEN Gpu LIKE '%Intel%' THEN 'Integrated'
    WHEN Gpu LIKE '%Nvidia%' THEN 'Dedicated'
	WHEN Gpu LIKE '%Graphics%' THEN 'Dedicated'
    WHEN Gpu LIKE '%RX%' OR Gpu LIKE '%Pro%' THEN 'Dedicated'
    WHEN Gpu  REGEXP '\\bR2\\b' THEN 'Integrated'
	WHEN Gpu REGEXP '\\bR[5-9]\\b' THEN 'Dedicated'
	WHEN Gpu REGEXP '\\b[5-9][0-9]{2}\\b' THEN 'Dedicated'
    ELSE 'Unknown'
END;
    
# ------------------------------- Dropping Gpu Column -------------------------
ALTER TABLE laptop_clean
DROP COLUMN Gpu;
    
# ---------------------------------- Creating And Updating Screen type column -------------------------
ALTER TABLE laptop_clean
ADD COLUMN Screen_type VARCHAR(25) AFTER ScreenResolution;

UPDATE laptop_clean
SET Screen_type = CASE
    WHEN width_px = 1366 AND height_px = 768 THEN 'HD'
    WHEN width_px = 1600 AND height_px = 900 THEN 'HD+'
    WHEN width_px = 1920 AND height_px = 1080 THEN 'Full HD'
    WHEN width_px IN (2560,2160) AND height_px IN (1600, 1440) THEN 'QHD / Retina'
    WHEN width_px = 3840 AND height_px = 2160 THEN '4K UHD'
    WHEN screenresolution LIKE '%Quad%' THEN 'Quad HD+'
    ELSE 'Other'
END;


# ------------------------------------ Creating and Updating width_px And height_px Column ----------------
ALTER TABLE laptop_clean
ADD width_px INT AFTER Screen_type,
ADD height_px INT AFTER width_px;

UPDATE laptop_clean
SET width_px = SUBSTRING_INDEX(REGEXP_SUBSTR(screenresolution, '[0-9]{3,4}x[0-9]{3,4}'),'x',1),
	height_px = SUBSTRING_INDEX(REGEXP_SUBSTR(screenresolution, '[0-9]{3,4}x[0-9]{3,4}'),'x',-1);

# -------------------------------- Creating and Updating has_touchscreen column -----------------
ALTER TABLE laptop_clean
ADD has_touchscreen INT AFTER height_px;

UPDATE laptop_clean
SET has_touchscreen = CASE
	WHEN Screenresolution LIKE '%Touchscreen%' THEN 1
    ELSE 0
END;

# -------------------------------- Creating and Updating has_ips_panel column -----------------
ALTER TABLE laptop_clean
ADD has_ips_panel INT AFTER height_px;

UPDATE laptop_clean
SET has_ips_panel = CASE
	WHEN Screenresolution LIKE '%IPS%' THEN 1
    ELSE 0
END;

# ------------------------------------ Dropping ScreenResolution column -----------------
ALTER TABLE laptop_clean
DROP COLUMN ScreenResolution;


# -------------------------------------------- CLEANED! --------------------------------
SELECT * FROM laptop_clean;