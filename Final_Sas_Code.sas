/* loading Diaper groc dataset*/

LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.Diaper_groc;
infile 'C:\Users\sxm180029\Desktop\Project\diapers_groc_1114_1165' firstobs=2 missover;
input IRI_KEY  WEEK SY  GE VEND ITEM UNITS DOLLARS F $ D PR;
run;


/*loading Diaper panel grocery dataset*/
LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.panel_groc;
infile 'C:\Users\sxm180029\Desktop\Project\diapers_PANEL_GR_1114_1165.dat' dlm='09'X firstobs=2 missover;
input PANID	WEEK UNITS OUTLET$ DOLLARS IRI_KEY COLUPC;
run;

/*loading demographic dataset*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\ads_demo3.csv' OUT =demo_fm DBMS=CSV replace;
guessingrows=6566;
RUN;

/*loading demographic dataset*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\ads demo1.csv' OUT =demo1 DBMS=CSV replace;
guessingrows=13984;
RUN;

/*loading demographic dataset after removing irelevant columns*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\ads demo3_updated.csv' OUT =demo_upd DBMS=CSV replace;
guessingrows=6566;
RUN;

/*loading product description dataset*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\prod_diapers.csv' OUT =prod DBMS=CSV replace;
guessingrows=1844;
RUN;

/*loading Delivery store dataset */
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\Delivery_Stores.xlsx' OUT =delivery_store DBMS=EXCEL;
RUN;

/* Renaming the Company and Brand column*/
data prod;
set prod (RENAME=(L5=Brand L3=Company));
run;


/* creating new column in grocery data for merging purpose*/
data PS.Diaper_groc;
set PS.Diaper_groc;
upc_new=cats(of SY GE VEND ITEM);
run;

/* creating new column in product dataset for merging purpose*/
data prod;
set prod;
upc_new=cats(of SY GE VEND ITEM) ;
run;

/* sorting grocery data*/
proc sort data=PS.Diaper_groc;
by upc_new;
run;

/* sorting product  data*/
proc sort data=prod;
by upc_new;
run;

/*merging grocery and prod data*/
data groc_prod;
merge PS.Diaper_groc(IN=froma1x) prod(IN=froma2x);
by upc_new;
if froma1x and froma2x;
run;

/* sorting merged data on iri_key for merging with delivery stores data*/
proc sort data=groc_prod;
by iri_key;
run;

/* sorting delivery store data on iri_key */
proc sort data=delivery_store;
by iri_key;
run;

/*merging groc_prod and delivery data and creating a permanent sas data set for it*/
LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.Groc_Prod_Del;
merge groc_prod(IN=froma1x) delivery_store(IN=froma2x);
by iri_key;
if froma1x and froma2x;
run;

/*sorting panel_gr on panel id for merging*/
proc sort data=PS.panel_groc;
by panid;
run;

/*renaming and sorting demo data for merging with panel groc*/
data demo_upd;
set demo_upd (RENAME=(Panelist_ID=Panid));
run;

proc sort data=demo_upd;
by Panid;
run;

/*merging */
proc sql;
select count(panid) from demo_upd;
quit;

proc sql;
select count(panid) from PS.panel_groc;
quit;

/*merging panel_groc and demo*/
LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.Panel_groc_demo;
merge PS.panel_groc(IN=froma1x) demo_upd;
by panid;
if froma1x;
run;

/*sorting panel_groc_demo by week an iri key*/
proc sort data=PS.Panel_groc_demo;
by iri_key week;
run;

/*sorting groc proc with iri key and week*/
proc sort data=groc_prod;
by iri_key week;
run;

/*merging goc_prod and panel_demo*/
LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.goc_prod_pandemo;
merge PS.Panel_groc_demo(IN=froma1x) groc_prod ;
by iri_key week;
if froma1x;
run;

/*checking columns in the dataset*/
proc contents data=PS.Groc_Prod_Del;
run;

/*dropping irrelative columns*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
drop L1 L2 L4 L9 SY GE VEND ITEM _STUBSPEC_1828RC;
run;

/* checking for number of brands*/
proc freq;
table Brand;
run;

/* combining for similar brand */
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
if Brand in ('DRYPERS','DRYPERS SUPREME') then Brand='DRYPERS';
if Brand in ('FITTI','FITTI SUPREME ') then Brand='FITTI';
if Brand in ('HUGGIES','HUGGIES OVERNITES','HUGGIES SUPREME','HUGGIES ULTRATRIM','HUGGIES ULTRATRIM BABY STEPS') then Brand='HUGGIES';
if Brand in ('LUVS','LUVS ULTRA LEAKGUARDS','LUVS ULTRA LEAKGUARDS STRETCH') then Brand='LUVS';
if Brand in ('PAMPERS','PAMPERS BABY DRY','PAMPERS BABY DRY STRETCH','PAMPERS CRUISERS','PAMPERS PHASES','PAMPERS PREMIUM','PAMPERS RASH CARE','PAMPERS RASH GUARD','PAMPERS STRETCH','PAMPERS SWADDLERS ') then Brand='PAMPERS';
run;

/*again checking for the brands*/
proc freq;
table Brand;
run;

