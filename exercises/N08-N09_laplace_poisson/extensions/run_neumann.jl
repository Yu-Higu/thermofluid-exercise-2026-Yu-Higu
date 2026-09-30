module NeumannRun
include("neumann.jl");include("extension_support.jl");include("extension_plots.jl")
function main(;output_dir=DEFAULT_OUTPUT_DIR,solver=NeumannExtension.solve_neumann,publish_options...)
    cases=Dict{String,Any}();run_id=bytes2hex(rand(UInt8,16))
    # All compatibility checks and calculations precede staging and publication.
    for id in NEUMANN_CASES,(nx,ny) in OFFICIAL_GRIDS
        p=neumann_problem(id,nx,ny);result=solver(p.u0,p.f,p.dx,p.dy,p.bc)
        cases[id*"_"*case_id(nx,ny)]=extension_case(p,result,id)
    end
    relative=joinpath("N09","extensions","neumann");names=Tuple(joinpath(relative,n) for n in OUTPUT_FILES)
    staged(output_dir,names;publish_options...) do stage
        dir=joinpath(stage,relative);mkpath(dir);path=joinpath(dir,"fields.h5")
        pair=write_extension_fields(path,cases,extension_metadata("neumann",run_id))
        summary=extension_diagnostics(pair,file_sha(path));write_toml(joinpath(dir,"summary.toml"),summary)
        write_toml(joinpath(dir,"plots.toml"),plot_extension(dir,pair,summary));check_extension(dir)
    end
    println("Neumann発展の混合→純Neumannを検証・保存しました")
end
if abspath(PROGRAM_FILE)==(@__FILE__)
    isempty(ARGS) || error("run_neumann.jlは引数なしです");main()
end
end
