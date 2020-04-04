function [] = show_matches(matches1, matches2, img1, img2, numToShow, scales)
% showMatchedFeatures(img1, img2, matches1, matches2, numToShow)
% 
% Visualizes the matching between feature points in images.
% 
% INPUTS
% matches1  : Features from img1 that match row-wise to those from img2
% matches2  : Features from img2 that match row-wise to those from img1
% img1      : An image containing features
% img2      : A second image containing features
% numToShow : If scalar, determines number of matches to show. If a vector,
%             determines indices of matched points
% scales    : [scaleX1 scaleX2 scaleY1 scaleY2]
% 
% OUTPUTS
% None
% 
% Modified from a code by
% Author : Marc Eder
% Date   : 12/8/2015
% % % 


    if nargin < 5
        numToShow = size(matches1, 1);
    end

    % Dimensions of the images
    [rows1, cols1, chan1] = size(img1);
    [rows2, cols2, chan2] = size(img2);

    topBuff1 = 0;
    topBuff2 = 0;
    
    % Equalize image heights
    if rows1 > rows2
        diff = rows1 - rows2;
        topBuff2 = ceil(diff / 2);
        newImg = ones(rows2 + diff, cols2, chan2, 'uint8') * 255;
        newImg(topBuff2 : topBuff2 + rows2 - 1, :, :) = img2;
        img2 = newImg;
    elseif rows2 > rows1
        diff = rows2 - rows1;
        topBuff1 = ceil(diff / 2);
        newImg = ones(rows1 + diff, cols1, chan1, 'uint8') * 255;
        newImg(topBuff1 : topBuff1 + rows1 - 1, :, :) = img1;
        img1 = newImg;
    end
    
    % Concatenate images
    nbPixels = 20;
    img = [img1, ones(size(img1, 1), nbPixels,3)*255, img2];


    % If numToShow is a scalar then determine a vector of numToShow random
    % indices. If numToShow is a vector, use it for vector indexing.
    if length(numToShow) == 1
        idx = randsample(size(matches1, 1), numToShow);
    else
        idx = numToShow;
    end
    
    % Display matched feature points overlayed on images side by side
    imshow(img), title(['Matched Points in Image 1 (Left) and Image 2 (Right)']);
    if isempty(idx)
	return;
    end

    hold on;

    valSc = unique([matches1(idx, 6) matches2(idx, 6)]);
    clors = hsv(size(valSc, 1));

    % Plot feature point locations
    for idC = 1:size(idx, 1)
        colors1(idC,:) = clors(find(matches1(idx(idC), 6) == valSc), :);
        colors2(idC,:) = clors(find(matches2(idx(idC), 6) == valSc), :);
    end

    % Plot lines between points
    for i = 1 : length(idx);
        % Plot ellipses
        f1 = matches1(idx(i),:); 
        xy1 = drawell(f1', [scales(1) 0 0; 0 scales(3) topBuff1; 0 0 1], ...
                colors1(i,:),'linewidth', 2);
        f2 = matches2(idx(i),:); 
        xy2 = drawell(f2', [scales(2) 0 size(img1, 2)+nbPixels; 0 scales(4) topBuff2; 0 0 1], ...
                colors2(i,:), 'linewidth', 2);

	if ~size(matches1, 2) == 5 && (matches1(idx(i), 6) == matches2(idx(i), 6))
	    continue
	end

        % plot lines
        try
            plot([xy1(1, 3), xy2(1,3)],...
                 [xy1(2, 3), xy2(2, 3)], ...
                 'color', colors1(i,:),'linewidth', 2);
        catch
            disp('here')
        end
    end
end 