/*Dollar Sales of Brands*/
proc means sum data=PS.Groc_Prod_Del maxdec=2;
var Dollars;
class Brand;
output out=dollarb(where=(_Type_=1)) sum=Dollar_Sales;
run;

proc sort data=dollarb;
by descending Dollar_Sales;
run;

proc print data=dollarb(obs=5);
var brand _FREQ_ Dollar_Sales;
run;

/*Checking levels of feature column*/
proc freq data=PS.Groc_Prod_Del;
table F D;
run;

/*creating dummies for different levels of feature and display*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
if F='NONE' then No_Add=1; else No_Add=0;
if F='C' then Small_Ad=1; else Small_Ad=0;
if F='B' then Medium_Ad=1; else Medium_Ad=0;
if F='A' then Large_Add=1; else Large_Add=0;
if F='A+' then Cou_Reb=1; else Cou_Reb=0;
if D=0 then No_Dis=1; else No_Dis=0;
if D=1 then Min_Dis=1;else Min_Dis=0;
if D=2 then Maj_Dis=1; else Maj_Dis=0;
run;


/*calculating total units sold */
proc sql;
create table annual_units as select sum(units)as total_units from PS.Groc_Prod_Del;
quit;

/* total_units=8488240*/

/*Calculating market share for each brand*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
Total_Annual_Units=.;
run;

/*MARKET SHARE*/
proc means sum data=PS.Groc_Prod_Del maxdec=2;
var Dollars;
class Brand;
output out=dollarb(where=(_Type_=1)) sum=dollar_by_brand;
run;

proc sort data=dollarb;
by descending dollar_by_brand;
run;

proc print data=dollarb(obs=6);
var brand _FREQ_ dollar_by_brand;
run;

data dollarb1;
set dollarb;
where brand in ('HUGGIES','PAMPERS','PRIVATE LABEL','LUVS','DRYPERS','FITTI');
run;

/* Market share of categories*/
PROC GCHART DATA=dollarb1;
where _Type_=1;
      PIE Brand/sumvar=dollar_by_brand  VALUE=INSIDE
                 PERCENT=INSIDE SLICE=OUTSIDE;
RUN;

/*market share*/
LIBNAME PS 'C:\Users\sxm180029\Desktop';
proc means sum data=PS.Groc_Prod_Del maxdec=2;
var Units;
class Brand;
output out=unitsb(where=(_Type_=1)) sum=units_by_brand;
run;

proc sort data=unitsb;
by descending units_by_brand;
run;

proc print data=unitsb;
var brand _FREQ_ units_by_brand;
run;

PROC GCHART DATA=dollarb1;
where _Type_=1;
      PIE Brand/sumvar=dollar_by_brand  VALUE=INSIDE
                 PERCENT=INSIDE SLICE=OUTSIDE;
RUN;

proc sql;
update PS.Groc_Prod_Del
set Total_Annual_Units=(select sum(units_by_brand) from unitsb);
quit;

proc sql;
update PS.Groc_Prod_Del as u
   set Units_by_brand=(select units_by_brand from unitsb as n
			where u.brand=n.brand)
		where u.brand in (select brand from unitsb);
quit;


LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
market_share=(Units_by_brand/Total_Annual_Units);
run;

/*calculating price per units*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
price_per_unit_diaper=(dollars/units)/vol_eq;
run; 

proc contents data=PS.Groc_Prod_Del;
run;

/*weighted columns*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
weighted_No_Add=No_Add*Market_share;
weighted_Small_Add=Small_Ad*Market_share;
weighted_Medium_Ad=Medium_Ad*Market_share;
weighted_Large_Add=Large_Add*Market_share;
weighted_Cou_Reb=Cou_Reb*Market_share;
weighted_No_Dis=No_Dis*Market_share;
weighted_Min_Dis=Min_Dis*Market_share;
weighted_Maj_Dis=Maj_Dis*Market_share;
weighted_price_per_diaper=price_per_unit_diaper*Market_share;
run;

data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
weighted_PR=PR*Market_share;
run;

/*creating total sales column*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
total_sales=units*vol_eq;
run;

proc freq data=PS.Groc_Prod_Del;
table product_type flavor_scent weight_of_baby color thickness user_info stage_phase;
run;

/*not nuch division in user_info, thickness missing for more than 50% of the records,color,flavor scent missing for more than 90% of the records,
product type 95% of the records are disposable diapers*/

/*diaper characteristics which can be used for testing - stage_phase and weight_of_baby*/

/*STAGE_PHASE*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
if STAGE_PHASE in ('STAGE 1','STAGE 2','STAGE 3','STAGE 4','STAGE 5','STAGE 6') THEN NEW_STAGE_PHASE=STAGE_PHASE; else NEW_STAGE_PHASE='OTHERS';
run;

proc freq data=PS.Groc_Prod_Del;
table NEW_STAGE_PHASE;
run;

/*doing anova test to check whether sales differ for different Stage_phase*/
proc anova data=PS.Groc_Prod_Del;
class NEW_STAGE_PHASE;
model total_sales=NEW_STAGE_PHASE;
run;

/*Anova test result is significant */

