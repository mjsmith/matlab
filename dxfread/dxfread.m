function data = dxfread(filename)
%DXFREAD Read an AutoCAD dxf file.
%   data = DXFREAD('FILENAME') reads a dxf file FILENAME.
%   The result is returned in M, which is a data structure
%
%   See also SHAPEREAD, SHAPEWRITE
%
%   Copyright 2009 Michael Smith
%   $Revision: 0.1$  $Date: 2006/11/11 22:44:06 $


DXFREAD_VERSION = 0.1; %#ok<NASGU> %OK

% Validate input args
if nargin==0
    error(nargchk(1,1,nargin,'struct')); 
end

% Get Filename
if ~ischar(filename)
    error('MATLAB:dxfread:FileNameMustBeString', ...
        'Filename must be a string.'); 
end

% Make sure file exists
if exist(filename,'file') ~= 2 
    error('MATLAB:dxfread:FileNotFound',...
    'File not found.');
end


%% read in the file


% filename = '../../SampleFiles/contours_2500.dxf';
% filename = '../../SampleFiles/Woodhouse referenced.dxf';

fid=fopen(filename); % open file
C=textscan(fid,'%s'); % read dxf file as cell array of strings C
fclose(fid); % close file to accelerate further computation
C=C{1,1}; % reshape array


%% segment

AllIdx = strncmp('AcDb',C,4);
idx = find(AllIdx);

segment = cell(size(idx));

for ii = 1:length(segment)

    if ii == length(segment)
        segment{ii} = C(idx(ii):end);
    else
        segment{ii} = C( idx(ii) : (idx(ii+1)-1) );
    end
    
end


pointcount = 0;
polylinecount = 0;

%% go through the segments 1 by 1, in order

for ii = 1:length(segment)
    
    
    segmentType = segment{ii}{1};
    
    try
        
        if strcmp('AcDbPoint',segmentType)
            
            pointcount = pointcount + 1;
            Points{pointcount} = segment{ii};
            
            points(pointcount,1)=pointcount; % id of line
            points(pointcount,2)=str2double( segment{ii}{3} ); % x start
            points(pointcount,3)=str2double( segment{ii}{5} ); % y start
            points(pointcount,4)=str2double( segment{ii}{7} ); % z start
            
            
        elseif strcmp('AcDbPolyline',segmentType)
            
            polylinecount = polylinecount + 1;
            poly(polylinecount) = parsePolyline(segment{ii});
            
        end
        
        
    catch ex
        disp(['Error on segment ' num2str(ii)]);
        disp(ex.message);
    end
    
end

toc


function b = readDxfGroups(creationInterface)%#ok<DEFNU,INUSD>


function b = processDxfGroups(creationInterface, groupCode, grounpValue)%#ok<DEFNU,INUSD>




function p = parsePolyline(in)
%% Parse a DXF polyline
% [x Y z] = parsePolyline(in)
% 
% Michael Smith, Sept 2009

z = [];

c10 = find(strcmp('10',in(6:end)));
c20 = find(strcmp('20',in(6:end)));
c38 = find(strcmp('38',in(6:end)));

if isempty(c10) 
    return
end

c10 = c10 + 5;
c20 = c10 + 5;

numlines = length(c10);

try

    if (length(c10) ~= length(c20))
        error('ParsePolyline: X and y length do not match');
    end
    
    if isempty(c38)

        point = in(c10(1): c10(1) + numlines*4-1);
        c = str2double(point);
        d = reshape(c,4,numlines)';

        X = d(:,2);
        Y = d(:,4);

    else

        c38 = c38 + 5;
        
        point = in(c10(1): c10(1) + numlines*6-1);
        c = str2double(point);
        d = reshape(c,4,numlines)';
        X = d(:,2);
        Y = d(:,4);
        z = d(:,6);

    end

catch ex
    disp(ex.message);
    X = [];
    Y = [];
    rethrow(ex);
end

% p = struct([]);

p.X = X;
p.Y = Y;
p.Geometry = 'Line';