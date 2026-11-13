# N08/N09: 提供済みの必須確認 → 受講生が編集する自作テスト。

using Test
# 実行対象はN08-checkまたはall。
const N08N09_TEST_MODE =
    abspath(PROGRAM_FILE) == (@__FILE__) ?
    (isempty(ARGS) ? "all" : length(ARGS) == 1 ? only(ARGS) : "invalid") : "all"
N08N09_TEST_MODE in ("N08-check", "all") || error("引数は[N08-check|all]です")
using ThermofluidExercise
const E = ThermofluidExercise.Elliptic
include("provided_support.jl")
@testset "N08: 小配列・境界・独立残差・残差停止" begin
    old = [Float64(i ^ 2 + 3j ^ 2 + i * j) for i in 1:5, j in 1:4]
    saved = copy(old)
    new = fill(-7., 5, 4)
    g = [Float64(10i + j) for i in 1:5, j in 1:4]
    inside = copy(new[2:4, 2:3])
    @test E.apply_dirichlet!(new, g)===new
    @test new[1, :] == g[1, :] &&
          new[end, :] == g[end, :] &&
          new[:, 1] == g[:, 1] &&
          new[:, end] == g[:, end]
    @test new[2:4, 2:3] == inside
    @test E.laplace_jacobi_step!(new, old, 0.2, 0.3)===new
    @test new[2:4, 2:3]≈[281 / 13 502 / 13; 372 / 13 606 / 13; 489 / 13 736 / 13]
    @test old == saved
    @test new[1, :] == old[1, :] &&
          new[end, :] == old[end, :] &&
          new[:, 1] == old[:, 1] &&
          new[:, end] == old[:, end]
    r = similar(old)
    @test E.laplace_residual!(r, old, 0.2, 0.3)===r
    @test r[2:4, 2:3]≈fill(-350 / 3, 3, 2)
    @test all(iszero, r[1, :]) &&
          all(iszero, r[end, :]) &&
          all(iszero, r[:, 1]) &&
          all(iszero, r[:, end])
    @test E.residual_converged(1., 10.; atol = 1., rtol = 0.01)
    @test !E.residual_converged(1.01, 10.; atol = 1., rtol = 0.01)
    @test E.residual_converged(0., 0.; atol = 1e-10, rtol = 0.)
    zero = E.solve_laplace(zeros(5, 4), zeros(5, 4), 0.2, 0.3)
    @test zero.converged && zero.iterations == 0 && zero.update_history == [0.]
    boundary = zeros(5, 4)
    boundary[end, :].=1e-12
    # 更新量と方程式残差の違いを確認する。
    one = E.solve_laplace(
        zeros(5, 4),
        boundary,
        1e-7,
        2e-7;
        maxiter = 1,
        atol = 1e-10,
        rtol = 0.,
    )
    @test one.reason == :maxiter && !one.converged && one.iterations == 1
    @test one.update_history[end] < 1e-10 && one.residual_history[end] > one.threshold
    independent = independent_residual(one.u, zeros(5, 4), 1e-7, 2e-7)
    @test independent≈one.residual_history[end]
    @test length(one.residual_history) == length(one.update_history) == 2
    @test_throws ArgumentError E.laplace_jacobi_step!(old, old, 0.2, 0.3)
end
if N08N09_TEST_MODE == "N08-check"
    println("N08授業内検証成功")
