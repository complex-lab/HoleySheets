%% constans
fileName = 'Hexagonal1\IMG_0002.jpg';
angleRotate = -80; % should be define so that the stitch will be on the left 
threshold = 100; %"light sensetivity"
markerSize = 6; 

rejectedHoleLength = 90;
maxRequiredHoleLength = 140;
maxMiddleHoleLength = 140; % if maxMiddleHoleLength==maxRequiredHoleLength : manually choosing the center of the sheet

%% read image 

im=imread(fileName);
im = imrotate(im, angleRotate);
im=(im(:,:,1));
im=im>threshold;
figure('Name', 'Original Image'); imshow(im);

%% extract holes from image

[holes, rejectedHoles , middleHole, middleX, middleY] = extractHolesShape(im, rejectedHoleLength, maxRequiredHoleLength, maxMiddleHoleLength);

%%  plot 

figure('Name', 'Holes distance vs perimeter/sqrt(area)');
title('Holes distance vs perimeter/sqrt(area)');
xlabel('distance from center');ylabel('perimeter/sqrt(area)'); hold on;
rs = [holes.r];
perimeters = [holes.perimeter];
areas = [holes.area];
ind = middleX < [holes.centrX]; % only holes on the right
plot (rs(ind) ,perimeters(ind)./sqrt(areas(ind)) , '.b', 'MarkerSize',markerSize);

figure('Name', 'extracted holes');
title('extracted holes');
xlabel('x');ylabel('y'); hold on;
    
plotHoles(holes , '.b' , markerSize);
plotHoles(rejectedHoles , '.r' , markerSize);
plot(middleX , middleY, '*k');

%% functions

function [holes, rejectedHoles , middleHole, middleX, middleY] = extractHolesShape(im, rejectedHoleSize, requiredHoleSize, middleHoleSize)
B = bwboundaries(im); %a cell array of boundary pixel locations
%data stracture:
holes(length(B)) = struct('xs',[],'ys',[],'area',[],'perimeter', [],'centrX',[] ,'centrY',[] , 'r', []);
numOfholes = 0;
rejectedHoles(length(B)) = struct('xs',[],'ys',[],'area',[],'perimeter', [],'centrX',[] ,'centrY',[], 'r', []);
numOfrejected = 0;

%going through boundaries,collecting holes data and rejecting wrong shapes
for k = 1:length(B)
    boundary = B{k};
    lengthOfShape = length(boundary);
    shape = polyshape(boundary);
    shapeArea = area(shape);
    shapePerimeter = perimeter(shape);
    [centrY, centrX]  = centroid(shape);
        
    hole = struct('xs',boundary(:,2),'ys',boundary(:,1),'area',shapeArea,'perimeter', shapePerimeter ,'centrX',centrX ,'centrY',centrY, 'r', []);
    
    if ((rejectedHoleSize < lengthOfShape) && (lengthOfShape < requiredHoleSize ))
        numOfholes = numOfholes+1;
        holes(numOfholes) = hole;
    elseif (requiredHoleSize < lengthOfShape) && (lengthOfShape < middleHoleSize )
        middleHole = hole;
        middleX = centrX;
        middleY = centrY;
    elseif (lengthOfShape < rejectedHoleSize )
        numOfrejected = numOfrejected+1;
        rejectedHoles(numOfrejected) = hole;
    end
end

%manual selection of the center:
if ~ (exist('middleX', 'var') || exist('middleY', 'var'))
    pts = readPoints(im, 1);
    middleX = pts(1);
    middleY = pts(2);
    middleHole = NaN;
end

% calc and add r
for i = 1:numOfholes
    hole = holes(i);
    r = sqrt((middleX-hole.centrX).^2+(middleY-hole.centrY).^2);
    holes(i).r = r;
end

holes = holes(1:numOfholes);
rejectedHoles = rejectedHoles(1:numOfrejected);

end

%----------------------------------------------------------------------%

function [] = plotHoles(holes , style , markerSize ) 

    for i = 1:length(holes)
        hole = holes(i);
        plot (hole.xs, hole.ys , style , 'MarkerSize',markerSize);
    end
end
