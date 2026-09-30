module F02JuliaArraysAndTests

export mean_temperature, temperature_anomaly

function validate_temperatures(values::AbstractVector{<:Real})
    isempty(values) && throw(ArgumentError("温度の配列を空にはできません"))
    all(isfinite, values) || throw(
        ArgumentError("温度はすべて有限値にしてください。NaNとInfを取り除いてください"),
    )
    nothing
end

function mean_temperature(values::AbstractVector{<:Real})
    validate_temperatures(values)
    # TODO(F02): すべての値の合計を求め、要素数で割る。
    error("未実装 F02: mean_temperature")
end

function temperature_anomaly(values::AbstractVector{<:Real})
    validate_temperatures(values)
    # TODO(F02): `value - mean_temperature(values)`を要素とする新しい配列を返す。
    error("未実装 F02: temperature_anomaly")
end

end


if abspath(PROGRAM_FILE) == @__FILE__
    sample = [18.0, 20.0, 22.0]
    println("平均 = ", F02JuliaArraysAndTests.mean_temperature(sample))
    println("偏差 = ", F02JuliaArraysAndTests.temperature_anomaly(sample))
end
