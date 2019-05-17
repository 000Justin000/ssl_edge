using NetworkOP
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

#------------------------------------------------------------------------------------------------
# this function pick the edge by magnitude of edge flows, 
# not appliable in practice, just serve as an upper bound
# on how well we can do
#------------------------------------------------------------------------------------------------
function ssl_flow(FN::FlowNetwork, flow_vec::Vector{Float64}, TrRatio=0.5; order="ascending", TrSet=Set{Int64}())
    #--------------------------------------------------------------------------------------------
    if (order == "ascending")
        od = sortperm(abs.(flow_vec));
    elseif (order == "descending")
        od = sortperm(abs.(flow_vec), rev=true);
    else
        throw(ArgumentError("flowId: invalid option"));
    end
    #--------------------------------------------------------------------------------------------
    for i in od
        #----------------------------------------------------------------------------------------
        push!(TrSet, i)
        #----------------------------------------------------------------------------------------
        if (length(TrSet) >= TrRatio * length(FN.EE))
            break
        end
        #----------------------------------------------------------------------------------------
    end
    #--------------------------------------------------------------------------------------------

    return TrSet, setdiff(Set(1:length(FN.EE)), TrSet);
end
#------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# select edge randomly
#------------------------------------------------------------------------------------------------
function ssl_rand(FN::FlowNetwork, TrRatio=0.5; TrSet=Set{Int64}())
    #--------------------------------------------------------------------------------------------
    od = randperm(MersenneTwister(0),length(FN.EE));
    #--------------------------------------------------------------------------------------------
    for i in od
        #----------------------------------------------------------------------------------------
        push!(TrSet, i)
        #----------------------------------------------------------------------------------------
        if (length(TrSet) >= TrRatio * length(FN.EE))
            break
        end
        #----------------------------------------------------------------------------------------
    end
    #--------------------------------------------------------------------------------------------

    @assert length(TrSet) == Int64(ceil(length(FN.EE)*TrRatio));

    return TrSet, setdiff(Set(1:length(FN.EE)), TrSet);
