function GEOM = KMpt2tran(pos)  
  GEOM = pos;
  if numel(GEOM) == 0, return; end
  GEOM(3,:) = 1./sqrt(GEOM(3,:) - GEOM(4,:).^2./GEOM(5,:));
  GEOM(5,:) = 1./sqrt(GEOM(5,:));
  GEOM(4,:) = - GEOM(4,:) .* GEOM(5,:).* GEOM(5,:) .* GEOM(3,:);
end
