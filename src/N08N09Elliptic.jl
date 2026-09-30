module Elliptic
export apply_dirichlet!, laplace_jacobi_step!, laplace_residual!, residual_converged,
       poisson_jacobi_step!, poisson_residual!, solve_laplace, solve_poisson
require(ok,msg)=ok ? nothing : throw(ArgumentError(msg))
function matrix(a; finite=false)
    require(a isa AbstractMatrix{<:AbstractFloat} && all(>=(3),size(a)) && axes(a)==map(Base.OneTo,size(a)),"1始まり・各軸3点以上の浮動小数行列です")
    finite && require(all(isfinite,a),"入力場は有限です")
end
function buffers(out,inputs...)
    matrix(out)
    for a in inputs
        matrix(a;finite=true); require(size(out)==size(a),"配列の形状が異なります")
    end
    arrays=(out,inputs...)
    for j in 2:length(arrays),i in 1:j-1
        require(!Base.mightalias(arrays[i],arrays[j]),"配列は互いに非aliasです")
    end
end
function coefficients(dx,dy)
    require(all(h->h isa Real && !(h isa Bool) && isfinite(h) && h>0,(dx,dy)),"dx,dyは有限正値です")
    ax,ay=inv(Float64(dx))^2,inv(Float64(dy))^2; d=2ax+2ay
    require(all(v->isfinite(v) && v>0,(ax,ay,d)),"逆二乗係数・分母が表現範囲外です")
    ax,ay,d
end
function tolerances(atol,rtol)
    require(all(v->v isa Real && isfinite(v) && v>=0,(atol,rtol)) && (atol>0 || rtol>0),"許容値は有限非負、少なくとも一方が正です")
end
function apply_dirichlet!(u,g)
    buffers(u,g)
    # STUDENT_BEGIN apply_dirichlet!
    error("未実装 N08: apply_dirichlet!")
    # STUDENT_END apply_dirichlet!
    u
end
function laplace_jacobi_step!(u_new,u_old,dx,dy)
    buffers(u_new,u_old); ax,ay,d=coefficients(dx,dy)
    # STUDENT_BEGIN laplace_jacobi_step!
    error("未実装 N08: laplace_jacobi_step!")
    # STUDENT_END laplace_jacobi_step!
    u_new
end
function laplace_residual!(r,u,dx,dy)
    buffers(r,u);ax,ay,d=coefficients(dx,dy)
    # STUDENT_BEGIN laplace_residual!
    error("未実装 N08: laplace_residual!")
    # STUDENT_END laplace_residual!
    r
end
function residual_converged(r_norm,r_initial;atol=1e-10,rtol=1e-12)
    tolerances(atol,rtol)
    require(all(v->v isa Real && isfinite(v) && v>=0,(r_norm,r_initial)),"残差normは有限非負です")
    threshold=max(atol,rtol*r_initial)
    require(isfinite(threshold),"停止閾値が表現範囲外です")
    # STUDENT_BEGIN residual_converged
    error("未実装 N08: residual_converged")
    # STUDENT_END residual_converged
end
function poisson_jacobi_step!(u_new,u_old,f,dx,dy)
    buffers(u_new,u_old,f);ax,ay,d=coefficients(dx,dy)
    # STUDENT_BEGIN poisson_jacobi_step!
    error("未実装 N09: poisson_jacobi_step!")
    # STUDENT_END poisson_jacobi_step!
    u_new
end
function poisson_residual!(r,u,f,dx,dy)
    buffers(r,u,f);ax,ay,d=coefficients(dx,dy)
    # STUDENT_BEGIN poisson_residual!
    error("未実装 N09: poisson_residual!")
    # STUDENT_END poisson_residual!
    r
end
interior_norm(a)=maximum(abs,@view a[2:end-1,2:end-1])
"""提供の反復処理。新場の残差を使って停止を判定する。"""
function solve_driver(u0,g,f,dx,dy,step!,residual!;atol=1e-10,rtol=1e-12,maxiter=200000)
    matrix(u0;finite=true);matrix(g;finite=true);coefficients(dx,dy);tolerances(atol,rtol)
    require(maxiter isa Integer && !(maxiter isa Bool) && maxiter>0,"maxiterは正整数です")
    # 作業用配列を使い、入力を検査する。
    old=copy(u0); f===nothing ? buffers(old,u0,g) : buffers(old,u0,g,f)
    apply_dirichlet!(old,g);new=similar(old);r=similar(old)
    f===nothing ? residual!(r,old,dx,dy) : residual!(r,old,f,dx,dy)
    initial=interior_norm(r);threshold=max(atol,rtol*initial)
    isfinite(initial) && isfinite(threshold) || error("$(f===nothing ? :laplace : :poisson) $(size(old)): 初回残差／停止閾値が非有限です")
    rh=[Float64(initial)];uh=[0.];n=0;reason=:maxiter
    if residual_converged(initial,initial;atol,rtol)
        reason=:converged
    else
        for k in 1:maxiter
            f===nothing ? step!(new,old,dx,dy) : step!(new,old,f,dx,dy)
            if !all(isfinite,new);reason=:nonfinite;break;end
            apply_dirichlet!(new,g)
            f===nothing ? residual!(r,new,dx,dy) : residual!(r,new,f,dx,dy)
            rn=interior_norm(r);un=maximum(abs(new[i,j]-old[i,j]) for j in 2:size(old,2)-1,i in 2:size(old,1)-1)
            if !(isfinite(rn) && isfinite(un));reason=:nonfinite;break;end
            old,new=new,old;n=k;push!(rh,rn);push!(uh,un)
            if residual_converged(rn,initial;atol,rtol);reason=:converged;break;end
        end
    end
    (;u=old,converged=reason==:converged,reason,iterations=n,residual_history=rh,update_history=uh,threshold)
end
solve_laplace(u0,g,dx,dy;kwargs...)=solve_driver(u0,g,nothing,dx,dy,laplace_jacobi_step!,laplace_residual!;kwargs...)
solve_poisson(u0,g,f,dx,dy;kwargs...)=solve_driver(u0,g,f,dx,dy,poisson_jacobi_step!,poisson_residual!;kwargs...)
end
