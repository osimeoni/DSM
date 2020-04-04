function [desc, feats] = fit_localfeatures(im, net, params)
% FIT_LOCALFEATURES computes multi-scale D-dimensional CNN vector and local features for an image.
%
%   [DESC, FEATS] = fit_localfeatures(IM, NET, PARAMS)
%   
%   IM        : Input image, or input image path as a string
%   NET       : CNN network to evaluate on image IM
%   PARAMS    : DSM parameters
%
%   DESC      : Multi-scale output, D x 1 if AGGREGATE=1, D x numel(SCALES) if AGGREGATE=0
%   FEAT      : Multi-scale features, cell x number scales
%
% Authors: O. Simeoni, Y. Avrithis, O. Chum. 2019.
% Inspired from: F. Radenovic, G. Tolias, O. Chum. 2017. 
    
    minsize = 67;
    net.mode = 'test';
    convarname = params.layer;

    poollayername = 'pooldescriptor';
    descvarname = 'l2descriptor';

    if params.use_gpu
        gpuarrayfun = @(x) gpuArray(x);
        gatherfun = @(x) gather(x);
    else
        gpuarrayfun = @(x) x; % do not convert to gpuArray
        gatherfun = @(x) x; % do not gather
    end

    if isstr(im); im = imread(im); end

    % Initialization
    feats = cell(1, numel(params.DSM.scales));
    v = [];

    for s = 1:numel(params.DSM.scales)
        im_ = imresize(im, params.DSM.scales(s));

        im_ = single(im_) - mean(net.meta.normalization.averageImage(:));
        if size(im_, 3) == 1
            im_ = repmat(im_, [1 1 3]);
        end

        if min(size(im_, 1), size(im_, 2)) < minsize
            im_ = pad2minsize(im_, minsize, 0);
        end

        net.vars(net.getVarIndex(convarname)).precious = true;
        net.eval({'input', gpuarrayfun(reshape(im_, [size(im_), 1]))});

        % Compute descriptor
        v = [v, gatherfun(squeeze(net.getVar(descvarname).value))];

        % Compute feature maps 
        fm = gather(squeeze(net.getVar(convarname).value));
        if isempty(fm); error('fm empty'); end;
	
        % Compute MSER Delta
        params.MSER.delta = compute_delta(params, fm);

        feats{s} = get_features(fm, params, params.tmp.is_query, params.DSM.scales(s));
    end

    desc = aggregate_ms(params, net, v, poollayername, gatherfun);
end

function feats = get_features(x, params, isquery, scale)

    % Compute MSER regions + fit boxes
    feats = cmp_mser_regions(params, x, scale);

    %If DB image, compute NMS
    if ~isquery
        feats = cmp_nms(params, feats, x);
    end
end

function v = aggregate_ms(params, net, v, poollayername, gatherfun)
    if params.aggregate
        if isa(net.layers(net.getLayerIndex(poollayername)).block, 'GeM')
            p = gatherfun(net.params(net.layers(net.getLayerIndex(poollayername)).paramIndexes).value);
            p = reshape(p, [size(p,3), 1]);
        else 
            p = 1;
        end
        v = bsxfun(@power, v, p);
        v = (sum(v, 2) / size(v, 2)).^(1./p);
        v = vecpostproc(v);
    end
end

function delta = compute_delta(params, fm) 
    % Compute delta corresponding to percentage of the cumulative histogram of the activation values. 

    values = fm(:);
    values = values(values~=0);
    [co , ce] = hist(values, 1000); 
    v = find(cumsum(co)/sum(co) < params.MSER.varDelta); 
    delta = double(round(ce(v(end)))); 

    % Avoiding delta being too large 
    delta = min(delta, 12); 
end
