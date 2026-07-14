# KRD - Generating Covariates

This tutorial outlines the process of generating specific covariates for
a cohort of patients from the Komodo Research Dataset stored within the
OHDSI Lab. For the following code to function, you must be logged into
an OHDSI Lab workspace. This tutorial assumes you have already
successfully connected to the OHDSI Lab’s Amazon Redshift database
according to the instructions in the previous article “General -
Connecting to the database” and generated a cohort according the the
instructions in the previous article “KRD - Generating a Cohort”.

First, you need to identify the covariates you’re interested in. This
can be completed using two (main) methods.

Method 1: Identifying the relevant clinical codes yourself (better for
projects that only need a few covariates). In the below example, I’m
interested in diabetes and hypertension as covariates.

Create temp table that filters normalized_dx_events to patients in your
cohort where the events took place within the 365 days (lookback period
up to you) prior to each patient’s index date (requires your cohort to
have column index_date). Make sure to give yourself enough time (this
took 2.28 hours for me).

``` r
DatabaseConnector::executeSql(con, paste0("
  DROP TABLE IF EXISTS ", write_schema, ".cohort_dx_tmp;
  CREATE TABLE ", write_schema, ".cohort_dx_tmp AS
  SELECT DISTINCT n.patient_id, n.dx_code
  FROM ", komodo_schema, ".normalized_dx_events n
  INNER JOIN ", write_schema, ".t2d_cohort c ON n.patient_id = c.patient_id
    AND n.event_date >= DATEADD(day, -365, c.index_date)
    AND n.event_date <  c.index_date;
"))
```

Create table of qualifying events (in this case diabetes and
hypertension).

``` r
DatabaseConnector::executeSql(con, paste0("
  DROP TABLE IF EXISTS ", write_schema, ".covariate_hits;
  CREATE TABLE ", write_schema, ".covariate_hits AS

  SELECT DISTINCT patient_id, 'diabetes' AS covariate
  FROM ", write_schema, ".cohort_dx_tmp
  WHERE dx_code LIKE 'E10%' OR dx_code LIKE 'E11%'

  UNION ALL

  SELECT DISTINCT patient_id, 'hypertension' AS covariate
  FROM ", write_schema, ".cohort_dx_tmp
  WHERE dx_code LIKE 'I10%' OR dx_code LIKE 'I11%';

  DROP TABLE IF EXISTS ", write_schema, ".cohort_dx_tmp;
"))
```

Pivot qualifying events table into one row per patient and collect into
R

``` r
covariates <- tbl(
    con, 
    inDatabaseSchema(
        write_schema, 
        "t2d_cohort")) |>
  left_join(
    tbl(
      con, 
      inDatabaseSchema(
        write_schema, 
        "covariate_hits")),
    by = "patient_id"
  ) |>
  group_by(patient_id) |>
  summarize(
    diabetes = max(if_else(covariate == "diabetes", 1L, 0L), na.rm = TRUE),
    hypertension = max(if_else(covariate == "hypertension", 1L, 0L), na.rm = TRUE)
  )
```

Save your covariates to your personal schema so they can be accessed in
future sessions.

``` r
DatabaseConnector::executeSql(
  con,
  paste0(
    "DROP TABLE IF EXISTS ", write_schema, ".t2d_covariates;
   CREATE TABLE ", write_schema, ".t2d_covariates AS ",
    dbplyr::sql_render(covariates)
  ))
```

Load your covariates back into R for continued modeling/analysis (e.g.,
regression)

``` r
t2d_covariates <- tbl(
    con,
    inDatabaseSchema(
        write_schema,
        "t2d_covariates"
    )
)
```

================================================================================
END OF METHOD 1
================================================================================

Method 2: Using a pre-made list of covariates such as Elixhauser. In the
below example, I use the Elixhauser commorbidity categories, a standard
covariate set in claims-based research. The following code writes the
Elixhauser categories into my personal schema as a permanent table,
meaning I can access it for future analyses without rerunning this
chunk.