end
#------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# select edge with RRQR algorithm
#------------------------------------------------------------------------------------------------
function al_rrqr(FN::FlowNetwork, TrRatio=0.5; TrSet=Set{Int64}())
    TeId = collect(setdiff(Set(1:length(FN.EE)), TrSet));
    od = qr(nullspace(Matrix(NetworkOP.mat_div(FN)))'[:,TeId],Val(true)).p;
    union!(TrSet, TeId[od[1:Int64(ceil(length(FN.EE)*TrRatio))-length(TrSet)]]);

    @assert length(TrSet) == Int64(ceil(length(FN.EE)*TrRatio));

    return TrSet, setdiff(Set(1:length(FN.EE)), TrSet);
end
#------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# spectral embedding of vertices
#------------------------------------------------------------------------------------------------
function spectral_embedding(FN::FlowNetwork, ndim=2)
    A = NetworkOP.mat_adj(FN); L = spdiagm(0=>vec(sum(A,dims=1)))-A;
    tol = 1.0e-6+1.0; num_ev = ndim; result = nothing;
    while (true)
        global eigval,eigvec;
        while true
            try
                eigval,eigvec = eigs(L+I, nev=num_ev+1, which=:SM, maxiter=3000);
                break
            catch
                println("retry");
            end
        end

        if (sum(eigval .> tol) >= ndim)
            break
        else
            num_ev *= 2;
        end
    end

    fid = findfirst(eigval .> tol);
    X = collect(eigvec[:,fid:fid+1]');

    return X;
end
#------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# select edge with RB algorithm
#------------------------------------------------------------------------------------------------
function al_rb(FN::FlowNetwork, TrRatio; ndim=2)
    X = spectral_embedding(FN, ndim);

    TrSet = Set{Int64}();
    Clusters = OrderedDict{Int64,Vector{Int64}}(1=>collect(1:length(FN.VV)));
    edge2id = Dict{Tuple{Int64,Int64},Int64}(idx=>i for (i,idx) in enumerate(keys(FN.EE)));
    while (length(TrSet) < length(FN.EE) * TrRatio)
        #-------------------------------------------------
        # println(length(Clusters), "    ", length(TrSet)/length(FN.EE))
        #-------------------------------------------------
        max_id = argmax([length(cluster) for cluster in values(Clusters)]);
        cluster = Clusters[max_id];
        Xc = X[:,cluster];
        if (length(cluster) > 2)
            if (all(isapprox.(Xc,Xc[:,1])))
                cid = ones(Int64,length(cluster));
                cid[Int64(ceil(0.5*length(cluster))):end] .= 2;
            else
                Random.seed!(0);
                km = kmeans(Xc,2,init=:kmpp);
                cid = assignments(km);
            end
        elseif (length(cluster) == 2)
            cid = [1,2];
        else
            throw(ArgumentError("invalid cluster size"));
        end
        Clusters[max_id] = cluster[cid .== 1];
        Clusters[length(Clusters)+1] = cluster[cid .== 2];
        #-------------------------------------------------
        for i in Clusters[max_id]
            for j in Clusters[length(Clusters)]
                idx = (min(i,j),max(i,j));
                if (idx in keys(edge2id))
                    push!(TrSet, edge2id[idx]);
                end
            end
        end
        #-------------------------------------------------
    end

    cid = zeros(Int64,length(FN.VV));
    for (i,cluster) in enumerate(values(Clusters))
        cid[cluster] .= i;
    end

    return TrSet, setdiff(Set(1:length(FN.EE)), TrSet), X, cid;
end
#------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# this is the subroutine that actually performs the flow prediction
#------------------------------------------------------------------------------------------------
# FN:        FlowNetwork object encoding the topology of the network (see modules/NetworkOP.jl)
# flow_vec:  edge flows in a 1-d array, each element represents an edge
# ratio:     desired ratio of the edges to be labelled
# flow_data: "ori" then the flow_vec is going to be used
#            "syn" then create synthetic flows that is approximately divergence free
# algorithm: "zero_fill", alway predict zero flow for missing entries
#            "line_graph", use vertex-based semi-supervised learning algorithm on the line-graph
# edge_set:  "ascending", choose edges with the min edge flows
#            "descending", choose edges with the max edge flows
#            "random", choose edges by random
#            "rrqr", choose edges with RRQR algorithm
#            "rb", choose edges with RB algorithm
# lambda:    regulation parameter, same lambda in the paper
#------------------------------------------------------------------------------------------------
# ratio:     actual ratio of the edges to be labelled, this could differ from desired ratio due
#            to either rounding, or when RB algorithm is used
# rate:      correlation coefficient between ground truth and reconstructured edge flows
# flow_vec:  edge flows in a 1-d array, useful when flow_data="syn"
# f_vec:     reconstructured edge flows
# TrSet:     labeled set of edges
# TeSet:     unlabeled set of edges
#------------------------------------------------------------------------------------------------
function ssl_prediction(FN::FlowNetwork, flow_vec=nothing, ratio=0.5, flow_data="ori", algorithm="flow_regulation", edge_set="random", lambda=1.0e-1)
    #--------------------------------------------------------------------------------------------
    if (flow_data == "syn")
        u,s,v = svd(Matrix{Float64}(NetworkOP.mat_div(FN)), full=true)
        ss = vcat(s, zeros(length(FN.EE)-length(FN.VV)));
        flow_vec = v * (1.0 ./ (ss .+ lambda))
    else
        @assert flow_vec != nothing;
    end
    #--------------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------------
    if (edge_set in ["ascending", "descending"])
        TrSet,TeSet = ssl_flow(FN, flow_vec, ratio; order=edge_set); TeId = collect(TeSet);
    elseif (edge_set == "random")
        TrSet,TeSet = ssl_rand(FN, ratio); TeId = collect(TeSet);
    elseif (edge_set == "rrqr")
        TrSet,TeSet = al_rrqr(FN, ratio); TeId = collect(TeSet);
    elseif (edge_set == "rb")
        TrSet,TeSet = al_rb(FN, ratio); TeId = collect(TeSet);
    else
        throw(ArgumentError());
    end
    ratio = length(TrSet)/length(FN.EE);
    #--------------------------------------------------------------------------------------------

    #--------------------------------------------------------------------------------------------
    f0 = collect(flow_vec); f0[TeId] = zeros(length(TeId));
    expand = ff->collect(sparsevec(TeId,ff,length(FN.EE)));
    select = ff->ff[TeId];
    #--------------------------------------------------------------------------------------------
    if (algorithm == "flow_ssl")
        indices = collect(keys(FN.EE));
        lambda_vec = [lambda./sqrt(FN.VV[idx[1]] * FN.VV[idx[2]]) for idx in indices[TeId]];
        op = LinearMap{Float64}(ff->vcat(NetworkOP.div(FN,expand(ff)), lambda_vec.*ff),
                                pp->select(NetworkOP.divT(FN,pp[1:length(FN.VV)])) + lambda_vec.*pp[length(FN.VV)+1:end],
                                length(FN.VV)+length(TeId), length(TeId); ismutating=false);
        f, history = lsqr(op, vcat(-NetworkOP.div(FN,f0), lambda_vec.*zeros(length(TeId))); log=true, maxiter=1000);
        f_vec = f0 + collect(expand(f));
    elseif (algorithm == "line_graph")
        LG = NetworkOP.line_graph(FN)
        op = LinearMap{Float64}(pp->NetworkOP.divT(LG,expand(pp)),
                                ff->select(NetworkOP.div(LG,ff)),
                                length(LG.EE), length(TeId); ismutating=false);
        f, history = lsqr(op, -NetworkOP.divT(LG,f0); log=true, maxiter=1000);
        f_vec = f0 + expand(f);
    elseif (algorithm == "zero_fill")
        f_vec = collect(f0);
    else
        throw(ArgumentError());
    end
    #--------------------------------------------------------------------------------------------

    rate = cor(flow_vec, f_vec);
    err2 = norm(flow_vec - f_vec)/norm(flow_vec)
    println(flow_data, "    ", algorithm, "    ", edge_set, "    ", @sprintf("%.2f", ratio), "    ", @sprintf("%+.2f", rate), "    ", @sprintf("%+7.2f", err2));

    return ratio, rate, flow_vec, f_vec, TrSet, TeSet;
end
#------------------------------------------------------------------------------------------------
