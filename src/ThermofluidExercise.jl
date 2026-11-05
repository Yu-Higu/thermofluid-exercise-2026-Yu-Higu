# N05の共通API。周期添字 → 流束 → バッファ検証 → 刻み調整 → 既習課題の入口の順に読みます。
# TODOを実装して既存の入力・返り値の契約を保ち、N06以降でも再利用します。

module ThermofluidExercise

"""
    periodic_left_index(i, n)

1始まりの周期配列で左隣の添字を求める。

# 引数

- `i`: 1始まりの現在の添字。
- `n`: 配列の点数。

i,nはBoolを除く整数、n>=1、1<=i<=n。

# 返り値

実装後は 1からnまでの整数。

# 受講生のToDo

N02の周期左隣を共通化し、先頭から左へ越えたときは末尾の添字を返す。1点の場合も扱う。
この関数では引数条件の検証も学生が実装する。N05の共通APIと既習N02を参照する。配布状態では未実装エラーで停止する。
"""
function periodic_left_index(i, n)
    # TODO(N05): 周期配列の左隣添字を返す。
    i isa Integer && !(i isa Bool) && n isa Integer && !(n isa Bool) &&
        n >= 1 && 1 <= i <= n ||
        throw(ArgumentError("i,nはBoolを除く整数で、n >= 1かつ1 <= i <= nです"))
    return i == 1 ? n : i - 1
end

"""
    periodic_right_index(i, n)

1始まりの周期配列で右隣の添字を求める。

# 引数

- `i`: 1始まりの現在の添字。
- `n`: 配列の点数。

i,nはBoolを除く整数、n>=1、1<=i<=n。

# 返り値

実装後は 1からnまでの整数。

# 受講生のToDo

周期右隣の添字を求め、末尾から右へ越えたときは先頭へ戻す。1点の場合も扱う。
左隣APIと同じ引数条件の検証も学生が実装する。N04の周期左右隣接とN05の共通APIを参照する。配布状態では未実装エラーで停止する。
"""
function periodic_right_index(i, n)
    # TODO(N05): 周期配列の右隣添字を返す。
    i isa Integer && !(i isa Bool) && n isa Integer && !(n isa Bool) &&
        n >= 1 && 1 <= i <= n ||
        throw(ArgumentError("i,nはBoolを除く整数で、n >= 1かつ1 <= i <= nです"))
    return i == n ? 1 : i + 1
end

"""
    linear_flux(u, speed)

有限な実数の線形流束を評価する。

# 引数

- `u`: 有限な実数の場の値。
- `speed`: 有限な実数の移流速度。

u,speedの有限実数を検証する。

# 返り値

実装後は スカラーの線形流束。

# 受講生のToDo

1点の場と速度を有限実数として検証し、N01で使った線形流束をスカラーで返す。配列の更新は呼出し側の責務である。
入力検証も学生の実装範囲。N05の共通APIを参照する。配布状態では未実装エラーで停止する。
"""
function linear_flux(u, speed)
    # TODO(N05): 有限実数の入力を検証し、線形流束を返す。
    u isa Real && isfinite(u) || throw(ArgumentError("uは有限な実数です"))
    speed isa Real && isfinite(speed) || throw(ArgumentError("speedは有限な実数です"))
    flux = float(u) * float(speed)
    isfinite(flux) || throw(ArgumentError("線形流束が有限値の範囲を超えています"))
    return flux
end

"""
    burgers_flux(u)

有限な実数のBurgers流束を評価する。

# 引数

- `u`: 有限な実数の場の値。

負値も受け付け、有限実数を検証する。

# 返り値

実装後は スカラーのBurgers流束。

# 受講生のToDo

1点の場を有限実数として検証し、既習N02のBurgers流束をスカラーで返す。負値も流束の入力として扱う。
入力検証も学生の実装範囲。配布状態では未実装エラーで停止する。
"""
function burgers_flux(u)
    # TODO(N05): 有限実数の入力を検証し、Burgers流束を返す。
    u isa Real && isfinite(u) || throw(ArgumentError("uは有限な実数です"))
    flux = (float(u) / 2) * float(u)
    isfinite(flux) || throw(ArgumentError("Burgers流束が有限値の範囲を超えています"))
    return flux
end

"""
    validate_buffers(u_new, u_old)

新旧バッファが安全に更新できる入力か検証する。

# 引数

- `u_new`: 更新結果を書き込む配列。旧配列と重ならない独立したバッファ。
- `u_old`: 更新前の値を読む配列。更新中は変更しない。

各軸3点以上・1始まりの同形状の浮動小数配列。非aliasとは同じ記憶領域を共有しないこと。
この条件と有限な旧値を検証する。不正入力は実装後の検証でArgumentError。

# 返り値

実装後は 成功時はnothing。

# 受講生のToDo

新旧配列の型・形状・軸・点数・有限旧値と、同じ記憶領域を共有しないことを検査する。出力の初期値の有限性は要求しない。
全点で同じ旧場を読むため、入力を書き換えず、不正なら更新前にArgumentErrorを投げる検証APIを実装する。
N01〜N04のバッファ検証とN05の共通APIを参照する。配布状態では未実装エラーで停止する。
"""
function validate_buffers(u_new, u_old)
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

