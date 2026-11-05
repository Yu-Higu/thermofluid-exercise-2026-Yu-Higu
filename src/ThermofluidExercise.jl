module ThermofluidExercise

"""周期左隣。整数1 <= i <= n、Bool不可。"""
function periodic_left_index(i,n)
    # TODO(N05): 周期配列の左隣添字を返す。
    i isa Integer && !(i isa Bool) && n isa Integer && !(n isa Bool) &&
        n >= 1 && 1 <= i <= n ||
        throw(ArgumentError("i,nはBoolを除く整数で、n >= 1かつ1 <= i <= nです"))
    return i == 1 ? n : i - 1
end

"""周期右隣。整数1 <= i <= n、Bool不可。"""
function periodic_right_index(i,n)
    # TODO(N05): 周期配列の右隣添字を返す。
    i isa Integer && !(i isa Bool) && n isa Integer && !(n isa Bool) &&
        n >= 1 && 1 <= i <= n ||
        throw(ArgumentError("i,nはBoolを除く整数で、n >= 1かつ1 <= i <= nです"))
    return i == n ? 1 : i + 1
end

"""有限実数の線形流束。"""
function linear_flux(u,speed)
    # TODO(N05): 有限実数の入力を検証し、線形流束を返す。
    u isa Real && isfinite(u) || throw(ArgumentError("uは有限な実数です"))
    speed isa Real && isfinite(speed) || throw(ArgumentError("speedは有限な実数です"))
    flux = float(u) * float(speed)
    isfinite(flux) || throw(ArgumentError("線形流束が有限値の範囲を超えています"))
    return flux
end

"""有限実数のBurgers流束。負値も受け付ける。"""
function burgers_flux(u)
    # TODO(N05): 有限実数の入力を検証し、Burgers流束を返す。
    u isa Real && isfinite(u) || throw(ArgumentError("uは有限な実数です"))
    flux = (float(u) / 2) * float(u)
    isfinite(flux) || throw(ArgumentError("Burgers流束が有限値の範囲を超えています"))
    return flux
end

"""1始まり・浮動小数・同形状・各軸3点以上・非alias・有限旧値。"""
function validate_buffers(u_new,u_old)
    # TODO(N05): 新旧配列の形状・型・非alias・旧値の有限性を検証する。
    all(u -> u isa AbstractArray{<:AbstractFloat}, (u_new, u_old)) ||
        throw(ArgumentError("新旧バッファは浮動小数配列です"))
    Base.require_one_based_indexing(u_new, u_old)
    size(u_new) == size(u_old) ||
        throw(ArgumentError("新旧バッファは同じ形状です"))
    ndims(u_old) >= 1 && all(n -> n >= 3, size(u_old)) ||
        throw(ArgumentError("各軸に3点以上が必要です"))
    Base.mightalias(u_new, u_old) &&
        throw(ArgumentError("新旧バッファが重なっています"))
    all(isfinite, u_old) ||
        throw(ArgumentError("旧バッファは有限値にしてください"))
    return nothing
end

"""正の有限値から (;steps,dt) を返し最終時刻へ合わせる。"""
function fit_timestep(dt_max,t_final)
    # TODO(N05): 安定上限を超えない刻みとステップ数を最終時刻から返す。
    dt_max isa Real && isfinite(dt_max) && dt_max > 0 ||
        throw(ArgumentError("dt_maxは有限な正の実数です"))
    t_final isa Real && isfinite(t_final) && t_final > 0 ||
        throw(ArgumentError("t_finalは有限な正の実数です"))
    max_step = Float64(dt_max)
    final_time = Float64(t_final)
    isfinite(max_step) && max_step > 0 &&
        isfinite(final_time) && final_time > 0 ||
        throw(ArgumentError("dt_maxとt_finalは正のFloat64で表現可能です"))
    count = final_time / max_step
    isfinite(count) && count < typemax(Int) ||
        throw(ArgumentError("ステップ数がIntの表現範囲を超えています"))
    steps = max(1, ceil(Int, count))
    dt = final_time / steps
    dt <= max_step || begin
        steps < typemax(Int) ||
            throw(ArgumentError("ステップ数がIntの表現範囲を超えています"))
        steps += 1
        dt = final_time / steps
    end
    isfinite(dt) && dt > 0 && dt <= max_step ||
        throw(ArgumentError("調整後dtは有限な正値で、dt_max以下である必要があります"))
    return (; steps, dt)
