# i2b2 totalnum pre-calculation

## What is it ?

- calculates number of patient for each ontologie level
- uses the "castle of cards" algorithm presented at i2b2 aug meeting 2015 boston
- facts, patient, visit & provider dimension
- takes 10 minutes, on 1GHZ6 & 4GB Ram
  - with observation_fact = 50M
  - with visit_dim = 5M
  - with patient_dim = 1M5
  - with i2b2 (onthologie table) = 400K


## What's needed ?

- R 3.1
- data.table package 1.9.4

## Principle

-  extract csv from i2b2 database with SQL (queries described in R files as comment)
-  run Rscript path2Csv1 path2Csv2 path2Csv3 with the console
-  it produces 2 columns files : c_fullname & totalnum  (the result)
