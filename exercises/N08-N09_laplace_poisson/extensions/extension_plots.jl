using Plots
function plot_extension(dir,pair,summary)
    ext=pair.metadata["extension_id"];ids=ext=="neumann" ? collect(NEUMANN_CASES) : ["jacobi","gauss_seidel","sor"]
    panels=Any[];config=Dict{String,Any}()
    for id in ids
        c=pair.cases[id*"_"*case_id(33,25)];p=ext=="neumann" ? neumann_problem(id,33,25) : problem("N09",33,25)
        exact=copy(p.exact);ext=="neumann" && is_pure(p.bc) && (exact.-=weighted_mean(exact,p.dx,p.dy))
        limits=extrema(vcat(vec(c["u"]),vec(exact)));error=c["u"]-exact;e=max(maximum(abs,error),eps())
        config[id]=Dict("field_color_range"=>collect(limits),"error_color_range"=>[-e,e])
        for (a,t,clims,color) in ((c["u"],"$id numerical",limits,:viridis),(exact,"Exact",limits,:viridis),(error,"Error",(-e,e),:RdBu))
            ticks=color==:RdBu ? [-e,0.,e] : collect(range(clims...;length=3))
            push!(panels,heatmap(p.x,p.y,transpose(a);title=t,xlabel="x",ylabel="y",aspect_ratio=:equal,clims,color,titlefontsize=9,colorbar_ticks=ticks,colorbar_formatter=color==:RdBu ? :scientific : :auto))
        end
    end
    savefig(plot(panels...;layout=(length(ids),3),size=(1200,350length(ids)),margin=5Plots.mm),joinpath(dir,"fields.png"))
    residual=plot(;yscale=:log10,xlabel="Iteration",ylabel="Linf residual / update",size=(1000,600),legend=:outerright)
    for (id,color) in zip(ids,(:blue,:orange,:green,:purple,:red))
        c=pair.cases[id*"_"*case_id(33,25)];floor=1e-16
        plot!(residual,c["iteration"],max.(c["residual_history"],floor);label=id,color,linewidth=2)
        plot!(residual,c["iteration"],max.(c["update_history"],floor);label="$id update",color,linestyle=:dash)
        plot!(residual,[0,c["iterations"]],fill(max(c["threshold"],floor),2);label="$id threshold",color,linestyle=:dot)
    end
    savefig(residual,joinpath(dir,"residual.png"))
    convergence=plot(;xscale=:log10,yscale=:log10,xlabel="dx",ylabel="RMS error",size=(750,500))
    order_ids=ext=="neumann" ? ["pure_poisson_zero_flux"] : ids
    hs=[2/(n[1]-1) for n in OFFICIAL_GRIDS]
    for id in order_ids
        errors=[summary["cases"][id*"_"*case_id(n...)]["l2_error"] for n in OFFICIAL_GRIDS]
        plot!(convergence,hs,errors;marker=:circle,label=id)
        plot!(convergence,hs,errors[1].*(hs./hs[1]).^2;label="$id second order",linestyle=:dash)
    end
    savefig(convergence,joinpath(dir,"convergence.png"))
    merge(config,Dict("display_grid"=>case_id(33,25),"axis_order"=>"y,x","log_floor"=>1e-16,"schema_version"=>1,"extension_id"=>ext,"task_id"=>"N09","run_id"=>summary["run_id"],"source_fields_sha256"=>file_sha(joinpath(dir,"fields.h5")),"source_summary_sha256"=>file_sha(joinpath(dir,"summary.toml")),"png_sha256"=>Dict(n=>file_sha(joinpath(dir,n)) for n in PNG_FILES)))
end
