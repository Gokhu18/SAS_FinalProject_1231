%let path = %str(C:\Users\user\Desktop\F_Final);
%put &path;

*報酬是用比率 不是%; 
data EachFirmReturn_Data;
	 infile "&path\EachFirmReturn_Data.csv"  dlm=',' firstobs=2 dsd;
	 input Name :$9. Date :yymmdd10. Return ;
	 format Date yymmdd10.;
	 Return = Return / 100;
run;

proc sort data = EachFirmReturn_Data;
	by Name Date;
run;

* 將每一筆資料依據公司名稱作編號; 
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

* 計算每一間公司各期的ＢＨＲ;
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

*** 計算總樣本的持有期間報酬 *** ;
proc sql;
	create table AllFirmBHR_Data
	as select n, mean(BHR) as BHRMean
	from CalculateBHR
	where n <= 750
	group by n;
quit;

data AllFirmBHR;
	set AllFirmBHR_Data;
	GroupSign = "總樣本";
run;


*** 導入中籤率資料將公司區分為高中低積極組 ***;
*Qual 代表總合格件數 Allot 中籤率 Aggre 積極性 ; 
data Final_Aggre;
	infile "&path\Final_Aggre.csv" dlm=',' firstobs=2 dsd;
	input Name  :$9. Ask OfferPrice TotalOfferValue Qual Allot Allot_1 Aggre_1;
		OfferAmount = (TotalOfferValue/ OfferPrice)/1000000;
		Aggre = log(1 / Allot);
		Ask = Ask / 1000; 
		Qual = Qual / 1000;
	keep  Name Allot ;
run;

* 以proc univariate 找出       25百分位數: 0.01620         75百分位數 : 0.43875;
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

*** 將資料區分為高中低積極組 ***;
data BHRForPlot1;
	set BHRForPlot1_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "高積極組";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "中積極組";
	end;
	else do;
		GroupSign = "低積極組";
	end;
	drop Name Allot;
run;

*** 計算高中低積極組各組的平均BHR ***;
proc sql;
	create table DataForFigure1WithoutTotal
	as select n, GroupSign, mean(BHR) as BHRMean
	from  BHRForPlot1
	where n <= 750
	group by n, GroupSign;
quit;

*** 合併高中低積極組與總樣本資料 ***;
data DataForFigure1;
	set DataForFigure1WithoutTotal AllFirmBHR;
run;

*** 畫圖 ***;
proc sgplot  data = DataForFigure1;
 	scatter x=n  y=BHRMean / group=GroupSign;
	title "Figure 1 IPOs 持有期間報酬走勢 - 以承銷價買進";
run;

*** Figure 2 ***;
*** 計算從第20日開始持有的BHR ***;
data EachFirmReturnAfterDay20;
	set EachFirmReturn;
	if n > 20;
run;

proc sort data = EachFirmReturnAfterDay20; 
	by Name n;
run;

* 計算從第20天開始持有 每一間公司各期的ＢＨＲ;
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

*** 計算 從第20天開始持有 總樣本的持有期間報酬 *** ;
proc sql;
	create table AllFirmBHRAfterDay20_Data
	as select n, mean(BHR) as BHRMean
	from CalculateBHRAfterDay20
	where n <= 750
	group by n;
quit;

data AllFirmBHRAfterDay20;
	set AllFirmBHRAfterDay20_Data;
	GroupSign = "總樣本";
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

*** 將資料區分為高中低積極組 ***;
data BHRForPlot2;
	set BHRForPlot2_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "高積極組";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "中積極組";
	end;
	else do;
		GroupSign = "低積極組";
	end;
	drop Name Allot;
run;

*** 計算高中低積極組各組的平均BHR ***;
proc sql;
	create table DataForFigure2WithoutTotal
	as select n, GroupSign, mean(BHR) as BHRMean
	from  BHRForPlot2
	where n <= 750
	group by n, GroupSign;
quit;

*** 合併高中低積極組與總樣本資料 ***;
data DataForFigure2;
	set DataForFigure2WithoutTotal AllFirmBHRAfterDay20;
