using Test

if !isdefined(Main, :N01LinearAdvection)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "N01 必須テスト" begin
    x = [0.0, 0.5, 0.75, 1.0, 1.25]
    x_before = copy(x)
    @test N01LinearAdvection.rectangular_initial_condition(
        x; base = -1.0, plateau = 3.0, plateau_start = 0.5, plateau_end = 1.0,
    ) == [-1.0, 3.0, 3.0, 3.0, -1.0]
    @test x == x_before

    u_old = [1.0, 2.0, 4.0, 8.0, 16.0]
    old_before = copy(u_old)
    u_new = similar(u_old)
    @test N01LinearAdvection.upwind_step!(u_new, u_old, 1.0, 0.25, 1.0) === u_new
    @test u_new == [1.0, 1.75, 3.5, 7.0, 16.0]
    @test u_old == old_before

    u_new = similar(u_old)
    @test N01LinearAdvection.centered_step!(u_new, u_old, 1.0, 0.25, 1.0) === u_new
    @test u_new == [1.0, 1.625, 3.25, 6.5, 16.0]
    @test u_old == old_before

    u = [9.0, 2.0, 4.0, 7.0, 8.0]
    @test N01LinearAdvection.apply_boundary!(u) === u
    @test u == [1.0, 2.0, 4.0, 7.0, 7.0]

    upwind = N01LinearAdvection.simulate(
        ; scheme = :upwind, nx = 21, c = 1.0, cfl = 0.5, t_final = 0.5,
    )
    centered = N01LinearAdvection.simulate(
        ; scheme = :centered, nx = 21, c = 1.0, cfl = 0.5, t_final = 0.5,
    )
    @test 1.0 <= upwind.minimum <= upwind.maximum <= 2.0
    @test centered.minimum < 1.0 || centered.maximum > 2.0
end

@testset "N01 自作テスト" begin
    x = [0.0, 0.25, 0.5, 0.75, 1.0]
    u0 = N01LinearAdvection.rectangular_initial_condition(
        x; base = 4.0, plateau = -2.0, plateau_start = 0.25, plateau_end = 0.75,
    )
    @test u0 == [4.0, -2.0, -2.0, -2.0, 4.0]
end
