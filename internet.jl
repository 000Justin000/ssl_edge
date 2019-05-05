using Random;
using LinearAlgebra;
using SparseArrays;
using DataFrames;
using CSV;
using NetworkOP;
using Plots;

include("utils.jl");

function path(next,i,j)
    if (next[i,j] == -1)
        return Vector{Int64}();
    else
        path = Vector{Int64}([i]);
        while (i != j)
            i = next[i,j];
            push!(path,i)
        end
        return path;
    end
end

function read_Internet()
    #---------------------------------------------------------------------------------------
    df_topology = CSV.read("data/Internet/as19990110.txt", delim='\t', header=["src","dst"])
    #---------------------------------------------------------------------------------------
    id2num_topology = Dict{Int64,Int64}(id=>i for (i,id) in enumerate(unique(vcat(df_topology[:src],df_topology[:dst]))));
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
    #---------------------------------------------------------------------------------------

    FN = NetworkOP.FlowNetwork(A);

    return FN, nothing, nothing
end