end

module N01
import ..ThermofluidExercise as Common
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function upwind_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    # TODO(N05): 既習のN01.upwind_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    Common.validate_buffers(u_new, u_old)
    all(isfinite, (c, dt, dx)) && c > 0 && dt > 0 && dx > 0 ||
        throw(ArgumentError("c、dt、dxは有限で、c、dt、dxは正値です"))
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        u_new[i] = u_old[i] - (dt / dx) *
            (Common.linear_flux(u_old[i], c) - Common.linear_flux(u_old[i - 1], c))
    end
    return u_new
end
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function centered_step!(u_new, u_old, c::Real, dt::Real, dx::Real)
    # TODO(N05): 既習のN01.centered_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    Common.validate_buffers(u_new, u_old)
    all(isfinite, (c, dt, dx)) && c > 0 && dt > 0 && dx > 0 ||
        throw(ArgumentError("c、dt、dxは有限で、c、dt、dxは正値です"))
    copyto!(u_new, u_old)
    for i in 2:(length(u_old) - 1)
        u_new[i] = u_old[i] - (dt / (2 * dx)) *
            (Common.linear_flux(u_old[i + 1], c) - Common.linear_flux(u_old[i - 1], c))
    end
    return u_new
end
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(u::AbstractVector{<:Real}; left_value::Real = 1.0)
    # TODO(N05): 既習のN01.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    length(u) >= 2 && isfinite(left_value) ||
        throw(ArgumentError("uには2点以上、left_valueには有限値が必要です"))
    u[1] = left_value
    u[end] = u[end - 1]
    return u
end
end
module N02
import ..ThermofluidExercise as Common
"""N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function nonlinear_upwind_step!(u_new, u_old, dt::Real, dx::Real; boundary=:fixed)
    # TODO(N05): 既習のN02.nonlinear_upwind_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    boundary in (:fixed, :periodic) ||
        throw(ArgumentError("boundaryは:fixedまたは:periodicです"))
    Common.validate_buffers(u_new, u_old)
    all(v -> isfinite(v) && v > 0, (dt, dx)) ||
        throw(ArgumentError("dtとdxは有限な正の値です"))
    copyto!(u_new, u_old)
    indices = boundary == :periodic ? (1:length(u_old)) : (2:length(u_old)-1)
    for i in indices
        left = boundary == :periodic ? Common.periodic_left_index(i, length(u_old)) : i - 1
        u_new[i] = u_old[i] - (dt / dx) *
            (Common.burgers_flux(u_old[i]) - Common.burgers_flux(u_old[left]))
    end
    all(isfinite, u_new) || error("更新後に非有限値があります。更新式を確認してください")
    return u_new
end
"""N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(u; boundary=:fixed)
    # TODO(N05): 既習のN02.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    boundary in (:fixed, :periodic) ||
        throw(ArgumentError("boundaryは:fixedまたは:periodicです"))
    length(u) >= 3 || throw(ArgumentError("境界配列には3点以上が必要です"))
    if boundary == :fixed
        u[1] = 1.0
        u[end] = u[end - 1]
    end
    return u
end
end
module N03
import ..ThermofluidExercise as Common
"""N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function diffusion_step!(u_new, u_old, dt::Real, dx::Real, diffusivity::Real; boundary=:fixed)
    # TODO(N05): 既習のN03.diffusion_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    boundary in (:fixed, :insulated) ||
        throw(ArgumentError("boundaryは:fixedまたは:insulatedです"))
    Common.validate_buffers(u_new, u_old)
    all(v -> isfinite(v) && v > 0, (dt, dx, diffusivity)) ||
        throw(ArgumentError("dt、dx、diffusivityは有限な正の値です"))
    r = diffusivity * dt / dx^2
    isfinite(r) && r > 0 || throw(ArgumentError("実効Fourier数は有限な正の値です"))
    for i in 2:length(u_old)-1
        u_new[i] = u_old[i] + r * (u_old[i - 1] - 2.0 * u_old[i] + u_old[i + 1])
    end
    apply_boundary!(u_new, u_old, r; boundary)
    return u_new
end
"""N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(u_new, u_old, r::Real; boundary=:fixed)
    # TODO(N05): 既習のN03.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    boundary in (:fixed, :insulated) ||
        throw(ArgumentError("boundaryは:fixedまたは:insulatedです"))
    Common.validate_buffers(u_new, u_old)
    isfinite(r) && r > 0 || throw(ArgumentError("rは有限な正の値です"))
    if boundary == :fixed
        u_new[1] = 0.0
        u_new[end] = 0.0
    else
        u_new[1] = u_old[1] + 2.0 * r * (u_old[2] - u_old[1])
        u_new[end] = u_old[end] + 2.0 * r * (u_old[end - 1] - u_old[end])
    end
    return u_new