/*making dummy variables for stage phase to use in reression*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
if NEW_STAGE_PHASE='STAGE 1' then SP1=1;else SP1=0;
if NEW_STAGE_PHASE='STAGE 2' then SP2=1;else SP2=0;
if NEW_STAGE_PHASE='STAGE 3' then SP3=1;else SP3=0;
if NEW_STAGE_PHASE='STAGE 4' then SP4=1;else SP4=0;
if NEW_STAGE_PHASE='STAGE 5' then SP5=1;else SP5=0;
if NEW_STAGE_PHASE='STAGE 6' then SP6=1;else SP6=0;
if NEW_STAGE_PHASE='OTHERS' then SP_Other=1;else SP_Other=0;
run;

/*WEIGHT_0F_BABY*/

proc sql;
select NEW_STAGE_PHASE,count(*) from PS.Groc_Prod_Del group by NEW_STAGE_PHASE;
quit;


proc freq data=PS.Groc_Prod_Del;
table NEW_STAGE_PHASE;
run;

/*doing anova test to check whether sales differ for different Stage_phase*/
proc anova data=PS.Groc_Prod_Del;
class NEW_STAGE_PHASE;
model total_sales=NEW_STAGE_PHASE;
run;

/*Anova test result is significant */

/*making dummy variables for stage phase to use in reression*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
if NEW_STAGE_PHASE='STAGE 1' then SP1=1;else SP1=0;
if NEW_STAGE_PHASE='STAGE 2' then SP2=1;else SP2=0;
if NEW_STAGE_PHASE='STAGE 3' then SP3=1;else SP3=0;
if NEW_STAGE_PHASE='STAGE 4' then SP4=1;else SP4=0;
if NEW_STAGE_PHASE='STAGE 5' then SP5=1;else SP5=0;
if NEW_STAGE_PHASE='STAGE 6' then SP6=1;else SP6=0;
if NEW_STAGE_PHASE='OTHERS' then SP_Other=1;else SP_Other=0;
run;

/*taking log of sales to reduce the spread*/
data PS.Groc_Prod_Del;
set PS.Groc_Prod_Del;
lntotal_sales=log(total_sales);
run;

/* subsetting data only for top 3 brands*/
data PS.Groc_Prod_Del3;
set PS.Groc_Prod_Del;
where brand in ('HUGGIES','PAMPERS','PRIVATE LABEL');
run;

/*exporting storelevel data for top 3 stores for descriptive analysis*/
proc export data=PS.Groc_Prod_Del3
   outfile='C:\Users\sxm180029\Desktop\Store_wise_Top3.csv'
   dbms=csv
   replace;
run;

/*creating dataset only for pampers*/
data PS.Groc_Prod_DelP;
set PS.Groc_Prod_Del3;
where brand='PAMPERS';
run;

data PS.Groc_Prod_DelH;
set PS.Groc_Prod_Del3;
where brand='HUGGIES';
run;


/*Model 1 FOR OUR BRAND PAMPERS*/
proc reg data=PS.Groc_Prod_DelP;
model total_sales= weighted_PR weighted_Small_Add weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper  ;
run;


/*Model 2  using log of total_sales*/
proc reg data=PS.Groc_Prod_DelP;
model lntotal_sales= weighted_PR weighted_Small_Add weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper ;
run;


/*Model 3 adding dummy variables for stage_phase whic came out significant in anova test*/
proc reg data=PS.Groc_Prod_DelP;
model lntotal_sales= weighted_PR weighted_Small_Add weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper/vif ;
run;


/* TRYING DIFFERENT INTERACTION TERMS*/
data PS.Groc_Prod_DelP;
set PS.Groc_Prod_DelP;
PRICE_MEDIUM_ADD=weighted_price_per_diaper*weighted_Medium_Ad;
PRICE_SMALL_ADD=weighted_price_per_diaper*weighted_Small_Add;
PRICE_LARGE_ADD=weighted_price_per_diaper*weighted_Large_Add;
PRICE_COU=weighted_price_per_diaper*weighted_Cou_Reb;
PRICE_MIN_DIS=weighted_price_per_diaper*weighted_Min_Dis;
PRICE_MAX_DIS=weighted_price_per_diaper*weighted_Maj_Dis;
PRICE_PR=weighted_price_per_diaper*weighted_PR;
PR_MEDIUM_ADD=weighted_PR*weighted_Medium_Ad;
PR_SMALL_ADD=weighted_PR*weighted_Small_Add;
PR_LARGE_ADD=weighted_PR*weighted_Large_Add;
PR_COU=weighted_PR*weighted_Cou_Reb;
PR_MIN_DIS=weighted_PR*weighted_Min_Dis;
PR_MAJ_DIS=weighted_PR*weighted_Maj_Dis;
COU_MIN_DIS=weighted_Cou_Reb*weighted_Min_Dis;
MEDIUM_ADD_MAJ_DIS=weighted_Medium_Ad*weighted_Min_Dis;
weighted_price_per_diaper2=weighted_price_per_diaper*weighted_price_per_diaper;
run;


