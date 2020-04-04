% TEST_DSM  Code to evaluate the method DSM presented in the paper:
%
% O. Siméoni, Y. Avrithis, O. Chum, Local Features and Visual Words Emerge in Activations, CVPR 2019
%
% Code modified from :
% F. Radenovic, G. Tolias, O. Chum, Fine-tuning CNN Image Retrieval with No Human Annotation, TPAMI 2018
% F. Radenovic, G. Tolias, O. Chum, CNN Image Retrieval Learns from BoW: Unsupervised Fine-Tuning with Hard Examples, ECCV 2016
% Authors: F. Radenovic, G. Tolias, O. Chum. 2017. 

clear;

%---------------------------------------------------------------------
% Set data folder and testing parameters
%---------------------------------------------------------------------

% Set data folder, change if you have downloaded the data somewhere else
data_root = fullfile('/path/to/data', 'data');
get_root_cnnimageretrieval()
% Check, and, if necessary, download test data (Oxf5k and Par6k), and fine-tuned networks
download_test(data_root); 

% Set test options
test_datasets = {'roxford5k', 'rparis6k'};  % list of datasets to evaluate on
params.use_gpu = [1];  % use GPUs (array of GPUIDs), if empty use CPU

% Test
params.eval.ks = [1, 5, 10];

% Netork 
% Available models are:
% - 'retrievalSfM120k-gem-vgg': the official VGG-GeM model trained by Radenovic etal.
% - 'retrievalSfM120k-gem-resnet101': the official ResNet101-GeM model trained by Radenovic etal.
% - 'dsm-retrained-mac-vgg': VGG-MAC retrained on the SfM-120k dataset by Simeoni etal.
% - 'dsm-retrained-mac-resnet101': ResNet101-MAC retrained on the SfM-120k dataset by Simeoni etal.
% - 'imagenet-mac-vgg': VGG-MAC retrained on the SfM-120k dataset by Simeoni etal.
% - 'imagenet-mac-resnet101': ResNet101-MAC retrained on the SfM-120k dataset by Simeoni etal.
params.network          = 'retrievalSfM120k-gem-vgg'; % See options above 
params.whitening        = 'retrieval-SfM-120k-whiten'; % Supervised whitening
params.DSM.nb_reranked  = 100; % Number of images reranked using DSM

% Configure parameters
params = configure_dsm(params, data_root);

% Upscale if needed 
net = load_network(params);

% Whitening, train if not existing
whit = train_whitening(params, net);

% Prep GPUs
prep_gpus(params, net)

for d = 1:numel(test_datasets)

    params = configure_dataset(params, test_datasets{d}, data_root);

    % Move network to GPU if needed
    if numel(params.use_gpu) >= 1
        if strcmp(net.device, 'cpu'), net.move('gpu'); end
    end

    % Compute descriptors and feature for queries 
    [q_descs, q_feats] = cmp_dsm_query_feats(params, net);

    % Compute descriptors and features for dataset 
    [db_descs, db_feats] = cmp_dsm_db_feats(params, net);

    % Ranks
    [ranks, ranks_whit] = cmp_ranks(params, q_descs, db_descs, whit);

    % Compute descriptors 
    [dsm_ranks_whit, fits_whit] = matching_dsm(params, q_feats, db_feats, ranks_whit);

    % Evaluation 
    evaluate(db_descs, q_descs, params, ranks_whit, dsm_ranks_whit, fits_whit, whit)

end


