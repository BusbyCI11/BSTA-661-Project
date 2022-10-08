dm 'log;clear;output;clear;odsresults;select all;clear;';

PROC IMPORT OUT= WORK.HEART_DISEASE 
            DATAFILE= "G:\SAS Projects\BSTA 661 Project\heart_2
020_cleaned.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

proc contents data=WORK.HEART_DISEASE order=varnum;
run;

data hd_num; set WORK.HEART_DISEASE;
	if AgeCategory='18-24' then agecatnum=21;
	if AgeCategory='25-29' then agecatnum=27;
	if AgeCategory='30-34' then agecatnum=32;
	if AgeCategory='35-39' then agecatnum=37;
	if AgeCategory='40-44' then agecatnum=42;
	if AgeCategory='45-49' then agecatnum=47;
	if AgeCategory='50-54' then agecatnum=52;
	if AgeCategory='55-59' then agecatnum=57;
	if AgeCategory='60-64' then agecatnum=62;
	if AgeCategory='65-69' then agecatnum=67;
	if AgeCategory='70-74' then agecatnum=72;
	if AgeCategory='75-79' then agecatnum=77;
	if AgeCategory='80 or older' then agecatnum=85;
	if Diabetic='Yes (during pregnancy)' then Diabetic='No';
	if Race='Ameri' then Race='White';
	if Race='Other' then Race='White';

run;

data hd_num; set hd_num;
age = agecatnum/5;
age2 = age*age;
run;

proc freq data=heart_disease;
table sex*AgeCategory/nocol norow;
run;

proc freq data=heart_disease;
	table Race*AgeCategory/nocol norow;
run;

proc freq data=hd_num;
	table Diabetic;
run;
proc freq data=hd_num;
	table Smoking;
run;

proc freq data=hd_num;
	table Stroke;
run;

proc univariate data=hd_num;
	var BMI;
	histogram;
run;

proc freq data=hd_num nlevels;
        table BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth PhysicalActivity DiffWalking Sex agecatnum Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer Sex*Stroke / noprint;
run;

proc surveyselect data = hd_num 
	out = hd_num_sample
	method = SRS rep = 1 
	sampsize = 5000 
	seed = 12345;
run;

proc genmod descending data=hd_num;
class Smoking(ref="No") AlcoholDrinking(ref="No") Stroke(ref="No") DiffWalking(ref="No") Sex agecatnum(ref='21') Race Diabetic(ref="No")
GenHealth(ref="Poor") Asthma(ref="No") KidneyDisease(ref="No") SkinCancer(ref="No") PhysicalActivity(ref="No");
model HeartDisease = BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer / dist=bin link=logit ;
output out=temp p=pred upper=ucl lower=lcl;
run;

ods graphics on;

proc logistic descending data=hd_num_sample plots=oddsratio;
class Smoking(ref="No") AlcoholDrinking(ref="No") Stroke(ref="No") DiffWalking(ref="No") Sex agecatnum(ref='21') Race Diabetic(ref="No")
GenHealth(ref="Poor") Asthma(ref="No") KidneyDisease(ref="No") SkinCancer(ref="No") PhysicalActivity(ref="No") / param=ref;
 model HeartDisease = BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking Sex age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer / selection=backward lackfit aggregate=(BMI Smoking AlcoholDrinking Stroke PhysicalHealth MentalHealth DiffWalking Sex age PhysicalActivity Race Diabetic 
GenHealth SleepTime Asthma KidneyDisease SkinCancer) outroc=classif1;
output out = prob PREDPROBS=I;
store logiModel;
run;

title "Predicted Probabilities of Heart Disease";
proc plm source=logiModel;
	effectplot slicefit(x=age sliceby=GenHealth plotby=Smoking);
	effectplot slicefit(x=age sliceby=Sex plotby=Smoking);
	effectplot slicefit(x=age sliceby=Sex plotby=Stroke);
	effectplot slicefit(x=age sliceby=Stroke plotby=Sex);
	effectplot slicefit(x=age sliceby=Stroke plotby=Smoking);
	effectplot slicefit(x=age sliceby=GenHealth plotby=Stroke);
run;

ods graphics off;
