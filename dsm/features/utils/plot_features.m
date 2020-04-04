function plot_features(i, im, fm, feats, s, isquery, plot_dir, fms)

    for fi = fms %[16 21] %1:30
        h = figure('visible','off');
        im = im2double(im);
        imshow(im); axis image off; 
        sz = size(im);

        f = imresize(fm(:,:,fi), [sz(1) sz(2)]);
        f = ((f-min(min(f)))*255/(max(max(f))-min(min(f))));
        finit = uint8(f);
        f = ind2rgb(finit, jet(256));

        fboth = .5*repmat(rgb2gray(im), [1 1 3]) + .5*f;
        colormap jet 

%:                imshow(f); axis off;
%                title(sprintf('max : %.2f', max(max(fm(:,:,fi)))));
        if isquery
            imwrite(fboth,sprintf('%s/q%d_fm%d.png',plot_dir, i, fi));
        else
            imwrite(fboth,sprintf('%s/db%d_fm%d.png',plot_dir, i, fi));
        end

        if isquery
            % TODO reput pdf
            get_name = @(x) sprintf('%s/q%d_fm%d_%s.png', plot_dir, i, fi, x);
        else
            get_name = @(x) sprintf('%s/db%d_fm%d_%s.png', plot_dir, i, fi, x);
        end

        % With mask
        iptsetpref('ImshowBorder', 'tight');
        h = figure('visible','off');
        colormap jet 
        imshow(fboth); axis off;
        %title(sprintf('max : %.2f', max(max(fm(:,:,fi)))));
        hold on

        % Find masks from one group, plot them
        ch = find(feats{s}.gp == fi);
        frames2Plot = KMpt2tran(feats{s}.geom(ch,:)');
        ratio = size(im) ./ size(fm);
        colrs = repmat([1 1 1], numel(ch), 1); 
%                colrs = hsv(numel(ch));
        try
            drawell(frames2Plot, [ratio(1) 0 0; 0 ratio(2) 0; 0 0 1], colrs, 'linewidth', 2);
        catch
            disp('plot issue')
            keyboard
        end

        f_name = get_name('ell_3');
        saveas(h,f_name); 
%                system(sprintf('/usr/bin/pdfcrop %s %s', f_name, f_name)), 

        iptsetpref('ImshowBorder', 'tight');
        h = figure('visible','off');
        colormap jet 
        imshow(im); axis off;
        %title(sprintf('max : %.2f', max(max(fm(:,:,fi)))));
        hold on

        % Find masks from one group, plot them
        ch = find(feats{s}.gp == fi);
        frames2Plot = KMpt2tran(feats{s}.geom(ch,:)');
        ratio = size(im) ./ size(fm);
        colrs = repmat([1 0 0], numel(ch), 1); 
%                colrs = hsv(numel(ch));
        try
            drawell(frames2Plot, [ratio(1) 0 0; 0 ratio(2) 0; 0 0 1], colrs, 'linewidth', 2);
        catch
            keyboard
        end

        f_name = get_name('ell_im');
        saveas(h,f_name); 
%                system(sprintf('/usr/bin/pdfcrop %s %s', f_name, f_name)), 

        iptsetpref('ImshowBorder', 'tight');
        h = figure('visible','off');
        colormap jet 
        fblack =  ind2rgb(finit, gray(256));
        imshow(fblack); axis off;
        %title(sprintf('max : %.2f', max(max(fm(:,:,fi)))));
        hold on

        % Find masks from one group, plot them
        ch = find(feats{s}.gp == fi);
        frames2Plot = KMpt2tran(feats{s}.geom(ch,:)');
        ratio = size(im) ./ size(fm);
        colrs = repmat([1 0 0], numel(ch), 1); 
%                colrs = hsv(numel(ch));
        try
            drawell(frames2Plot, [ratio(1) 0 0; 0 ratio(2) 0; 0 0 1], colrs, 'linewidth', 2);
        catch
            keyboard
        end

        f_name = get_name('ell_fm');
        saveas(h,f_name); 
%                system(sprintf('/usr/bin/pdfcrop %s %s', f_name, f_name)), 
        close all
        disp(sprintf('Saved to : %s', f_name))
    end


end
