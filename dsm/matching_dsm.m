% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function [dsm_ranks, fits] = matching_dsm(params, q_feats, db_feats, ranks)

    cfg = params.D.cfg;

    fprintf('\n>> %s: Computing RANSAC per query images...\n', params.D.name); 

    fits = cell(1, cfg.nq);
    dsm_ranks = ranks;

    progressbar(0);
    for i = 1:cfg.nq
        params.tmp.q_id = i;

        fits{i} = ransac_fit(params, q_feats{i}, db_feats, ranks(:,i)); 

        [v, reranked] = sort(max(max(fits{i}.nb_db(1:params.DSM.nb_reranked,:,:),[], 2), ...
                                [], 3), 'descend');
        dsm_ranks(1:params.DSM.nb_reranked,i) = ranks(reranked, i);
        progressbar(i/cfg.nq);
    end
end