"""
    fit_timestep(dt_max, t_final)

刻み上限を守り、最終時刻へ到達する刻みとステップ数を決める。

# 引数

- `dt_max`: 有限な正の刻み上限。
- `t_final`: 計算の最終時刻。

dt_max,t_finalは有限な正値。表現不能な刻みやステップ数も拒否する。

# 返り値

実装後は `(;steps, dt)` のNamedTuple。stepsは正整数、dtは有限正値でdt_max以下、steps回でt_finalへ到達する。

# 受講生のToDo

最終時刻へ等間隔で到達し、刻みがdt_max以下になる正整数stepsと正のdtを返す。
有限正の入力と、ステップ数・刻みの表現可能性の検証も実装する。N01〜N04の時間刻み調整とN05の共通APIを参照する。配布状態では未実装エラーで停止する。
"""
function fit_timestep(dt_max, t_final)
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
# N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    upwind_step!(u_new, u_old, c, dt, dx)

N01の風上更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、有限正の移流速度、時間刻み、格子幅の順。新配列に書込み、旧配列を保持する。
- `kwargs`: キーワード引数はない。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は更新した新配列。内部点を更新し、境界値は呼出し側で適用する。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
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
# N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    centered_step!(u_new, u_old, c, dt, dx)

N01の中心差分更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、有限正の移流速度、時間刻み、格子幅の順。新配列に書込み、旧配列を保持する。
- `kwargs`: キーワード引数はない。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は更新した新配列。内部点を更新し、境界値は呼出し側で適用する。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
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
# N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    apply_boundary!(u; left_value = 1.0)

N01の左流入・右流出境界を共通APIへ移す。

# 引数

- `args`: 端点を書き換えるベクトル。
- `kwargs`: `left_value` は有限な左境界値（既定1.0）。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は境界を適用した入力ベクトル。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
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
# N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    nonlinear_upwind_step!(u_new, u_old, dt, dx; boundary = :fixed)

N02の非線形風上更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、時間刻み、格子幅の順。新旧は独立し、旧場を保持する。
- `kwargs`: `boundary` は `:fixed` または `:periodic`（既定 `:fixed`）。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は境界も適用した新配列。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function nonlinear_upwind_step!(u_new, u_old, dt::Real, dx::Real; boundary = :fixed)
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
# N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    apply_boundary!(u; boundary = :fixed)

N02の固定または周期境界を共通APIへ移す。

# 引数

- `args`: 境界を適用するベクトル。周期境界では格子の全点を使う。
- `kwargs`: `boundary` は `:fixed` または `:periodic`（既定 `:fixed`）。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は境界を適用した入力ベクトル。周期境界では値を変更しない。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function apply_boundary!(u; boundary = :fixed)
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
# N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    diffusion_step!(u_new, u_old, dt, dx, diffusivity; boundary = :fixed)

N03の熱拡散更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、時間刻み、格子幅、有限正の拡散係数の順。新旧は独立し、旧場を保持する。
- `kwargs`: `boundary` は固定温度の `:fixed`（既定）または断熱の `:insulated`。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は選択した境界も適用した新配列。安定上限を超える刻みも実験用に受け付ける。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function diffusion_step!(u_new, u_old, dt::Real, dx::Real, diffusivity::Real; boundary = :fixed)
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
# N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    apply_boundary!(u_new, u_old, r; boundary = :fixed)

N03の固定温度または断熱端点の更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、有限正の実効Fourier数の順。新旧は独立し、旧場を保持する。
- `kwargs`: `boundary` は固定温度の `:fixed`（既定）または断熱の `:insulated`。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は両端を更新した新ベクトル。内部点は変更しない。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function apply_boundary!(u_new, u_old, r::Real; boundary = :fixed)
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
# N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    stable_timestep(max_speed, dx, diffusivity; safety = 0.8)

N04の合成安定条件による刻み選択を共通APIへ移す。

# 引数

- `args`: 有限非負の最大速度、有限正の格子幅、有限非負の拡散係数の順。速度と拡散係数を同時に0にしない。
- `kwargs`: `safety` は0より大きく1以下（既定0.8）。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は有限正の時間刻み。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function stable_timestep(max_speed, dx, diffusivity; safety = 0.8)
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
# N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。
"""
    advection_diffusion_step!(u_new, u_old, dt, dx, diffusivity;
                              model, advection = true, speed = 1.0)

N04の移流拡散更新を共通APIへ移す。

# 引数

- `args`: 新旧ベクトル、時間刻み、格子幅、有限非負の拡散係数の順。新旧は独立し、旧場を保持する。
- `kwargs`: `model` を明示する。`advection=true`、`speed=1.0` は既習入口と同じ。

対応する既習関数と同じ入力検証を保つ。未実装時は未実装エラーで停止する。

# 返り値

実装後は全周期格子点を更新した新配列。

# 受講生のToDo

既習の同名関数を共通APIを使う処理へ移す。入力検証・更新範囲・入力保持を保つ。
"""
function advection_diffusion_step!(u_new, u_old, dt, dx, diffusivity;
    model, advection = true, speed = 1.0)
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
