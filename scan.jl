include("utils.jl")
using LaTeXStrings;
using HDF5, JLD

#------------------------------------------------------------------------
# This function run a given dataset with different ratio of labeled edges
#------------------------------------------------------------------------
function scan(network_name, fun_read, read_result=false, flow_data="ori", ratios=0.05:0.05:0.95, range=1:5)
    #--------------------------------------------------------------------
    if (read_result)
        dat = load("tmp/" * network_name * ".jld")["data"];
    else
        dat = Dict{Tuple{String,String},Tuple{Vector{Float64},Vector{Float64}}}();
    end

    algorithm  = ["zero_fill", "line_graph", "flow_ssl", "flow_ssl", "flow_ssl"][range];
    edge_set   = ["random", "random", "random", "rrqr", "rb"][range];
    colors     = ["black", "black", "red", "purple", "green"][range];
    linestyles = [:dash, :solid, :solid, :solid, :solid, :solid][range];
    labels     = ["ZeroFill", "LineGraph", "FlowSSL", "RRQR", "RB"][range];

    modified = false;
    h = Plots.plot(size=(270,220), framestyle=:box, title="", xlabel=L"\rm{ratio\ labeled\ } \left(|\mathcal{E}^{\rm L}| / |\mathcal{E}|\right)",
                                                              ylabel="relative error",
                                                              xlim=(0.0,1.0),
                                                              ylim=(0.0,1.0),
                                                              xlabelfont=font(12),
                                                              ylabelfont=font(12),
                                                              xtickfont=font(10),
                                                              ytickfont=font(10),
                                                              legendfont=font(10),
                                                              legend=:none);
    for i in 1:length(algorithm)
        if ((algorithm[i],edge_set[i]) in keys(dat))
            real_ratios,correlations = dat[(algorithm[i],edge_set[i])];
        else
            real_ratios = Vector{Float64}();
            correlations = Vector{Float64}();
            for ratio in ratios
                FN,flow_vec = fun_read();
                real_ratio,correlation = ssl_prediction(FN,flow_vec,ratio,flow_data,algorithm[i],edge_set[i]);
                push!(real_ratios,real_ratio);
                push!(correlations,correlation);
            end
            dat[(algorithm[i],edge_set[i])] = (real_ratios,correlations);
            modified = true;
        end
        od = sortperm(real_ratios); Plots.plot!(h, real_ratios[od], correlations[od], linestyle=linestyles[i], color=colors[i], label=labels[i]);
    end

    if (modified)
        save("tmp/" * network_name * ".jld", "data", dat);
    end
    Plots.savefig(h, "results/" * flow_data * "_" * network_name * ".pdf");
    #--------------------------------------------------------------------
end
#------------------------------------------------------------------------
