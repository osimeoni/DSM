function [scores] = run_diffusion(lvecs, qV, params, kq, yq)
    % 
    % Code modified from :
    % Authors: A. Iscen, G. Tolias, Y. Avrithis, T. Furon, O. Chum. 2017. 

    cfg = params.D.cfg;

    alpha  = 0.99;                         % alpha for diffusion
    it     = 20;                           % iterations for CG
    tol    = 1e-6;                         % tolerance for CG
    gamma  = 3;                            % similarity exponent
    k      = 50; 

    ndes = size(lvecs, 2);
    [imids, ~] = imgfeatids (ndes);                        % image and region ids here
    Nf = numel(imids);                                     % number of images
    N = max(imids);                                        % number of database vectors

    % Construct knngraph 
    [knn_, s_] = knn_wrap(lvecs, lvecs, k, 100);
    A_ = knngraph(knn_(1:k, :), s_(1:k, :) .^ gamma);

    % Laplacian
    S = transition_matrix(A_);
    A = speye(size(S)) - alpha * S;
    clear A_ S; 

    % Query
    scores = cell(1, cfg.nq);

    sim = lvecs'*qV;

    for q = 1:cfg.nq; % number of queries
        if ~isempty(yq)
            y1 = yq(:,q);
            y2 = sim(:,q); % construction of y vector
            y = double(y1 .* y2);

            if all(y == 0); 
                y = y1; 
                disp('All y zerro')
            end;

            [val, id] = sort(y, 'descend'); 

            % Keep only the kqbis first
            y(id(kq:end)) = 0;
        else
            y = ymake(lvecs, qV(:,q), kq, gamma); % construction of y vector
        end
        scores{q} = dfs(A,y,tol,it)';  % diffusion
    end
end
