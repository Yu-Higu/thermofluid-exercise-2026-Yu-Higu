# 提供: N07セル中心格子と辺順。計算・保存・解析・作図で共有する。
using HDF5, SHA, TOML
const DEFAULT_OUTPUT_DIR=joinpath(@__DIR__,"results")
const OUTPUT_NAMES=("temperature.h5","burgers.h5","summary.toml","temperature_comparison.png","boundary_heat.png","burgers_fields.png","convergence.png","plots.toml")
const OFFICIAL_GRIDS=((40,30),(80,60),(160,120))
const SAVE_TIMES=[0.,.25,.5,.75,1.]
const SIDES=("west","east","south","north")
case_id(nx,ny)="n$(lpad(nx,3,'0'))x$(lpad(ny,3,'0'))"
cell_centers(n,L)=collect(((1:n).-0.5).*(L/n))

require(ok,msg)=ok ? nothing : throw(ArgumentError(msg))
function schedule(time,t_final=1.)
    require(time isa AbstractVector && length(time)>=2 && all(t->t isa Real && isfinite(t),time) && first(time)==0 && last(time)==t_final && all(diff(time).>0),"timeは0始まり・有限・狭義増加・末尾t_finalです")
    Float64.(time)
end
function validate_budget(time,heat,adv,diff)
    require(time isa AbstractVector && length(time)>=2,"timeは2点以上です")
    schedule(time,last(time)); nt=length(time)
    require(heat isa AbstractVector && length(heat)==nt && all(v->v isa Real && isfinite(v),heat),"heatは時刻に対応する有限列です")
    for a in (adv,diff)
        require(a isa AbstractMatrix && size(a)==(4,nt-1) && all(v->v isa Real && isfinite(v),a),"熱輸送積分は有限な(4,nt-1)配列です")
    end
end
const PERIODIC_CASES=("periodic_advection","periodic_diffusion","periodic_combined")
const THERMAL_CASES=(PERIODIC_CASES...,"closed_fixed","closed_insulated","channel_fixed","channel_insulated",("comparison_"*split(c,"_")[2] for c in PERIODIC_CASES)...)
function thermal_config(id)
    b(k,v=0.)=(;kind=k,value=Float64(v))
    allbc(k)=(;west=b(k),east=b(k),south=b(k),north=b(k))
    require(id in THERMAL_CASES,"未知の温度ケース: $id")
    if startswith(id,"periodic_") || startswith(id,"comparison_")
        mode=split(id,"_")[2]; cx,cy=mode=="diffusion" ? (0.,0.) : (1.,.5)
        return (;cx,cy,kappa=mode=="advection" ? 0. : .05,bc=allbc(:periodic),initial="fourier_v1")
    elseif startswith(id,"closed_")
        return (;cx=0.,cy=0.,kappa=.05,bc=allbc(id=="closed_fixed" ? :dirichlet : :insulated),initial="sine_wall_v1")
    end
    wall=id=="channel_fixed" ? :dirichlet : :insulated
    (;cx=1.,cy=0.,kappa=.05,bc=(;west=b(:inflow,1.),east=b(:outflow),south=b(wall),north=b(wall)),initial="uniform_0.2")
end
function exact_temperature(x,y,t,id)
    c=thermal_config(id)
    if c.initial=="fourier_v1"
        X=x.-c.cx*t; Y=y.-c.cy*t; k=c.kappa
        return [1+.2exp(-k*pi^2*t)*sin(pi*xi)+.3exp(-4k*pi^2*t)*cos(2pi*yj)+.1exp(-5k*pi^2*t)*sin(pi*xi+2pi*yj) for xi in X,yj in Y]
    elseif id=="closed_fixed" || (id=="closed_insulated" && t==0)
        return [sin(pi*xi/2)*sin(pi*yj)*exp(-c.kappa*((pi/2)^2+pi^2)*t) for xi in x,yj in y]
    elseif startswith(id,"channel_") && t==0
        return fill(.2,length(x),length(y))
    end
    nothing
end

"""Cole–Hopfの明示微分。X=x-.6t, Y=y+.3t。数値差分で解析値を作らない。"""
function exact_burgers(x,y,t;nu=.05)
    X=x.-.6t; Y=y.+.3t; A=.2exp(-nu*pi^2*t); B=.2exp(-4nu*pi^2*t)
    phi=[1+A*cos(pi*xi)+B*cos(2pi*yj) for xi in X,yj in Y]
    u=[.6+2nu*A*pi*sin(pi*xi)/phi[i,j] for (i,xi) in enumerate(X),(j,yj) in enumerate(Y)]
    v=[-.3+4nu*B*pi*sin(2pi*yj)/phi[i,j] for (i,xi) in enumerate(X),(j,yj) in enumerate(Y)]
    u,v
end
