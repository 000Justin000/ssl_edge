# Graph-based Semi-Supervised & Active Learning for Edge Flows

### This repository hosts the code and some example data for the following paper:  
[Graph-based Semi-Supervised & Active Learning for Edge Flows](https://arxiv.org/abs/1808.06544)  
[Junteng Jia](https://000justin000.github.io/), [Santiago Segarra](https://segarra.rice.edu/), [Michael T. Schaub](https://michaelschaub.github.io/) and [Austin R. Benson](https://www.cs.cornell.edu/~arb/)  
arXiv:1808.06544, 2018.

Our paper brings up the question of learning edge flows in a network with partial observation, assuming the network flow is approximately conserved (divergence-free).
- We propose to use the edge Laplacian to minimize the divergence of flows, which boils down to a least square problem that has efficient solution.
- We propose two active learning strategies for selecting the optimal set of edges to measure flows. The first strategy RRQR select edges to minimize reconstruction error bound, while the second recursive bisection (RB) algorithm cluster the graph and select bottleneck edges.


We have demonstrate in our paper that:
- Our proposed semi-supervised learning algorithm outperforms zerofill and linegraph baselines by a large margin.
- We gain additional mileage by using active learning strategies to select edges to measure. In particular, RRQR works well on flows that are approximately divergence-free, while RB works well on flows that have global trend.

Our code is tested under in Julia 1.1.0, you can install all dependent packages by running [env.jl](env.jl).

### Usage
In order to use our code on your own edge flows data, you first need to 1) provide the adjacency matrix **A** of your network 2) read your edge flows into an antisymmetric flow matrix **F**. Then you can create structures that are compatible with our code with the following. For a detailed example, we recommend the user to look at **read_TransportationNetwork** in [traffic.jl](traffic.jl)

```julia
FN = NetworkOP.FlowNetwork(A);
flow_vec = NetworkOP.mat2vec(FN, F);
```

After that, you can test our algorithm by the following function call. A detailed description of the input and output of this function is given in [utils.jl](utils.jl).

```julia
ratio, rate, flow_vec, f_vec, TrSet, TeSet = ssl_prediction(FN, flow_vec)
```

### Reproduce Experiments in Paper
The plots in our paper can be reproduced by running.
```
julia run.jl
```
which would create figures under [/results](/results).

If you have any questions, please email to [jj585@cornell.edu](mailto:jj585@cornell.edu).
