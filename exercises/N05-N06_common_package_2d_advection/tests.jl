# N05/N06: 提供済みの必須テスト → 受講生が編集する自作テスト。必須の期待値は保持します。

using Test, ThermofluidExercise
@testset "N05 共通API" begin
    @test ThermofluidExercise.periodic_left_index(1,4)==4
    @test ThermofluidExercise.periodic_right_index(4,4)==1
    @test ThermofluidExercise.periodic_left_index(1,1)==1
    @test ThermofluidExercise.periodic_right_index(1,1)==1
    @test_throws ArgumentError ThermofluidExercise.periodic_left_index(true,4)
    @test_throws ArgumentError ThermofluidExercise.periodic_right_index(5,4)
    @test ThermofluidExercise.linear_flux(2.,3.)==6.
    @test ThermofluidExercise.burgers_flux(-2.)==2.
    @test ThermofluidExercise.burgers_flux(typemax(Int64))>0
    @test_throws ArgumentError ThermofluidExercise.linear_flux(Inf,1.)
    @test_throws ArgumentError ThermofluidExercise.burgers_flux(NaN)
    new=fill(NaN,3,4); old=reshape(collect(1.:12.),3,4)
    @test ThermofluidExercise.validate_buffers(new,old)===nothing
    @test_throws ArgumentError ThermofluidExercise.validate_buffers(zeros(3,4),zeros(4,3))
    @test_throws ArgumentError ThermofluidExercise.validate_buffers(zeros(Int,3),ones(3))
    @test_throws ArgumentError ThermofluidExercise.validate_buffers(view(old,:,:),old)
    @test_throws ArgumentError ThermofluidExercise.validate_buffers(zeros(2,3),zeros(2,3))
    @test_throws ArgumentError ThermofluidExercise.validate_buffers(zeros(3),[1.,Inf,3.])
    @test ThermofluidExercise.fit_timestep(.3,1.)==(steps=4,dt=.25)
    @test ThermofluidExercise.fit_timestep(.7,1.)==(steps=2,dt=.5)
    @test_throws ArgumentError ThermofluidExercise.fit_timestep(0.,1.)
    @test_throws ArgumentError ThermofluidExercise.fit_timestep(.1,Inf)
end
@testset "N06 配布済み数値テスト" begin
    old=Float64[1 2 4 3;5 7 6 8;9 10 12 11]; saved=copy(old); new=similar(old)
    N=ThermofluidExercise.N06
    @test N.advection_step!(new,old,.1,.5,.25;cx=1.,cy=.75)===new
    @test new≈[3.2 3.3 5.0 4.9;5.1 5.4 5.9 6.4;8.8 9.1 10.2 10.7] atol=1e-13
    @test old==saved
    @test N.stable_timestep(1.,.75,.5,.25)≈.16
    @test_throws ArgumentError N.advection_step!(old,old,.1,.5,.25)
    unchanged=copy(new)
    @test_throws ArgumentError N.advection_step!(new,old,.21,.5,.25;cx=1.,cy=.75)
    @test new==unchanged
    N.advection_step!(new,fill(2.,3,4),.1,.5,.25); @test new==fill(2.,3,4)
    N.advection_step!(new,old,.1,.5,.25;cx=0.,cy=0.); @test new==old
    N.advection_step!(new,old,.1,.5,.25;cx=0.,cy=.75)
    @test new≈[1.6 1.7 3.4 3.3;5.9 6.4 6.3 7.4;9.6 9.7 11.4 11.3]
end
@testset "N06 自作: 複数ステップの保存量" begin
    # TODO: 非対称・非定数場を複数ステップ進め、保存量を確認する。
    old=[0.7 1.1 1.8 0.9; 1.4 0.6 1.2 1.9; 0.8 1.6 0.5 1.3; 1.7 1.0 1.5 0.4; 1.2 1.9 0.8 1.1]
    dx,dy,dt,cx,cy=0.4,0.25,0.08,0.7,0.4
    initial_mass=dx*dy*sum(old)
    saved=copy(old); new=similar(old)
    for _ in 1:30
        ThermofluidExercise.N06.advection_step!(new,old,dt,dx,dy;cx,cy)
        old,new=new,old
    end
    final_mass=dx*dy*sum(old)
    @test old!=saved
    @test isapprox(final_mass,initial_mass;rtol=0,atol=1e-12*max(1.,abs(initial_mass)))
end
@testset "N06 自作: 3格子の解析解誤差と収束" begin
    # TODO: 公式3格子で誤差が減少し、両区間が約1次収束することを確認する。
    if !isdefined(Main,:N06Simulation)
        include(joinpath(@__DIR__,"simulate.jl"))
    end
    runs=[Main.N06Simulation.simulate_case(nx,ny) for (nx,ny) in ((40,30),(80,60),(160,120))]
    errors=[sqrt(sum(abs2,r["u"][:,:,end]-
        Main.N06Simulation.exact_field(r["x"],r["y"],1.))/length(r["u"][:,:,end])) for r in runs]
    orders=log2.(errors[1:end-1]./errors[2:end])
    @test all(isfinite,errors)
    @test errors[1]>errors[2]>errors[3]
    @test all(order->0.8<=order<=1.2,orders)
end
if !isdefined(Main,:N06Analysis)
    include(joinpath(@__DIR__,"analyze.jl"))
end
@testset "N06 空間分散" begin
    @test Main.N06Analysis.spatial_variance([1. 2.; 3. 4.])==1.25
    @test Main.N06Analysis.spatial_variance(fill(2.,3,4))==0.0
    @test_throws ArgumentError Main.N06Analysis.spatial_variance([1. Inf; 2. 3.])
end
module N0506OutputChecks
include("provided_support.jl")
include("N05.jl")
end
@testset "N05-N06 保存結果と出自" begin
    @test N0506OutputChecks.check_complete()
    baseline = joinpath(@__DIR__, "results", "N05", "baseline.toml")
    regression = joinpath(@__DIR__, "results", "N05", "regression.toml")
    @test isfile(baseline) && isfile(regression)
    report = N0506OutputChecks.TOML.parsefile(regression)
    @test report["baseline_sha256"] == N0506OutputChecks.file_sha(baseline)
    @test report["code_sha256"] == N0506OutputChecks.N05Regression.code_hashes(
        normpath(joinpath(@__DIR__, "..", "..")),
    )
end
