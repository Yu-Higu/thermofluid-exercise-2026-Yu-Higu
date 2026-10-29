using Test
if !isdefined(Main, :N02NonlinearAdvection)
    include(joinpath(@__DIR__, "run.jl"))
end
using .N02NonlinearAdvection
@testset "N02 必須テスト" begin
    @testset "流束と周期添字" begin
        @test burgers_flux(1.) == 0.5
        @test burgers_flux(2.) == 2.
        @test periodic_left_index(1,4) == 4
        @test periodic_left_index(3,4) == 2
    end
    @testset "保存形1ステップと旧配列不変" begin
        old=[1.,2.,1.,1.]; saved=copy(old); new=similar(old)
        nonlinear_upwind_step!(new,old,0.25,1.;boundary=:periodic)
        @test new == [1.,1.625,1.375,1.]
        @test old == saved
    end
    @testset "定数場と境界条件" begin
        for (boundary,value) in ((:fixed,1.),(:periodic,0.7))
            old=fill(value,5); new=similar(old)
            nonlinear_upwind_step!(new,old,0.2,1.;boundary)
            apply_boundary!(new;boundary)
            @test new ≈ old
        end
        @test apply_boundary!([4.,2.,3.,8.]) == [1.,2.,3.,3.]
    end
    @testset "CFL・有界性・非線形な波形変形" begin
        for (boundary,nx) in ((:fixed,81),(:periodic,80))
            r=simulate(;boundary,nx)
            @test r.max_cfl <= 0.5+1e-14
            @test r.steps == 160
            @test r.dt == 0.00625
            @test getproperty.(r.snapshots,:time) ≈ [0.,0.25,0.5,0.75,1.]
            @test 1-1e-13 <= minimum(r.u) <= maximum(r.u) <= 2+1e-13
            # c=1で同じ最終時刻まで移した矩形との離散L1差。周期では左右をつなぐ。
            shifted=[0.5 <= (boundary==:periodic ? mod(x-r.t_final,2.) : x-r.t_final) <= 1.0 ? 2. : 1. for x in r.x]
            @test r.dx*sum(abs.(r.u-shifted)) > 0.2
            @test maximum(r.u[findall(>(1.5),r.x)]) > 1.2
        end
    end
end
@testset "N02 自作テスト" begin
    # TODO(自作): 周期の非定数・非負配列を複数ステップ進め、離散総和保存を確認する。入力・許容誤差・期待値を自分で決める。
    @testset "周期複数ステップの離散総和保存" begin
        old = [0.2, 0.5, 1.1, 0.8, 0.3]
        initial_sum = sum(old)
        new = similar(old)
        for _ in 1:8
            nonlinear_upwind_step!(new, old, 0.02, 0.2; boundary=:periodic)
            apply_boundary!(new; boundary=:periodic)
            old, new = new, old
        end
        @test isapprox(sum(old), initial_sum; atol=1e-12, rtol=1e-12)
    end
    # TODO(自作): 周期1ステップSについてS(circshift(u,k)) ≈ circshift(S(u),k)を確認する。非対称な非定数配列、k≠0、同じdtとdxを使う。
    @testset "周期更新の循環移動との整合" begin
        old = [0.7, 1.3, 0.4, 1.8, 0.9, 0.2]
        shift = 2
        dt, dx = 0.03, 0.2
        updated = similar(old)
        shifted_updated = similar(old)
        nonlinear_upwind_step!(updated, old, dt, dx; boundary=:periodic)
        nonlinear_upwind_step!(shifted_updated, circshift(old, shift), dt, dx; boundary=:periodic)
        @test isapprox(shifted_updated, circshift(updated, shift); atol=1e-14, rtol=1e-14)
    end
end