/*FINAL NON LINEAR MODEL FOR PAMPERS ADVERTISING EFFECT*/
proc reg data=PS.Groc_Prod_DelP;
model lntotal_sales=  PR_MEDIUM_ADD COU_MIN_DIS weighted_price_per_diaper2 PR_SMALL_ADD PR_LARGE_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_PR weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper /vif ;
run;

/*interaction with price term is highly collinear so not including that*/

/*TRYING TO ADD THE EEFECT OF ADVERTISING AND PRICE CHANGE IN OUR COMPETITOR BRAND*/
data PS.Groc_Prod_DelH;
SET PS.Groc_Prod_DelH(RENAME=(weighted_price_per_diaper=weighted_price_per_diaper_HU weighted_Cou_Reb=weighted_Cou_Reb_HU weighted_Maj_Dis=weighted_Maj_Dis_HU));
RUN;

data PS.Groc_Prod_DelH;
SET PS.Groc_Prod_DelH(RENAME=(weighted_Cou_Reb=weighted_Cou_Reb_HU weighted_Maj_Dis=weighted_Maj_Dis_HU));
RUN;

data PS.Groc_Prod_DelH;
SET PS.Groc_Prod_DelH(RENAME=(weighted_Large_Add=weighted_Large_Add_HU));
RUN;

data PS.Groc_Prod_DelH;
SET PS.Groc_Prod_DelH(RENAME=(weighted_Medium_Ad=weighted_Medium_Ad_HU weighted_Min_Dis=weighted_Min_Dis_HU weighted_Small_Add=weighted_Small_Add_HU weighted_PR=weighted_PR_HU));
RUN;


PROC SORT DATA=PS.Groc_Prod_DelH;
BY IRI_KEY WEEK;
RUN;

PROC SORT DATA=PS.Groc_Prod_DelP;
BY IRI_KEY WEEK;
RUN;

data PS.Groc_Prod_DelHP ;
   merge PS.Groc_Prod_DelP PS.Groc_Prod_DelH (KEEP=IRI_KEY WEEK weighted_price_per_diaper_HU weighted_Cou_Reb_HU weighted_Maj_Dis_HU weighted_Large_Add_HU weighted_Medium_Ad_HU weighted_Min_Dis_HU weighted_Small_Add_HU weighted_PR_HU);
   by IRI_KEY WEEK;
run;

/*SUBSETTING DATA FOR DIFFERENT PHASES OF BABY AS SALES MAY DIFFERE */

PROC FREQ DATA=PS.Groc_Prod_DelHP;
TABLE NEW_STAGE_PHASE;
RUN;

data PS.Groc_Prod_DelHPS3;
SET PS.Groc_Prod_DelHP;
WHERE NEW_STAGE_PHASE='STAGE 3';
RUN;

data PS.Groc_Prod_DelHPS4;
SET PS.Groc_Prod_DelHP;
WHERE NEW_STAGE_PHASE='STAGE 4';
RUN;

data PS.Groc_Prod_DelHPS5;
SET PS.Groc_Prod_DelHP;
WHERE NEW_STAGE_PHASE='STAGE 5';
RUN;

/*FINAL MODEL FOR CROSS EFFECT BY HUGGIES BRAND*/
proc reg data=PS.Groc_Prod_DelHP;
model lntotal_sales= weighted_Large_Add_HU weighted_Cou_Reb_HU weighted_Maj_Dis_HU PR_MEDIUM_ADD COU_MIN_DIS PR_SMALL_ADD PR_LARGE_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU/vif stb ;
run;

PROC MEANS DATA=PS.Groc_Prod_DelHP;
VAR weighted_price_per_diaper_HU weighted_price_per_diaper lntotal_sales;
RUN; 

/*MODEL WITH ONLY STAGE 4*/
proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_price_per_diaper_HU weighted_Large_Add_HU weighted_PR_HU weighted_Cou_Reb_HU weighted_Maj_Dis_HU weighted_PR PR_SMALL_ADD PR_MIN_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis WEIGHTED_SMALL_ADD weighted_price_per_diaper weighted_price_per_diaper2/vif stb ;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_price_per_diaper_HU weighted_Maj_Dis_HU cou_min_dis weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper2/vif stb ;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_Cou_Reb_HU weighted_PR weighted_Maj_Dis_HU PR_MEDIUM_ADD COU_MIN_DIS PR_SMALL_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper_HU/vif stb ;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_Cou_Reb_HU weighted_Min_Dis_HU weighted_Maj_Dis_HU PR_large_ADD PR_MEDIUM_ADD COU_MIN_DIS weighted_PR PR_SMALL_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU/vif stb ;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_Cou_Reb_HU weighted_Min_Dis_HU weighted_Maj_Dis_HU  COU_MIN_DIS weighted_PR PR_SMALL_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU/vif stb ;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_Medium_Ad_HU weighted_Small_Add_Hu weighted_Maj_Dis_HU weighted_PR PR_SMALL_ADD  Pr_medium_add PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Small_ADD weighted_Maj_Dis weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU/SELECTION = stepwise slentry = 0.05 slstay = 0.05;
run;

/*FINAL MODEL AFTER TRYING SEVERAL DIFFRENT MODELS*/
proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_PR PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Maj_Dis_HU weighted_Large_Add_HU/stb vif;
run;

