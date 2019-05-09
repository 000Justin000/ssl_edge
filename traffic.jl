using NetworkOP;
using Random;
using LinearAlgebra;
using DataStructures;
using DelimitedFiles;
using Printf;
using Statistics;
using Clustering;
using SparseArrays;
using LightGraphs;
using LinearMaps;
using IterativeSolvers;
using Arpack;
using Optim;
using LaTeXStrings;
using Plots; pyplot()

include("utils.jl")



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



#------------------------------------------------------------------------------------------------
function read_Transportation(network_name)
    #--------------------------------------------------------------------------------------------
    coordinates = nothing;
    #--------------------------------------------------------------------------------------------
    if (network_name == "Anaheim")
        FN, flow_vec = read_TransportationNetwork("Anaheim/Anaheim_flow.tntp", 1:416, 6, [1,2,4]);
    elseif (network_name == "Barcelona")
        FN, flow_vec = read_TransportationNetwork("Barcelona/Barcelona_flow.tntp", 1:1020, 1, [1,2,3]);
    elseif (network_name == "ChicagoSketch")
        FN, flow_vec = read_TransportationNetwork("Chicago-Sketch/ChicagoSketch_flow.tntp", 388:933, 1, [1,2,3]);
        loc = readdlm("data/TransportationNetworks/Chicago-Sketch/ChicagoSketch_node.tntp", skipstart=1)[:,[2,3]];
        coordinates = [float(loc[i,j]) for j in 1:2, i in 388:933]
    elseif (network_name == "SiouxFalls")
        FN, flow_vec = read_TransportationNetwork("SiouxFalls/SiouxFalls_flow.tntp", 1:24, 1, [1,2,3]);
    elseif (network_name == "Winnipeg")
        FN, flow_vec = read_TransportationNetwork("Winnipeg/Winnipeg_flow.tntp", 1:1052, 1, [1,2,3]);
    else
        throw(ArgumentError());
    end
    #--------------------------------------------------------------------------------------------

    return FN, flow_vec, coordinates;
end
#------------------------------------------------------------------------------------------------