``` r
DatabaseConnector::executeSql(con, paste0("
  DROP TABLE IF EXISTS ", write_schema, ".elixhauser_mapping;
  CREATE TABLE ", write_schema, ".elixhauser_mapping (
    comorbidity    VARCHAR(60),   -- category name (becomes column name in pivot)
    icd_prefix     VARCHAR(10)    -- ICD-10-CM prefix; match with LIKE 'prefix%'
  );

  INSERT INTO ", write_schema, ".elixhauser_mapping VALUES

  -- Congestive heart failure
  ('chf', 'I099'), ('chf', 'I110'), ('chf', 'I130'), ('chf', 'I132'),
  ('chf', 'I255'), ('chf', 'I420'), ('chf', 'I425'), ('chf', 'I426'),
  ('chf', 'I427'), ('chf', 'I428'), ('chf', 'I429'), ('chf', 'I43'),
  ('chf', 'I50'),   ('chf', 'P290'),

  -- Cardiac arrhythmias
  ('arrhythmia', 'I441'), ('arrhythmia', 'I442'), ('arrhythmia', 'I443'),
  ('arrhythmia', 'I456'), ('arrhythmia', 'I459'), ('arrhythmia', 'I47'),
  ('arrhythmia', 'I48'),   ('arrhythmia', 'I49'),   ('arrhythmia', 'R000'),
  ('arrhythmia', 'R001'), ('arrhythmia', 'R008'), ('arrhythmia', 'T821'),
  ('arrhythmia', 'Z450'), ('arrhythmia', 'Z950'),

  -- Valvular disease
  ('valvular', 'A520'), ('valvular', 'I05'),  ('valvular', 'I06'),
  ('valvular', 'I07'),   ('valvular', 'I08'),  ('valvular', 'I091'),
  ('valvular', 'I098'), ('valvular', 'I34'),  ('valvular', 'I35'),
  ('valvular', 'I36'),   ('valvular', 'I37'),  ('valvular', 'I38'),
  ('valvular', 'I39'),   ('valvular', 'Q230'),('valvular', 'Q231'),
  ('valvular', 'Q232'), ('valvular', 'Q233'),('valvular', 'Z952'),
  ('valvular', 'Z953'), ('valvular', 'Z954'),

  -- Pulmonary circulation disorders
  ('pulm_circ', 'I26'),  ('pulm_circ', 'I27'),  ('pulm_circ', 'I280'),
  ('pulm_circ', 'I288'),('pulm_circ', 'I289'),

  -- Peripheral vascular disorders
  ('pvd', 'I70'),  ('pvd', 'I71'),  ('pvd', 'I731'), ('pvd', 'I738'),
  ('pvd', 'I739'),('pvd', 'I771'),('pvd', 'I790'), ('pvd', 'I792'),
  ('pvd', 'K551'),('pvd', 'K558'),('pvd', 'K559'), ('pvd', 'Z958'),
  ('pvd', 'Z959'),

  -- Hypertension, uncomplicated
  ('htn_uncx', 'I10'),

  -- Hypertension, complicated
  ('htn_cx', 'I11'),  ('htn_cx', 'I12'),  ('htn_cx', 'I13'),
  ('htn_cx', 'I15'),

  -- Paralysis
  ('paralysis', 'G041'), ('paralysis', 'G114'), ('paralysis', 'G801'),
  ('paralysis', 'G802'), ('paralysis', 'G81'),   ('paralysis', 'G82'),
  ('paralysis', 'G830'), ('paralysis', 'G831'), ('paralysis', 'G832'),
  ('paralysis', 'G833'), ('paralysis', 'G834'), ('paralysis', 'G839'),

  -- Other neurological disorders
  ('neuro_other', 'G10'),  ('neuro_other', 'G11'),  ('neuro_other', 'G12'),
  ('neuro_other', 'G13'),  ('neuro_other', 'G20'),  ('neuro_other', 'G21'),
  ('neuro_other', 'G22'),  ('neuro_other', 'G254'),('neuro_other', 'G255'),
  ('neuro_other', 'G312'),('neuro_other', 'G318'),('neuro_other', 'G319'),
  ('neuro_other', 'G32'),  ('neuro_other', 'G35'),  ('neuro_other', 'G36'),
  ('neuro_other', 'G37'),  ('neuro_other', 'G40'),  ('neuro_other', 'G41'),
  ('neuro_other', 'G931'),('neuro_other', 'G934'),('neuro_other', 'R470'),
  ('neuro_other', 'R56'),

  -- Chronic pulmonary disease
  ('copd', 'I278'), ('copd', 'I279'), ('copd', 'J40'),  ('copd', 'J41'),
  ('copd', 'J42'),   ('copd', 'J43'),   ('copd', 'J44'),  ('copd', 'J45'),
  ('copd', 'J46'),   ('copd', 'J47'),   ('copd', 'J60'),  ('copd', 'J61'),
  ('copd', 'J62'),   ('copd', 'J63'),   ('copd', 'J64'),  ('copd', 'J65'),
  ('copd', 'J66'),   ('copd', 'J67'),   ('copd', 'J684'),('copd', 'J701'),
  ('copd', 'J703'),

  -- Diabetes, uncomplicated
  ('dm_uncx', 'E100'), ('dm_uncx', 'E101'), ('dm_uncx', 'E106'),
  ('dm_uncx', 'E108'), ('dm_uncx', 'E109'), ('dm_uncx', 'E110'),
  ('dm_uncx', 'E111'), ('dm_uncx', 'E116'), ('dm_uncx', 'E118'),
  ('dm_uncx', 'E119'), ('dm_uncx', 'E12'),   ('dm_uncx', 'E13'),
  ('dm_uncx', 'E14'),

  -- Diabetes, complicated
  ('dm_cx', 'E102'), ('dm_cx', 'E103'), ('dm_cx', 'E104'),
  ('dm_cx', 'E105'), ('dm_cx', 'E107'), ('dm_cx', 'E112'),
  ('dm_cx', 'E113'), ('dm_cx', 'E114'), ('dm_cx', 'E115'),
  ('dm_cx', 'E117'),

  -- Hypothyroidism
  ('hypothyroid', 'E00'),  ('hypothyroid', 'E01'),  ('hypothyroid', 'E02'),
  ('hypothyroid', 'E03'),  ('hypothyroid', 'E890'),

  -- Renal failure
  ('renal', 'I120'), ('renal', 'I131'), ('renal', 'N18'),
  ('renal', 'N19'),   ('renal', 'N250'), ('renal', 'Z490'),
  ('renal', 'Z491'), ('renal', 'Z492'), ('renal', 'Z940'),
  ('renal', 'Z992'),

  -- Liver disease
  ('liver', 'B18'),   ('liver', 'I85'),   ('liver', 'I864'),
  ('liver', 'I982'), ('liver', 'K70'),   ('liver', 'K711'),
  ('liver', 'K713'), ('liver', 'K714'), ('liver', 'K715'),
  ('liver', 'K717'), ('liver', 'K72'),   ('liver', 'K73'),
  ('liver', 'K74'),   ('liver', 'K760'), ('liver', 'K762'),
  ('liver', 'K763'), ('liver', 'K764'), ('liver', 'K765'),
  ('liver', 'K766'), ('liver', 'K767'), ('liver', 'K768'),
  ('liver', 'K769'), ('liver', 'Z944'),

  -- Peptic ulcer disease (excluding bleeding)
  ('pud', 'K253'), ('pud', 'K257'), ('pud', 'K263'), ('pud', 'K267'),
  ('pud', 'K273'), ('pud', 'K277'), ('pud', 'K283'), ('pud', 'K287'),

  -- AIDS/HIV
  ('hiv', 'B20'), ('hiv', 'B21'), ('hiv', 'B22'), ('hiv', 'B24'),

  -- Lymphoma
  ('lymphoma', 'C81'), ('lymphoma', 'C82'), ('lymphoma', 'C83'),
  ('lymphoma', 'C84'), ('lymphoma', 'C85'), ('lymphoma', 'C88'),
  ('lymphoma', 'C96'), ('lymphoma', 'Z855'),

  -- Metastatic cancer
  ('mets', 'C77'), ('mets', 'C78'), ('mets', 'C79'), ('mets', 'C80'),

  -- Solid tumor without metastasis
  ('solid_tumor', 'C00'), ('solid_tumor', 'C01'), ('solid_tumor', 'C02'),
  ('solid_tumor', 'C03'), ('solid_tumor', 'C04'), ('solid_tumor', 'C05'),
  ('solid_tumor', 'C06'), ('solid_tumor', 'C07'), ('solid_tumor', 'C08'),
  ('solid_tumor', 'C09'), ('solid_tumor', 'C10'), ('solid_tumor', 'C11'),
  ('solid_tumor', 'C12'), ('solid_tumor', 'C13'), ('solid_tumor', 'C14'),
  ('solid_tumor', 'C15'), ('solid_tumor', 'C16'), ('solid_tumor', 'C17'),
  ('solid_tumor', 'C18'), ('solid_tumor', 'C19'), ('solid_tumor', 'C20'),
  ('solid_tumor', 'C21'), ('solid_tumor', 'C22'), ('solid_tumor', 'C23'),
  ('solid_tumor', 'C24'), ('solid_tumor', 'C25'), ('solid_tumor', 'C26'),
  ('solid_tumor', 'C30'), ('solid_tumor', 'C31'), ('solid_tumor', 'C32'),
  ('solid_tumor', 'C33'), ('solid_tumor', 'C34'), ('solid_tumor', 'C37'),
  ('solid_tumor', 'C38'), ('solid_tumor', 'C39'), ('solid_tumor', 'C40'),
  ('solid_tumor', 'C41'), ('solid_tumor', 'C43'), ('solid_tumor', 'C45'),
  ('solid_tumor', 'C46'), ('solid_tumor', 'C47'), ('solid_tumor', 'C48'),
  ('solid_tumor', 'C49'), ('solid_tumor', 'C50'), ('solid_tumor', 'C51'),
  ('solid_tumor', 'C52'), ('solid_tumor', 'C53'), ('solid_tumor', 'C54'),
  ('solid_tumor', 'C55'), ('solid_tumor', 'C56'), ('solid_tumor', 'C57'),
  ('solid_tumor', 'C58'), ('solid_tumor', 'C60'), ('solid_tumor', 'C61'),
  ('solid_tumor', 'C62'), ('solid_tumor', 'C63'), ('solid_tumor', 'C64'),
  ('solid_tumor', 'C65'), ('solid_tumor', 'C66'), ('solid_tumor', 'C67'),
  ('solid_tumor', 'C68'), ('solid_tumor', 'C69'), ('solid_tumor', 'C70'),
  ('solid_tumor', 'C71'), ('solid_tumor', 'C72'), ('solid_tumor', 'C73'),
  ('solid_tumor', 'C74'), ('solid_tumor', 'C75'), ('solid_tumor', 'C76'),
  ('solid_tumor', 'C97'),

  -- Rheumatoid arthritis / collagen vascular disease
  ('rheumatoid', 'L940'), ('rheumatoid', 'L941'), ('rheumatoid', 'L943'),
  ('rheumatoid', 'M05'),   ('rheumatoid', 'M06'),   ('rheumatoid', 'M08'),
  ('rheumatoid', 'M120'), ('rheumatoid', 'M123'), ('rheumatoid', 'M30'),
  ('rheumatoid', 'M310'), ('rheumatoid', 'M311'), ('rheumatoid', 'M312'),
  ('rheumatoid', 'M313'), ('rheumatoid', 'M32'),   ('rheumatoid', 'M33'),
  ('rheumatoid', 'M34'),   ('rheumatoid', 'M351'), ('rheumatoid', 'M353'),
  ('rheumatoid', 'M360'),

  -- Coagulopathy
  ('coagulopathy', 'D65'),  ('coagulopathy', 'D66'),  ('coagulopathy', 'D67'),
  ('coagulopathy', 'D68'),  ('coagulopathy', 'D691'),('coagulopathy', 'D693'),
  ('coagulopathy', 'D694'),('coagulopathy', 'D695'),('coagulopathy', 'D696'),

  -- Obesity
  ('obesity', 'E66'),

  -- Weight loss / malnutrition
  ('weight_loss', 'E40'), ('weight_loss', 'E41'), ('weight_loss', 'E42'),
  ('weight_loss', 'E43'), ('weight_loss', 'E44'), ('weight_loss', 'E45'),
  ('weight_loss', 'E46'), ('weight_loss', 'R634'),('weight_loss', 'R64'),

  -- Fluid and electrolyte disorders
  ('fluid_elec', 'E222'), ('fluid_elec', 'E86'),  ('fluid_elec', 'E87'),

  -- Blood loss anemia
  ('anemia_blood_loss', 'D500'),

  -- Deficiency anemia
  ('anemia_deficiency', 'D508'), ('anemia_deficiency', 'D509'),
  ('anemia_deficiency', 'D51'),   ('anemia_deficiency', 'D52'),
  ('anemia_deficiency', 'D53'),

  -- Alcohol abuse
  ('alcohol', 'F10'),   ('alcohol', 'E52'),   ('alcohol', 'G621'),
  ('alcohol', 'I426'), ('alcohol', 'K292'), ('alcohol', 'K700'),
  ('alcohol', 'K703'), ('alcohol', 'K709'), ('alcohol', 'T51'),
  ('alcohol', 'Z502'), ('alcohol', 'Z714'), ('alcohol', 'Z721'),

  -- Drug abuse
  ('drug_abuse', 'F11'), ('drug_abuse', 'F12'), ('drug_abuse', 'F13'),
  ('drug_abuse', 'F14'), ('drug_abuse', 'F15'), ('drug_abuse', 'F16'),
  ('drug_abuse', 'F18'), ('drug_abuse', 'F19'), ('drug_abuse', 'Z715'),
  ('drug_abuse', 'Z722'),

  -- Psychoses
  ('psychoses', 'F20'), ('psychoses', 'F22'), ('psychoses', 'F23'),
  ('psychoses', 'F24'), ('psychoses', 'F25'), ('psychoses', 'F28'),
  ('psychoses', 'F29'), ('psychoses', 'F302'),('psychoses', 'F312'),
  ('psychoses', 'F315'),

  -- Depression
  ('depression', 'F204'), ('depression', 'F313'), ('depression', 'F314'),
  ('depression', 'F315'), ('depression', 'F32'),   ('depression', 'F33'),
  ('depression', 'F341'), ('depression', 'F412'), ('depression', 'F432');
"))
```

