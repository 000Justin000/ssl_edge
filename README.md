# Graph-based Semi-Supervised & Active Learning for Edge Flows

### This repository hosts the code and some example data for the following paper:  
[Graph-based Semi-Supervised & Active Learning for Edge Flows](https://arxiv.org/abs/1808.06544)  
[Junteng Jia](https://000justin000.github.io/), [Santiago Segarra](https://segarra.rice.edu/), [Michael T. Schaub](https://michaelschaub.github.io/) and [Austin R. Benson](https://www.cs.cornell.edu/~arb/)  
arXiv:1808.06544, 2018.

Our paper brings up the question of learning edge flows in a network with partial observation, assuming the network flow is approximately conserved (divergence-free).
- We propose to use the edge Laplacian to minimize the divergence of flows, which boils down to a least square problem that has efficient solution.
- We propose two algorithm for selecting edges to measure flows, the first strategy RRQR select edges to minimize reconstruction error bound, while the second recursive bisection (RB) algorithm cluster the graph and select bottleneck edges.


We have demonstrate in our paper that:
- Our proposed semi-supervised learning algorithm outperforms zerofill and linegraph baselines by a large margin.
- We gain additional mileage by using active learning strategies to select edges to measure. In particular, RRQR works well on network flows that are approximately divergence-free, while RB works well on network flows that have global trend.

Our code is tested under in Julia 1.1.0.

### Usage
In order to use our code on your own edge flows data, you first need to 1) provide the adjacency matrix A of your network 2) read your edge flows into an antisymmetric flow matrix F. Then you can create structures that are compatible with our code with the following. For a detailed example, we recommend the user to look at **read_TransportationNetwork** in [traffic.jl](traffic.jl)

```julia
FN = NetworkOP.FlowNetwork(A);
flow_vec = NetworkOP.mat2vec(FN, F);
```

**Input**: 
- `A` is the |V| x |V| adjacency matrix of the input network.
- `F` is a |V| x |V| anti-symmetirc flow matrix with F<sup>ij</sup> = -F<sup>ji</sup>

After that, 


### Network generation
Given vertex coordinates and vertex core scores, our model sample an instance of random network. Here is the code snippet for generating a random network for celegans dataset.

```julia
B = SCP_FMM.model_gen(theta, coords, Euclidean_CoM2, Euclidean(), epsilon; opt=opt);
```

**Output**:
- `B` is the adjacency matrix of the generated random network.

### Examples
For a more detailed explanation, please (see [examples](/examples)). For instance, the following code snippet reproduces figure 4 (A) in our paper.

```julia
include("examples/celegans_naive.jl");
include("examples/celegans_fmm.jl");
using Plots;

Plots.plot(size=(550,500),-5.0:0.1:1.0,-5.0:0.1:1.0,framestyle=:box,label="ideal",color="red",legend=:topleft);
Plots.scatter!(theta0,theta,label="experiment",color="blue")
```

If you have any questions, please email to [jj585@cornell.edu](mailto:jj585@cornell.edu).
