using Random;
using LinearAlgebra;
using SparseArrays;
using DataFrames;
using CSV;
using NetworkOP;
using Plots;

include("utils.jl");

function read_Minnesota()
    df_topology = CSV.read("data/minnesota/minnesota.mtx", delim=' ', header=["src","dst"])
    num_id = unique(vcat(df_topology[:src],df_topology[:dst]));
    id2num_topology = Dict{Int64,Int64}(id=>i for (i,id) in enumerate(num_id));
    n = length(id2num_topology);
    #---------------------------------------------------------------------------------------
    I = Vector{Int64}();
    J = Vector{Int64}();
    V = Vector{Float64}();
    for i in 1:size(df_topology,1)
        if (df_topology[i,1] != df_topology[i,2])
            #------------------------
            push!(I,id2num_topology[df_topology[i,1]]);
            push!(J,id2num_topology[df_topology[i,2]]);
            push!(V,1.0);
            #------------------------
            push!(I,id2num_topology[df_topology[i,2]]);
            push!(J,id2num_topology[df_topology[i,1]]);
            push!(V,1.0);
            #------------------------
        end
    end
    A = sparse(I,J,V,n,n);
    FN = NetworkOP.FlowNetwork(A);

    coordinates = convert(Array{Float64,2},collect(reshape(CSV.read("data/minnesota/minnesota_coord.mtx",header=["num"])[:num],(2642,2))'))[:,num_id];

    return FN, nothing, coordinates
end
