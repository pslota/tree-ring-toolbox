function [Lcull,logscrn,Lneg]=screen6a
% screen6a: cull network of sites with signal for one season and not another
% CALL: Iuse=screen6a;
%
% Meko 8-26-97
%
%
%******************* screen6.m will need these files *************
%
% siteinf?.txt -- produced from foxpro by siteinf?.qpr
% gosp?.dat -- produced from foxpro by gosp?.qpr
% crnxy?.dat -- produced from foxpro by crnxy?.qpr
% ap1os5.dat -- produced by screen5.m on season desiring signal for
% ap2os5.dat -- produced by screen5.m on season for which demand no signal
%
%
%***************** screen6a.m will produce these ****************
%
% Lcull -- logical pointer to chrons (cols of tsm) selected
% Lneg -- logical flag to chrons with negative simple r, clim vs tree
% logscrn -- string matrix summarizing selection criteria
%
% ?p#tbl.txt -- ascii text file summarizing results
% ?p#tree.sov -- ascii strung-out vector of tree-ring indices
%		for selected sites, with -9.99 as missing values
% ?p#tree.mat -- X= tsm corresponding to the strung-out vector
%		yr -- year vector for X
%		scrit -- critical variance-explained fraction, or empty
%			if screened by significant-parameter criterion
%
%***************** screen6a.m allows selection of chronogies by ****
%
% year coverage; then for given year coverage:
% variance-explained fraction of best-fit OE model, or
% yes or no for any OE parameters significant at 2 sdevs

% Help in file selection by specifying letter code for tree-ring set
char=input('Letter code for tree-ring matrix: ','s');

% Help in file selection by specifying season "number", where, for
% example in one application, 
% 1=nov-apr
% 2=may-oct
% 3=aug-jul
cseas1=input('Number code for season that want signal for: ','s');
cseas2=input('Number code for season that want no signal for: ','s');

% Help in file selection by specifying "P" for pcp
% or "T" for temp
cvar=input('Climate variable  -- P or T: ','s');
if cvar=='p';
	cvar=upper(cvar);
end
if cvar=='t';
	cvar=upper(cvar);
end
if cvar~='P' & cvar ~= 'T',
	error('cvar must be P or T')
end



%***********  GET THE SCREEN5.M OUTPUT FOR 'SIGNAL' SEASON
fn5=[char '*os5.dat'];
txt5='screen5.m file output for signal season';
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]);  
eval(['ZY = ' strtok(file5,'.')  ';']);

%***********  GET THE SCREEN5.M OUTPUT FOR 'NO SIGNAL' SEASON
fn5=[char '*os5.dat'];
txt5='screen5.m file output for no-signal season';
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]);  
eval(['ZN = ' strtok(file5,'.')  ';']);


%************ GET THE XY MAPPING COORDINATES
fn5=['crnxy' char '.dat'];
txt5='crnxy?.dat? (in c:\wrk6)-- tree-ring x,y coords';
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]);  
eval(['fxy = '  'crnxy' char ';']);

%**********   GET THE START AND END YEARS
fn5=['gosp' char '.dat'];
txt5='gosp?.dat? (in c:\wrk6)-- tree-ring start,end years';
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]);  
eval(['IYRS = ' 'gosp' char ';']);
% Subract 8000 from values in any row where ending year >2030
L7=IYRS(:,2)>2030;
if ~isempty(L7)
	temp=IYRS(L7,:);
	temp=temp-8000;
	IYRS(L7,:)= temp;
end

%**********  GET THE SITE INFO

fn5=['sitelst' char '.txt'];
txt5='sitelst?.txt (in c:\wrk6)-- siteinfo file';
[file5,path5]=uigetfile(fn5,txt5);
ff=[path5 file5];

%***************************************************
% Build the logical matrix L whose columns will point to 
% selected chronologies

% Initialize text strings of screening info
T1=' '; % year coverage
T2=' '; % minimum decimap proportion of variance explained
T3=' '; % require at least 1 signif model parameter?
T4=' '; % at least 1 param signif OR  high VE fraction
T5=' '; % at least 1 signif param for signal season, none for no-signal season,
% and more than some threshold VE fraction for signal season

ns1=size(ZY,1);  % number of chronologies before screening
if size(ZN,1) ~= ns1; error('Diff # of rows in ZN and ZY '); end;

% First level of screening by time coverage
yrgo=input('Chron must start in this year or earlier:  ');
yrsp=input('Chron must end in this year or later:  ');
T1 = ['Required year coverage : ' int2str(yrgo) '-' int2str(yrsp)];
L1 = IYRS(:,1)<=yrgo & IYRS(:,2)>=yrsp;

