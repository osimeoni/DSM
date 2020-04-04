% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function [dbvecs, dbfeats] = cmp_dsm_db_feats(params, net)

    cfg = params.D.cfg;

    feats = cell(1, cfg.nq);
    dbvecs = cell(1, cfg.nq);

    params.tmp.is_query = false;

    if ~exist(params.dsm_db_feats_file, 'file') 
        fprintf('>> %s: Detecting features for database images...\n', params.D.name); 

        progressbar(0);
        for i = 1:cfg.n
            params.tmp.im_id = i;
            im = imread(cfg.im_fname(cfg, i));
            [dbvecs{i}, feats{i}] = fit_localfeatures(im, net, params); 
            progressbar(i/cfg.n);
        end

        save(params.db_descs_file, 'dbvecs', '-v7.3');
        dbfeats = get_max_feats_ms(feats, params, 'db');
        save(params.dsm_db_feats_file, 'dbfeats', '-v7.3');
    else
        fprintf('>> %s: Loading features for db images...\n', params.D.name); 
        vecs = load(params.db_descs_file);
        dbvecs = vecs.dbvecs;

        feats = load(params.dsm_db_feats_file);
        dbfeats = feats.dbfeats;
    end
end