/*Trying out other interaction terms*/
data PS.Groc_Prod_DelHPS4;
set PS.Groc_Prod_DelHPS4;
MIN_DIS_SMALL_ADD=weighted_SMALL_ADD*weighted_Min_Dis;
MIN_DIS_LAR_ADD=WEIGHTED_LARGE_ADD*WEIGHTED_MIN_DIS;
MIN_DIS_MED_AD=weighted_Medium_Ad*WEIGHTED_MIN_DIS;
COU_MIN_DIS=weighted_Cou_Reb*weighted_Min_Dis;
MAJ_DIS_SMALL_ADD=WEIGHTED_SMALL_ADD*WEIGHTED_MAJ_DIS;
MAJ_DIS_LAR_ADD=WEIGHTED_LARGE_ADD*WEIGHTED_MAJ_DIS;
MAJ_DIS_MED_ADD=weighted_Medium_Ad*weighted_MAJ_Dis;
COU_MAJ_DIS=weighted_MAJ_Dis*WEIGHTED_COU_REB;
run;

/*Final model with interaction of display and featue*/

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_price_per_diaper weighted_price_per_diaper2 weighted_price_per_diaper_HU weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_PR MAJ_DIS_MED_ADD COU_MAJ_DIS COU_MIN_DIS MIN_DIS_LAR_ADD PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Maj_Dis_HU weighted_Large_Add_HU/stb vif;
run;

/*****************************/

/*
data PS.Groc_Prod_DelHPS4;
set PS.Groc_Prod_DelHPS4;
weighted_price_per_diaperP=weighted_price_per_diaper/0.1;
weighted_price_per_diaperH=weighted_price_per_diaper_HU/0.1;
run;

data PS.Groc_Prod_DelHPS4;
set PS.Groc_Prod_DelHPS4;
weighted_price_per_diaperP2=weighted_price_per_diaperP*weighted_price_per_diaperP;
run;

proc reg data=PS.Groc_Prod_DelHPS4;
model lntotal_sales= weighted_price_per_diaperP weighted_price_per_diaperP2 weighted_price_per_diaperH weighted_Medium_Ad weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_PR PR_COU PR_MIN_DIS PR_MAJ_DIS weighted_Maj_Dis_HU weighted_Large_Add_HU/stb vif;
run;

PROC MEANS DATA=PS.Groc_Prod_DelHPS4;
VAR weighted_price_per_diaper weighted_price_per_diaper_HU weighted_Medium_Ad weighted_Small_Add weighted_Large_Add weighted_Cou_Reb weighted_Min_Dis weighted_Maj_Dis weighted_PR;
RUN;

PROC MEANS DATA=PS.Groc_Prod_DelHPS4;
VAR weighted_price_per_diaper weighted_price_per_diaper_HU;
RUN;

PROC MEANS DATA=PS.Groc_Prod_DelHPS4;
VAR weighted_price_per_diaperP weighted_price_per_diaperH;
RUN;
*/

proc sql;
select iri_key,week,count(*) from PS.Groc_Prod_DelHPS4 group by iri_key,week;
quit;

proc sql;
select iri_key,week,sum(total_sales) as weekly_sales from PS.Groc_Prod_DelHPS4  group by iri_key,week having sum(total_sales)=.;
quit;





//*****************************************HOW SALES CHANGE WITH HH CHARACTERISTICS**********************************************************//

proc sql
delete from PS.Panel_groc_demo where panelist_type=.;
quit;

PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\prod_diapers.csv' OUT =prod_panel DBMS=CSV replace;
guessingrows=1844;
RUN;

Data prod_panel;
set prod_panel;
COLUPC1=compress(UPC,'-','l');
COLUPC= input(COLUPC1, 16.);
drop COLUPC1;
RUN;

proc sort data=PS.Panel_groc_demo;
by COLUPC;
run;

proc sort data=prod_panel;
by COLUPC;
run;

LIBNAME PS 'C:\Users\sxm180029\Desktop';
data PS.Panel_prod_demo;
merge PS.Panel_groc_demo(IN=froma1x) prod_panel(IN=froma2x);
by COLUPC;
if froma1x and froma2x;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo (RENAME=(L5=Brand L3=Company));
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Brand in ('DRYPERS','DRYPERS SUPREME') then Brand='DRYPERS';
if Brand in ('FITTI','FITTI SUPREME ') then Brand='FITTI';
if Brand in ('HUGGIES','HUGGIES OVERNITES','HUGGIES SUPREME','HUGGIES ULTRATRIM','HUGGIES ULTRATRIM BABY STEPS') then Brand='HUGGIES';
if Brand in ('LUVS','LUVS ULTRA LEAKGUARDS','LUVS ULTRA LEAKGUARDS STRETCH') then Brand='LUVS';
if Brand in ('PAMPERS','PAMPERS BABY DRY','PAMPERS BABY DRY STRETCH','PAMPERS CRUISERS','PAMPERS PHASES','PAMPERS PREMIUM','PAMPERS RASH CARE','PAMPERS RASH GUARD','PAMPERS STRETCH','PAMPERS SWADDLERS ') then Brand='PAMPERS';
run;

