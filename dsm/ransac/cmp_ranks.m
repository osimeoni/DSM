% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function [ranks, ranks_w] = cmp_ranks(params, q_descs, db_descs, whit)

    db_descs = cell2mat(db_descs);
    q_descs = cell2mat(q_descs);

    % raw descriptors
    sim = db_descs'*q_descs;
    [sim, ranks] = sort(sim, 'descend');

    db_descs_w = whitenapply(db_descs, whit.Lw.m, whit.Lw.P);
    q_descs_w = whitenapply(q_descs, whit.Lw.m, whit.Lw.P);

    % whitened descriptors
    sim_w = db_descs_w'*q_descs_w;
    [sim_w, ranks_w] = sort(sim_w, 'descend');
end
