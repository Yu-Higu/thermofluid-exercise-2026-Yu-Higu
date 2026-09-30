# 提供: 定常場の問題生成、独立診断、保存と反映。
using HDF5, SHA, TOML
const DEFAULT_OUTPUT_DIR=joinpath(@__DIR__,"results")
const OFFICIAL_GRIDS=((17,13),(33,25),(65,49))
const OUTPUT_FILES=("fields.h5","summary.toml","fields.png","residual.png","convergence.png","plots.toml")
const PNG_FILES=("fields.png","residual.png","convergence.png")
const ROOT_KEYS=("schema_version","task_id","equation","domain","units","grid_location","boundary","method","atol","rtol","maxiter","run_id","code_sha256","git_head")
const CASE_KEYS=("nx","ny","dx","dy","case_id","converged","reason","iterations","threshold","initial_residual")
const DATA_KEYS=("x","y","u","f","g","residual_history","update_history","iteration")
require(ok,msg)=ok ? nothing : throw(ArgumentError(msg))
file_sha(path)=bytes2hex(sha256(read(path)))
write_toml(path,doc)=open(io->TOML.print(io,doc;sorted=true),path,"w")
case_id(nx,ny)="n$(lpad(nx,3,'0'))x$(lpad(ny,3,'0'))"
function selection_ids(selection)
    require(selection in ("N08","N09","all"),"引数はN08／N09／allです")
    selection=="all" ? ("N08","N09") : (selection,)
end
function cli_selection(args)
    require(length(args)<=1,"引数は[N08|N09|all]です")
    selection=isempty(args) ? "all" : only(args);selection_ids(selection);selection
end
H(x,y)=1+x/2+y+sin(pi*x/2)*sinh(pi*y/2)/sinh(pi/2)
V(x,y)=sin(pi*x/2)*sin(pi*y)
function problem(id,nx,ny)
    selection_ids(id);require(id!="all","単一IDが必要です")
    require(all(n->n isa Integer && !(n isa Bool) && n>=3,(nx,ny)),"節点数は各軸3以上の整数です")
    x=collect(range(0.,2.;length=nx));y=collect(range(0.,1.;length=ny));dx=2/(nx-1);dy=1/(ny-1)
    exact=[H(xi,yj)+(id=="N09" ? V(xi,yj) : 0.) for xi in x,yj in y]
    f=[id=="N09" ? -((pi/2)^2+pi^2)*V(xi,yj) : 0. for xi in x,yj in y]
    g=zeros(nx,ny);g[1,:]=exact[1,:];g[end,:]=exact[end,:];g[:,1]=exact[:,1];g[:,end]=exact[:,end]
    (;x,y,dx,dy,exact,f,g,u0=zeros(nx,ny),case_id=id=="N08" ? "laplace_dirichlet" : "poisson_dirichlet")
end
function source_metadata(id,run_id;atol=1e-10,rtol=1e-12,maxiter=200000)
    root=normpath(joinpath(@__DIR__,"..",".."))
    paths=("src/N08N09Elliptic.jl",relpath(joinpath(@__DIR__,"simulate.jl"),root),relpath(@__FILE__,root))
    hashes=Dict(p=>file_sha(joinpath(root,p)) for p in paths)
    code=sprint(io->TOML.print(io,hashes;sorted=true))
    head=try String(readchomp(pipeline(`git -C $root rev-parse HEAD`;stderr=devnull))) catch; "unversioned" end
    Dict{String,Any}("schema_version"=>1,"task_id"=>id,"equation"=>id=="N08" ? "laplace_2d" : "poisson_2d",
        "domain"=>[0.,2.,0.,1.],"units"=>"1","grid_location"=>"node","boundary"=>"dirichlet","method"=>"jacobi",
        "atol"=>atol,"rtol"=>rtol,"maxiter"=>maxiter,"run_id"=>run_id,"code_sha256"=>code,"git_head"=>head)
