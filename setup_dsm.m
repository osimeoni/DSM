function setup_dsm()
% SETUP_DSM Setup the toolbox.
%
%   setup_dsm()  Adds the toolbox to MATLAB path.
%
% Authors: O. Simeoni, Y. Avrithis, O. Chum. 2019.
% Inspired from: F. Radenovic, G. Tolias, O. Chum. 2017. 

[root] = fileparts(mfilename('fullpath')) ;

% add paths from this package
addpath(fullfile(root, 'cnnblocks'));
addpath(fullfile(root, 'cnninit'));
addpath(fullfile(root, 'cnnvecs'));
addpath(fullfile(root, 'examples'));
addpath(fullfile(root, 'whiten')); 
addpath(fullfile(root, 'utils')); 

run('tools/VLFeat/vlfeat-0.9.21/toolbox/vl_setup.m');

addpath(fullfile(root, 'dsm')); 
addpath(fullfile(root, 'dsm/features')); 
addpath(fullfile(root, 'dsm/features/utils')); 
addpath(fullfile(root, 'dsm/ransac')); 
addpath(fullfile(root, 'dsm/ransac/utils')); 
addpath(fullfile(root, 'dsm/network')); 
addpath(fullfile(root, 'utils/diffusion')); 
