function fox2pth
% fox2pth: Build path\filename file from Foxpro information on chronologies. 
% CALL: foxpth;
%
% D Meko 4-22-96
%
%************** SCREEN PROMPTED INPUT FILES *************
%
% file1 -- "cross-reference" file.  Each line of this file has
%		a key and a path, separated by spaces. This file
%		would typically be built manually by the user with a text 
%		editor.  An example of lines:
%
%			nw d:\icrns\nwusa     .... alaska
%			nwusa d:\icrns\nwusa    ... oregon, wash, etc
%			southusa d:\icrns\southusa
%			sw d:\icrns\swusa
%			midusa d:\icrns\midusa
%			updates d:\icrns\updates
%			updates\ d:\icrns\updates
%			canada d:\icrns\canada
%			mexico d:\icrns\mexico
%
% file2 -- 'key-.crn' file.  Each line contains a key and a name of
%		a chronology file.  This file is generated by a Foxpro
%		query from an existing database.  An example of some lines:
%
%		southusa  	 ak001.crn
%		southusa	ak002.crn
%		swusa  	nv01.crn
%		nwusa  	wa03.crn
%	
%
%
%************** SCREEN PROMPTED OUTPUT FILE *************
%
%
% file3 -- 'path/filename' file.  Same number of rows as in file2
%		 An example of some rows:
%
%			c:\wrk10\ak001.crn
%			c:\wrk10\ak002.crn
%			d:\wrk5\nv01.crn
%			d:\projs\wk4\wa03.crn
%
%
%*************** USE ****************************************
%
% Written for NOAA western NA tree-ring study. Had ITRDB .crn files
% in various subdirectories.  Each chronology has an entry (record)
% in a FoxPro database.  The database includes fields for the 
% .crn file name (e.g., 'ak001.crn'), and for a 'key' that can
% be used to build the path to the file (e.g., 'sw').  Needed a 
% function to look at the key, cross-reference to a path, and 
% put the path/filename for each file into an output file.  


file1=uigetfile('*.dat','Cross-reference input file')
file2=uigetfile('*.dat','key-space-crn input file')
fid1 = fopen(file1,'r+')
fid2= fopen(file2,'r+')


% Split the cross-reference matrix into two string matrices,
% same row size.  S1 will hold the "path key" from the database.
% S2 will hold the corresponding path in the computer.
n1=0; % counter for number of lines in file1
while 1
	line = fgetl(fid1);
	if ~isstr(line), break, end
	n1=n1+1;
end

disp('Finished initial read of file1 for record count')
disp(['number of lines in file1 is ',int2str(n1)])

fseek(fid1,0,-1); % rewind file1
S1=[];
S2=[];
for n = 1:n1;
	line=fgetl(fid1);
	line=deblank(line);
	L1 = isspace(line);
	if sum(L1)==0
		fclose(fid1)
		error('Parts of cross-ref file should be separ by spaces')
	end
	i1=find(L1);
	isp1=i1(1)-1;
	igo2=max(i1)+1;
	isp2=length(line);
	S1=str2mat(S1,line(1:isp1));
	S2=str2mat(S2,line(igo2:isp2));
end
S1(1,:)=[];
S2(1,:)=[];
fclose(fid1);

disp('Finished splitting xref file names')
 

% Read in the second file, containing the .crn filenames
n2=0; % counter for number of lines in file2
while 1
	line=fgetl(fid2);
	if ~isstr(line), break, end
	disp(line)
	n2=n2+1;
end

disp('Finished intial read of file2')
disp(['number of lines in file2 is ',int2str(n2)])
disp('Now rewinding and re-reading file2')

T=[];
fseek(fid2,0,-1); % rewind file2
for n=1:n2;
	line=fgetl(fid2);
	T=str2mat(T,line);
end
T(1,:)=[];
fclose(fid2)

disp('Finished second read of file2')
disp('Now starting to split the key-crn records')

% Split the key-.crn records into two string matrices:
% R1 will be the key, T1 will be the .crn filename
R1=[];
T1=[];
for n=1:n2;
	line=T(n,:);
	% Strip off trailing and leading blanks
	line=deblank(line);
	line=fliplr(line);
	line=deblank(line);
	line=fliplr(line);

	% Find internal blanks
	L1 = isspace(line);
	if sum(L1)==0
		error('Cross-ref file should spaces separator')
	end
	i1=find(L1);
	ns = length(i1); % how many blanks internal
	nsp1=i1(1)-1;
	ngo2=max(i1)+1;
	nsp2=length(line);
	R1=str2mat(R1,line(1:nsp1));
	T1=str2mat(T1,line(ngo2:nsp2));
end	
R1(1,:)=[];
T1(1,:)=[];

disp('Finished splitting key-crn records')
disp('Starting to build file names')


% Build the path/filenames
B=[];
% Loop over each chronology name
for n=1:n2;
   
	c=deblank(T1(n,:));  % .crn file
	% Get the correct path
	temp = deblank(R1(n,:)); % e.g., "nw"
	k1=0;
   for j = 1:n1; % loop over the paths in cross reference file
      if c(1:5)=='wa085';
         disp('here');
      end;
      
		s = deblank(S1(j,:));
		if strcmp(temp,s)
			a=deblank(S2(j,:)); % path
			b=[a '\' c];
			B=str2mat(B,b);
			disp(b)
			k1=1;
			break
		end
		if k1, break, end
		if j==n1 & k1==0,
			disp(['n = ',int2str(n)])
			disp(['temp = ',temp])
			disp(['c = ',c])
			disp(['s = ',s])
			error(['No match; j = ',int2str(j)])
		end
	end
end
B(1,:)=[];

disp('Finished building file names')
disp('Starting to write to output file')

% write output file
file3= uiputfile('*.dat', 'Save result as');
fid3=fopen(file3,'wt')

for n = 1:n2
	b=deblank(B(n,:));
	fprintf(fid3,'%s\n',b);
end
fclose(fid3)
