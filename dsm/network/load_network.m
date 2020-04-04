% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function net = load_network(params)

    if ~exist(params.network_file); error('Non existing network file'); end;

    % Load Network
    N = load(params.network_file);
    net = dagnn.DagNN.loadobj(N.net);

    if params.DSM.upscale; 
        fprintf('>> Upscaling the network...\n'); 
        net = upsampling_by_dilation(net); end;
    end
