module N08N09Analysis
include("provided_support.jl")
function main(;selection="all",input_dir=DEFAULT_OUTPUT_DIR,output_dir=DEFAULT_OUTPUT_DIR,publish_options...)
    ids=selection_ids(selection);pairs=Dict(id=>read_fields(joinpath(input_dir,id,"fields.h5");expected_id=id) for id in ids)
    require(length(unique(pairs[id].metadata["run_id"] for id in ids))==1,"run_idが混在しています")
    staged(output_dir,Tuple(joinpath(id,"summary.toml") for id in ids);publish_options...) do stage
        for id in ids
            mkpath(joinpath(stage,id));write_toml(joinpath(stage,id,"summary.toml"),diagnostics(pairs[id],file_sha(joinpath(input_dir,id,"fields.h5"))))
        end
    end
    println("$(join(ids,"・")) 独立残差・解析解誤差・3格子収束を解析しました。")
end
abspath(PROGRAM_FILE)==(@__FILE__) && main(;selection=cli_selection(ARGS))
end