/*TAKING BACKUP OF THIS TABLE*/

DATA PS.Panel_prod_demo_BCK;
SET PS.Panel_prod_demo;
RUN;


/*dummy variable creation*/
/*Stage_Phase*/
data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Stage_Phase='MISSING' OR Stage_Phase='NEW BORN' OR Stage_Phase='PREMATURE' then sta0=1; else sta0=0;
if Stage_Phase='STAGE 1' then sta1=1; else sta1=0;
if Stage_Phase='STAGE 2' then sta2=1; else sta2=0;
if Stage_Phase='STAGE 3' then sta3=1; else sta3=0;
if Stage_Phase='STAGE 4' then sta4=1; else sta4=0;
if Stage_Phase='STAGE 5' then sta5=1; else sta5=0;
if Stage_Phase='STAGE 6' then sta6=1; else sta6=0;
run;

/*Thickness*/
/*Missing come under thick?*/
data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if THICKNESS='THIN' OR THICKNESS='ULTRA THIN' OR THICKNESS='ULTRA TRIM' then thin=1; else thin=0;
run;

/*WEIGHT_OF_BABY*/
data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
IF WEIGHT_OF_BABY = '8 TO 14 POUNDS' OR WEIGHT_OF_BABY = '8 TO 15 POUNDS' OR WEIGHT_OF_BABY = 'UP TO 10 POUNDS' OR WEIGHT_OF_BABY = 'UP TO 14 POUNDS' OR WEIGHT_OF_BABY = 'UP TO 5 POUNDS' then wei1=1; else wei1=0;
IF WEIGHT_OF_BABY = '12 TO 18 POUNDS' OR WEIGHT_OF_BABY = '12 TO 22 POUNDS' OR WEIGHT_OF_BABY = '12 TO 24 POUNDS' OR WEIGHT_OF_BABY = '12 TO 26 POUNDS' OR WEIGHT_OF_BABY = '16 TO 24 POUNDS' OR WEIGHT_OF_BABY = '16 TO 28 POUNDS' then wei2=1; else wei2=0;
IF WEIGHT_OF_BABY = '22 TO 32 POUNDS' OR WEIGHT_OF_BABY = '22 TO 35 POUNDS' OR WEIGHT_OF_BABY = '22 TO 37 POUNDS' OR WEIGHT_OF_BABY = '26 POUNDS AND OVER' OR WEIGHT_OF_BABY = '27 POUNDS AND OVER' OR WEIGHT_OF_BABY = '30 POUNDS AND OVER' OR WEIGHT_OF_BABY = '35 POUNDS AND OVER' OR WEIGHT_OF_BABY = 'UP TO 27 POUNDS'  then wei3=1; else wei3=0;
run;


/*Type of Residential possession*/
proc freq data=PS.Panel_prod_demo;
tables Type_of_Residential_Possession;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Type_of_Residential_Possession = 1 then resident = 0;
else resident = 1;
run;

/*HH_OCC*/
proc freq data=PS.Panel_prod_demo;
tables HH_OCC;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if HH_OCC=1 then occ1=1; else occ1=0;
if HH_OCC=2 then occ2=1; else occ2=0;
if HH_OCC=3 then occ3=1; else occ3=0;
if HH_OCC=4 then occ4=1; else occ4=0;
if HH_OCC=5 then occ5=1; else occ5=0;
if HH_OCC=6 then occ6=1; else occ6=0;
if HH_OCC=7 then occ7=1; else occ7=0;
if HH_OCC=8 then occ8=1; else occ8=0;
if HH_OCC=9 then occ9=1; else occ9=0;
if HH_OCC=10 then occ10=1; else occ10=0;
if HH_OCC=11 then occ11=1; else occ11=0;
if HH_OCC=13 then occ13=1; else occ13=0;
run;


/*Combined_Pre_Tax_Income_of_HH*/
proc freq data=PS.Panel_prod_demo;
tables Combined_Pre_Tax_Income_of_HH;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Combined_Pre_Tax_Income_of_HH <= 5 then inc1=1; else inc1=0;
if Combined_Pre_Tax_Income_of_HH >= 6 and Combined_Pre_Tax_Income_of_HH <= 8  then inc2=1; else inc2=0;
if Combined_Pre_Tax_Income_of_HH >= 7 and Combined_Pre_Tax_Income_of_HH <= 10  then inc3=1; else inc3=0;
if Combined_Pre_Tax_Income_of_HH >= 11 then inc4=1; else inc4=0;
run;

/*HH_EDU*/
proc freq data=panel;
tables HH_edu;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if HH_edu <= 4 then edu1=1; else edu1=0;
if HH_edu >= 5 and HH_edu <= 7 then edu2=1; else edu2=0;
if HH_edu = 8 then edu3=1; else edu3=0;
run;

/*Children_Group_Code*/
/*Binary dummy for groups involving 0-5 age group who wear diapers*/
proc freq data=panel;
tables Children_Group_Code;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Children_Group_Code = 1 or Children_Group_Code = 4 or Children_Group_Code = 5 or Children_Group_Code = 7 then cgc=1; else cgc=0;
run;


