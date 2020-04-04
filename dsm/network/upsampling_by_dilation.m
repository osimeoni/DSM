% Authors: O. Siméoni, Y. Avrithis, O. Chum. 2019.

function net = upsampling_by_dilation(net)

    % Pooling layers to be removed in vgg
    vggPoolLayer = 'pool4';
    vggIndex = net.getLayerIndex(vggPoolLayer); 

    % Pooling layers to be removed in resnet
    resStrideLayer = {'res5a_branch1', 'res5a_branch2a'};
    resIndex = net.getLayerIndex(resStrideLayer); 

    if vggIndex > 0
        % Change the dilation of next convolution
        for i = 1:size(net.layers, 2)
            if ~isempty(strfind(net.layers(i).name, 'conv5')) && all(i~=resIndex)
                if strcmp('dagnn.Conv', class(net.layers(i).block))
                    net.layers(i).block.dilate = net.layers(i).block.dilate *2; 
                end
            end
        end

        % Remove the Pooling layer
        net.layers(vggIndex-1).outputIndexes = net.layers(vggIndex).outputIndexes;
        net.layers(net.layers(vggIndex-1).outputIndexes).inputs = net.layers(vggIndex-1).outputs;
        net.layers(vggIndex).outputIndexes = [];
        net.removeLayer(net.layers(vggIndex).name);
    elseif resIndex > 0
        % Change the stride of next convolution
        for ind = resIndex
            % If network evolution already done continue
            if net.layers(ind).block.stride <= 1; return; end 
            net.layers(ind).block.stride = net.layers(ind).block.stride/2; 
        end

        % Dilate all above layers 
        for i = 1:size(net.layers, 2)
            if ~isempty(strfind(net.layers(i).name, 'res5')) && all(i~=resIndex)
                if strcmp('dagnn.Conv', class(net.layers(i).block))
                    net.layers(i).block.dilate = net.layers(i).block.dilate *2; 
                end
            end
        end

        % Pad where needed
        net.layers(net.getLayerIndex('res5a_branch2b')).block.pad = [2 2 2 2];
        net.layers(net.getLayerIndex('res5b_branch2b')).block.pad = [2 2 2 2];
        net.layers(net.getLayerIndex('res5c_branch2b')).block.pad = [2 2 2 2];
    else 
        disp('unknown pooling function')
        net.layers
    end
end