else
    @testset "N09: 生成項の符号・f=0一致・残差" begin
        old = [Float64(i ^ 2 + 3j ^ 2 + i * j) for i in 1:5, j in 1:4]
        saved = copy(old)
        f = fill(2., 5, 4)
        new = similar(old)
        r = similar(old)
        lap = similar(old)
        @test E.poisson_jacobi_step!(new, old, f, 0.2, 0.3)===new
        @test new[2:4, 2:3]≈[
            7016 / 325 12541 / 325;
            9291 / 325 15141 / 325;
            12216 / 325 18391 / 325
        ]
        @test old == saved && new[1, :] == old[1, :] && new[:, end] == old[:, end]
        @test E.poisson_residual!(r, old, f, 0.2, 0.3)===r
        @test r[2:4, 2:3]≈fill(-344 / 3, 3, 2)
        @test all(iszero, r[1, :]) && all(iszero, r[:, end])
        E.laplace_jacobi_step!(lap, old, 0.2, 0.3)
        E.poisson_jacobi_step!(new, old, zeros(5, 4), 0.2, 0.3)
        @test lap == new
        E.laplace_residual!(lap, old, 0.2, 0.3)
        E.poisson_residual!(r, old, zeros(5, 4), 0.2, 0.3)
        @test lap == r
    end
    @testset "自作1: 非対称小配列・両問題1 sweep・旧場・境界・f=0一致" begin
        # TODO: 手計算した入力と期待値を使い、配布済みassertionを保持して独自に検証する。
        old = [Float64(2i ^ 2 + 3j ^ 2 + i * j) for i in 1:4, j in 1:5]
        saved = copy(old)
        f = fill(8., 4, 5)
        saved_f = copy(f)
        laplace = similar(old)
        poisson = similar(old)
        zero_source = zeros(4, 5)

        @test E.laplace_jacobi_step!(laplace, old, 0.25, 0.5) === laplace
        @test laplace[2:3, 2:4] ≈
              [26.2 43.2 66.2; 38.2 56.2 80.2] atol = 1e-14 rtol = 0
        @test laplace[1, :] == old[1, :] &&
              laplace[end, :] == old[end, :] &&
              laplace[:, 1] == old[:, 1] &&
              laplace[:, end] == old[:, end]
        @test old == saved

        @test E.poisson_jacobi_step!(poisson, old, f, 0.25, 0.5) === poisson
        @test poisson[2:3, 2:4] ≈
              [26. 43. 66.; 38. 56. 80.] atol = 1e-14 rtol = 0
        @test poisson[1, :] == old[1, :] &&
              poisson[end, :] == old[end, :] &&
              poisson[:, 1] == old[:, 1] &&
              poisson[:, end] == old[:, end]
        @test old == saved && f == saved_f

        E.laplace_jacobi_step!(laplace, old, 0.25, 0.5)
        E.poisson_jacobi_step!(poisson, old, zero_source, 0.25, 0.5)
        @test laplace == poisson
    end
    @testset "自作2: 両問題の残差停止・解析解誤差・3格子の両区間収束" begin
        # TODO: LaplaceとPoissonの両方、p=log2(E_coarse/E_fine)を検証する。
        for id in ("N08", "N09")
            l2_errors = Float64[]
            linf_errors = Float64[]
            for (nx, ny) in OFFICIAL_GRIDS
                p = problem(id, nx, ny)
                result =
                    id == "N08" ?
                    E.solve_laplace(p.u0, p.g, p.dx, p.dy) :
                    E.solve_poisson(p.u0, p.g, p.f, p.dx, p.dy)
                @test result.converged
                @test result.reason == :converged
                @test result.residual_history[end] <= result.threshold
                @test independent_residual(result.u, p.f, p.dx, p.dy) ≈
                      result.residual_history[end] atol = 2e-11 rtol = 1e-5

                error = result.u[2:(end - 1), 2:(end - 1)] -
                        p.exact[2:(end - 1), 2:(end - 1)]
                push!(l2_errors, sqrt(sum(abs2, error) / length(error)))
                push!(linf_errors, maximum(abs, error))
            end

            l2_orders = log2.(l2_errors[1:(end - 1)] ./ l2_errors[2:end])
            linf_orders = log2.(linf_errors[1:(end - 1)] ./ linf_errors[2:end])
            @test all(diff(l2_errors) .< 0)
            @test all(diff(linf_errors) .< 0)
            @test all(order->1.8 <= order <= 2.2, l2_orders)
            @test all(order->1.8 <= order <= 2.2, linf_orders)
        end
    end
    @testset "公式12出力・来歴・容量" begin
        @test check_complete()
    end
end
