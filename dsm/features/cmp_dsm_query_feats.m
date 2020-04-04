% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function [qvecs, qfeats] = cmp_dsm_query_feats(params, net)

    cfg = params.D.cfg;

    feats = cell(1, cfg.nq);
    qvecs = cell(1, cfg.nq);
    
    params.tmp.is_query = true;

    if ~exist(params.dsm_q_feats_file, 'file') 
        fprintf('>> %s: Detecting features for query images...\n', params.D.name); 

        progressbar(0);
        for i = 1:cfg.nq
            params.tmp.im_id = i;
            im = crop_qim(imread(cfg.qim_fname(cfg, i)), cfg.gnd(i).bbx, params.test_imdim);

            % Compute features
            [qvecs{i}, feats{i}] = fit_localfeatures(im, net, params);

            progressbar(i/cfg.nq);
        end
        qfeats = get_max_feats_ms(feats, params, 'query');
        save(params.dsm_q_feats_file, 'qfeats', '-v7.3');
        save(params.q_descs_file, 'qvecs', '-v7.3');
    else

        fprintf('>> %s: Loading features for query images...\n', params.D.name); 
        feats = load(params.dsm_q_feats_file);
        vecs = load(params.q_descs_file);
        qfeats = feats.qfeats;
        qvecs = vecs.qvecs;
    end
end
