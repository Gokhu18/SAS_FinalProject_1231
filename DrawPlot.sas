%let path = %str(C:\Users\user\Desktop\F_Final);
%put &path;

*���S�O�Τ�v ���O%; 
data EachFirmReturn_Data;
	 infile "&path\EachFirmReturn_Data.csv"  dlm=',' firstobs=2 dsd;
	 input Name :$9. Date :yymmdd10. Return ;
	 format Date yymmdd10.;
	 Return = Return / 100;
run;

proc sort data = EachFirmReturn_Data;
	by Name Date;
run;

* �N�C�@����ƨ̾ڤ��q�W�٧@�s��; 
data EachFirmReturn;
	set EachFirmReturn_Data;
	by Name;
	retain n 0;
		n = n+1;
		if first.Name then n = 1;
run;

proc sort data = EachFirmReturn;
	by Name Date n;
run;

* �p��C�@�����q�U�����Т֢�;
data CalculateBHR;
	set EachFirmReturn;
	by Name;
	retain BHR_NeedMinus1;
	if first.Name then do;
		BHR_NeedMinus1 = (1 + Return);
		end;
	else do ;
		 BHR_NeedMinus1 = BHR_NeedMinus1 * (1+Return);
		end;
BHR = BHR_NeedMinus1 -1; 
drop BHR_NeedMinus1;
keep Name n BHR;
run;

*** �p���`�˥��������������S *** ;
proc sql;
	create table AllFirmBHR_Data
	as select n, mean(BHR) as BHRMean
	from CalculateBHR
	where n <= 750
	group by n;
quit;

data AllFirmBHR;
	set AllFirmBHR_Data;
	GroupSign = "�`�˥�";
run;


*** �ɤJ���Ҳv��ƱN���q�Ϥ��������C�n���� ***;
*Qual �N���`�X���� Allot ���Ҳv Aggre �n���� ; 
data Final_Aggre;
	infile "&path\Final_Aggre.csv" dlm=',' firstobs=2 dsd;
	input Name  :$9. Ask OfferPrice TotalOfferValue Qual Allot Allot_1 Aggre_1;
		OfferAmount = (TotalOfferValue/ OfferPrice)/1000000;
		Aggre = log(1 / Allot);
		Ask = Ask / 1000; 
		Qual = Qual / 1000;
	keep  Name Allot ;
run;

* �Hproc univariate ��X       25�ʤ����: 0.01620         75�ʤ���� : 0.43875;
proc univariate data = Final_Aggre ;
	var Allot ;
run;

* proc sql to left join ;
proc sql;
	create table BHRForPlot1_Data
	as select  a.*, b.*
	from CalculateBHR as a 
	left join Final_Aggre as b 
		on a.Name = b.Name
	order by Name;
quit;

*** �N��ưϤ��������C�n���� ***;
data BHRForPlot1;
	set BHRForPlot1_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "���n����";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "���n����";
	end;
	else do;
		GroupSign = "�C�n����";
	end;
	drop Name Allot;
run;

*** �p�Ⱚ���C�n���զU�ժ�����BHR ***;
proc sql;
	create table DataForFigure1WithoutTotal
	as select n, GroupSign, mean(BHR) as BHRMean
	from  BHRForPlot1
	where n <= 750
	group by n, GroupSign;
quit;

*** �X�ְ����C�n���ջP�`�˥���� ***;
data DataForFigure1;
	set DataForFigure1WithoutTotal AllFirmBHR;
run;

*** �e�� ***;
proc sgplot  data = DataForFigure1;
 	scatter x=n  y=BHRMean / group=GroupSign;
	title "Figure 1 IPOs �����������S���� - �H�ӾP���R�i";
run;

*** Figure 2 ***;
*** �p��q��20��}�l������BHR ***;
data EachFirmReturnAfterDay20;
	set EachFirmReturn;
	if n > 20;
run;

proc sort data = EachFirmReturnAfterDay20; 
	by Name n;
run;

* �p��q��20�Ѷ}�l���� �C�@�����q�U�����Т֢�;
data CalculateBHRAfterDay20;
	set EachFirmReturnAfterDay20;
	by Name;
	retain BHR_NeedMinus1;
	if first.Name then do;
		BHR_NeedMinus1 = (1 + Return);
		end;
	else do ;
		 BHR_NeedMinus1 = BHR_NeedMinus1 * (1+Return);
		end;
BHR = BHR_NeedMinus1 -1; 
drop BHR_NeedMinus1;
keep Name n BHR;
run;

*** �p�� �q��20�Ѷ}�l���� �`�˥��������������S *** ;
proc sql;
	create table AllFirmBHRAfterDay20_Data
	as select n, mean(BHR) as BHRMean
	from CalculateBHRAfterDay20
	where n <= 750
	group by n;
quit;

data AllFirmBHRAfterDay20;
	set AllFirmBHRAfterDay20_Data;
	GroupSign = "�`�˥�";
run;

* proc sql to left join ;
proc sql;
	create table BHRForPlot2_Data
	as select  a.*, b.*
	from CalculateBHRAfterDay20 as a 
	left join Final_Aggre as b 
		on a.Name = b.Name
	order by Name;
quit;

*** �N��ưϤ��������C�n���� ***;
data BHRForPlot2;
	set BHRForPlot2_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "���n����";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "���n����";
	end;
	else do;
		GroupSign = "�C�n����";
	end;
	drop Name Allot;
run;

