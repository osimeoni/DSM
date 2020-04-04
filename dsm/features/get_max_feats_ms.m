% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function new_features = get_max_feats_ms(features, params, set)
    
    % Query or DB setup
    if ~(strcmp(set, 'db') || strcmp(set, 'query')); error('unknown'); end
    is_db = strcmp(set, 'db');

    new_features = cell(1, size(features, 2));

    for im_id = 1:size(features, 2)

        % Only gotten images
        if isempty(features{im_id}); continue; end;

        maxes    = [];
        id_maxes = [];
        sc_maxes = [];

        feats = features{im_id};
        nb_scales = size(feats, 2);
        
        tot_max = params.FEATS.tot_max;

        for sc_id = 1:nb_scales

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Check number of features per Channel
            if strcmp(set, 'db')
                cha_max = params.FEATS.db_cha_max;
            else
                cha_max = params.FEATS.q_cha_max;
            end
            
            sel_id = [];

            for scale = unique(feats{sc_id}.sc)
                for group = unique(feats{sc_id}.gp)
                    pos_gp = find((feats{sc_id}.gp == group).*(feats{sc_id}.sc == scale));
                    if size(pos_gp, 2) > cha_max 
                        [~, ord] = sort(abs(feats{sc_id}.max(pos_gp)), 'descend');

                        pos_gp = pos_gp(ord(1:cha_max));
                        sel_id = [sel_id; pos_gp'];
                    else
                        sel_id = [sel_id; pos_gp'];
                    end
                end
            end
            feats{sc_id} = sel_feats(feats{sc_id}, sel_id);

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% Check number of features per Image 
            sel_id = [];
            if tot_max > 0 && size(feats{sc_id}.gp, 2) > tot_max 
                [~, sel_id] = sort(abs(feats{sc_id}.max), 'descend');
                sel_id = sel_id(1:tot_max);

                feats{sc_id} = sel_feats(feats{sc_id}, sel_id);
            end

            maxes    = [maxes feats{sc_id}.max]; 
            sc_maxes = [sc_maxes repmat(sc_id, 1, size(feats{sc_id}.max,2))]; 
            id_maxes = [id_maxes 1:size(feats{sc_id}.max,2)]; 
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Check number of features per Image per MS 
        if params.FEATS.ms_tot_max > 0 && size(maxes, 2) > params.FEATS.ms_tot_max 

            [~, ms_sel] = sort(abs(maxes), 'descend');
            ms_sel = ms_sel(1:params.FEATS.ms_tot_max);

            ms_sel_id={};
            for sc_id = 1:nb_scales; ms_sel_id{sc_id} = []; end

            % Find the good features in each scale
            for id = ms_sel
                ms_sel_id{sc_maxes(id)} = [ms_sel_id{sc_maxes(id)} id_maxes(id)]; 
            end

            % Keep the selected features
            for sc_id = 1:nb_scales
                sel_id = ms_sel_id{sc_id};
                feats{sc_id} = sel_feats(feats{sc_id}, sel_id);
            end
        end

        new_features{im_id} = feats;
    end
end
