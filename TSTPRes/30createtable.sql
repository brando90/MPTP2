-- sample SQL table creation for Bliksem___1_12
-- CREATE TABLE `Bliksem___1_12` (
-- `problem` VARCHAR( 255 ) NOT NULL ,
-- `result` CHAR( 3 ) NOT NULL ,
-- `output_status` CHAR( 3 ) NOT NULL ,
-- `time` FLOAT NOT NULL DEFAULT 700,
-- PRIMARY KEY ( `problem` ) ,
-- INDEX ( `result`) , 
-- INDEX (`output_status`) ,
-- INDEX (`time` )
-- ) TYPE = MYISAM ;

-- create the load files 
-- (assumes geoff's results are in the directory geoff_res):
-- for i in `cat 00Systems`; do ./20mksqlloadfile.sh $i; done

-- create load file for all: 
-- for i in `cat 00Systems | sed -e 's/[-.]/_/g'`; do sed -e "s/^\([^\\t]\+\)\\t/\\1\\t$i\\t/" loadsql/"$i"_r1; done > loadsql/all_r1


-- SQL table of all provers
CREATE TABLE `all` (
`problem` VARCHAR( 255 ) NOT NULL ,
`prover` VARCHAR( 255 ) NOT NULL ,
`result` CHAR( 3 ) NOT NULL ,
`output_status` CHAR( 3 ) NOT NULL ,
`time` FLOAT NOT NULL DEFAULT 700,
INDEX ( `problem` ) ,
INDEX ( `prover` ) ,
INDEX ( `result`) , 
INDEX (`output_status`) ,
INDEX (`time` )
) TYPE = MYISAM ;


-- load the all table
LOAD DATA LOCAL INFILE 'all_r1' INTO TABLE `all` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';

-- table tptp of problem divisions, categories, and whether used at CASC21
-- the casc21 field is actually boolean - 1 for casc21 problems, 0 for the rest
-- the category is NULL for:
--  FOF_UNS_EPR_EQU FOF_UNS_EPR_NEQ FOF_UNS_RFO_EQU FOF_UNS_RFO_NEQ
CREATE TABLE `tptp` (
`problem` VARCHAR( 255 ) NOT NULL ,
`division` CHAR( 3 ) NOT NULL ,
`category` CHAR( 3 ) NULL ,
`casc21` tinyint NOT NULL DEFAULT 0,
INDEX ( `problem` ) ,
INDEX ( `division` ) ,
INDEX ( `category`) , 
INDEX (`casc21`) 
) TYPE = MYISAM ;

-- create category and division data from Geoff's SPC files
-- ./40mktptploadfile.sh

-- load the tptp table
LOAD DATA LOCAL INFILE 'tptp_r1' INTO TABLE `tptp` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';



-- sample loading of the table form a file
-- LOAD DATA LOCAL INFILE 'Bliksem___1_12_r1' INTO TABLE `Bliksem___1_12` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';

-- the rest of tables (generate this from the 00Systems file):
-- cat 00Systems | sed -e 's/[-.]/_/g'| sed -e 's/\(.*\)/CREATE TABLE `\1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT\ 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;/'

CREATE TABLE `Bliksem___1_12` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `CARINE___0_734` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `CiME___2_01` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Darwin___1_3` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Darwin___1_4_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `DarwinFM___1_3g` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `DarwinFM___1_4_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `DCTP___10_21p` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `DCTP___1_31` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `DCTP___1_31_EPR` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E___0_91` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E___0_99` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E___0_999` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E_KRHyper___1_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `EP___0_999` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `EQP___0_9d` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Equinox___1_0b` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Equinox___1_2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E_SETHEO___csp04` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `E_SETHEO___csp04_SAT` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Fampire___1_3` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Faust___1_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `FDP___0_9_16` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Fiesta___2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Gandalf___c_2_6` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Geo___2006j` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Geo___2007f` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `GrAnDe___1_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `iProver___0_2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `leanCoP___2_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `LeanTAP___2_3` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Mace2___2_2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Mace4___0307` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Mace4___0607` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Matita___0_1_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Metis___2_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Otter___3_3` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Paradox___2_0b` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Paradox___2_2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Prover9___0307` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Prover9___0607` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SCOTT___6_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SETHEO___3_3` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SNARK___20061020` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SOS___1_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SOS___2_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SPASS___2_2` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SPASS___3_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `SRASS___0_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `S_SETHEO___0_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Theo___2006` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Vampire___8_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Vampire___9_0` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Waldmeister___806` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `zChaff___2004_11_15` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;
CREATE TABLE `Zenon___0_4_1` (`problem` VARCHAR( 255 ) NOT NULL , `result` CHAR( 3 ) NOT NULL , `output_status` CHAR( 3 ) NOT NULL , `time` FLOAT NOT NULL DEFAULT 700, PRIMARY KEY ( `problem` ) , INDEX ( `result`) , INDEX (`output_status`) , INDEX (`time` )) TYPE = MYISAM ;





-- the rest of loading (generate this from the 00Systems file):
-- cat 00Systems | sed -e 's/[-.]/_/g'| sed -e "s/\(.*\)/LOAD DATA LOCAL INFILE \'\1_r1\' INTO TABLE \`\1\` FIELDS TERMINATED BY \'\\\t\' ENCLOSED BY \'\"\' ESCAPED BY \'\\\\\\\' LINES TERMINATED BY \'\\\n\';/"

LOAD DATA LOCAL INFILE 'Bliksem___1_12_r1' INTO TABLE `Bliksem___1_12` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'CARINE___0_734_r1' INTO TABLE `CARINE___0_734` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'CiME___2_01_r1' INTO TABLE `CiME___2_01` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Darwin___1_3_r1' INTO TABLE `Darwin___1_3` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Darwin___1_4_1_r1' INTO TABLE `Darwin___1_4_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'DarwinFM___1_3g_r1' INTO TABLE `DarwinFM___1_3g` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'DarwinFM___1_4_1_r1' INTO TABLE `DarwinFM___1_4_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'DCTP___10_21p_r1' INTO TABLE `DCTP___10_21p` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'DCTP___1_31_r1' INTO TABLE `DCTP___1_31` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'DCTP___1_31_EPR_r1' INTO TABLE `DCTP___1_31_EPR` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E___0_91_r1' INTO TABLE `E___0_91` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E___0_99_r1' INTO TABLE `E___0_99` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E___0_999_r1' INTO TABLE `E___0_999` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E_KRHyper___1_0_r1' INTO TABLE `E_KRHyper___1_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'EP___0_999_r1' INTO TABLE `EP___0_999` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'EQP___0_9d_r1' INTO TABLE `EQP___0_9d` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Equinox___1_0b_r1' INTO TABLE `Equinox___1_0b` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Equinox___1_2_r1' INTO TABLE `Equinox___1_2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E_SETHEO___csp04_r1' INTO TABLE `E_SETHEO___csp04` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'E_SETHEO___csp04_SAT_r1' INTO TABLE `E_SETHEO___csp04_SAT` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Fampire___1_3_r1' INTO TABLE `Fampire___1_3` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Faust___1_0_r1' INTO TABLE `Faust___1_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'FDP___0_9_16_r1' INTO TABLE `FDP___0_9_16` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Fiesta___2_r1' INTO TABLE `Fiesta___2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Gandalf___c_2_6_r1' INTO TABLE `Gandalf___c_2_6` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Geo___2006j_r1' INTO TABLE `Geo___2006j` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Geo___2007f_r1' INTO TABLE `Geo___2007f` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'GrAnDe___1_1_r1' INTO TABLE `GrAnDe___1_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'iProver___0_2_r1' INTO TABLE `iProver___0_2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'leanCoP___2_0_r1' INTO TABLE `leanCoP___2_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'LeanTAP___2_3_r1' INTO TABLE `LeanTAP___2_3` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Mace2___2_2_r1' INTO TABLE `Mace2___2_2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Mace4___0307_r1' INTO TABLE `Mace4___0307` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Mace4___0607_r1' INTO TABLE `Mace4___0607` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Matita___0_1_0_r1' INTO TABLE `Matita___0_1_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Metis___2_0_r1' INTO TABLE `Metis___2_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Otter___3_3_r1' INTO TABLE `Otter___3_3` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Paradox___2_0b_r1' INTO TABLE `Paradox___2_0b` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Paradox___2_2_r1' INTO TABLE `Paradox___2_2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Prover9___0307_r1' INTO TABLE `Prover9___0307` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Prover9___0607_r1' INTO TABLE `Prover9___0607` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SCOTT___6_1_r1' INTO TABLE `SCOTT___6_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SETHEO___3_3_r1' INTO TABLE `SETHEO___3_3` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SNARK___20061020_r1' INTO TABLE `SNARK___20061020` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SOS___1_0_r1' INTO TABLE `SOS___1_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SOS___2_0_r1' INTO TABLE `SOS___2_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SPASS___2_2_r1' INTO TABLE `SPASS___2_2` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SPASS___3_0_r1' INTO TABLE `SPASS___3_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'SRASS___0_1_r1' INTO TABLE `SRASS___0_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'S_SETHEO___0_0_r1' INTO TABLE `S_SETHEO___0_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Theo___2006_r1' INTO TABLE `Theo___2006` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Vampire___8_1_r1' INTO TABLE `Vampire___8_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Vampire___9_0_r1' INTO TABLE `Vampire___9_0` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Waldmeister___806_r1' INTO TABLE `Waldmeister___806` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'zChaff___2004_11_15_r1' INTO TABLE `zChaff___2004_11_15` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
LOAD DATA LOCAL INFILE 'Zenon___0_4_1_r1' INTO TABLE `Zenon___0_4_1` FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n';
 