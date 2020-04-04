function A = cholesky_decomp(geom)

	% E = At * A
	E = [geom(3) geom(4) ;
	     geom(5) geom(6)];

	res = inv(chol(E, 'lower'));
	A = [geom(1) geom(2) res(1,1) res(2,1) res(2,2)];
end
