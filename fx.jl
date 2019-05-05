push!(LOAD_PATH, "./modules")

using NetworkOP;
using Random;
using LinearAlgebra;
using SparseArrays;
using DataFrames;
using CSV;
using JuMP;
using Gurobi;
using LaTeXStrings;
using Plots; pyplot();

function read_FX()
    dat = CSV.read("data/ForeignExchange/FX_1538758800.csv", delim=',')
    currencies = sort(collect(Set(dat[:base_currency])));
    c2num = Dict(currency => i for (i,currency) in enumerate(currencies));

    I = Vector{Int64}();
    J = Vector{Int64}();
    E = Vector{Float64}();

    Vbid = Vector{Float64}();
    Vask = Vector{Float64}();
    Vmid = Vector{Float64}();

    for i in 1:size(dat,1)
        if (dat[:base_currency][i] != dat[:quote_currency][i])
            push!(I, c2num[dat[:base_currency][i]]);
            push!(J, c2num[dat[:quote_currency][i]]);
            push!(E, 1.0);

            push!(Vbid, log(dat[:bid][i]));
            push!(Vask, log(dat[:ask][i]));
            push!(Vmid, (log(dat[:bid][i])+log(dat[:ask][i]))/2.0);
        end
    end

    Mbid = sparse(I,J,Vbid);
    Mask = sparse(I,J,Vask);
    Mmid = sparse(I,J,Vmid);

    MatBidAsk = (Mbid-Mask')/2.0;
    MatMid = (Mmid-Mmid')/2.0;
    MatBid = (triu(MatBidAsk) - triu(MatBidAsk)');
    MatAsk = (tril(MatBidAsk) - tril(MatBidAsk)');

    FN = FlowNetwork(sparse(I,J,E));

    return FN, NetworkOP.mat2vec(FN,MatBid), NetworkOP.mat2vec(FN,MatMid), NetworkOP.mat2vec(FN,MatAsk)
end


function test_FX(lambda=1.0e-1)
    FN, bid, mid, ask = read_FX();

    n = length(FN.VV);
    m = length(FN.EE);

    e2id = Dict(e=>i for (i,e) in enumerate(keys(FN.EE)));

    model = Model(solver=GurobiSolver(Presolve=0));
    @variable(model, bid[i] <= prc[i=1:m] <= ask[i]);
    @objective(model, Min, sum((prc[e2id[(i,j)]]+prc[e2id[(j,k)]]-prc[e2id[(i,k)]])^2.0 for i=1:n, j=i+1:n, k=j+1:n) + lambda^2.0*sum((prc[i]-mid[i])^2.0 for i=1:m));
    status = solve(model);

    slv = getvalue(prc);
    svc = (ask-bid).^1.0;
    h = plot(size=(390,300), xlabel="currency pair index", ylabel=L"r_{\rm n}^{\rm A/B}", ylim=[-0.70,0.50], yticks=-0.50:0.25:0.50, framestyle=:box, legend=:topleft);
    scatter!(h, (slv-mid)./svc, color=1, markerstrokecolor=1, markersize=2.5, label="fair");
    plot!(h, (mid-mid)./svc, color=2, linewidth=2.0, label="mid");
    plot!(h, (bid-mid)./svc, color=3, linewidth=2.0, label="bid");
    plot!(h, (ask-mid)./svc, color=4, linewidth=2.0, label="ask");

    #---------------------------------------------------------------------------
    obj = 0.0;
    #---------------------------------------------------------------------------
    for i in 1:n
        for j in i+1:n
            for k in j+1:n
                obj += (slv[e2id[(i,j)]]+slv[e2id[(j,k)]]-slv[e2id[(i,k)]])^2.0;
            end
        end
    end
    #---------------------------------------------------------------------------
    for i in 1:m
        obj += lambda^2.0*(slv[i]-mid[i])^2.0;
    end
    #---------------------------------------------------------------------------
    println(obj);
    println(model.objVal);
    @assert isapprox(obj, model.objVal; atol=1.0e-10, rtol=1.0e-3);
    #---------------------------------------------------------------------------

    Plots.savefig(h, "results/fx.svg");

    return h, FN, model, bid, mid, ask, slv, obj
end
