% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function [fits] = ransac_fit(params, qfeats, dbfeats, ranks)

    for q_sc = 1:numel(params.DSM.scales) 
        qfeat = qfeats{q_sc};

        % When no features were detected for the query
        if isempty(qfeat.geom)
            continue
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Transform ellipses
        q_geom_plot = KMpt2tran(qfeat.geom');
        q_geom_plot = [q_geom_plot; qfeat.sc];

        q_geom = [q_geom_plot([1 2 3], :); zeros(1, size(q_geom_plot, 2)); ...
                  q_geom_plot([4 5], :)];

        % Pre-processing - Inverting
        q_geom = invert(q_geom);
        q_geom = [q_geom; qfeat.sc];

        % Get database ranks
        top_dbs = ranks(1:params.DSM.nb_reranked)';

        rank = 1;
        for db_id = top_dbs
            for db_sc = 1:numel(params.DSM.scales)
                dbfeat = dbfeats{db_id}{db_sc};

                % Initialization 
                nb_db    (rank, q_sc, db_sc) = 0;
                inl_q    {rank, q_sc, db_sc} = []; 
                inl_db   {rank, q_sc, db_sc} = []; 
                transfs  {rank, q_sc, db_sc} = []; 

                if isempty(dbfeat.geom)
                    continue
                end

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Transform ellipses
                db_geom_plot = KMpt2tran(dbfeat.geom');
                db_geom = db_geom_plot;

                if ~isempty(db_geom_plot)
                    db_geom = [db_geom_plot([1 2 3], :); zeros(1, size(db_geom_plot, 2)); ... 
                              db_geom_plot([4 5], :)];
                end
                db_geom = [db_geom; dbfeat.sc];
                db_geom_plot = [db_geom_plot; dbfeat.sc];

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Compute RANSAC

                %%% Compute tentative correspondences
                corresp = cmp_corresp(qfeat, dbfeat);

                % m2mransac is a C++ RANSAC script. Use -1 and +1 to transform indices from Matlab
                % to C++ and vice-versa
                [inliers, F] = m2mransac(single(q_geom), single(db_geom), ...
                                         uint32(corresp.cor1)-1, uint32(corresp.cor2)-1, ...
                                         params.RANSAC.error_thresh, params.RANSAC.max_sc_change);

                % Get number of inliers
                nb_inl = size(inliers, 2);

                if nb_inl == 0
                    continue
                end

                nb_db   (rank, q_sc, db_sc) = nb_inl;
                inl_q   {rank, q_sc, db_sc} = corresp.cor1(inliers+1); 
                inl_db  {rank, q_sc, db_sc} = corresp.cor2(inliers+1); 
                transfs {rank, q_sc, db_sc} = F; 

                if params.ransac_plot 
                    plot_matching(db_id, qfeats, dbfeats, q_geom_plot, ...
                                  db_geom_plot, corresp, inliers, params)
                end
            end

            rank = rank+1;
        end
    end

    fits.nb_db = nb_db;
    fits.inl_db = inl_db; 
    fits.inl_q  = inl_q; 
    fits.transformation = transfs; 
end

function corresp = cmp_corresp(qfeat, dbfeat)
    cor1 = []; cor2 = [];
    gp1 = []; gp2 = [];
    sc1 = []; sc2 = [];

    for i = 1:numel(qfeat.gp)
        f = find(dbfeat.gp==qfeat.gp(i));
        for j = 1:numel(f)
            cor1 = [cor1, i];
            cor2 = [cor2, f(j)];
            gp1 = [gp1, qfeat.gp(i)];
            gp2 = [gp2, dbfeat.gp(f(j))];
            sc1 = [sc1, qfeat.sc(i)];
            sc2 = [sc2, dbfeat.sc(f(j))];
        end
    end

    corresp.cor1 = cor1;
    corresp.cor2 = cor2;
    corresp.gp1 = gp1;
    corresp.gp2 = gp2;
    corresp.sc1 = sc1;
    corresp.sc2 = sc2;
end

function geom = invert(geom)
    geom(3,:) = 1./geom(3,:); 
    geom(6,:) = 1./geom(6,:); 
    geom(5,:) = -geom(5,:) .* geom(3,:) .* geom(6,:);
end

function plot_matching(db_id, qfeats, dbfeats, q_geom_plot, db_geom_plot, corresp, inliers, params)

    cfg = params.D.cfg;
    nb_inl = size(inliers, 2);

    close all
    im1 = crop_qim(imread(cfg.qim_fname(cfg, params.tmp.q_id)), ... 
                   cfg.gnd(params.tmp.q_id).bbx, params.test_imdim);
    im2 = imread(cfg.im_fname(cfg, db_id));

    % Ratios used for the projection of features on the image
    ratio1     = size(im1) ./ qfeats{1}.fm_size;
    disp('Change here')
    %ratio2     = size(im2) ./ dbfeats{db_id}{1}.fm_size;
    ratio2     = size(im2) ./ qfeats{1}.fm_size;
    im_scales   = double([ratio1(1) ratio2(1) ratio1(2) ratio2(2)]);

    h = figure('Visible', 'off');
    show_matches(q_geom_plot(:,corresp.cor1(inliers+1))', db_geom_plot(:,corresp.cor2(inliers+1))', ...
                im1, im2, nb_inl, im_scales);
    
    title(sprintf('Q %d DB %d, nb inliers %d / nb tent %d', params.tmp.q_id, db_id, ...
                  nb_inl, size(corresp.cor1, 2)), 'Interpreter', 'none');

    plot_dir = sprintf('plots/%s/%s/q%d', cfg.dataset, params.network, params.tmp.q_id);
    if ~exist(plot_dir); mkdir(plot_dir); end

    path = sprintf('%s/q%d_im%d_dsm_match.png', plot_dir, params.tmp.q_id, db_id);
    saveas(h, path); 
end