function params = configure_dsm(params, data_root)

    fprintf('>> Configure params...\n'); 

    % General
    params.test_imdim = 1024;  % choose test image dimensionality
    params.use_ms = 1; % use multi-scale representation, otherwise use single-scale
    params.use_rvec = 0;  % use regional representation (R-MAC, R-GeM), otherwise use global (MAC, GeM)
    params.aggregate = 1;

    if ~strcmp(params.network, 'retrievalSfM120k-gem-vgg') && ...
       ~strcmp(params.network, 'retrievalSfM120k-gem-resnet101') && ...
       ~strcmp(params.network, 'dsm-retrained-mac-vgg') && ...
       ~strcmp(params.network, 'dsm-retrained-mac-resnet101') && ...
       ~strcmp(params.network, 'imagenet-mac-vgg') && ...
       ~strcmp(params.network, 'imagenet-mac-resnet101') 
       error('Unknown models.')
    end


    if contains(params.network, 'retrievalSfM120k') 
        params.network_folder = 'retrieval-SfM-120k';
    elseif contains(params.network, 'dsm-retrained') 
        params.network_folder = 'dsm-retrained';
    elseif contains(params.network, 'imagenet') 
        params.network_folder = 'imagenet';
    else
        error('Unknown model.')
    end

    params.ransac_plot = false;

    if contains(params.network, 'resnet101')
        params.DSM.upscale      = 1; % need to upscale network
        params.FEATS.ms_tot_max = 2048; %CPVR19 2048 if ResNet
        params.FEATS.tot_max    = 2048; %CPVR19 2048 if ResNet
    else
        params.DSM.upscale      = 0; % should not upscale the network
        params.FEATS.ms_tot_max = 512; %CPVR19 512 if VGG
        params.FEATS.tot_max    = 512; %CPVR19 512 if VGG
    end

    params.DSM.scales = [1 1/sqrt(2) 1/2];
 
    % MSER params
    params.MSER.diversity = .7; % CVPR19 .7
    params.MSER.varDelta  = .6; % CVPR19 .6
    params.MSER.maxVar    = .5; % CVPR19 .5
    
    % Maximum features
    params.FEATS.nb_max      = 36; % CPVR19 36 
    params.FEATS.q_cha_max   = 20; % CPVR19 20
    params.FEATS.db_cha_max  = 10; % CVPR19 10

    % NMS                    
    params.FEATS.nms_iou     = .2; % CVPR19 .2

    % Ransac
    params.RANSAC.max_sc_change = 3; % CVPR19 3
    params.RANSAC.error_thresh  = 2; % CPVR19 2

    % Diffusion
    params.DIFF.kq = 5;          % CVPR19 5 
    params.DIFF.max_dsm_kq = 10; % CVPR19 10

    if params.DSM.upscale; ups = 'upscale'; else ups = ''; end;

    params.network_file = fullfile(data_root, 'networks', params.network_folder, ...
                                   sprintf('%s.mat', params.network));

    if ~exist(params.network_file, 'file')
        error(sprintf('Please make sure file %s exists.', params.network_file));
    end

    params.layer = 'xx0';

    params.ims_whiten_dir  = fullfile(data_root, 'train', 'ims');
    params.train_whit_file = fullfile(data_root, 'train', 'dbs', sprintf('%s.mat', params.whitening));
    whit_folder            = fullfile(data_root, 'exp', 'whitening', ups, params.network); 
    if ~exist(whit_folder); mkdir(whit_folder); end;
    params.whit_file = fullfile(whit_folder, sprintf('%s.mat', params.whitening));

    params.feats_dir       = fullfile(data_root, 'exp', 'dsm', ups, params.network);
    if ~exist(params.feats_dir); mkdir(params.feats_dir); end;

end

function params = configure_dataset(params, dataset, data_root) 

    fprintf('>> %s: Processing test dataset...\n', dataset);		

    dataset_dir = fullfile(params.feats_dir, dataset);
    if ~exist(dataset_dir); mkdir(dataset_dir); end;

    params.withGetReg = true; %false;
    if params.withGetReg
        params.dsm_q_feats_file = fullfile(dataset_dir, 'q_local_feats.mat');
        params.q_descs_file     = fullfile(dataset_dir, 'q_descs.mat');
        params.dsm_db_feats_file = fullfile(dataset_dir, 'db_local_feats.mat');
        params.db_descs_file     = fullfile(dataset_dir, 'db_descs.mat');
    else
        params.dsm_q_feats_file = fullfile(dataset_dir, 'q_local_feats_wR.mat');
        params.q_descs_file     = fullfile(dataset_dir, 'q_descs.mat');
        params.dsm_db_feats_file = fullfile(dataset_dir, 'db_local_feats_wR.mat');
        params.db_descs_file     = fullfile(dataset_dir, 'db_descs.mat');
    end

    % Configuration per dataset
    params.D.name = dataset;
    params.D.cfg = configdataset(dataset, fullfile(data_root, 'test/'));
    [params.D.gnds, params.D.gnd_names] = config_gnd(params.D.cfg);
end

function [gnds, gnd_names] = config_gnd(cfg)

    % Configure Ground Truth 
    if isfield(cfg.gnd, 'easy')
        gnd_names = {'medium', 'hard', 'easy'};
        for i=1:numel(cfg.gnd)

            gndE(i).name = 'easy';
            gndM(i).name = 'medium';
            gndH(i).name = 'hard';

            gndE(i).ok = [cfg.gnd(i).easy];
            gndM(i).ok = [cfg.gnd(i).easy, cfg.gnd(i).hard]; 
            gndH(i).ok = [cfg.gnd(i).hard];

            gndE(i).junk = [cfg.gnd(i).junk, cfg.gnd(i).hard];
            gndM(i).junk = cfg.gnd(i).junk; 
            gndH(i).junk = [cfg.gnd(i).junk, cfg.gnd(i).easy];
        end
        gnds = {gndM, gndH, gndE};
    else
        gnd_names = {'normal'};
        gnds = {cfg.gnd, cfg.gnd};
    end
end