end
read_attribute(o,k)=haskey(attributes(o),k) ? read(attributes(o)[k]) : throw(ArgumentError("必要属性欠落: $k"))
function validate_metadata(meta)
    id=meta["task_id"];require(id in ("N08","N09"),"task_id不一致")
    require(meta["schema_version"]==1 && meta["equation"]==(id=="N08" ? "laplace_2d" : "poisson_2d") && meta["domain"]==[0.,2.,0.,1.],"schema／領域／方程式不一致")
    require(meta["units"]=="1" && meta["grid_location"]=="node" && meta["boundary"]=="dirichlet" && meta["method"]=="jacobi","単位／節点／境界／手法不一致")
    require(all(v->v isa Real && isfinite(v) && v>=0,(meta["atol"],meta["rtol"])) && max(meta["atol"],meta["rtol"])>0,"許容値不正")
    require(meta["maxiter"] isa Integer && !(meta["maxiter"] isa Bool) && meta["maxiter"]>0,"maxiter不正")
    require(meta["run_id"] isa String && occursin(r"^[0-9a-f]{32}$",meta["run_id"]),"run_id不正")
    hashes=TOML.parse(meta["code_sha256"])
    require(!isempty(hashes) && all(v->v isa String && occursin(r"^[0-9a-f]{64}$",v),values(hashes)) && meta["git_head"] isa String && !isempty(meta["git_head"]),"ソース来歴不正")
end
function validate_case(c,grid,meta)
    nx,ny=c["nx"],c["ny"]
    require(all(n->n isa Integer && !(n isa Bool) && n>=3,(nx,ny)) && grid==case_id(nx,ny),"格子数不正")
    p=problem(meta["task_id"],nx,ny)
    require(c["case_id"]==p.case_id && c["dx"]==p.dx && c["dy"]==p.dy,"case／格子幅不一致")
    for (key,n,expected) in (("x",nx,p.x),("y",ny,p.y))
        require(c[key] isa Vector{Float64} && length(c[key])==n && c[key]==expected,"座標／軸不一致: $key")
    end
    for k in ("u","f","g")
        require(c[k] isa Matrix{Float64} && size(c[k])==(nx,ny) && all(isfinite,c[k]),"場のshape／有限値不正: $k")
    end
    require(c["f"]==p.f && c["g"]==p.g,"生成項／境界行列不一致")
    n=c["iterations"];rh=c["residual_history"];uh=c["update_history"]
    require(n isa Integer && !(n isa Bool) && 0<=n<=meta["maxiter"],"反復数不正")
    require(c["iteration"] isa AbstractVector{<:Integer} && c["iteration"]==collect(0:n),"反復番号不一致")
    require(rh isa Vector{Float64} && uh isa Vector{Float64} && length(rh)==length(uh)==n+1 && all(v->isfinite(v)&&v>=0,rh) && all(v->isfinite(v)&&v>=0,uh) && first(uh)==0.,"履歴不正")
    require(c["initial_residual"]==first(rh) && c["threshold"]==max(meta["atol"],meta["rtol"]*first(rh)) && isfinite(c["threshold"]),"停止情報不一致")
    require(c["converged"]==true && c["reason"]=="converged" && last(rh)<=c["threshold"],"非収束の公式場です")
    nothing
end
function write_fields(path,cases,meta;official=true)
    validate_metadata(meta)
    for (grid,c) in cases;validate_case(c,grid,meta);end
    h5open(path,"w") do h
        for (k,v) in meta;attributes(h)[k]=v;end
        parent=create_group(h,"cases")
        for (grid,c) in sort(collect(cases);by=first)
            group=create_group(parent,grid)
            for k in CASE_KEYS;attributes(group)[k]=c[k];end
            for k in DATA_KEYS
                group[k]=c[k];attributes(group[k])["units"]=k=="iteration" ? "iteration" : "1"
                k in ("u","f","g") && (attributes(group[k])["axis_order"]="y,x")
            end
        end
    end
    read_fields(path;official)
end
function read_fields(path;official=true,expected_id=nothing)
    isfile(path) || error("HDF5欠落: $(path)。simulate.jlを実行してください")
    try
        h5open(path,"r") do h
            meta=Dict(k=>read_attribute(h,k) for k in ROOT_KEYS);validate_metadata(meta)
            expected_id===nothing || require(meta["task_id"]==expected_id,"保存場のtask_idと要求された内容IDが不一致です")
            require(haskey(h,"cases"),"cases欠落");cases=Dict{String,Any}()
            for grid in keys(h["cases"])
                group=h["cases/$grid"];c=Dict{String,Any}(k=>read_attribute(group,k) for k in CASE_KEYS)
                for k in DATA_KEYS
                    require(haskey(group,k),"dataset欠落: $k");c[k]=read(group[k])
                    require(read_attribute(group[k],"units")== (k=="iteration" ? "iteration" : "1"),"単位不一致: $k")
                    k in ("u","f","g") && require(read_attribute(group[k],"axis_order")=="y,x","場の軸不一致")
                end
                validate_case(c,grid,meta);cases[grid]=c
            end
            official && require(Set(keys(cases))==Set(case_id(n...) for n in OFFICIAL_GRIDS),"公式3格子が不一致")
            (;metadata=meta,cases)
        end
    catch e
        error("HDF5読取り失敗 $path: $(sprint(showerror,e))")
    end