L2=[];
k2=0;
while k2==0;
k1=0;
k1=menu('Choose a screening method',...
'VE high for signal season, low for no-signal season',...
'A signif OE param for signal season, none for no-signal season',...
'At least one param signif OR high VE fraction in signal season, neither in non',...
'Signif param and high VE for one, no signif param and low VE for other',...
'View total and re-do the screening',...
'Abort',...
'Quit, and move on to building output matrices and files');
if k1==1; % screen by pctg variance explained
   pcty=input('Dec fraction signal-season VE>=:  ');
   pctn=input('Dec fraction no-signal-season VE<: ');
   T2=['Dec fraction VE in signal seas  >=' num2str(pcty)];
   T2=str2mat(T2,['Dec fraction VE for no-signal season <' num2str(pctn)]);
   T3=' ';   T4=' '; T5=' ';
	L2 = ZY(:,6)>=pcty  & ZN(:,6)<=pctn;
	Lcull=L1 & L2;
elseif k1==2; % require a model parameter significant
   T2=' ';  T4=' '; T5=' ';
   T3 = ['At least 1 model parameter signif for signal season'];
   T3=str2mat(T3,['  none signif for no-signal season']);
	L2 = ZY(:,9)==1  & ZN(:,9)==0;
	Lcull=L2;
elseif k1==3; % An OE param signif or high VE for signal season, neither for non-signal seas
   T2=' '; T3=' '; T5=' ';
   pcty=input('Dec fraction signal-season VE >= ');
   pctn=input('Dec fraction no-signal-season VE < ');
   T4 = ['At least 1 param signif OR VE >= ' num2str(pcty)];
   T4=str2mat(T4,['  and no signif params and VE< ' num2str(pctn)]);
   T4=str2mat(T4,['  for non-signal season']);
	L2 = (ZY(:,6)>=pcty | ZY(:,9)==1) & (ZN(:,6)<pctn & ZN(:,9)==0);
	Lcull = L1 & L2;
elseif k1==4; % two season screening
   T2=' '; T3=' '; T4=' ';
   pcty=input('Decimal fraction signal-season VE >=  ');
   pctn=input('Decimal fraction no-signal-season VE <  ');
   T5='Two conditions must be fullfilled:';
   T5=str2mat(T5,['Signal season VE at least ' num2str(pcty)]);
   T5=str2mat(T5,['  and at least one OE param significant, AND ']);
   T5=str2mat(T5,['No-signal season VE less than ' num2str(pctn)]);
   T5=str2mat(T5,['  or no OE params signif']);
   L2=(ZY(:,6)>=pcty & ZY(:,9)==1)  &  (ZN(:,9)==0 | ZN(:,6)<pctn);
   Lcull=L1 & L2;
elseif k1==5; % view total and redo screening
	if isempty(L2)
		break
	else 
		ns2=sum(Lcull);
      disp(['Number of sites selected = ',int2str(ns2)]);
      disp('Press any key to continue');
      pause;
      
   end
   
elseif k1==6; % abort, to avoid having to go thru rest of pgm
	error('You decided to abort program , OK')
elseif k1==7;
	k2=1;
end
end; % of while k2


logscrn = str2mat(T1,T2,T3,T4,T5);



%--------------  MANUAL MASKING OUT OF ANY OTHER CHRONOLOGIES?

k2=0;
while k2==0;
k1=0;
k1=menu('Manual mask option; choose one',...
'Manual mask another site',...
'Quit, and move on to building output matrices and files');
if k1==1; % You want to mask out a chronology
	ikill = input('Sequence number of site to drop: ');
	T6=['Manually masked out site ' int2str(ikill)];
	logscrn = str2mat(logscrn,T6);
	if Lcull(ikill)==0;
		fclose all
		error(['Site ' ikill ' already masked']);
	else;
		Lcull(ikill)=0;
	end
elseif k1==2;
	k2=1;
end
end; % of while k2



ns2=sum(Lcull);

disp(['Final number of culled sites = ' int2str(ns2)]);
pause(2)


%**********************  Logical pointer to chrons with negative tree vs clim corr

Lneg = logical(ZY(:,20));  % flag to negative simple r for signal season -->* in
   % output table far right



%************************  BUILD OUTPUT TABLE

fid1=fopen(ff,'r');
fid2=fopen('jack1.dat','w');
fid3=fopen('jack2.dat','w');
fmt1a='%3.0f %3.0f %s %s %5.0f %4.0f ';
fmt1b='%s %s %s %7.2f %5.2f %4.0f\n';

fmt2a='%3.0f %3.0f %s  %5.2f %5.2f %5.0f %4.0f ';
fmt2b='%1.0f %4.0f %4.0f %3.0f %1.0f  %1.0f %1.0f %5.2f %5.2f%s\n';

blank1=' ';

