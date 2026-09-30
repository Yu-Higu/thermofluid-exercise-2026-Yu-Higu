module N08N09Run
include("simulate.jl")
include("analyze.jl")
include("plot.jl")
function main(;selection="all",output_dir=N08N09Simulation.DEFAULT_OUTPUT_DIR,simulation=N08N09Simulation.main,analysis=N08N09Analysis.main,plotting=N08N09Plots.main,publish_options...)
    N08N09Simulation.selection_ids(selection)
    mktempdir() do stage
        simulation(;selection,output_dir=stage)
        analysis(;selection,input_dir=stage,output_dir=stage)
        plotting(;selection,input_dir=stage,output_dir=stage)
        N08N09Simulation.check_complete(stage;selection)
        N08N09Simulation.publish(stage,output_dir,N08N09Simulation.output_names(selection);publish_options...)
    end
    println("$selection の公式出力を検証してまとめて反映しました。")
end
abspath(PROGRAM_FILE)==(@__FILE__) && main(;selection=N08N09Simulation.cli_selection(ARGS))
end
