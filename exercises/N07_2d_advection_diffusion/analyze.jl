module N07Analysis
include("provided_support.jl")
"""辺別の区間積分から熱量変化を再構成する。流入を正とする。"""
function heat_budget(time,heat,advective_integrals,diffusive_integrals)
    validate_budget(time,heat,advective_integrals,diffusive_integrals)
    # TODO(N07): 各区間の正味流入、累積流入、初期熱量からの変化との差。
    error("未実装 N07: 熱収支解析")
end
end
