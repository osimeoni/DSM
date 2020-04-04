# Deep Spatial Matching (DSM)

This repository provides a MATLAB implementation of the the deep spatial matching (DSM) method introduced in our CVPR 2019 paper:

**Local Features and Visual Words Emerge in Activations** 
[Siméoni O.](http://people.rennes.inria.fr/Oriane.Simeoni/), [Avrithis Y.](https://avrithis.net/), [Chum O.](http://cmp.felk.cvut.cz/~chum/), 
CVPR 2019 [[arXiv](https://arxiv.org/abs/1905.06358)]

<p align="center">
  <img src="http://people.rennes.inria.fr/Oriane.Simeoni/img/cvpr2019.jpg" width="460" height="300" >
</div>

<p align="justify">
Our method allows to refine image retrieval ranking. Initial ranking is based on image descriptors extracted from convolutional neural network activations by global pooling, as in recent state-of-the-art work. However, the same sparse 3D activation tensor is also approximated by a collection of local features. These local features are then robustly matched to approximate the optimal alignment of the tensors. This happens <strong>without any network modification</strong>, additional layers or training. No local feature detection happens on the original image. <strong>No local feature descriptors and no visual vocabulary are needed throughout the whole process.</strong>
</p>


## Usage

This section introduces the different steps in order to run the evaluation presented in the paper.

*This code borrows heavily from the CNN Image Retrieval framework published by Radenovic et al, which can be found at https://github.com/filipradenovic/cnnimageretrieval.*


### Prerequities
In order to run this toolbox you will need:

- MATLAB (tested with MATLAB R2017a on Debian 8.1)
- [MatConvNet MATLAB toolbox version 1.0-beta25](https://www.vlfeat.org/matconvnet/)

### 1. Models

The DSM method is used on 3 different sets of retrieval models:
- MAC pooling: Please [download](https://drive.google.com/open?id=1konm3rVuCwNQO4H7AlLR_nbv9gcqQvZw) the VGG16 and ResNet101 models retrained by us on the [SfM-120k dataset](https://arxiv.org/abs/1711.02512) using MAC pooling. [[Link]](https://drive.google.com/open?id=1konm3rVuCwNQO4H7AlLR_nbv9gcqQvZw).
- GeM pooling: Both VGG16 and ResNet101 trained using GeM pooling by Radenovic etal will be automatically downloaded by the script. 
- Off-the-shelf: Models trained on Imagenet [To come]

Make sure the models folders are placed in *data/networks*. Full paths should be as following : *data/networks/dsm-retrained/dsm-retrained-mac-vgg.mat* 

### 2. Matlab

Launch matlab
```
>> run [MATCONVNET_ROOT]/matlab/vl_setupnn;
```

### 3. Setup

The following scripts sets matlab libraries correctly.  
```
>> run [CNNIMAGERETRIEVAL_ROOT]/setup_dsm;
```

### 4. Evaluation

Code for evaluating the method can be found in the examples at: ```[CNNIMAGERETRIEVAL_ROOT]/examples/test_dsm```. 

In order to test the different models, please change the parameter ```params.network```. The available options are

- `'retrievalSfM120k-gem-vgg'`: the official VGG-GeM model trained by Radenovic etal.
- `'retrievalSfM120k-gem-resnet101'`: the official ResNet101-GeM model trained by Radenovic etal.
- `'dsm-retrained-mac-vgg'`: VGG-MAC retrained on the SfM-120k dataset by Simeoni etal.
- `'dsm-retrained-mac-resnet101'`: ResNet101-MAC retrained on the SfM-120k dataset by Simeoni etal.
- `'imagenet-vgg'`: VGG-MAC retrained on the SfM-120k dataset by Simeoni etal.
- `'imagenet-resnet101'`: ResNet101-MAC retrained on the SfM-120k dataset by Simeoni etal.


Once set as desired, the script can be run using:

```
>> test_dsm
```


### Citation
```
@inproceedings{SAC18,
 author = {Siméoni O. and Avrithis, Y. and Chum, O.},
 title = {Local Features and Visual Words Emerge in Activations},
 booktitle = {CVPR},
 year = {2019}
}
```

### Contact

oriane.simeoni at inria.fr
