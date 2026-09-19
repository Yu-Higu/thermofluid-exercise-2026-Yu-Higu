# 入力検証・描画・保存を担当する提供ファイル。学生の編集対象ではありません。
using Plots
using TOML
const DEFAULT_OUTPUT_DIR = joinpath(@__DIR__, "results")

function validate_boundary(boundary)
    boundary in (:fixed, :periodic) || throw(ArgumentError("boundaryは:fixedまたは:periodicです"))
end
function validate_simulation_inputs(boundary, nx, cfl, t_final)
    validate_boundary(boundary)
    !(nx isa Bool) && nx >= 3 || throw(ArgumentError("nxは3以上の整数です（Bool不可）"))
    isfinite(cfl) && 0 < cfl <= 1 || throw(ArgumentError("cflは有限で0 < cfl <= 1です"))
    isfinite(t_final) && t_final > 0 || throw(ArgumentError("t_finalは有限な正の値です"))
end
function validate_step_inputs(u_new, u_old, dt, dx, boundary)
    validate_boundary(boundary)
    all(u -> u isa AbstractVector{<:AbstractFloat}, (u_new,u_old)) ||
        throw(ArgumentError("新旧バッファは浮動小数の一次元配列です"))
    Base.require_one_based_indexing(u_new,u_old)
    length(u_new) == length(u_old) >= 3 || throw(ArgumentError("新旧は同長で3点以上必要です"))
    Base.mightalias(u_new,u_old) && throw(ArgumentError("新旧バッファが重なっています"))
    all(isfinite,u_old) || throw(ArgumentError("旧配列は有限値にしてください"))
    all(>=(0),u_old) || throw(ArgumentError("後退差分では非負の旧配列だけを扱います"))
    all(v -> isfinite(v) && v > 0, (dt,dx)) || throw(ArgumentError("dtとdxは有限な正の値です"))
    courant = maximum(abs,u_old) * dt / dx
    isfinite(courant) && courant <= 1 + 32eps(Float64) ||
        throw(ArgumentError("更新前の実効CFLが1を超えています"))
end
function summary_section(result; periodic=false)
    section = Dict{String,Any}("nx"=>length(result.x))
    for key in (:dx,:steps,:dt,:max_cfl,:initial_minimum,:initial_maximum,:minimum,:maximum,:overshoot,:undershoot)
        section[string(key)] = getproperty(result,key)
    end
    if periodic
        for key in (:initial_sum,:final_sum,:sum_change)
            section[string(key)] = getproperty(result,key)
        end
    end
    all(isfinite,values(section)) || error("非有限な診断量は保存できません")
    section
end
function make_plots(output_dir, fixed, periodic)
    for (r, name, label) in ((fixed,"fixed-boundary.png","Fixed boundary"),(periodic,"periodic.png","Periodic boundary"))
        # 周期の末尾へ表示用の点だけ追加する。診断の配列には混ぜない。
        x = label == "Periodic boundary" ? vcat(r.x,2.0) : r.x
        initial = label == "Periodic boundary" ? vcat(r.u0,r.u0[1]) : r.u0
        final = label == "Periodic boundary" ? vcat(r.u,r.u[1]) : r.u
        p = plot(x,initial;label="Initial",linewidth=2,xlabel="x",ylabel="u",
            title="$label, t = $(r.t_final)",size=(800,500),ylims=(0.9,2.1))
        plot!(p,x,final;label="Final",linewidth=2)
        savefig(p,joinpath(output_dir,name))
    end
end
function write_outputs(output_dir, fixed, periodic, cfl, t_final)
    summary = Dict("course_id"=>"N02", "domain"=>[0.0,2.0], "requested_cfl"=>cfl,
        "t_final"=>t_final,"fixed"=>summary_section(fixed),"periodic"=>summary_section(periodic;periodic=true))
    # 全ファイルを一時領域で生成してから正式パスへ移す。生成失敗なら既存結果を保持。
    mktempdir() do temporary
        open(joinpath(temporary,"summary.toml"),"w") do io
            TOML.print(io,summary;sorted=true)
        end
        make_plots(temporary,fixed,periodic)
        names = ("fixed-boundary.png","periodic.png","summary.toml")
        sizes = [filesize(joinpath(temporary,n)) for n in names]
        maximum(sizes) <= 5*1024^2 && sum(sizes) <= 10*1024^2 || error("N02出力サイズの上限を超えています")
        mkpath(output_dir)
        for name in names
            cp(joinpath(temporary,name),joinpath(output_dir,name);force=true)
        end
    end
end
