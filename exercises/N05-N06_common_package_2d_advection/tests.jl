using Test, ThermofluidExercise
@testset "N05 共通API" begin
    @test ThermofluidExercise.periodic_left_index(1,4)==4
    @test ThermofluidExercise.periodic_right_index(4,4)==1
    @test ThermofluidExercise.linear_flux(2.,3.)==6.
    @test ThermofluidExercise.burgers_flux(-2.)==2.
    @test ThermofluidExercise.fit_timestep(.3,1.)==(steps=4,dt=.25)
end