*** �p�Ⱚ���C�n���զU�ժ�����BHR ***;
proc sql;
	create table DataForFigure2WithoutTotal
	as select n, GroupSign, mean(BHR) as BHRMean
	from  BHRForPlot2
	where n <= 750
	group by n, GroupSign;
quit;

*** �X�ְ����C�n���ջP�`�˥���� ***;
data DataForFigure2;
	set DataForFigure2WithoutTotal AllFirmBHRAfterDay20;
run;

*** �e�� ***;
proc sgplot  data = DataForFigure2;
 	scatter x=n  y=BHRMean / group=GroupSign;
	title "Figure 2 IPOs �����������S���� - �H�W�����20�餧���L���R�i";
run;

*** Figure 3  ***;
*** �p��U����AR  ***;
data CalculateFirm_MarketBHR;
	infile "&path\CalculateFirm_MarketBHR.csv" dlm=',' firstobs=2 dsd;
	input Name :$9. n BHR MarketBHR;
		AR = BHR - MarketBHR;
	keep Name n AR;
run; 

*** �p�� �`�˥������������W�B���S *** ;
proc sql;
	create table AllFirmAR_Data
	as select n, mean(AR) as ARMean
	from CalculateFirm_MarketBHR
	where n <= 750
	group by n;
quit;

data AllFirmAR;
	set AllFirmAR_Data;
	GroupSign = "�`�˥�";
run;

* proc sql to left join ;
proc sql;
	create table ARForPlot3_Data
	as select  a.*, b.*
	from CalculateFirm_MarketBHR as a 
	left join Final_Aggre as b 
		on a.Name = b.Name
	order by Name;
quit;

*** �N��ưϤ��������C�n���� ***;
data ARForPlot3;
	set ARForPlot3_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "���n����";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "���n����";
	end;
	else do;
		GroupSign = "�C�n����";
	end;
	drop Name Allot;
run;

*** �p�Ⱚ���C�n���զU�ժ�����AR ***;
proc sql;
	create table DataForFigure3WithoutTotal
	as select n, GroupSign, mean(AR) as ARMean
	from  ARForPlot3
	where n <= 750
	group by n, GroupSign;
quit;

*** �X�ְ����C�n���ջP�`�˥���� ***;
data DataForFigure3;
	set DataForFigure3WithoutTotal AllFirmAR;
run;

*** �e�� ***;
proc sgplot  data = DataForFigure3;
 	scatter x=n  y=ARMean / group=GroupSign;
	title "Figure 3 IPOs ���������W�B���S���� - �H�ӾP���R�i";
run;

*** Figure 4  ***;
data Firm_MarketReturnWithNumber;
	infile "&path\Firm_MarketReturnWithNumber.csv" dlm=',' firstobs=2 dsd;
	input Name :$9. Date :yymmdd10. Market $ Return MarketReturn n;
	if n > 20;
run;

* �p��C�@�����q�P�����U����BHR (�q��20�Ѷ}�l����);
data CalculateBHRAfterDay20;
	set Firm_MarketReturnWithNumber;
	by Name;
	retain BHR_NeedMinus1 MarketBHR_NeedMinus1;
	if first.Name then do;
		BHR_NeedMinus1 = (1 + Return);
		MarketBHR_NeedMinus1 = (1 + MarketReturn);
		end;
	else do ;
		 BHR_NeedMinus1 = BHR_NeedMinus1 * (1+Return);
		 MarketBHR_NeedMinus1 = MarketBHR_NeedMinus1 * (1 + MarketReturn);
		end;
	BHR = BHR_NeedMinus1 -1; 
	MarketBHR = MarketBHR_NeedMinus1 - 1;
	drop BHR_NeedMinus1 MarketBHR_NeedMinus1;
	keep Name n BHR MarketBHR;
run;

*** �p��AR (�q��20�Ѫ��ѻ��}�l�p��) ***;
data CalculateARAfterDay20;
	set CalculateBHRAfterDay20;
	AR = BHR - MarketBHR;
	keep Name n AR;
run;

*** �p�� �`�˥������������W�B���S *** ;
proc sql;
	create table AllFirmARAfterDay20_Data
	as select n, mean(AR) as ARMean
	from CalculateARAfterDay20
	where n <= 750
	group by n;
quit;

data AllFirmARAfterDay20;
	set AllFirmARAfterDay20_Data;
	GroupSign = "�`�˥�";
run;

* proc sql to left join ;
proc sql;
	create table ARForPlot4_Data
	as select  a.*, b.*
	from CalculateARAfterDay20 as a 
	left join Final_Aggre as b 
		on a.Name = b.Name
	order by Name;
quit;

*** �N��ưϤ��������C�n���� ***;
data ARForPlot4;
	set ARForPlot4_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "���n����";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "���n����";
	end;
	else do;
		GroupSign = "�C�n����";
	end;
	drop Name Allot;
run;

*** �p�Ⱚ���C�n���զU�ժ�����AR ***;
proc sql;
	create table DataForFigure4WithoutTotal
	as select n, GroupSign, mean(AR) as ARMean
	from  ARForPlot4
	where n <= 750
	group by n, GroupSign;
quit;

*** �X�ְ����C�n���ջP�`�˥���� ***;
data DataForFigure4;
	set DataForFigure4WithoutTotal AllFirmARAfterDay20;
run;

*** �e�� ***;
proc sgplot  data = DataForFigure4;
 	scatter x=n  y=ARMean / group=GroupSign;
	title "Figure 4 IPOs ���������W�B���S���� - �H�W�����20�餧���L���R�i";
run;


