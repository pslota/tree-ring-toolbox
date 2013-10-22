% scrn1.m -- a script file to begin screening of chronologies vs GHCN climate data
% 
% Screen a network of tree-ring chronologies for climate signal
% using output-error modeling vs GHCN station and site-interpolated
% seasonal climate series.
%
% D. Meko 5-11-00
%
% First in a sequence of functions for screening 
%
%  scr1.m -- chrons vs site interpolated and nearest ns stations within search radius
%  screen2.m -- uses results from screen1.m to make pointers to 
%		"best" station to pair with each site.  "Best" by length
%		of overlap data for modeling and proximity
%	screen3.m -- model chrons vs their paired climate series as
%		identified in screen2.m
%	screen4.m -- detailed diagostic modeling of a single chronology, 
%		using some input generated by a run of screen3.m with
%		O(1)==2
%  screen5.m -- prepare results for mapping by surfer
%  
%
%************* INPUT - from screen-prompted input or files
%
% T (mT x nT)r chronology indices; NaN filled; variable start and
%		end years allowed; mT years, nT chronologies
% C (mC x nC)r climate variable; NaN filled; variable start and 
%		end years allowed; mC years, nC stations
% YRS (2 x 2)i start, end years of 
%		row-1: T
%		row-2: C
% ds (1 x 1)r search radius (km)
% mx (1 x 5)i maximum setting for 
%  1-number of stations to find in search radius
%  2-number of B-operator parameters in a model
%  3-number of F-operator parameters
%  4-number of total parameters in model
%  5-number of ranked models to consider (nranked)
%
%---- next info normally loaded from distinfa.mat ---
%
% N (nT x 1)i number of stations found in search radius;
%		nT chronologies
% W (nT x mxs)i which stations (columns of C) grouped with this
%		chronology
% D (mD x nD)r distance (km) from chronology to each station in
%		search radius;  mD==nT; nD==mxs
%
% 
%************************* OUT ARGS **********************
%
%
% K2 (nT x mxs)i  significant signal?  meaning are any of the
%		parameters of the full-period model signifantly different
% 		from zero (2+ sdevs); 1=yes 0=no
% OB (nT x mxs)i  order of B-operator in model
% OF (nT x mxs)i  order of F-operator in model
% R1 (nT x mxs)r  corr coefficient between y(t) and u(t)
% R2 (nT x mxs)r  corr coefficient between y(t) and B u(t)
% G (nT x mxs)i number of significant (99% level) autocorrelation
%		coefficients  of residuals of model
% H (nT x mxs)i number of significant (99% level) cross-
%		correlations between input u(t) and residuals e(t)
% S (nT x mxs)r variance-explained fraction for best OE model
%		Computed as 1 - (var(residuals)/var(y)) 
%		for final model fit to entire data period
% Smore(nT x mxs)r incremental variance explained above OE(1,0) model
%     NaN if final model is OE(1,0)
% NY (nT x mxs)i number of years used to fit final OE model
%
%****************** STEPS IN SCREENING*************************
%
% Check input data
% Get distance settings, sites in search radius
% Model each chronology -- output series y(t)
%	Pull out submatrices of columns
%	Loop over "near" climate stations -- input series u(t)
%		Pull row subset for valid overlap years
%		Loop over potential models
%			Find best model
%		End Loop
%		Fill slots in R1, R2, etc
%	End Loop
% 
%
%******************** NOTES *************************************
% 
% I assume you ran regcli5.m, seas01.m, seas02.m to get the site-interpolated
% monthly data and convert it to seasonal
%
% Function oesplit.m is called to perform split-sample modeling;
% calibrate on first half and verify on second; then vice versa;
%
% Details of the split-sample modeling are covered in 
% oesplit.m
%
% Coordinate file TC and CC are assumed to be in mapping format,
% that is, decimal long (negative west) followed by decimal
% latitude
%
% Modeling period is flexible to differing time coverage of the
% climate station series and chronologies;  model is fit to 
% full common period for any pair
%
% The call to near3 is hard-coded to get the nearest mx(1) stations,
% regardless of whether they are in the search radius.  To change
% this, see instructions for near3.m and pass a different option
% to near3.m
%
% Originally written as a function, but because of "stack" errors,
% used as a script file.
%****************** CHECK INPUT DATA, SIZE, ALLOCATE

clear

tstart=clock; % start timer to check elapsed time for running script (see elapsed)

% Help in file selection by specifying letter code for tree-ring set
keylet=input(['Letter code for analysis (e.g., ''a''):  '],'s');