run;

*** 畫圖 ***;
proc sgplot  data = DataForFigure2;
 	scatter x=n  y=BHRMean / group=GroupSign;
	title "Figure 2 IPOs 持有期間報酬走勢 - 以上市後第20日之收盤價買進";
run;

*** Figure 3  ***;
*** 計算各期間AR  ***;
data CalculateFirm_MarketBHR;
	infile "&path\CalculateFirm_MarketBHR.csv" dlm=',' firstobs=2 dsd;
	input Name :$9. n BHR MarketBHR;
		AR = BHR - MarketBHR;
	keep Name n AR;
run; 

*** 計算 總樣本的持有期間超額報酬 *** ;
proc sql;
	create table AllFirmAR_Data
	as select n, mean(AR) as ARMean
	from CalculateFirm_MarketBHR
	where n <= 750
	group by n;
quit;

data AllFirmAR;
	set AllFirmAR_Data;
	GroupSign = "總樣本";
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

*** 將資料區分為高中低積極組 ***;
data ARForPlot3;
	set ARForPlot3_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "高積極組";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "中積極組";
	end;
	else do;
		GroupSign = "低積極組";
	end;
	drop Name Allot;
run;

*** 計算高中低積極組各組的平均AR ***;
proc sql;
	create table DataForFigure3WithoutTotal
	as select n, GroupSign, mean(AR) as ARMean
	from  ARForPlot3
	where n <= 750
	group by n, GroupSign;
quit;

*** 合併高中低積極組與總樣本資料 ***;
data DataForFigure3;
	set DataForFigure3WithoutTotal AllFirmAR;
run;

*** 畫圖 ***;
proc sgplot  data = DataForFigure3;
 	scatter x=n  y=ARMean / group=GroupSign;
	title "Figure 3 IPOs 持有期間超額報酬走勢 - 以承銷價買進";
run;

*** Figure 4  ***;
data Firm_MarketReturnWithNumber;
	infile "&path\Firm_MarketReturnWithNumber.csv" dlm=',' firstobs=2 dsd;
	input Name :$9. Date :yymmdd10. Market $ Return MarketReturn n;
	if n > 20;
run;

* 計算每一間公司與市場各期的BHR (從第20天開始持有);
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

*** 計算AR (從第20天的股價開始計算) ***;
data CalculateARAfterDay20;
	set CalculateBHRAfterDay20;
	AR = BHR - MarketBHR;
	keep Name n AR;
run;

*** 計算 總樣本的持有期間超額報酬 *** ;
proc sql;
	create table AllFirmARAfterDay20_Data
	as select n, mean(AR) as ARMean
	from CalculateARAfterDay20
	where n <= 750
	group by n;
quit;

data AllFirmARAfterDay20;
	set AllFirmARAfterDay20_Data;
	GroupSign = "總樣本";
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

*** 將資料區分為高中低積極組 ***;
data ARForPlot4;
	set ARForPlot4_Data;
	if 0 <= Allot <  0.01620  then do;
		GroupSign = "高積極組";
	end;
	else if 0.01620 <= Allot < 0.43875 then do ;
		GroupSign = "中積極組";
	end;
	else do;
		GroupSign = "低積極組";
	end;
	drop Name Allot;
run;

*** 計算高中低積極組各組的平均AR ***;
proc sql;
	create table DataForFigure4WithoutTotal
	as select n, GroupSign, mean(AR) as ARMean
	from  ARForPlot4
	where n <= 750
	group by n, GroupSign;
quit;

*** 合併高中低積極組與總樣本資料 ***;
data DataForFigure4;
	set DataForFigure4WithoutTotal AllFirmARAfterDay20;
run;

*** 畫圖 ***;
proc sgplot  data = DataForFigure4;
 	scatter x=n  y=ARMean / group=GroupSign;
	title "Figure 4 IPOs 持有期間超額報酬走勢 - 以上市後第20日之收盤價買進";
run;


