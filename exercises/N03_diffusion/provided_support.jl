# 入力検証・描画・保存の提供ファイル。学生の編集対象ではありません。
using Plots, TOML
const DEFAULT_OUTPUT_DIR=joinpath(@__DIR__,"results")
positive_finite(v,name) = isfinite(v) && v>0 ? nothing : throw(ArgumentError("$name は有限な正の値です"))
validate_boundary(b) = b in (:fixed,:insulated) ? nothing : throw(ArgumentError("boundaryは:fixedまたは:insulatedです"))
validate_initial(i) = i in (:pulse,:mode) ? nothing : throw(ArgumentError("initialは:pulseまたは:modeです"))
function validate_buffers(a,b,boundary)
    validate_boundary(boundary)
    all(u->u isa AbstractVector{<:AbstractFloat},(a,b)) || throw(ArgumentError("新旧バッファは浮動小数の一次元配列です"))
    Base.require_one_based_indexing(a,b)
    length(a)==length(b)>=3 || throw(ArgumentError("新旧は同長で3点以上必要です"))
    Base.mightalias(a,b) && throw(ArgumentError("新旧バッファが重なっています"))
    all(isfinite,b) || throw(ArgumentError("旧配列は有限値にしてください"))
end
function validate_simulation_inputs(boundary,nx,d,fo,t,initial)
    validate_boundary(boundary); validate_initial(initial)
    !(nx isa Bool) && nx>=3 || throw(ArgumentError("nxは3以上の整数です（Bool不可）"))
    for (v,name) in ((d,"diffusivity"),(fo,"fo"),(t,"t_final"))
        positive_finite(v,name)
    end
end
function ensure_finite(values,step,t,fo)
    all(isfinite,values) || error("非有限値のため停止: step=$step, t=$t, effective_fo=$fo")
end
function summary_section(r)
    section=Dict{String,Any}("nx"=>length(r.x))
    for key in (:dx,:dt,:steps,:requested_fo,:fo,:t_final,:diffusivity,:initial_heat,:final_heat,
        :heat_change,:initial_minimum,:initial_maximum,:minimum,:maximum)
        section[string(key)]=getproperty(r,key)
    end
    all(isfinite,values(section)) || error("非有限な診断量は保存できません")
    return section
end
function convergence_results()
    result=Dict{String,Any}()
    for boundary in (:fixed,:insulated)
        nx=[41,81,161]
        runs=[simulate(;boundary,nx=n,initial=:mode) for n in nx]
        errors=[maximum(abs.(r.u-analytic_solution(r.x,r.t_final;boundary))) for r in runs]
        orders=log2.(errors[1:2]./errors[2:3])
        all(isfinite,vcat(errors,orders)) || error("非有限な収束診断量です")
        result[string(boundary)]=Dict("nx"=>nx,"dx"=>[r.dx for r in runs],"errors"=>errors,"orders"=>orders)
    end
    return result
end
function comparison_plot(a,b;unstable=false)
    p=plot(a.x,a.u0;label="Initial",linewidth=2,xlabel="x (dimensionless)",ylabel="u (dimensionless)",
        title="Diffusion, t = $(a.t_final)",size=(800,500))
    plot!(p,a.x,a.u;label=unstable ? "Stable (fo=$(round(a.fo;digits=4)))" : "Fixed temperature",linewidth=2)
    plot!(p,b.x,b.u;label=unstable ? "Unstable (fo=$(round(b.fo;digits=4)))" : "Insulated",linewidth=2)
    low=min(minimum(a.u0),minimum(a.u),minimum(b.u))
    high=max(maximum(a.u0),maximum(a.u),maximum(b.u))
    padding=max(0.05*(high-low),0.01)
    ylims!(p,(low-padding,high+padding))
    return p
end
function make_plots(directory,fixed,insulated,convergence)
    savefig(comparison_plot(fixed,insulated),joinpath(directory,"boundary-comparison.png"))
    p=plot(fixed.times,fixed.heat_history;label="Fixed temperature",linewidth=2,
        xlabel="t (dimensionless)",ylabel="Heat content H (dimensionless)",size=(800,500))
    plot!(p,insulated.times,insulated.heat_history;label="Insulated",linewidth=2)
    hline!(p,[fixed.initial_heat];label="Initial H",linestyle=:dash)
    savefig(p,joinpath(directory,"heat-content.png"))
    p=plot(;xscale=:log10,yscale=:log10,xlabel="dx",ylabel="Maximum absolute error",size=(800,500),legend=:topleft)
    for (boundary,label) in (("fixed","Fixed temperature"),("insulated","Insulated"))
        c=convergence[boundary]
        plot!(p,c["dx"],c["errors"];label,marker=:circle,linewidth=2)
    end
    c=convergence["fixed"]
    plot!(p,c["dx"],c["errors"][1].*(c["dx"]./c["dx"][1]).^2;label="Second order",linestyle=:dash)
    savefig(p,joinpath(directory,"convergence.png"))
end
function save_staged(draw,output_dir,summary,names)
    mktempdir() do temporary
        open(joinpath(temporary,"summary.toml"),"w") do io
            TOML.print(io,summary;sorted=true)
        end
        draw(temporary)
        sizes=[filesize(joinpath(temporary,n)) for n in names]
        all(s->0<s<=5*1024^2,sizes) && sum(sizes)<=10*1024^2 || error("N03出力サイズの上限を超えています")
        for n in filter(n->endswith(n,".png"),names)
            open(joinpath(temporary,n)) do io
                read(io,8)==UInt8[0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a] || error("PNG出力が不正です: $n")
            end
        end
        mkpath(output_dir)
        for n in names
            cp(joinpath(temporary,n),joinpath(output_dir,n);force=true)
        end
    end
end
function write_outputs(output_dir,fixed,insulated,convergence)
    summary=Dict("course_id"=>"N03","units"=>"dimensionless; heat_content H uses trapezoidal endpoint weights",
        "domain"=>[0.,2.],"diffusivity"=>0.1,"requested_fo"=>0.4,"t_final"=>1.,
        "fixed"=>summary_section(fixed),"insulated"=>summary_section(insulated),"convergence"=>convergence)
    save_staged(output_dir,summary,("boundary-comparison.png","heat-content.png","convergence.png","summary.toml")) do temp
        make_plots(temp,fixed,insulated,convergence)
    end
end
function make_stability_plot(directory,stable,unstable)
    savefig(comparison_plot(stable,unstable;unstable=true),joinpath(directory,"stability-comparison.png"))
end
function write_stability_outputs(output_dir,stable,unstable)
    summary=Dict("course_id"=>"N03","units"=>"dimensionless","boundary"=>"fixed",
        "stable"=>summary_section(stable),"unstable"=>summary_section(unstable))
    save_staged(output_dir,summary,("stability-comparison.png","summary.toml")) do temp
        make_stability_plot(temp,stable,unstable)
    end
end
