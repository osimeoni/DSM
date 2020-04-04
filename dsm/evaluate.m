% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function res = evaluate(vecs, qvecs, params, ranks, dsm_ranks, fits, whit)

    fprintf('\n>> %s: Evaluation...\n', params.D.name); 

    vecs = cell2mat(vecs);
    qvecs = cell2mat(qvecs);
    cfg = params.D.cfg;

    if exist('whit', 'var')
        vecs = whitenapply(vecs, whit.Lw.m, whit.Lw.P);
        qvecs = whitenapply(qvecs, whit.Lw.m, whit.Lw.P);
    end

    scores = run_diffusion(vecs, qvecs, params, params.DIFF.kq, []);
    % sort images and evaluate
    [~, rks_diff] = sort (cell2mat(scores')', 'descend');

    % If possible, ranks using DSM 
    if ~isempty(fits)

        % Diffusion with DSM
        yq  = zeros(cfg.nq, cfg.n);
        for q = 1:cfg.nq
            [v, reranks] = sort(max(max(fits{q}.nb_db(1:params.DSM.nb_reranked,:,:),[], 2), [], 3), 'descend');
            use = dsm_ranks(1:params.DIFF.max_dsm_kq,q);
            yq(q, use') = v(1:params.DIFF.max_dsm_kq)./max(v(1:params.DIFF.max_dsm_kq));
        end
        scores = run_diffusion(vecs, qvecs, params, params.DIFF.kq, yq');

        % sort images and evaluate
        [~, rks_diff_dsm] = sort (cell2mat(scores')', 'descend');
    end

    for m = 1:length(params.D.gnds)
        fprintf('---------------- %s -------------\n', params.D.gnds{m}(1).name)
        [map, ap, mpr, pr] = compute_map (ranks, params.D.gnds{m}, params.eval.ks);	
        fprintf('>> \t\t\tmAP = %.1f, pr = %.1f, \n', map*100, mpr(3)*100);

        if ~isempty(fits)
            [map_m, ap_m, mpr_m, pr_m] = compute_map (dsm_ranks, params.D.gnds{m}, params.eval.ks);	
            fprintf('>> DSM \t\t\tmAP = %.1f, pr = %.1f, \n', map_m*100, mpr_m(3)*100);
        end

        [d_map , d_ap, d_pr, d_prs] = compute_map (rks_diff, params.D.gnds{m}, params.eval.ks);
        fprintf('>> Diffusion \t\tmAP = %.1f, pr = %.1f, \n', d_map*100, d_pr(3)*100);

        if ~isempty(fits)
            [d_map , d_ap, d_pr, d_prs] = compute_map (rks_diff_dsm, params.D.gnds{m}, params.eval.ks);
            fprintf('>> Diffusion DSM \tmAP = %.1f, pr %.1f, \n', d_map*100, d_pr(3)*100);
        end
        fprintf('--------------------------------------------------\n')
    end
end
