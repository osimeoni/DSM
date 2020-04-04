function [feats] = cmp_mser_regions(params, fms, scale)
% COMPUTE_MSER_REGION computes MSER regions from feature maps.
%
%   [FEATS] = compute_mser_region(PARAMS, FMs, SCALE)
%   
%   PARAMS    : DSM parameters
%   FMs       : Feature maps tensor
%   SCALE     : Scale of feature map 
%
%   FEATS      : Local features
%
% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.
    

    feats = initialize_feats(fms);
    ellipse = [];
    fms_ui  = uint8(fms);

    % Detect feature per feature maps
    for i_fm = 1:size(fms, 3)
        fm_ui  = fms_ui (:,:,i_fm);
        geom = []; elli = [];

        if max(fm_ui(:)) <= 0
            continue
        end

        % Run MSER 
        [r, f] = vl_mser(fm_ui, 'MinDiversity', params.MSER.diversity, ...
                 'MaxVariation', params.MSER.maxVar, 'Delta', params.MSER.delta,...
                 'MinArea', 0.001);

        if isempty(r); continue; end; 

        % Put X and Y in the good order
        f = vl_ertr(f);

        % Remove singular covariance matrix
        rmv_id = find((f(4, :).^2 - f(5, :).*f(3, :)) == 0);
        f(:,rmv_id) = [];
        r(rmv_id)   = [];

        if isempty(r); continue; end; 

        nb_f = size(r, 1);

        % Do not save features from cluttered FM
        if params.FEATS.nb_max > 0 && nb_f > params.FEATS.nb_max 
            continue
        end

        % Stored as x y a11 a12 a22
        pts = f';

        % Compute decomposition 
        rmv_id = [];
        for ind = 1:nb_f 
            try
                A = cholesky_decomp([pts(ind,[1 2 3 4]) pts(ind,[4 5])]); 
                geom = [geom; A];
                elli = [elli; pts(ind,:)];
            catch
                rmv_id = [rmv_id, ind];
            end
        end
        f(:,rmv_id) = [];
        r(rmv_id)   = [];

        if isempty(r); continue; end; 

        nb_f = size(r, 1);

        if size(geom, 1) == 0; continue; end;

        feats.geom    = [feats.geom; geom]; 
        feats.gp      = [feats.gp repmat(i_fm, 1, size(geom,1))]; 
        ellipse = [ellipse; elli]; 

    end

    if isempty(ellipse)
        return
    end

    % reduce all other cases to ellipses/oriented ellipses
    frames = vl_frame2oell(ellipse') ;

    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % Fit boxe to ellipse

    % number of vertices drawn for each frame
    np = 40;
    K   = size(frames,2) ;
    thr = linspace(0,2*pi,np) ;
    Xp = [cos(thr) ; sin(thr) ;] ;

    maxs  = zeros(1, K);
    regs  = zeros(4, K);
    maxsLoc = zeros(2, K);
    maxLoc = [];

    rmv_id = [];

    for k=1:K
        fm = fms(:,:,feats.gp(k));

        % Frame center
        xc = frames(1,k);
        yc = frames(2,k);

        % Frame matrix
        A = reshape(frames(3:6,k),2,2);

        % Vertices along the boundary
        X = A * Xp;
        X(1,:) = X(1,:) + xc;
        X(2,:) = X(2,:) + yc;

        % Get max from ellipses
        mask = poly2mask(round(X(1,:)), round(X(2,:)), size(fm,1), size(fm,2));

        minX = max(round(min(X(1,:))), 1);
        maxX = min(round(max(X(1,:))), size(fm,2));
        minY = max(round(min(X(2,:))), 1);
        maxY = min(round(max(X(2,:))), size(fm,1));

        % Square region
        reg  = fm(minY:maxY, minX:maxX);

        % Real region 
        masked = mask.*fm;

        if any(size(reg) == 0) || any(size(reg) == 1) || sum(masked(:)) == 0
            rmv_id = [rmv_id k];
            continue
        else
            maxs(k)  = max(masked(:));
        end

        % Region
        regs(:,k) = [minY minX maxY maxX];

        % Find maximum position
        [p, max_pos] = max(masked(:));
        [maxsLoc(1,k), maxsLoc(2,k)] = ind2sub(size(masked), max_pos);
        maxLoc = [maxLoc p];

    end

    feats.reg = regs;
    feats.max = maxs;

    feats.geom(rmv_id,:) = [];
    feats.gp(rmv_id)     = []; 
    feats.max(rmv_id)   = [];
    feats.reg(:,rmv_id) = []; 

    feats.sc = ones(size(feats.gp))*scale;
    feats.maxLoc = [feats.maxLoc maxLoc]; 
    feats.maxLoc = feats.maxLoc';
end

function feats = initialize_feats(fms)
    feats.geom = [];
    feats.gp = [];
    feats.sc = [];
    feats.reg = [];
    feats.max = [];
    feats.maxLoc = [];
    feats.fm_size = size(fms);
end