p1b1='  N1 N2   FILE       SITE  NAME                    BEG  END '; 
p1c1='___ ___ _______ ________________________________ _____ ____ ';
p1b2='SPEC CTY ST  LONG    LAT  EL-M'; 
p1c2='____ ___ __ _______ _____ ____';

p2a1='                   FIVE-STATION RESULTS ';
p2b1='         .CRN      ____________________ ';
p2c1=' N1  N2  FILE      SMAX  SMIN DMAX DMIN ';
p2d1='___ ___ ________  _____ _____ ____ ____ ';
p2a2='      FINAL MOODELING             ';
p2b2='  ________________________________'; 
p2c2='C  STN D(KM) YR S  B F    R2    EV'; 
p2d2='_ ____ ____ ___ _  _ _ _____ _____';


fprintf(fid2,'%s%s\n%s%s\n\n',p1b1,p1b2,p1c1,p1c2);
fprintf(fid3,'%s%s\n%s%s\n%s%s\n%s%s\n\n',...
	p2a1,p2a2,p2b1,p2b2,p2c1,p2c2,p2d1,p2d2);

lnpg=75; % repeat header after every lnpg chronologies on printout
j=0;
for n=1:ns1
	c = fgetl(fid1);
	if Lcull(n);
	disp(['Working on site # ',int2str(n)]);
	j = j+1;
	if  j>1 & (rem(j-1,lnpg)==0); % repeatcol headings
		fprintf(fid2,'\n\n%s%s\n%s%s\n\n',p1b1,p1b2,p1c1,p1c2);
		fprintf(fid3,'\n\n%s%s\n%s%s\n%s%s\n%s%s\n\n',...
			p2a1,p2a2,p2b1,p2b2,p2c1,p2c2,p2d1,p2d2);
	end
	s1=j; % sequential number of selected sites
	s2=n; % which column (+1) is this chron in master tree-ring tsm
	s3=c(1:15); % chron .crn file name (before suffix)
		s3=strtok(s3,'.');
		nn = length(s3);
		s3=s3(nn:-1:1);
		s3=deblank(s3);
		nn=length(s3);
		s3=s3(nn:-1:1); % only as long as chronfn, max of 8 chars
		if nn~=8;
			ndif=8-nn;
			s3=[s3 blanks(ndif)];
		end
	s4=c(16:46); % site name
	s5=IYRS(n,1); % first year
  s6=IYRS(n,2); % last year
	s7=c(98:101); % species
	s8=c(53:55); % country (3 char max)
	s9=c(47:48); % state (2 char max)
	s10=fxy(n,1); % long
	s11=fxy(n,2); % latitude
	s12=c(91:94); % elev (m)
		n12=str2num(s12);
		if isempty(n12);
			n12=0;
		end
	s13=ZY(n,15); % highest EV for five nearest stations
	s14=ZY(n,17); % lowest EV for five nearest stations
	s15=ZY(n,18); % will be km to nearest clim stn
	s16=ZY(n,19); % will be km to furthest station of nearest 5
	s17=ZY(n,4); % class of data for modeling (1 or 2)
	s18=ZY(n,12); % which station (col of climate data) used
	s19=ZY(n,13); %distance in km to station
	s20=ZY(n,14); %number of years in full-model period
	s21=ZY(n,9); % 1 if any OE params sign at 2 sdev, 0 otherwise
	s22=ZY(n,7); % B-order
	s23=ZY(n,8); % F-order
	s24=ZY(n,5); % squared correlation between input and output series
   s25=ZY(n,6); % EV dec pctg
   
   % Asterisk if negative r clim vs tree
   if ZY(n,20)==1;
      s26='*';
   else
      s26=blank1;
   end
   
   
	fprintf(fid2,fmt1a,s1,s2,s3,s4,s5,s6);
	fprintf(fid2,fmt1b,s7,s8,s9,s10,s11,n12);

	fprintf(fid3,fmt2a,s1,s2,s3,s13,s14,s15,s16);
	fprintf(fid3,fmt2b,s17,s18,s19,s20,s21,s22,s23,s24,s25,s26);

	end; % of if Lcull(n)
end
	
fclose(fid1);
fclose(fid2);
fclose(fid3)


% Build x,y (long-lat) plot file, with EV  for use in surfer
xys = [fxy(Lcull,:) ZY(Lcull ,6)];
fn5=['xy*.dat'];
txt5='xy file for surfer map of EV';
[file5,path5]=uiputfile(fn5,txt5);
eval(['save ' path5 file5 ' xys ' '-ascii']);  

% Save the logical vector to select columns from master tsm of
% tree data to give malcolm subset
fn5=['L' '*.mat'];
txt5='File ?P#OS6.mat, to hold logscrn and Lcull the logical col pointer to selected sites';
[file5,path5]=uiputfile('*os6.mat',txt5);
eval(['save '  path5 file5   ' logscrn Lcull Lneg yrgo yrsp']);
