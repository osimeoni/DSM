% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function feats = cmp_nms(params, feats, x)

    if size(feats.max, 2) == 0
        return
    end

    id_keep = nms([feats.reg; feats.max;]', params.FEATS.nms_iou);
    feats = sel_feats(feats, id_keep);
end