end
"""保存場から残差を独立に再計算する。"""
function independent_residual(u,f,dx,dy)
    r=zeros(size(u))
    for j in 2:size(u,2)-1,i in 2:size(u,1)-1
        r[i,j]=f[i,j]-((u[i-1,j]-2u[i,j]+u[i+1,j])/dx^2+(u[i,j-1]-2u[i,j]+u[i,j+1])/dy^2)
    end
    maximum(abs,@view r[2:end-1,2:end-1])
end
function diagnostics(pair,hash)
    meta=pair.metadata;id=meta["task_id"];out=Dict{String,Any}();l2=Float64[];linf=Float64[]
    for (nx,ny) in OFFICIAL_GRIDS
        grid=case_id(nx,ny);c=pair.cases[grid];p=problem(id,nx,ny);u=c["u"]
        b=max(maximum(abs,u[1,:]-p.g[1,:]),maximum(abs,u[end,:]-p.g[end,:]),maximum(abs,u[:,1]-p.g[:,1]),maximum(abs,u[:,end]-p.g[:,end]))
        require(b<=1e-13,"境界が変更されています")
        residual=independent_residual(u,c["f"],p.dx,p.dy)
        require(isapprox(residual,last(c["residual_history"]);atol=2e-11,rtol=1e-5) && residual<=c["threshold"]+2e-11,"独立残差／停止条件不一致")
        err=u[2:end-1,2:end-1]-p.exact[2:end-1,2:end-1];a=sqrt(sum(abs2,err)/length(err));z=maximum(abs,err)
        push!(l2,a);push!(linf,z)
        out[grid]=Dict("nx"=>nx,"ny"=>ny,"dx"=>p.dx,"dy"=>p.dy,"case_id"=>p.case_id,"boundary_error"=>b,"independent_residual"=>residual,"l2_error"=>a,"linf_error"=>z,"iterations"=>c["iterations"],"reason"=>c["reason"],"threshold"=>c["threshold"])
    end
    orders(a)=log2.(a[1:end-1]./a[2:end])
    require(all(diff(l2).<0) && all(diff(linf).<0) && all(p->1.8<=p<=2.2,orders(l2)) && all(p->1.8<=p<=2.2,orders(linf)),"両区間の約2次収束が未達です")
    Dict("schema_version"=>1,"task_id"=>id,"run_id"=>meta["run_id"],"source_fields_sha256"=>hash,"diagnostics_complete"=>true,"conditions"=>Dict(k=>meta[k] for k in ("domain","units","grid_location","boundary","method","atol","rtol","maxiter")),"orders_l2"=>orders(l2),"orders_linf"=>orders(linf),"cases"=>out)
end
function read_summary(path,input_dir,id)
    d=TOML.parsefile(path);hash=file_sha(joinpath(input_dir,id,"fields.h5"));pair=read_fields(joinpath(input_dir,id,"fields.h5");expected_id=id)
    require(d==diagnostics(pair,hash),"summaryが保存場の独立診断と一致しません")
    d
end
function check_complete(output_dir=DEFAULT_OUTPUT_DIR;selection="all")
    ids=selection_ids(selection);runs=String[]
    for id in ids
        dir=joinpath(output_dir,id);require(all(isfile(joinpath(dir,n)) for n in OUTPUT_FILES),"$id 公式6出力が不足しています")
        summary=read_summary(joinpath(dir,"summary.toml"),output_dir,id);push!(runs,summary["run_id"])
        plots=TOML.parsefile(joinpath(dir,"plots.toml"))
        require(plots["task_id"]==id && plots["run_id"]==summary["run_id"] && plots["source_fields_sha256"]==file_sha(joinpath(dir,"fields.h5")) && plots["source_summary_sha256"]==file_sha(joinpath(dir,"summary.toml")),"図の来歴が不一致")
        require(Set(keys(plots["png_sha256"]))==Set(PNG_FILES) && all(plots["png_sha256"][n]==file_sha(joinpath(dir,n)) for n in PNG_FILES),"図のhash不一致")
    end
    require(length(unique(runs))==1,"run_idが混在しています。run.jl allを再実行してください")
    validate_capacity(output_dir,Dict{String,Int}());true
