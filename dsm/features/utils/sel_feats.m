function feats = sel_feats(feats, sel_id)

    feats.geom   = feats.geom(sel_id, :);
    feats.gp = feats.gp(sel_id);
    feats.max = feats.max(sel_id);
    feats.reg = feats.reg(:,sel_id);
    feats.maxLoc = feats.maxLoc(sel_id,:);  
    feats.sc     = feats.sc(sel_id);
end                                                                
