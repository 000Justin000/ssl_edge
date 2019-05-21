# Semi-Supervised Learning for Edge Flows

### This repository hosts the code and some example data for the following paper:  
[Graph-based Semi-Supervised & Active Learning for Edge Flows](https://arxiv.org/abs/1905.07451)  
[Junteng Jia](https://000justin000.github.io/), [Santiago Segarra](https://segarra.rice.edu/), [Michael T. Schaub](https://michaelschaub.github.io/) and [Austin R. Benson](https://www.cs.cornell.edu/~arb/)  
arXiv:1905.07451, 2019.

Our paper brings up the problem of learning edge flows in a network with partial observation, assuming the network flow is approximately conserved (divergence-free).
- We propose to use the edge Laplacian to minimize the divergence of flows, which boils down to a least square problem that has efficient solution.
- We propose two active learning strategies for selecting the optimal set of edges to measure flows. The first strategy RRQR select edges to minimize reconstruction error bound, while the second recursive bisection (RB) algorithm cluster the graph and select bottleneck edges.


We have demonstrate in our paper that:
- Our proposed semi-supervised learning algorithm outperforms zerofill and linegraph baselines by a large margin.
- We gain additional mileage by using active learning strategies to select edges to measure. In particular, RRQR works well on flows that are approximately divergence-free, while RB works well on flows that have global trend.

Our code is tested under in Julia 1.1.0, you can install all dependent packages by running.
```
julia env.jl
```

### Usage
In order to use our code on your own edge flows data, you need to provide 1) the adjacency matrix **A** of your network 2) an antisymmetric flow matrix **F**. Then you can convert them to structures compatible with our code with the following.

```julia
FN = NetworkOP.FlowNetwork(A);
flow_vec = NetworkOP.mat2vec(FN, F);
```

The following is an example **read_TransportationNetwork** in [traffic.jl](traffic.jl). The first part of the function constructs the adjacency matrix of the graph as well as the anti-symmetric flow matrix from the input file.
```julia
#------------------------------------------------------------------------------------------------
function read_TransportationNetwork(file, VS, skipstart, col)
    dat = readdlm("data/TransportationNetworks/"*file, skipstart=skipstart);
    NV = length(VS);
    g = Graph(NV);
    id2num = Dict{Int64,Int64}(v=>i for (i,v) in enumerate(VS));

    # construct a graph and the anti-symmetric flow matrix
    I = Vector{Int64}();
    J = Vector{Int64}();
    V = Vector{Float64}();

    for i in 1:size(dat,1)
        if (Int64(dat[i,col[1]]) in keys(id2num) && Int64(dat[i,col[2]]) in keys(id2num))
            src = id2num[Int64(dat[i,col[1]])];
            dst = id2num[Int64(dat[i,col[2]])];
            flv = Float64(dat[i,col[3]]);

            # edge does not exist, but error when creating edge
            if (!has_edge(g, Edge(src,dst)) && !add_edge!(g, Edge(src,dst)))
                # print warning
                println(src,"---x-->", dst);
            end

            push!(I, src);
            push!(J, dst);
            push!(V, flv);

            push!(I,  dst);
            push!(J,  src);
            push!(V, -flv);
        end
    end

    # the FlowNetwork struct can be created by passing in the adjacency matrix
    FN = FlowNetwork(adjacency_matrix(g));

    # convert the anti-symmetric flow matrix to vector
    flow_vec = NetworkOP.mat2vec(FN, sparse(I,J,V, NV,NV, +));

    return FN, flow_vec;
end
#------------------------------------------------------------------------------------------------
```

After that, you can test our algorithm by the following function call, where **f_vec** is the reconstructured edge flows.
```julia
ratio, rate, flow_vec, f_vec, TrSet, TeSet = ssl_prediction(FN, flow_vec, ratio=0.5, algorithm="flow_regulation", edge_set="random")
```

In the line above,
- **ratio** keyword sets the ratio of labeled edges;
- **algorithm** keyword can be chosen from ["flow_ssl", "line_graph", "zero_fill"] and corresponds to our proposed algorithm and two base lines in the paper;
- **edge_set** keyword can be chosen from ["random", "rrqr", "rb"] and controls the strategy used to pick labeled edges; in particular, active learning strategies are actived by setting it to be "rrqr" or "rb".

A more detailed description of algorithm options and other outputs is given as the comments of **ssl_prediction** in [utils.jl](utils.jl).

### Reproduce Experiments in Paper
The plots in our paper can be reproduced by running.
```
julia run.jl
```
which would create figures under [/results](/results). Note this would take a long time due to 1) we are testing reconstruction quality at many different ratio of labeled edges 2) the SVD used for creating synthetic edge flows are cubic scaling 3) the QR factorization in RRQR strategy is cubic scaling. On the other hand, the recursive bisection strategy and the least-square solution for actual flow reconstruction is very efficient.

If you have any questions, please email to [jj585@cornell.edu](mailto:jj585@cornell.edu).