end
output_names(selection)=Tuple(joinpath(id,n) for id in selection_ids(selection) for n in OUTPUT_FILES)
function allowed_name(n)
    parts=splitpath(n)
    length(parts)==2 && parts[1] in ("N08","N09") && parts[2] in OUTPUT_FILES ||
        length(parts)==4 && parts[1:2]==["N09","extensions"] && parts[3] in ("neumann","relaxation") && parts[4] in OUTPUT_FILES
end
function validate_capacity(output_dir,replacements;file_limit=5*1024^2,task_limit=10*1024^2,course_limit=100*1024^2)
    sizes=copy(replacements)
    if isdir(output_dir)
        for (dir,_,files) in walkdir(output_dir),name in files
            path=joinpath(dir,name);rel=relpath(path,output_dir);haskey(sizes,rel) || (sizes[rel]=filesize(path))
        end
    end
    totals=Dict("N08"=>0,"N09"=>0)
    for (n,size) in sizes
        require(size<=file_limit,"1ファイルの5 MiB上限: $n ($size bytes)")
        id=first(splitpath(n));require(haskey(totals,id),"内容IDへ割当できない出力: $n");totals[id]+=size
    end
    require(all(values(totals).<=task_limit),"内容ID合計の10 MiB上限を超えています")
    task=dirname(abspath(output_dir));exercises=dirname(task);total=sum(values(totals))
    if basename(exercises)=="exercises"
        for other in readdir(exercises;join=true)
            other==task && continue;dir=joinpath(other,"results");isdir(dir) || continue
            for (d,_,files) in walkdir(dir),name in files;total+=filesize(joinpath(d,name));end
        end
        legacy=joinpath(dirname(exercises),"results")
        if isdir(legacy)
            for (d,_,files) in walkdir(legacy),name in files;total+=filesize(joinpath(d,name));end
        end
    end
    require(total<=course_limit,"全課題合計の100 MiB上限を超えています")
    nothing
end
function publish(stage,output_dir,names;copy_file=(a,b)->cp(a,b;force=true),restore_file=(a,b)->cp(a,b;force=true),capacity_options...)
    require(all(allowed_name,names) && length(unique(names))==length(names),"公式出力名不正")
    for n in names
        target=abspath(joinpath(output_dir,n))
        while true
            require(!islink(target),"出力先のsymlinkは使えません: $target")
            parent=dirname(target);parent==target && break;target=parent
        end
    end
    validate_capacity(output_dir,Dict(n=>filesize(joinpath(stage,n)) for n in names);capacity_options...)
    backup=mktempdir(;cleanup=false);existed=Dict{String,Bool}();applied=String[]
    try
        for n in names
            target=joinpath(output_dir,n);require(!ispath(target) || isfile(target),"通常ファイル以外の出力先: $target")
            require(!islink(target),"出力先のsymlinkは使えません: $target")
            existed[n]=isfile(target)
            if existed[n];saved=joinpath(backup,n);mkpath(dirname(saved));cp(target,saved);end
        end
        for n in names
            target=joinpath(output_dir,n);mkpath(dirname(target));push!(applied,n);copy_file(joinpath(stage,n),target)
        end
    catch original
        failures=String[]
        for n in reverse(applied)
            target=joinpath(output_dir,n)
            try
                existed[n] ? restore_file(joinpath(backup,n),target) : rm(target;force=true)
            catch e;push!(failures,"$target: $e");end
        end
        if !isempty(failures)
            error("反映と復元に失敗しました。バックアップ: $backup\n"*join(failures,"\n")*"\n元のエラー: $original")
        end
        rm(backup;recursive=true);rethrow()
    end
    rm(backup;recursive=true);nothing
end
function staged(action,output_dir,names;kwargs...)
    mktempdir() do stage
        action(stage);publish(stage,output_dir,names;kwargs...)
    end
end