/*HH_Head_Race__RACE3_*/
/* 92% of data is race =2, I think so we can drop this column */

proc freq data=panel;
tables HH_Head_Race__RACE3_;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if HH_Head_Race__RACE3_=1 then race1=1; else race1=0;
if HH_Head_Race__RACE3_=2 then race2=1; else race2=0;
if HH_Head_Race__RACE3_=3 then race3=1; else race3=0;
if HH_Head_Race__RACE3_=4 then race4=1; else race4=0;
if HH_Head_Race__RACE3_=5 then race5=1; else race5=0;
if HH_Head_Race__RACE3_=6 then race6=1; else race6=0;
if HH_Head_Race__RACE3_=7 then race7=1; else race7=0;
run;

data PS.Panel_prod_demo;
set PS.Panel_prod_demo;
if Brand in ('DRYPERS','DRYPERS SUPREME') then Brand='DRYPERS';
if Brand in ('FITTI','FITTI SUPREME ') then Brand='FITTI';
if Brand in ('HUGGIES','HUGGIES OVERNITES','HUGGIES SUPREME','HUGGIES ULTRATRIM','HUGGIES ULTRATRIM BABY STEPS') then Brand='HUGGIES';
if Brand in ('LUVS','LUVS ULTRA LEAKGUARDS','LUVS ULTRA LEAKGUARDS STRETCH') then Brand='LUVS';
if Brand in ('PAMPERS','PAMPERS BABY DRY','PAMPERS BABY DRY STRETCH','PAMPERS CRUISERS','PAMPERS PHASES','PAMPERS PREMIUM','PAMPERS RASH CARE','PAMPERS RASH GUARD','PAMPERS STRETCH','PAMPERS SWADDLERS ') then Brand='PAMPERS';
run;

/*loading demographic dataset*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\ads_demo3.csv' OUT =demo_fm DBMS=CSV replace;
guessingrows=6566;
RUN;


data PS.Panel_prod_demo_merge;
merge PS.Panel_prod_demo(in=froma1) demo_fm(in=froma2);
by panid;
if froma1 and froma2;
run;

data PS.Panel_prod_demo_merge;
set PS.Panel_prod_demo_merge;
if Age_Group_Applied_to_Female_HH=1 then Fage1=1; else Fage1=0;
if Age_Group_Applied_to_Female_HH=2 then Fage2=1; else Fage2=0;
if Age_Group_Applied_to_Female_HH=3 then Fage3=1; else Fage3=0;
if Age_Group_Applied_to_Female_HH=4 then Fage4=1; else Fage4=0;
if Age_Group_Applied_to_Female_HH=5 then Fage5=1; else Fage5=0;
if Age_Group_Applied_to_Female_HH=6 then Fage6=1; else Fage6=0;
run;

data PS.Panel_prod_demo_merge;
set PS.Panel_prod_demo_merge;
if Age_Group_Applied_to_Male_HH=1 then Mage1=1; else Mage1=0;
if Age_Group_Applied_to_Male_HH=2 then Mage2=1; else Mage2=0;
if Age_Group_Applied_to_Male_HH=3 then Mage3=1; else Mage3=0;
if Age_Group_Applied_to_Male_HH=4 then Mage4=1; else Mage4=0;
if Age_Group_Applied_to_Male_HH=5 then Mage5=1; else Mage5=0;
if Age_Group_Applied_to_Male_HH=6 then Mage6=1; else Mage6=0;
run;

/*creating column for unit price of diaper and qty_sold*/
data PS.Panel_prod_demo_merge;
set PS.Panel_prod_demo_merge;
unit_price=(dollars/units)/vol_eq;
qty_sold=units*vol_eq;
run;

proc sort data=PS.Panel_prod_demo_merge;;
by panid week;
run;

data PS.Panel_prod_demo_mergeb;
set PS.Panel_prod_demo_merge;
run;

proc sql;
delete from PS.Panel_prod_demo_merge where Number_of_TVs_Hooked_to_Cable=.;
run;

proc sql;
select panid,week,count(*) from PS.Panel_prod_demo_merge group by panid,week having count(*)>1;
quit;

proc sort data=PS.Panel_prod_demo_merge out=PS.Panel_prod_demo_mergeno nodupkey;
by panid week;
run;

proc export data=PS.Panel_prod_demo_mergeno
   outfile='C:\Users\sxm180029\Desktop\HH_Data_mergeno.csv'
   dbms=csv
   replace;
run;

data PS.Panel_prod_demo_mergenoP;
set PS.Panel_prod_demo_mergeno;
where brand='PAMPERS';
run;

proc panel data=PS.Panel_prod_demo_mergeno;
id panid week;
model qty_sold=unit_price Number_of_TVs_Hooked_to_Cable inc1 inc2 resident cgc Fage1-Fage5 Mage2-Mage5  / pooled fixone fixtwo ranone rantwo;
run;

proc panel data=PS.Panel_prod_demo_mergenoP;
id panid week;
model qty_sold=unit_price Number_of_TVs_Hooked_to_Cable inc1 inc2 resident cgc Fage1-Fage5 Mage2-Mage5  / pooled fixone fixtwo ranone rantwo;
run;