% GET TSM OF TREE-RING DATA

file5=['tsm' keylet];
path5='c:\wrk6\';
pf5=[path5 file5];
eval(['data=load(''' pf5 ''');'])  % tree-data will be in X, but with year
% in col 1
if ~isfield(data,'X') | ~isfield(data,'N') ;
   error(['X not in ' pf5]);
end;
T=data.X;  % time series matrix of treering data, index units x 1000
Tnm=data.N;  % char matrix (8 char) of tree-ring chron filenames
clear data;
yrT=T(:,1);   % year vector for T
T(:,1)=[];
[mT,nT]=size(T); % size of tree-ring matrix
txtsum=['Analysis run on ' date];
txtsum=char(txtsum,['Tree-ring data from ' pf5]);

% Diagnostics mode?
kdiag=questdlg('Diagnostics mode (one site only)?');
if strcmp(kdiag,'Yes');
   prompt={'Enter site number:'};
   def={'1'};
   dlgTitle='Site number for detailed analysis';
   lineNo=1;
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   ngo=str2double(answer{1});
   nsp=ngo;
else; % by default, analyze all sites, but allow specify first and last
   prompt={'Enter starting and ending site number:'};
   def={['1   ' num2str(nT)]};
   dlgTitle='Start and end site numbers for analysis';
   lineNo=1;
   answer=inputdlg(prompt,dlgTitle,lineNo,def);
   ngo=str2num(answer{1});
   nsp=ngo(2);
   ngo=ngo(1);
end;
if nsp>nT; 
   error('nsp higher than col dimension of tree-ring matrix T');
end;
if ngo>nsp;
   error('ngo greater than nsp');
end;
txtsum=char(txtsum,['Start and end site numbers for run: ' int2str(ngo) '-' int2str(nsp)]);


% TELL THE TYPE OF CLIMATE VARIABLE AND THE SEASON FOR ANALYSIS

% Type of climate variable
kmen1=menu('Choose type of climate variable',...
   'P == precip',...
   'D == maximum Temperature',...
   'E == minimum Temperature',...
   'M == mean Temperature');
if kmen1==1; 
   ctype='P';
   sitefile='siteinf';
   stnfile='stninf';
elseif kmen1==2;
   ctype='D';
   sitefile='siteinfd';
   stnfile='stninfd';
elseif kmen1==3;
   ctype='E';
   sitefile='siteinfe';
   stnfile='stninfe';
elseif kmen1==4;
   ctype='M';
   sitefile='siteinfm';
   stnfile='stninfm';
end;

dirmat1='c:wrk0\'; % where to get mtx of seasonalizedstn climate files

% Season of climate variable
S1={'A:Nov-Mar','B:May-Oct','C:Nov-Oct','D:Oct-Sept','E:June-Sept','F:July-Aug'};

kmen2=menu('Choose season of climate variable',S1);
if kmen2==1; 
   cseas='A';
elseif kmen2==2;;
   cseas='B';
elseif kmen2==3;
   cseas='C';
elseif kmen2==4;
   cseas='D';
elseif kmen2==5;;
   cseas='E';
elseif kmen2==6;
   cseas='F';
end;
txtsum=char(txtsum,'SEASON CODING');
txtsum=char(txtsum,char(S1));
txtsum=char(txtsum,blanks(5));
txtsum=char(txtsum,['Climate variable = ' ctype]);
txtsum=char(txtsum,['Climate season (see seas02.m) = ' cseas ]);

% FORM PREFIX FOR INPUT SEASONAL GRIDPOINT CLIMATE FILE
prefc1=['G' ctype cseas];

% LOAD INFO ON THE INTERPOLATION SCHEME
miscfile=['misc' ctype '.mat']; % file for misc info (dsrch, dcrit, etc)
[file2,path2]=uigetfile(miscfile,'Infile with dsrch, dcrit,nmax');
pf2=[path2 file2];
eval(['load ' pf2  ' dsrch dcrit nmax;']);
strtemp0=sprintf('%s',['Interpolation settings from ' pf2]);
strtemp1=sprintf('  dsrch = %6.2f km',dsrch);
strtemp2=sprintf('  dcrit = %6.2f km',dcrit);
strtemp3=sprintf('  nmax = %4d',nmax);
txtsum=char(txtsum,strtemp0);
txtsum=char(txtsum,strtemp1);
txtsum=char(txtsum,strtemp2);
txtsum=char(txtsum,strtemp3);
clear strtemp0 strtemp1 strtemp2 strtemp3 pf2 file2 path2;



% LOAD THE TSMS OF SEASONAL CLIMATE FOR POINTS AND STATIONS

% Gridpoint data
path3='c:\wrk0\';
file3=['G' ctype cseas];
pf3=[path3 file3];
eval(['load ' file3 '  X yr inone;']);
G=X; yrG=yr; inoneG=inone;  clear X inone yr;   % G is the tsm of 
[mG,nG]=size(G);
txtsum=char(txtsum,['Seasonalized interpol climate data from ' pf3]);
strtemp1=['   ' int2str(mG) ' years x ' int2str(nG) ' points'];
strtemp2=['   Years: ' int2str(min(yrG)) ' - '  int2str(max(yrG))];
txtsum=char(txtsum,strtemp1);
txtsum=char(txtsum,strtemp2);
clear pf3 file3 path3 strtemp1 strtemp2;

% Station climate data
path3='c:\wrk0\';
file3=[ctype cseas];
pf3=[path3 file3];
eval(['load ' file3 '  X yr;']);
C=X; yrC=yr; clear X inone yr;   
[mC,nC]=size(C);
txtsum=char(txtsum,['Seasonalized station climate data from ' pf3]);
strtemp1=['   ' int2str(mC) ' years x ' int2str(nC) ' stations'];
strtemp2=['   Years: ' int2str(min(yrC)) ' - '  int2str(max(yrC))];
txtsum=char(txtsum,strtemp1);
txtsum=char(txtsum,strtemp2);
clear pf3 file3 path3 strtemp1 strtemp2;


% CHECK COL SIZES OF TREE MATRIX AND POINT CLIMATE MATRIX
if nT ~= nG;  
   error('Tree matrix and interpolated climate matrix must be same column size');
end;


% INITIALIZE STORAGE FOR GLOBAL STATISTICS

% Next for complete overlap period, not necessarily unbroken
Rg=repmat(NaN,nT,1); % gridpoint correlations, y(t) vs u(t)
Rs=repmat(NaN,nT,nmax); % tree vs station climate correlations
NRg=repmat(NaN,nT,1); % sample size for all-years correlations, gridpoint
NRs=repmat(NaN,nT,nmax); % sample size for correlations, y(t) vs individual u(t) at stations

% Next for the point modeling period, which requires unbroken data
R1=repmat(NaN,nT,1); % gridpoint correlations y(t) vs B u(t) for oe(1,0) model
R2=repmat(NaN,nT,1); % gridpoint correlation, y(t) vs B/Fu(t) for final oe(nb,nf) model
NR1=repmat(NaN,nT,1); % sample size for R1
NR2=repmat(NaN,nT,1); % sample size for R2
% variance explained fraction, defined as
%   1-[var(noise)/var(y)]
S1=repmat(NaN,nT,1); % variance explained fraction for OE(1,0) point model
S2=repmat(NaN,nT,1); % .... OE(nb,nf) model
% Other OE(nb,nf) model info
OB=repmat(NaN,nT,1);  % order of B operator
OF=repmat(NaN,nT,1); % order of F operator
K2=repmat(NaN,nT,1); % logical: any signif parms in model?
H= repmat(NaN,nT,1); % number of sig autocorrelations of residuals, among lags 0-10
D= repmat(NaN,nT,1); %  number of sig cc of res with input, lags 0-10
Q=repmat(NaN,nT,1); % "way" best model was finally selected

FLN=cell(nT,nmax); % filenames of nearby climate stations



% GET CLIMATE STATION-POINT INFO

% Get the col indices of "near" stations in station climate matrix
eval(['load ' sitefile ' Nnear Inear;']);
% Nnear is number of nearby stations.
% Inear is index to station ids, via rows of flnm in station info file
eval(['load ' stnfile ' flnm SS;']);
% flnm{m} holds the .mat station file prefix for mth station


% Pointers not varying from chron to chron
% Find common period, possibly with internal NaNs
yron = max([min(yrG) min(yrT)]); % first year of common period
yroff= min([max(yrG) max(yrT)]); % last year of common period
L1=yrT>=yron & yrT<=yroff;
L2=yrG>=yron & yrG<=yroff;
yrCTon = max([min(yrC) min(yrT)]); % first year of common period
yrCToff= min([max(yrC) max(yrT)]); % last year of common period
LCT1=yrT>=yrCTon & yrT<=yrCToff;
LCT2=yrC>=yrCTon & yrC<=yrCToff;



%************** LOOP OVER CHRONOLOGIES

for n =ngo:nsp;
   nnear=Nnear(n); % number of nearby sites used in interpolation
   if nnear>0;
      inear=Inear(n,1:nnear); % xref to interpolator stations
      % Store the station filenames (prefix to .mat)
      for m = 1:nnear;
         FLN(n,m)=flnm(inear(m));
      end;
      
      % Get tree-ring index, corresp to years yrT, 
      z=T(:,n); % tree-ring index, units 1000xindex
      % Get the point climate series
      
      g=G(:,n); % units climatic
      
      % Compute simple r for point data
      z1=z(L1);
      g1=g(L2);
      L3=~isnan(z1) & ~isnan(g1);
      sumL3=sum(L3);
      if sumL3>0;
         z2=z1(L3);
         g2=g1(L3);
      else;
         error(['No common data for point ' int2str(n)]);
      end;
      r = corrcoef(g2,z2);
      Rg(n)=r(1,2);
      NRg(n)=sumL3;
      clear L3 z1 g1 sumL3 z2 g2 r ;
      
      % GET & STORE POINT-MODEL TIME SERIES AND SUPPORTING INFO
      
      u=g; y=z; % store time seriie, retaining original full-length tree 
      % series in z for later use vs station climate series.
      
      % Find row index to first and last valid tree ring and climate data.
      % Get the data
      Lg1=~isnan(u); 
      i1=nanmin(find(Lg1));
      i2=nanmax(find(Lg1));
      yru=yrG(i1:i2);
      u=u(i1:i2);
      Lz1=~isnan(y); 
      i1=nanmin(find(Lz1));
      i2=nanmax(find(Lz1));
      yry=yrT(i1:i2);
      y=y(i1:i2);
      
      % Get the data in common 
      yrgo = max([min(yru) min(yry)]);
      yrsp = min([max(yru) max(yry)]);
      Lu=yru>=yrgo & yru<=yrsp;
      Ly=yry>=yrgo & yry<=yrsp;
      u=u(Lu); yru=yru(Lu);
      y=y(Ly); yry = yry(Ly);
      clear Lz1 i1 i2 yrz yrgo yrsp Lu Ly ;
      
      % Cull longest consecutive non-NaN period of climate data in the common period
      [ii1,ii2]=consec(u); % row index to desired period
      yr = yru(ii1:ii2);
      u=u(ii1:ii2);
      
      % Cull corresp period of tree-ring data
      Ly=yry>=min(yr) & yry<=max(yr);
      y=y(Ly);
      clear Ly yry yru ii1 ii2;
      % now have model data u(t), y(t) and year vector yr
      
      % In diagnostics mode, save data for this site so that can use with GUI ident.
      if strcmp(kdiag,'Yes');
         vlist=['Site # ' int2str(n)];
         vlist=char(vlist,' u = input');
         vlist=char(vlist,' y = output');
         vlist=char(vlist,[' years = ' int2str(min(yr)) ' - ' int2str(max(yr))]);
         save dufus vlist yr u y ;
         return;
      end;
      
      % CORRELATE TREE-RING SERIES WITH INDIVIDUAL STATION CLIMATE SERIES
      
      for m=1:nnear;
         ithis=inear(m);
         c=C(LCT2,ithis); % station climate series, for rows overlapping in C and T
         w=T(LCT1,n); % tree ring series
         Lgood=~isnan(c) & ~isnan(w);
         sum1=sum(Lgood);
         if sum1>0;
            r=corrcoef(c(Lgood),w(Lgood));
            r=r(1,2);
            Rs(n,m)=r;
            NRs(n,m)=sum1;
         else;
            error('no years in common between tree-ring series and station climate');
         end;
      end;
   else; % nnear ==0 
      % No action.  Rg, NRg, Rs, NRs are NaN
   end;
   
   
   % STOPPED HERE
   % OE MODELING OF U(T) --> Y(T), WHERE U(T) IS SITE-INTERP. SEASONAL CLIMATE VARIABLE
   
   
end; % for n=ngo:nsp






% Get the climate data tsm
fn5=['C*.mat'];
txt5='CP#.mat  -- climate data,season #';
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]);  % climate data is C
clear X path5 file5 N
% T and C should now be in workspace

% Get the years info and miscellanous settings
fn5=[keylet '*.mat'];
txt5=[keylet 'P#IS1.MAT -- misc screen1.m input']; 
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]); 

% Get the site-to-station distance info
fn5=['DIST' keylet '.mat'];
txt5='DIST?.MAT -- distance info'; 
[file5,path5]=uigetfile(fn5,txt5);
eval(['load ',path5,file5]); 

clear path5 file5


a=NaN;

[mT,nT]=size(T);
[mC,nC]=size(C);

[m1,n1]=size(YRS);
if m1~=2 | n1~=2
	error('YRS must be 2 x 2');	
end

[m1,n1]=size(mx);
if m1~=1 | n1~=5,
	error('mx must be 1 x 5')
end
maxs=mx(1); % maximum number of stations to grab within search
	% radius; use the nearest maxs stations
nb = mx(2); % maximum allowable order of B operator
nf = mx(3); % maximum allowable order of F operator
ntot = mx(4); % maximum total number of parameters allowed
nranked=mx(5); % number of "good" models to consider before
		% selecting best OE model



% Initialize some matrices
R1=a(ones(nT,1),ones(maxs,1)); % Correlations y(t) vs u(t)
R2=a(ones(nT,1),ones(maxs,1)); % Correlations y(t) vs Bu(t)
S1=repmat
S=a(ones(nT,1),ones(maxs,1)); % Variance-explained fraction
Smore=a(ones(nT,1),ones(maxs,1)); % Variance-explained fraction above OE(1,0)
OB=a(ones(nT,1),ones(maxs,1)); % B-operator order for best model
OF=a(ones(nT,1),ones(maxs,1)); % F-operator order for best model
K2=a(ones(nT,1),ones(maxs,1)); % any signif params in final model?
H= a(ones(nT,1),ones(maxs,1)); % number of sig autoc of residual
G= a(ones(nT,1),ones(maxs,1)); % number of sig cc of res with input
Q=a(ones(nT,1),ones(maxs,1)); % "way" best model was finally selected
NY=a(ones(nT,1),ones(maxs,1)); % number of years for final OE model


%**************** ADJUST CLIMATE MATRIX C SO ONLY
% THE LONGEST CONSEC NON-NAN SEQUENCES REMAIN NON-NAN
% In other words, the result will have no internal imbedded NaNs
for n = 1:nC;
	c1=C(:,n); % temporary storage of this stations climate vector
	c2=a(ones(mC,1),:); % same size vector of NaN
	[ii1,ii2]=consec(c1); % start,end row indices of good stretch
	nsub = ii2-ii1+1; % number of values in good stretch
	c2(ii1:ii2)=c1(ii1:ii2); % insert the good stretch in c2
	C(:,n)=c2; % replace column of C
end
clear c1 c2 nsub	



%*************** LOOP OVER CHRONOLOGIES ************************



% Build a matrix of OE model structures.  These will be the
% candidate models.
nn=struc3(1:nb,0:nf,0,ntot); % no-delay models only


% Start the loop over chronologies
for n =1:nT; %575:584; %1:nT;
	ns=N(n); % number of stations found for this chronology
	C1=C(:,W(n,1:ns)); % col sub-matrix of the "near" stations
	z= T(:,n); % all rows of data for this chronology
	
	for k = 1:ns;
		disp(['On chron ',int2str(n),' station ',int2str(k)])
		c = C1(:,k);

		% Get the valid data for common period; need input climate
		% series u and output chronology y, and year vector yrs
		[u,y,yrs]=overlap(c,z,flipud(YRS));

		% Get correlation coefficient between u and y
		rr1= corrcoef([y u]);
		r1=rr1(1,2);

		nyrs = length(u); % number of years for OE modeling
		%  OE-model the series with split-sample validation
		Z=[y u];
		[s,r2,ob,of,f1,f2,way,k2,smore]=oefit(Z,yrs,nn,nranked,1);

		% Store the results for this chronology/station
		K2(n,k)=k2;
		OB(n,k)=ob;
		OF(n,k)=of;
		G(n,k)=f1;
		H(n,k)=f2;
		R1(n,k)=r1;
		R2(n,k)=r2;
      S(n,k)=s;
      Smore(n,k)=smore;
		NY(n,k)=nyrs;
      %Q(n,k)=way;
      Q(n,k)=NaN;
	end

end; % of "n=" loop over chronologies

elapsed=etime(clock,tstart);

set2=' K2 OB OF R1 R2 G H S Smore NY ';

% Store result in a .mat file of the user's choice
disp('Example file name for next prompt is AP1OS1.mat')
disp(' meaning tree-matri A')
disp('		Precip')
disp('		season 1 (nov-apr)')
disp('		Output, Screen1.m')
disp(' press return')
pause
[file1, newpath] = uiputfile('*.mat', '?P#OS1.MAT ');
eval(['save ',newpath,file1,set2])
