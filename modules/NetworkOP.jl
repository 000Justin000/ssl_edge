module NetworkOP
    using DataStructures;
    using IterativeSolvers;
    using LinearMaps;
    using Plots;
    using LaTeXStrings;
    using LinearAlgebra;
    using SparseArrays;

    export FlowNetwork

    # the FlowNetwork structure store the topology of a graph
    # VV: the coefficient of vertices
    # EE: the coefficients of the edges 
    # TT: the coefficients of the triangles
    # the coefficients maps to coefficients in hodge laplacian literatures, in the experiments of our paper, all coefficients are set to 1.0
    mutable struct FlowNetwork
        VV::OrderedDict{Int64, Float64}
        EE::OrderedDict{Tuple{Int64,Int64}, Float64}
        TT::Union{OrderedDict{Tuple{Int64,Int64,Int64},Float64}, Nothing}
    end

    function FlowNetwork(A::SparseMatrixCSC; computeTT=false)
        @assert issymmetric(A);
        @assert sum(abs.(diag(A))) == 0;
        I,J,V = findnz(A);

        # set the vertex coefficients
        VV = OrderedDict{Int64,Float64}();
        for u in 1:size(A,1)
            VV[u] = 1.0; # default weight is 1.0
        end

        # set the edge coefficients
        EE = OrderedDict{Tuple{Int64,Int64},Float64}();
        for (u,v) in zip(I,J)
            if (u < v)
                EE[(u,v)] = 1.0; # default weight is 1.0
            end
        end

        # we do not use this part of the code in this paper
        if (computeTT)
            # find the triangles and set their coefficients
            tid(i,j,k) = tuple(sort([i,j,k])...);
            TT = OrderedDict{Tuple{Int64,Int64,Int64},Float64}();
            d = vec(sum(sparse(I,J,ones(length(V)), size(A,1),size(A,2));dims=1));
            # create & compute outEdges list
            outE = Vector{Set{Int}}();
            for u in 1:length(VV)
                push!(outE, Set{Int}());
            end
            for (u,v) in keys(EE)
                src,dst = d[u]<=d[v] ? (u,v) : (v,u);
                push!(outE[src], dst);
            end
            for u in 1:length(VV)
                nbs = collect(outE[u]);
                for j in 1:length(nbs)
                    for k in j+1:length(nbs)
                        v = nbs[j];
                        w = nbs[k];
                        if ((v in outE[w]) || (w in outE[v]))
                            TT[tid(u,v,w)] = 1.0; # default weight is 1.0
                        end
                    end
                end
            end
        else
            TT = nothing;
        end

        return FlowNetwork(VV, EE, TT);
    end

    # given the anti-symmetric edge flow matrix, convert it to a vector where each element corresponds to an edge
    function mat2vec(FN::FlowNetwork, flow_mat::SparseMatrixCSC)
        @assert sum(abs.(flow_mat + flow_mat')) == 0;

        flow_vec = Vector{Float64}();
        for idx in keys(FN.EE)
            push!(flow_vec, flow_mat[idx...]);
        end

        return flow_vec;
    end

    # given the vector where each element corresponds to an edge, convert it to an anti-symmetric edge flow matrix
    function vec2mat(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert length(flow_vec) == length(FN.EE);

        I = Vector{Int64}();
        J = Vector{Int64}();
        V = Vector{Float64}();

        for (i,idx) in enumerate(keys(FN.EE))
            push!(I, idx[1]);
            push!(J, idx[2]);
            push!(V, flow_vec[i]);

            push!(I, idx[2]);
            push!(J, idx[1]);
            push!(V, -flow_vec[i]);
        end

        flow_mat = sparse(I,J,V, length(FN.VV), length(FN.VV));

        return flow_mat;
    end

    # return the adjacency matrix of the network
    function mat_adj(FN::FlowNetwork)
        I = Vector{Int64}();
        J = Vector{Int64}();
        V = Vector{Float64}();

        for (i,idx) in enumerate(keys(FN.EE))
            push!(I, idx[1]);
            push!(J, idx[2]);
            push!(V, 1.0);

            push!(I, idx[2]);
            push!(J, idx[1]);
            push!(V, 1.0);
        end

        return sparse(I,J,V, length(FN.VV), length(FN.VV));
    end

    # return the divergence operator as matrix, which is denoted as B in the paper
    function mat_div(FN::FlowNetwork)
        I = Vector{Int64}();
        J = Vector{Int64}();
        V = Vector{Float64}();

        for (i,idx) in enumerate(keys(FN.EE))
            push!(I, idx[1]);
            push!(J, i);
            push!(V,  FN.EE[idx]/FN.VV[idx[1]]);

            push!(I, idx[2]);
            push!(J, i);
            push!(V, -FN.EE[idx]/FN.VV[idx[2]]);
        end

        return sparse(I,J,V, length(FN.VV), length(FN.EE));
    end

    # apply the divergence operator to a vector
    function div(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert length(flow_vec) == length(FN.EE);

        div_vec = zeros(length(FN.VV));

        for (i,idx) in enumerate(keys(FN.EE))
            div_vec[idx[1]] += (FN.EE[idx]/FN.VV[idx[1]])*flow_vec[i];
            div_vec[idx[2]] -= (FN.EE[idx]/FN.VV[idx[2]])*flow_vec[i];
        end

        return div_vec;
    end

    # apply the gradient operator to a vector
    function divT(FN::FlowNetwork, pot_vec::Vector{Float64})
        @assert length(pot_vec) == length(FN.VV);

        flow_vec = Vector{Float64}();
        for idx in keys(FN.EE)
            push!(flow_vec, (FN.EE[idx]/FN.VV[idx[1]])*pot_vec[idx[1]]-
                            (FN.EE[idx]/FN.VV[idx[2]])*pot_vec[idx[2]]);
        end

        return flow_vec;
    end

    # return the curl operator as matrix, which is denoted as C in the paper
    function mat_curl(FN::FlowNetwork)
        @assert FN.TT != nothing;

        eid = Dict{Tuple{Int64,Int64},Int64}(idx=>i for (i,idx) in enumerate(keys(FN.EE)))

        I = Vector{Int64}();
        J = Vector{Int64}();
        V = Vector{Float64}();

        for (i,idx) in enumerate(keys(FN.TT))
            push!(I, i);
            push!(J, eid[(idx[1],idx[2])]);
            push!(V,  FN.TT[idx]/FN.EE[(idx[1],idx[2])]);

            push!(I, i);
            push!(J, eid[(idx[2],idx[3])]);
            push!(V,  FN.TT[idx]/FN.EE[(idx[2],idx[3])]);

            push!(I, i);
            push!(J, eid[(idx[1],idx[3])]);
            push!(V, -FN.TT[idx]/FN.EE[(idx[1],idx[3])]);
        end

        return sparse(I,J,V, length(FN.TT), length(FN.EE));
    end

    # apply the curl operator to a vector
    function curl(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert FN.TT != nothing
        @assert length(flow_vec) == length(FN.EE);

        flow_mat = vec2mat(FN, flow_vec);

        curl_vec = Vector{Float64}();
        for idx in keys(FN.TT)
            push!(curl_vec, (FN.TT[idx]/FN.EE[(idx[1],idx[2])])*flow_mat[idx[1],idx[2]]+
                            (FN.TT[idx]/FN.EE[(idx[2],idx[3])])*flow_mat[idx[2],idx[3]]-
                            (FN.TT[idx]/FN.EE[(idx[1],idx[3])])*flow_mat[idx[1],idx[3]]);
        end

        return curl_vec;
    end

    # apply the curl operator transpose to a vector
    function curlT(FN::FlowNetwork, curl_vec::Vector{Float64})
        @assert FN.TT != nothing;
        @assert length(curl_vec) == length(FN.TT)

        curlT_mat = vec2mat(FN, zeros(length(FN.EE)));

        for (i,idx) in enumerate(keys(FN.TT))
            curlT_mat[idx[1],idx[2]] += (FN.TT[idx]/FN.EE[(idx[1],idx[2])])*curl_vec[i];
            curlT_mat[idx[2],idx[3]] += (FN.TT[idx]/FN.EE[(idx[2],idx[3])])*curl_vec[i];
            curlT_mat[idx[1],idx[3]] -= (FN.TT[idx]/FN.EE[(idx[1],idx[3])])*curl_vec[i];

            curlT_mat[idx[2],idx[1]] -= (FN.TT[idx]/FN.EE[(idx[1],idx[2])])*curl_vec[i];
            curlT_mat[idx[3],idx[2]] -= (FN.TT[idx]/FN.EE[(idx[2],idx[3])])*curl_vec[i];
            curlT_mat[idx[3],idx[1]] += (FN.TT[idx]/FN.EE[(idx[1],idx[3])])*curl_vec[i];
        end

        return mat2vec(FN, curlT_mat);
    end

    # apply the laplacian matrix L
    function delta0(FN::FlowNetwork, pot_vec::Vector{Float64})
        @assert length(pot_vec) == length(FN.VV);
        return div(FN,divT(FN,pot_vec))
    end

    # apply the edge laplacian matrix Le
    function deltaE(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert length(flow_vec) == length(FN.EE);
        return divT(FN,div(FN,flow_vec))
    end

    # apply the hodge laplacian matrix
    function delta1(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert length(flow_vec) == length(FN.EE);
        return divT(FN,div(FN,flow_vec)) + curlT(FN,curl(FN,flow_vec));
    end

    # apply the cut-space projector
    function Q1(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert length(flow_vec) == length(FN.EE);

        op = LinearMap{Float64}(pp->divT(FN,pp), ff->div(FN,ff), length(FN.EE), length(FN.VV); ismutating=false);
        pot_vec = lsqr(op, flow_vec);

        return op * pot_vec;
    end

    # (curl-space) \union (harmonic-space) = cut-space
    # apply the curl-space projector
    function Q2(FN::FlowNetwork, flow_vec::Vector{Float64})
        @assert FN.TT != nothing;
        @assert length(flow_vec) == length(FN.EE);

        op = LinearMap{Float64}(cc->curlT(FN,cc), ff->curl(FN,ff), length(FN.EE), length(FN.TT); ismutating=false);
        curl_vec = lsqr(op, flow_vec);

        return op * curl_vec;
    end

    # apply the harmonic-space projector
    function Q3(FN::FlowNetwork, flow_vec::Vector{Float64})
        return flow_vec - Q1(FN, flow_vec) - Q2(FN, flow_vec);
    end

    # return the line graph of the original network
    function line_graph(FN::FlowNetwork)
        # construct the original network as list of adjacency set
        outE = Vector{Set{Int}}();
        for u in 1:length(FN.VV)
            push!(outE, Set{Int}());
        end
        for (u,v) in keys(FN.EE)
            push!(outE[u], v);
            push!(outE[v], u);
        end

        tup2id = Dict{Tuple{Int64,Int64}, Int64}(idx=>i for (i,idx) in enumerate(keys(FN.EE)));

        I = Vector{Int64}();
        J = Vector{Int64}();
        V = Vector{Float64}();

        for u in 1:length(FN.VV)
            nbs = collect(outE[u]);
            for j in 1:length(nbs)
                for k in j+1:length(nbs)
                    v = nbs[j];
                    w = nbs[k];

                    id_1 = tup2id[u<v ? (u,v) : (v,u)];
                    id_2 = tup2id[u<w ? (u,w) : (w,u)];

                    push!(I,id_1);
                    push!(J,id_2);
                    push!(V,1.0);

                    push!(I,id_2);
                    push!(J,id_1);
                    push!(V,1.0);
                end
            end
        end

        return FlowNetwork(sparse(I,J,V, length(FN.EE), length(FN.EE)))
    end
end
