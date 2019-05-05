using Random;
using LinearAlgebra;
using SparseArrays;
using DataFrames;
using CSV;
using Dates;
using NetworkOP;
using Plots;

include("utils.jl");

function read_Music(delta_minutes=20, target="song")
    if (target == "song")
        target_id = :traid;
        target_name = :traname;
    elseif (target == "artist")
        target_id = :artid;
        target_name = :artname;
    end

    df = CSV.read("data/lastfm-dataset-1K/user000001.tsv", delim='\t', header=["userid","timestamp","artid","artname","traid","traname"]);
    df = df[[!ismissing(name) for name in df[target_name]],:];
    name2id = Dict{String,Int64}(name=>i for (i,name) in enumerate(unique(collect(skipmissing(df[target_name])))));
    n = length(name2id);

    userid_p = "user_000000"
    target_name_p = ""
    time_p = Dates.DateTime("2020-01-01T00:00:00Z", "yyyy-mm-dd\\THH:MM:SS\\Z")
    I = Vector{Int64}();
    J = Vector{Int64}();
    V = Vector{Float64}();
    for i in 1:size(df,1)
        t = Dates.DateTime(df[:timestamp][i], "yyyy-mm-dd\\THH:MM:SS\\Z")
        if (df[:userid][i] == userid_p && df[target_name][i] != target_name_p && (time_p-t).value/(delta_minutes*60*1000) < 1.0)
            push!(I,name2id[target_name_p]);
            push!(J,name2id[df[target_name][i]]);
            push!(V,-1.0);

            push!(I,name2id[df[target_name][i]]);
            push!(J,name2id[target_name_p]);
            push!(V,1.0);
        end
        userid_p = df[:userid][i];
        target_name_p = df[target_name][i];
        time_p = t;
    end

    W = sparse(I,J,V,n,n);
    I,J,V = findnz(W);
    A = sparse(I,J,ones(length(V)));

    FN = NetworkOP.FlowNetwork(A);
    flow_vec = NetworkOP.mat2vec(FN,W);

    return FN, flow_vec, nothing;
end
