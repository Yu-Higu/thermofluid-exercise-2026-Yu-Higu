module N08N09Simulation
using ThermofluidExercise
include("provided_support.jl")
const E=ThermofluidExercise.Elliptic
function simulate_case(id,nx,ny;laplace_solver=E.solve_laplace,poisson_solver=E.solve_poisson,atol=1e-10,rtol=1e-12,maxiter=200000)
    p=problem(id,nx,ny)
    try
        result=id=="N08" ? laplace_solver(p.u0,p.g,p.dx,p.dy;atol,rtol,maxiter) : poisson_solver(p.u0,p.g,p.f,p.dx,p.dy;atol,rtol,maxiter)
        require(result.converged,"reason=$(result.reason), iterations=$(result.iterations), residual=$(last(result.residual_history)), threshold=$(result.threshold)")
        Dict{String,Any}("nx"=>nx,"ny"=>ny,"dx"=>p.dx,"dy"=>p.dy,"case_id"=>p.case_id,"x"=>p.x,"y"=>p.y,"u"=>result.u,"f"=>p.f,"g"=>p.g,
            "converged"=>result.converged,"reason"=>string(result.reason),"iterations"=>result.iterations,"threshold"=>result.threshold,"initial_residual"=>first(result.residual_history),
            "residual_history"=>result.residual_history,"update_history"=>result.update_history,"iteration"=>collect(0:result.iterations))
    catch e;error("$id $(p.case_id) $(nx)x$(ny): $(sprint(showerror,e))");end
end
function main(;selection="all",output_dir=DEFAULT_OUTPUT_DIR,laplace_solver=E.solve_laplace,poisson_solver=E.solve_poisson,publish_options...)
    ids=selection_ids(selection);run_id=bytes2hex(rand(UInt8,16));names=Tuple(joinpath(id,"fields.h5") for id in ids)
    staged(output_dir,names;publish_options...) do stage
        for id in ids
            mkpath(joinpath(stage,id))
            cases=Dict(case_id(n...)=>simulate_case(id,n...;laplace_solver,poisson_solver) for n in OFFICIAL_GRIDS)
            write_fields(joinpath(stage,id,"fields.h5"),cases,source_metadata(id,run_id))
            diagnostics(read_fields(joinpath(stage,id,"fields.h5")),file_sha(joinpath(stage,id,"fields.h5")))
        end
    end
    println("$(join(ids,"・")) 定常場を保存しました。analyze.jl、plot.jlを実行してください。")
end
abspath(PROGRAM_FILE)==(@__FILE__) && main(;selection=cli_selection(ARGS))
end