end
end
module N04
import ..ThermofluidExercise as Common
"""N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function stable_timestep(max_speed, dx, diffusivity; safety=0.8)
    # TODO(N05): 既習のN04.stable_timestepを共通APIを使う処理へ移し、既存の契約を保つ。
    max_speed isa Real && isfinite(max_speed) && max_speed >= 0 ||
        throw(ArgumentError("max_speedは有限な非負値です"))
    dx isa Real && isfinite(dx) && dx > 0 ||
        throw(ArgumentError("dxは有限な正値です"))
    diffusivity isa Real && isfinite(diffusivity) && diffusivity >= 0 ||
        throw(ArgumentError("diffusivityは有限な非負値です"))
    safety isa Real && isfinite(safety) && 0 < safety <= 1 ||
        throw(ArgumentError("safetyは有限で0より大きく1以下です"))
    max_speed > 0 || diffusivity > 0 ||
        throw(ArgumentError("移流速度とdiffusivityがともに0では刻みを定義できません"))
    rate = max_speed / dx + 2 * (diffusivity / dx) / dx
    dt = safety / rate
    isfinite(dt) && dt > 0 ||
        throw(ArgumentError("合成条件のdtは有限な正の値です"))
    return dt
end
"""N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function advection_diffusion_step!(u_new, u_old, dt, dx, diffusivity;
    model, advection=true, speed=1.0)
    # TODO(N05): 既習のN04.advection_diffusion_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    model in (:linear, :nonlinear) ||
        throw(ArgumentError("modelは:linearまたは:nonlinearです"))
    advection isa Bool || throw(ArgumentError("advectionはBoolです"))
    speed isa Real && isfinite(speed) ||
        throw(ArgumentError("speedは有限な実数です"))
    model == :linear && speed <= 0 &&
        throw(ArgumentError("線形speedは正の値です"))
    Common.validate_buffers(u_new, u_old)
    dt isa Real && isfinite(dt) && dt > 0 ||
        throw(ArgumentError("dtは有限な正の値です"))
    dx isa Real && isfinite(dx) && dx > 0 ||
        throw(ArgumentError("dxは有限な正の値です"))
    diffusivity isa Real && isfinite(diffusivity) && diffusivity >= 0 ||
        throw(ArgumentError("diffusivityは有限な非負値です"))
    advection && model == :nonlinear && minimum(u_old) < 0 &&
        throw(ArgumentError("非線形移流は非負値が必要です"))
    max_speed = !advection ? 0.0 : model == :linear ? speed : maximum(u_old)
    cfl = max_speed * (dt / dx)
    fo = diffusivity * (dt / dx) / dx
    isfinite(cfl) && isfinite(fo) && cfl + 2 * fo <= 1 + 32eps(Float64) ||
        throw(ArgumentError("合成安定条件CFL+2Fo<=1を超えています"))
    for i in eachindex(u_old)
        left = Common.periodic_left_index(i, length(u_old))
        right = Common.periodic_right_index(i, length(u_old))
        advective_term = advection ?
            (model == :linear ?
                Common.linear_flux(u_old[i], speed) - Common.linear_flux(u_old[left], speed) :
                Common.burgers_flux(u_old[i]) - Common.burgers_flux(u_old[left])) / dx : 0.0
        diffusive_term = diffusivity * (u_old[right] - 2 * u_old[i] + u_old[left]) / (dx * dx)
        u_new[i] = u_old[i] - dt * advective_term + dt * diffusive_term
    end
    return u_new
end
end
include("N06Advection.jl")
include("N07Transport.jl")
include("N08N09Elliptic.jl")
end
