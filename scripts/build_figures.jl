# Reproduce the book's original figures and numerical checks.
# Julia >= 1.10; standard libraries only. Run from any directory.
using LinearAlgebra, Printf, DelimitedFiles
const ROOT = normpath(joinpath(@__DIR__, ".."))
const FIG = joinpath(ROOT, "figs")
const DATA = joinpath(ROOT, "data")
mkpath(FIG); mkpath(DATA)
xml(s) = replace(string(s), "&"=>"&amp;", "<"=>"&lt;", ">"=>"&gt;")
function chart(name, title, xlabel, ylabel, xs, ys, labels;
               colors=["#176b70", "#b87440", "#5c6196"], xlim=extrema(xs), ylim=nothing)
    W,H=900,490; l,r,t,b=95,34,95,78
    ymin,ymax = isnothing(ylim) ? extrema(vcat(ys...)) : ylim
    if isnothing(ylim)
        pad=max((ymax-ymin)*.1,1e-6); ymin-=pad; ymax+=pad
    end
    xmin,xmax=xlim
    X(x)=l+(x-xmin)/(xmax-xmin)*(W-l-r)
    Y(y)=H-b-(y-ymin)/(ymax-ymin)*(H-t-b)
    open(joinpath(FIG,name*".svg"),"w") do io
        println(io,"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $W $H" role="img"><title>$(xml(title))</title><rect width="$W" height="$H" fill="#ffffff"/><g font-family="DejaVu Sans, sans-serif" fill="#263c45"><text x="$l" y="34" font-size="23" font-weight="bold">$(xml(title))</text>""")
        for f in range(0,1,length=6)
            x=xmin+f*(xmax-xmin); y=ymin+f*(ymax-ymin)
            println(io,"""<path d="M $(X(x)) $t V $(H-b) M $l $(Y(y)) H $(W-r)" stroke="#e4e8e7" fill="none"/><text x="$(X(x))" y="$(H-b+26)" font-size="15" text-anchor="middle">$(@sprintf("%.2g",x))</text><text x="$(l-12)" y="$(Y(y)+5)" font-size="15" text-anchor="end">$(@sprintf("%.2g",y))</text>""")
        end
        println(io,"""<path d="M $l $t V $(H-b) H $(W-r)" stroke="#718083" fill="none" stroke-width="1.5"/><text x="$(l+(W-l-r)/2)" y="$(H-19)" text-anchor="middle" font-size="18">$(xml(xlabel))</text><text transform="translate(25 $(t+(H-t-b)/2)) rotate(-90)" text-anchor="middle" font-size="18">$(xml(ylabel))</text>""")
        for (i,y) in enumerate(ys)
            points=join((@sprintf("%.2f,%.2f",X(x),Y(v)) for (x,v) in zip(xs,y))," ")
            dash = i==2 ? "stroke-dasharray=\"8 5\"" : ""
            println(io,"""<polyline points="$points" fill="none" stroke="$(colors[i])" stroke-width="2.8" $dash/>""")
            lx=l+(i-1)*285
            println(io,"""<path d="M $lx 64 h 30" stroke="$(colors[i])" stroke-width="3" $dash/><text x="$(lx+40)" y="69" font-size="15">$(xml(labels[i]))</text>""")
        end
        println(io,"</g></svg>")
    end
end
function csv(name, header, cols...)
    open(joinpath(DATA,name),"w") do io
        println(io,join(header,",")); writedlm(io,hcat(cols...),',')
    end
end
function main()
# 1. Independent birth-death solution of the pumped/lossy cavity.
kappa,p,w0=1.,.2,1.; Gamma=(kappa-p)/2; N=28
Q=zeros(N,N)
for n in 0:N-1
    if n>0
        Q[n,n+1]+=kappa*n; Q[n+1,n+1]-=kappa*n
    end
    if n<N-1
        Q[n+2,n+1]+=p*(n+1); Q[n+1,n+1]-=p*(n+1)
    end
end
B=copy(Q); B[end,:].=1; rhs=zeros(N); rhs[end]=1
prob=B\rhs; nbar=dot(0:N-1,prob); exact=p/(kappa-p)
@assert norm(Q*prob)<1e-12 && minimum(prob)>-1e-14
@assert abs(nbar-exact)<1e-12
w=collect(range(-1,3,length=601)); den=(w.-w0).^2 .+Gamma^2
A=2Gamma./den; K=(kappa+p)./den
@assert maximum(abs.(K./A .-(2exact+1)))<1e-12
chart("cavity-spectrum","Response and fluctuations are different spectra","frequency / ω₀","spectral weight",w,[A,K],["A = −2 Im Gᴿ","iGᴷ = (2n + 1) A"])
csv("cavity-spectrum.csv",["omega","spectral_function","i_GK"],w,A,K)
# 2. Dicke stability: drift eigenvalues versus the analytic threshold.
wz=1.; wc=1.; loss=.4; gamma=loss/2
lc=sqrt(wz*(wc^2+gamma^2)/(4wc))
function drift(lambda)
    [-gamma wc 0. 0.; -wc -gamma -2lambda 0.; 0. 0. 0. wz; -2lambda 0. -wz 0.]
end
rate(lambda)=maximum(real.(eigvals(drift(lambda))))
@assert rate(.99lc)<0 && rate(1.01lc)>0
@assert abs(det(drift(lc)))<1e-12
ls=collect(range(.05,.8,length=501)); rates=rate.(ls)
chart("dicke-stability","A collective mode crosses into instability","coupling λ / ωz","largest Re(eigenvalue)",ls,[rates,zeros(length(ls))],["linear drift spectrum","stability boundary"])
csv("dicke-stability.csv",["lambda","max_real_eigenvalue"],ls,rates)
# 3. Exact stationary EW ring: Fourier-mode covariance versus continuum result.
L,D,Delta=100.,1.,.08; modes=1024
xs=collect(range(0,L,length=401))
variance=[4Delta/(D*L)*sum((1-cos(2pi*n*x/L))/(2pi*n/L)^2 for n in 1:modes) for x in xs]
continuum=Delta/D.*xs.*(1 .-xs./L)
@assert maximum(abs.(variance-continuum))<.001
chart("phase-variance","Stationary phase fluctuations on a ring","separation x","⟨[θ(x) − θ(0)]²⟩",xs,[variance,continuum],["1024 positive Fourier modes","continuum: (Δ/D)x(1 − x/L)"])
csv("phase-variance.csv",["x","mode_sum_variance","continuum_variance","Gaussian_g1"],xs,variance,continuum,exp.(-variance./2))
# 4. Number-conserving heating, exact one-particle/two-site Liouvillian.
J,noise=1.,.7
H=ComplexF64[0 -J; -J 0]; eye=Matrix{ComplexF64}(I,2,2)
Lio=-im*(kron(eye,H)-kron(transpose(H),eye))
for n in (ComplexF64[1 0;0 0], ComplexF64[0 0;0 1])
    nn=n'*n
    Lio+=noise*(kron(conj(n),n)-.5kron(eye,nn)-.5kron(transpose(nn),eye))
end
rho0=fill(.5+0im,2,2); ts=collect(range(0,8,length=121))
energies=Float64[]
for time in ts
    rho=reshape(exp(Lio*time)*vec(rho0),2,2)
    @assert abs(tr(rho)-1)<1e-12 && norm(rho-rho')<1e-12
    @assert minimum(eigvals(Hermitian(rho)))>-1e-12
    push!(energies,real(tr(H*rho)))
end
expected=-J*exp.(-noise.*ts)
@assert maximum(abs.(energies-expected))<1e-12
chart("two-site-heating","Dephasing heats without removing particles","time · J","energy / J",ts,[energies,expected],["matrix exponential","exact: −exp(−γt)"])
csv("two-site-heating.csv",["time","matrix_energy","analytic_energy"],ts,energies,expected)
# An asymptotic one-loop formula, not a simulation of KPZ.
gs=collect(range(.05,1,length=301)); logscale=8pi./(gs.*log(10))
chart("kpz-crossover","A weak drive can hide at enormous length scales","bare dimensionless coupling g₀","log₁₀(L*/ξ)",gs,[logscale],["isotropic 2D one-loop estimate"],ylim=(0,230))
csv("kpz-crossover.csv",["g0","log10_Lstar_over_xi"],gs,logscale)
open(joinpath(DATA,"checks.txt"),"w") do io
    println(io,"Julia ",VERSION,"; standard libraries only")
    println(io,"Cavity nbar = ",nbar,"; exact = ",exact)
    println(io,"Dicke lambda_c = ",lc)
    println(io,"EW maximum cutoff discrepancy = ",maximum(abs.(variance-continuum)))
    println(io,"Two-site maximum energy discrepancy = ",maximum(abs.(energies-expected)))
    println(io,"All trace, positivity, stationarity, threshold, and covariance checks passed.")
end
println(read(joinpath(DATA,"checks.txt"),String))

end
main()
