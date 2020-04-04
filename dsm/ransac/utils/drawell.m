function [tr, hell] = drawell(geom, H, colors, varargin)

%DRAWELL(geom)
%draws ellipses into an image, geom = (x y a b c)'
%x,y ellipse center
%[a 0; b c] transrers unit circle to the ellipse

pos = double(geom);

circ = circ_pts(75, 0);
circ(3,:)=1;
hell = [];

for ft = 1:size(pos,2)
   D = [pos(3,ft),         0,  pos(1,ft);
        pos(4,ft), pos(5,ft),  pos(2,ft);
                0,         0,         1];
   tr = H * D;
   ell = H * D * circ;
   ell(1,:) = ell(1,:)./ell(3,:); %+ 1;
   ell(2,:) = ell(2,:)./ell(3,:); % + 1;
   if nargin<3
     hell = [hell, plot(ell(1,[1:end,1]), ell(2,[1:end,1]), 'b-')];
   else
     hell = [hell, plot(ell(1,[1:end,1]), ell(2,[1:end,1]), 'Color', colors(ft,:), varargin{:})];
   end
end

function pts = circ_pts (num, ph)

angl = [0:num-1] * (2 * pi / num) + ph;
pts = [cos(angl); sin(angl)];
