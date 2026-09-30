module RelaxationExtension
using ThermofluidExercise
const E=ThermofluidExercise.Elliptic
export gauss_seidel_step!,sor_step!,solve_relaxation
function sor_step!(u,f,dx,dy;omega=1.5)
    E.buffers(u,f);E.require(all(isfinite,u),"更新前の場は有限値が必要です")
    ax,ay,d=E.coefficients(dx,dy)
    E.require(omega isa Real && isfinite(omega) && 0<omega<2,"omegaは0<omega<2です")
    # TODO_BEGIN sor
    error("未実装 発展: sor")
    # TODO_END sor
    u
end
gauss_seidel_step!(u,f,dx,dy)=sor_step!(u,f,dx,dy;omega=1.)
function solve_relaxation(u0,g,f,dx,dy;method=:sor,omega=1.5,atol=1e-10,rtol=1e-12,maxiter=200000)
    E.require(method in (:gauss_seidel,:sor),"method不正")
    E.require(omega isa Real && isfinite(omega) && 0<omega<2,"omega不正")
    # Provided driver uses a private old field; the lexicographic sweep is in-place there.
    step! = (new,old,f,dx,dy)->(copyto!(new,old);sor_step!(new,f,dx,dy;omega=method==:gauss_seidel ? 1. : omega))
    E.solve_driver(u0,g,f,dx,dy,step!,E.poisson_residual!;atol,rtol,maxiter)
end
end
