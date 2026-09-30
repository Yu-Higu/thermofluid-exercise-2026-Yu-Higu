module N08N09Plots
using Plots
include("provided_support.jl")
function make_plots(stage,id,pair,summary)
    grid=case_id(33,25);c=pair.cases[grid];p=problem(id,33,25);u=c["u"];err=u-p.exact
    limits=extrema(vcat(vec(u),vec(p.exact)));e=max(maximum(abs,err),eps(Float64))
    panels=[];scales=[]
    for (a,title,clims,palette) in ((u,"Numerical",limits,:viridis),(p.exact,"Exact",limits,:viridis),(err,"Error u - exact",(-e,e),:RdBu))
        push!(panels,heatmap(p.x,p.y,transpose(a);xlabel="x",ylabel="y",title,
            xlims=extrema(p.x),ylims=extrema(p.y),xticks=0:0.5:2,yticks=0:0.5:1,
            clims,color=palette,colorbar=false,aspect_ratio=:equal,widen=false))
        values=collect(range(clims...;length=256))
        ticks=[first(values),(first(values)+last(values))/2,last(values)]
        push!(scales,heatmap(values,[0.,1.],repeat(transpose(values),2,1);
            clims,color=palette,colorbar=false,xlims=clims,ylims=(0.,1.),
            xticks=(ticks,string.(round.(ticks;sigdigits=3))),
            yaxis=false,grid=false,widen=false,tickfontsize=7))
    end
    layout=@layout [a b c; d{0.08h} e f]
    savefig(plot(panels...,scales...;layout,size=(1200,310),margin=5Plots.mm,left_margin=7Plots.mm),joinpath(stage,"fields.png"))
    residual=plot(;xlabel="Iteration (not time)",ylabel="Linf norm",yscale=:log10,legend=:topright,size=(850,520))
    colors=(:blue,:orange,:green)
    for ((nx,ny),color) in zip(OFFICIAL_GRIDS,colors)
        v=pair.cases[case_id(nx,ny)];iterations=v["iteration"];floor=1e-16
        plot!(residual,iterations,max.(v["residual_history"],floor);color,label="$nx × $ny residual",linewidth=2)
        plot!(residual,iterations,max.(v["update_history"],floor);color,label="$nx × $ny update",linestyle=:dash)
        plot!(residual,[0,last(iterations)],fill(max(v["threshold"],floor),2);color,label="$nx × $ny threshold",linestyle=:dot)
    end
    savefig(residual,joinpath(stage,"residual.png"))
    hs=[2/(nx-1) for (nx,ny) in OFFICIAL_GRIDS];l2=[summary["cases"][case_id(n...)]["l2_error"] for n in OFFICIAL_GRIDS];linf=[summary["cases"][case_id(n...)]["linf_error"] for n in OFFICIAL_GRIDS]
    convergence=plot(hs,l2;marker=:circle,xscale=:log10,yscale=:log10,label="Interior RMS",xlabel="dx (dy refined together)",ylabel="Error",size=(750,500))
    plot!(convergence,hs,linf;marker=:square,label="Interior Linf")
    plot!(convergence,hs,l2[1].*(hs./hs[1]).^2;label="Second order",linestyle=:dash,color=:black)
    savefig(convergence,joinpath(stage,"convergence.png"))
    Dict("display_grid"=>grid,"field_color_range"=>collect(limits),"error_color_range"=>[-e,e],"field_colormap"=>"viridis","error_colormap"=>"RdBu","log_floor"=>1e-16,"axis_order"=>"y,x")
end
function main(;selection="all",input_dir=DEFAULT_OUTPUT_DIR,output_dir=DEFAULT_OUTPUT_DIR,publish_options...)
    ids=selection_ids(selection)
    summaries=Dict(id=>read_summary(joinpath(input_dir,id,"summary.toml"),input_dir,id) for id in ids)
    require(length(unique(summaries[id]["run_id"] for id in ids))==1,"run_idが混在しています")
    names=Tuple(joinpath(id,n) for id in ids for n in (PNG_FILES...,"plots.toml"))
    staged(output_dir,names;publish_options...) do stage
        for id in ids
            dir=joinpath(stage,id);mkpath(dir);pair=read_fields(joinpath(input_dir,id,"fields.h5");expected_id=id);summary=summaries[id]
            config=make_plots(dir,id,pair,summary)
            doc=merge(config,Dict("schema_version"=>1,"task_id"=>id,"run_id"=>summary["run_id"],"source_fields_sha256"=>file_sha(joinpath(input_dir,id,"fields.h5")),"source_summary_sha256"=>file_sha(joinpath(input_dir,id,"summary.toml")),"png_sha256"=>Dict(n=>file_sha(joinpath(dir,n)) for n in PNG_FILES)))
            write_toml(joinpath(dir,"plots.toml"),doc)
        end
    end
    println("N08-N09の指定図と来歴を保存しました。")
end
abspath(PROGRAM_FILE)==(@__FILE__) && main(;selection=cli_selection(ARGS))
end
