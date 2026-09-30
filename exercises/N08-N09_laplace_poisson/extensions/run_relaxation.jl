module RelaxationRun
include("relaxation.jl");include("extension_support.jl");include("extension_plots.jl")
using ThermofluidExercise
function main(;output_dir=DEFAULT_OUTPUT_DIR,jacobi_solver=ThermofluidExercise.Elliptic.solve_poisson,solver=RelaxationExtension.solve_relaxation,publish_options...)
    cases=Dict{String,Any}();run_id=bytes2hex(rand(UInt8,16))
    for id in ("jacobi","gauss_seidel","sor"),(nx,ny) in OFFICIAL_GRIDS
        p=problem("N09",nx,ny)
        solve=()->id=="jacobi" ? jacobi_solver(p.u0,p.g,p.f,p.dx,p.dy) : solver(p.u0,p.g,p.f,p.dx,p.dy;method=Symbol(id))
        solve() # warm-up: same shape and argument types, excluded from recorded time
        elapsed=@elapsed result=solve()
        cases[id*"_"*case_id(nx,ny)]=extension_case(p,result,id;method=id,omega=id=="sor" ? 1.5 : 1.,elapsed)
    end
    relative=joinpath("N09","extensions","relaxation");names=Tuple(joinpath(relative,n) for n in OUTPUT_FILES)
    staged(output_dir,names;publish_options...) do stage
        dir=joinpath(stage,relative);mkpath(dir);path=joinpath(dir,"fields.h5")
        pair=write_extension_fields(path,cases,extension_metadata("relaxation",run_id))
        summary=extension_diagnostics(pair,file_sha(path));write_toml(joinpath(dir,"summary.toml"),summary)
        write_toml(joinpath(dir,"plots.toml"),plot_extension(dir,pair,summary));check_extension(dir)
    end
    println("Jacobi・Gauss–Seidel・SORの反復数・誤差・通常実行時間を保存しました")
end
if abspath(PROGRAM_FILE)==(@__FILE__)
    isempty(ARGS) || error("run_relaxation.jlは引数なしです");main()
end
end
