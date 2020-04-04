% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function whit = train_whitening(params, net)

    if exist(params.whit_file, 'file')
        fprintf('\n>> %s: Loading whitening...\n', params.network);
        whit = load(params.whit_file);
        return
    else

        fprintf('\n>> %s: Computing whitening...\n', params.network);

        descfun = select_fun(params);

        % prepare GPUs if necessary
        numGpus = numel(params.use_gpu);
        if numGpus, fprintf('>> Preparing GPU(s)...\n'); end
        if numGpus > 1
            % check parallel pool integrity as it could have timed out
            pool = gcp('nocreate');
            if ~isempty(pool) && pool.NumWorkers ~= numGpus
                delete(pool);
            end
            pool = gcp('nocreate');
            if isempty(pool)
                parpool('local', numGpus);
            end
        end
        if numGpus >= 1
            if numGpus == 1
                gpuinfo = gpuDevice(params.use_gpu);
                net.move('gpu');
                fprintf('>>>> Running on GPU %s with Index %d\n', gpuinfo.Name, gpuinfo.Index);  
            else
                spmd
                    gpuinfo = gpuDevice(params.use_gpu(labindex));
                    fprintf('>>>> Running on GPU %s with Index %d\n', gpuinfo.Name, gpuinfo.Index);  
                end
            end
        end

        % Load training data filenames and pairs for whitening
        train_whiten = load(params.train_whit_file);
        if isfield(train_whiten, 'train') && isfield(train_whiten, 'val')
            cids  = [train_whiten.train.cids train_whiten.val.cids]; 
            qidxs = [train_whiten.train.qidxs train_whiten.val.qidxs+numel(train_whiten.train.cids)]; % query indexes 
            pidxs = [train_whiten.train.pidxs train_whiten.val.pidxs+numel(train_whiten.train.cids)]; % positive indexes
        else
            cids  = train_whiten.cids; 
                qidxs = train_whiten.qidxs; % query indexes 
                pidxs = train_whiten.pidxs; % positive indexes
        end

        % learn whitening
        fprintf('>> whitening: Extracting CNN descriptors for training images...\n');
        vecs_whiten = cell(1, numel(cids));
        if numGpus <= 1
            progressbar(0);
            for i=1:numel(cids)
                vecs_whiten{i} = descfun(imresizemaxd(imread(cid2filename(cids{i}, params.ims_whiten_dir)), params.test_imdim, 0), net);
                progressbar(i/numel(cids));
            end
        else
            time = tic;
            parfor i=1:numel(cids)
                if strcmp(net.device, 'cpu'), net.move('gpu'); end
                vecs_whiten{i} = descfun(imresizemaxd(imread(cid2filename(cids{i}, params.ims_whiten_dir)), params.test_imdim, 0), net);
            end
            fprintf('>>>> done in %s\n', htime(toc(time)));
        end
        vecs_whiten = cell2mat(vecs_whiten);

        fprintf('>> Whitening: Learning...\n');
        Lw = whitenlearn(vecs_whiten, qidxs, pidxs);
        save(params.whit_file, 'Lw', '-v7.3');

        whit.Lw = Lw
    end
end
