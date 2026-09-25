using Test

if !isdefined(Main, :F02JuliaArraysAndTests)
    include(joinpath(@__DIR__, "run.jl"))
end

@testset "F02 必須テスト（配布済み）" begin
    values = [5.0, 7.0, 12.0]
    original = copy(values)
    anomalies = F02JuliaArraysAndTests.temperature_anomaly(values)

    @test F02JuliaArraysAndTests.mean_temperature(values) == 8.0
    @test anomalies == [-3.0, -1.0, 4.0]
    @test isapprox(sum(anomalies), 0.0; atol=100eps())
    @test values == original
    @test_throws ArgumentError F02JuliaArraysAndTests.mean_temperature(Float64[])
end

@testset "F02 自作テスト" begin
    # TODO(自作): 戻り値の型、別の数学的性質、または必須とは異なる不正入力から一つ選び、入力と期待値を自分で書く。
    
    # Float32型配列での計算結果と型の維持を検証
    v_f32 = Float32[10.0, 20.0, 30.0]
    m_f32 = F02JuliaArraysAndTests.mean_temperature(v_f32)
    @test m_f32 ≈ 20.0f0

    anom_f32 = F02JuliaArraysAndTests.temperature_anomaly(v_f32)
    @test eltype(anom_f32) == Float32
    @test isapprox(sum(anom_f32), 0.0f0; atol=1e-5)

    # NaN や Inf が含まれる場合に ArgumentError で拒否するか検証
    @test_throws ArgumentError F02JuliaArraysAndTests.mean_temperature([1.0, NaN, 3.0])
    @test_throws ArgumentError F02JuliaArraysAndTests.temperature_anomaly([1.0, Inf, 3.0])

end
