module ThermofluidExercise

"""周期左隣。整数1 <= i <= n、Bool不可。"""
function periodic_left_index(i,n)
    # TODO(N05): 周期配列の左隣添字を返す。
    error("未実装 N05: periodic_left_index")
end

"""周期右隣。整数1 <= i <= n、Bool不可。"""
function periodic_right_index(i,n)
    # TODO(N05): 周期配列の右隣添字を返す。
    error("未実装 N05: periodic_right_index")
end

"""有限実数の線形流束。"""
function linear_flux(u,speed)
    # TODO(N05): 有限実数の入力を検証し、線形流束を返す。
    error("未実装 N05: linear_flux")
end

"""有限実数のBurgers流束。負値も受け付ける。"""
function burgers_flux(u)
    # TODO(N05): 有限実数の入力を検証し、Burgers流束を返す。
    error("未実装 N05: burgers_flux")
end

"""1始まり・浮動小数・同形状・各軸3点以上・非alias・有限旧値。"""
function validate_buffers(u_new,u_old)
    # TODO(N05): 新旧配列の形状・型・非alias・旧値の有限性を検証する。
    error("未実装 N05: validate_buffers")
end

"""正の有限値から (;steps,dt) を返し最終時刻へ合わせる。"""
function fit_timestep(dt_max,t_final)
    # TODO(N05): 安定上限を超えない刻みとステップ数を最終時刻から返す。
    error("未実装 N05: fit_timestep")
end

module N01
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function upwind_step!(args...;kwargs...)
    # TODO(N05): 既習のN01.upwind_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N01.upwind_step!")
end
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function centered_step!(args...;kwargs...)
    # TODO(N05): 既習のN01.centered_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N01.centered_step!")
end
"""N01の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(args...;kwargs...)
    # TODO(N05): 既習のN01.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N01.apply_boundary!")
end
end
module N02
"""N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function nonlinear_upwind_step!(args...;kwargs...)
    # TODO(N05): 既習のN02.nonlinear_upwind_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N02.nonlinear_upwind_step!")
end
"""N02の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(args...;kwargs...)
    # TODO(N05): 既習のN02.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N02.apply_boundary!")
end
end
module N03
"""N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function diffusion_step!(args...;kwargs...)
    # TODO(N05): 既習のN03.diffusion_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N03.diffusion_step!")
end
"""N03の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function apply_boundary!(args...;kwargs...)
    # TODO(N05): 既習のN03.apply_boundary!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N03.apply_boundary!")
end
end
module N04
"""N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function stable_timestep(args...;kwargs...)
    # TODO(N05): 既習のN04.stable_timestepを共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N04.stable_timestep")
end
"""N04の既存入口と同じ契約を保つ。N04更新ではmodelを明示する。"""
function advection_diffusion_step!(args...;kwargs...)
    # TODO(N05): 既習のN04.advection_diffusion_step!を共通APIを使う処理へ移し、既存の契約を保つ。
    error("未実装 N05: N04.advection_diffusion_step!")
end
end
include("N06Advection.jl")
include("N07Transport.jl")
include("N08N09Elliptic.jl")
end