Create temp table that filters normalized_dx_events to patients in your
cohort where the events took place within the 365 days prior to each
patient’s index date.

``` r
DatabaseConnector::executeSql(con, paste0("
  DROP TABLE IF EXISTS ", write_schema, ".cohort_dx_tmp;
  CREATE TABLE ", write_schema, ".cohort_dx_tmp AS
  SELECT DISTINCT n.patient_id, n.dx_code
  FROM ", komodo_schema, ".normalized_dx_events n
  INNER JOIN ", write_schema, ".my_cohort c ON n.patient_id = c.patient_id
    AND n.event_date >= DATEADD(day, -365, c.index_date)
    AND n.event_date <  c.index_date;
"))
```

Create table of qualifying events (in this case covariates from the
Elixhauser table).

``` r
DatabaseConnector::executeSql(con, paste0("
  DROP TABLE IF EXISTS ", write_schema, ".covariate_hits;
CREATE TABLE ", write_schema, ".covariate_hits AS
SELECT DISTINCT d.patient_id, e.comorbidity
FROM ", write_schema, ".cohort_dx_tmp d
JOIN ", write_schema, ".elixhauser_mapping e ON d.dx_code LIKE e.icd_prefix || '%';

DROP TABLE IF EXISTS ", write_schema, ".cohort_dx_tmp;
"))
```