/****************************RFM ANALYSIS*/*********************************************/

/*RFM Analysis*/
%aaRFM;
%EM_RFM_CONTROL
(
   Mode = T,              
   InData = PS.Panel_prod_demo,            
   CustomerID = Panid,        
   N_R_Grp = 5,         
   N_F_Grp = 5,         
   N_M_Grp = 5,         
   BinMethod = I,          
   PurchaseDate = Week,      
   PurchaseAmt = Dollars,       
   SetMiss = Y,                                                         
   SummaryFunc = SUM,      
   MostRecentDate = ,    
   NPurchase = ,         
   TotPurchaseAmt = ,    
   MonetizationMap = Y, 
   BinChart = Y,        
   BinTable = Y,        
   OutData = PS.RFM_RESULTS,           
   Recency_Score = recency_score,     
   Frequency_Score = frequency_score,   
   Monetary_Score = monetary_score,    
   RFM_Score = rfm_score           
);

/*determing corelation*/
proc corr data=PS.RFM_RESULTS;
var recency_score frequency_score monetary_score;
run;

proc sort data = PS.RFM_RESULTS;
by panid;

proc sort data = PS.Panel_prod_demo;
by panid;

data PS.RFM_Panel;
merge PS.RFM_RESULTS (in=froma1) PS.Panel_prod_demo (in=froma2);
by panid;
if froma1 and  froma2;
run;

proc print data = PS.RFM_Panel (obs=10); 
run;

data PS.RFM_Panel;
set PS.RFM_Panel;
RFM_score_new = Recency_Score + Monetary_Score;
run;

proc sql;
select max(RFM_score_new) from PS.RFM_Panel;
quit;

data PS.RFM_Panel;
set PS.RFM_Panel;
if RFM_score_new>=8  & recency_score >= 4 & monetary_score >= 4 then loyal = 1; else loyal=0;
run;

proc export data=PS.RFM_Panel
   outfile='C:\Users\sxm180029\Desktop\RFM_Loyal.csv'
   dbms=csv
   replace;
run;

/**************CHECKING THE CHARACTERISTICS OF LOYAL CUSTOMER ****************/

/*loading demographic dataset*/
PROC IMPORT DATAFILE='C:\Users\sxm180029\Desktop\Project\ads_demo3.csv' OUT =demo_fm DBMS=CSV replace;
guessingrows=6566;
RUN;

proc sort data=PS.RFM_PANEL out=PS.RFM_PANEL_nodup nodupkey;
by panid brand;
run;

data PS.RFM_PANEL_nodup_merge;
merge PS.RFM_PANEL_nodup(in=froma1) demo_fm(in=froma2);
by panid;
if froma1 and froma2;
run;

data PS.RFM_PANEL_nodup_merge;
set PS.RFM_PANEL_nodup_merge;
if Age_Group_Applied_to_Female_HH=1 then Fage1=1; else Fage1=0;
if Age_Group_Applied_to_Female_HH=2 then Fage2=1; else Fage2=0;
if Age_Group_Applied_to_Female_HH=3 then Fage3=1; else Fage3=0;
if Age_Group_Applied_to_Female_HH=4 then Fage4=1; else Fage4=0;
if Age_Group_Applied_to_Female_HH=5 then Fage5=1; else Fage5=0;
if Age_Group_Applied_to_Female_HH=6 then Fage6=1; else Fage6=0;
run;

data PS.RFM_PANEL_nodup_merge;
set PS.RFM_PANEL_nodup_merge;
if Age_Group_Applied_to_Male_HH=1 then Mage1=1; else Mage1=0;
if Age_Group_Applied_to_Male_HH=2 then Mage2=1; else Mage2=0;
if Age_Group_Applied_to_Male_HH=3 then Mage3=1; else Mage3=0;
if Age_Group_Applied_to_Male_HH=4 then Mage4=1; else Mage4=0;
if Age_Group_Applied_to_Male_HH=5 then Mage5=1; else Mage5=0;
if Age_Group_Applied_to_Male_HH=6 then Mage6=1; else Mage6=0;
run;


/* logistic  (ALL the brands)*/
proc logistic data=PS.RFM_PANEL_nodup_merge descending outmodel=loyal_pred;
model loyal=inc1 inc2 inc3  resident cgc Fage1-Fage5 Mage2-Mage5 edu1 edu2 / expb;
output out =pred predprobs=(individual);
run;

DATA pred2; 
   SET pred;
   KEEP _FROM_ _INTO_;
RUN;

proc contents data=pred2;
run;

data pred2;
set pred2 (RENAME=(_FROM_=Actual _INTO_=Predicted));
run;

data pred2;
set pred2 ;
label Actual='Actual';
run;

data pred2;
set pred2 ;
label Predicted='Predicted';
run;

proc means data = pred2;
class Actual Predicted;
run;

/* FIT Stat for our model*/
PROC LOGISTIC INMODEL = loyal_pred;
SCORE DATA = PS.RFM_PANEL_nodup_merge OUT = Prediction FITSTAT; 
RUN;
