using Test
if !isdefined(Main,:N03Diffusion)
    include(joinpath(@__DIR__,"run.jl"))
end
import .N03Diffusion
@testset "N03 必須テスト" begin
    @testset "小配列1ステップと旧配列不変" begin
        old=[1.,2.,4.,3.]; saved=copy(old); new=similar(old)
        N03Diffusion.diffusion_step!(new,old,0.25,1.,1.;boundary=:insulated)
        @test new == [1.5,2.25,3.25,3.5]
        @test old == saved
    end
    @testset "定数場と固定端" begin
        for (boundary,value) in ((:insulated,0.7),(:fixed,0.))
            old=fill(value,5); new=similar(old)
            N03Diffusion.diffusion_step!(new,old,0.2,1.,1.;boundary)
            @test new ≈ old
        end
        old=[1.,2.,4.,3.]; new=similar(old)
        N03Diffusion.diffusion_step!(new,old,0.25,1.,1.)
        @test new == [0.,2.25,3.25,0.]
    end
    @testset "台形則の熱量" begin
        @test N03Diffusion.thermal_content([1.,2.,4.,3.],1.) == 8.
        @test N03Diffusion.thermal_content([1.5,2.25,3.25,3.5],1.) == 8.
    end
    @testset "標準計算の安定性" begin
        for boundary in (:fixed,:insulated)
            r=N03Diffusion.simulate(;boundary)
            @test r.steps*r.dt ≈ r.t_final == 1.
            @test 0 < r.fo <= 0.5
            @test all(isfinite,r.u)
            @test -1e-13 <= r.minimum <= r.maximum <= 1+1e-13
        end
    end
end
@testset "N03 自作テスト" begin
    @testset "断熱境界での熱量保存" begin
        old = [0.2, 0.9, 1.5, 0.8, 0.6, 1.1, 0.4]
        dx = 0.25
        initial_heat = N03Diffusion.thermal_content(old, dx)
        new = similar(old)
        for _ in 1:20
            N03Diffusion.diffusion_step!(new, old, 0.04, dx, 0.1; boundary=:insulated)
            old, new = new, old
        end
        @test isapprox(N03Diffusion.thermal_content(old, dx), initial_heat; rtol=0, atol=1e-12)
    end

    @testset "固定端の正弦解析解と格子収束" begin
        nx_values = (41, 81, 161)
        runs = [N03Diffusion.simulate(; boundary=:fixed, nx=n, initial=:mode) for n in nx_values]
        errors = [maximum(abs.(r.u - N03Diffusion.analytic_solution(r.x, r.t_final; boundary=:fixed))) for r in runs]
        orders = log2.(errors[1:2] ./ errors[2:3])
        @test all(isfinite, errors)
        @test all(isfinite, orders)
        @test errors[1] > errors[2] > errors[3]
        @test minimum(orders) > 1.8
    end
end