Pivot qualifying events table into one row per patient and collect into
R

``` r
covariates <- tbl(
  con, 
  inDatabaseSchema(
    write_schema, 
    "my_cohort")) |>
  left_join(
    tbl(
      con, 
      inDatabaseSchema(
        write_schema, 
        "covariate_hits")),
    by = "patient_id"
  ) |>
  group_by(patient_id) |>
  summarise(
    chf               = max(if_else(comorbidity == "chf",               1L, 0L), na.rm = TRUE),
    arrhythmia        = max(if_else(comorbidity == "arrhythmia",        1L, 0L), na.rm = TRUE),
    valvular          = max(if_else(comorbidity == "valvular",          1L, 0L), na.rm = TRUE),
    pulm_circ         = max(if_else(comorbidity == "pulm_circ",         1L, 0L), na.rm = TRUE),
    pvd               = max(if_else(comorbidity == "pvd",               1L, 0L), na.rm = TRUE),
    htn_uncx          = max(if_else(comorbidity == "htn_uncx",          1L, 0L), na.rm = TRUE),
    htn_cx            = max(if_else(comorbidity == "htn_cx",            1L, 0L), na.rm = TRUE),
    paralysis         = max(if_else(comorbidity == "paralysis",         1L, 0L), na.rm = TRUE),
    neuro_other       = max(if_else(comorbidity == "neuro_other",       1L, 0L), na.rm = TRUE),
    copd              = max(if_else(comorbidity == "copd",              1L, 0L), na.rm = TRUE),
    dm_uncx           = max(if_else(comorbidity == "dm_uncx",           1L, 0L), na.rm = TRUE),
    dm_cx             = max(if_else(comorbidity == "dm_cx",             1L, 0L), na.rm = TRUE),
    hypothyroid       = max(if_else(comorbidity == "hypothyroid",       1L, 0L), na.rm = TRUE),
    renal             = max(if_else(comorbidity == "renal",             1L, 0L), na.rm = TRUE),
    liver             = max(if_else(comorbidity == "liver",             1L, 0L), na.rm = TRUE),
    pud               = max(if_else(comorbidity == "pud",               1L, 0L), na.rm = TRUE),
    hiv               = max(if_else(comorbidity == "hiv",               1L, 0L), na.rm = TRUE),
    lymphoma          = max(if_else(comorbidity == "lymphoma",          1L, 0L), na.rm = TRUE),
    mets              = max(if_else(comorbidity == "mets",              1L, 0L), na.rm = TRUE),
    solid_tumor       = max(if_else(comorbidity == "solid_tumor",       1L, 0L), na.rm = TRUE),
    rheumatoid        = max(if_else(comorbidity == "rheumatoid",        1L, 0L), na.rm = TRUE),
    coagulopathy      = max(if_else(comorbidity == "coagulopathy",      1L, 0L), na.rm = TRUE),
    obesity           = max(if_else(comorbidity == "obesity",           1L, 0L), na.rm = TRUE),
    weight_loss       = max(if_else(comorbidity == "weight_loss",       1L, 0L), na.rm = TRUE),
    fluid_elec        = max(if_else(comorbidity == "fluid_elec",        1L, 0L), na.rm = TRUE),
    anemia_blood_loss = max(if_else(comorbidity == "anemia_blood_loss", 1L, 0L), na.rm = TRUE),
    anemia_deficiency = max(if_else(comorbidity == "anemia_deficiency", 1L, 0L), na.rm = TRUE),
    alcohol           = max(if_else(comorbidity == "alcohol",           1L, 0L), na.rm = TRUE),
    drug_abuse        = max(if_else(comorbidity == "drug_abuse",        1L, 0L), na.rm = TRUE),
    psychoses         = max(if_else(comorbidity == "psychoses",         1L, 0L), na.rm = TRUE),
    depression        = max(if_else(comorbidity == "depression",        1L, 0L), na.rm = TRUE),
    elixhauser_score  = n_distinct(comorbidity[!is.na(comorbidity)])
  )
```

Save your covariates to your personal schema so they can be accessed in
future sessions.

``` r
DatabaseConnector::executeSql(
  con,
  paste0(
    "DROP TABLE IF EXISTS ", write_schema, ".t2d_covariates;
   CREATE TABLE ", write_schema, ".t2d_covariates AS ",
    dbplyr::sql_render(covariates)
  ))
```

Load your covariates back into R for continued modeling/analysis (e.g.,
regression)

``` r
t2d_covariates <- tbl(
    con,
    inDatabaseSchema(
        write_schema,
        "t2d_covariates"
    )
)
```

And that’s it! You can now use your covariates in regression/other
modeling analyses.
