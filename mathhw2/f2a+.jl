using Printf
using TyPlot

# 被积函数在 x = 0 处取连续延拓值，避免计算 log(0)
function f(x)
    if x == 0.0
        return 0.0
    else
        return sqrt(x) * log(x)
    end
end

# 复合梯形公式
function composite_trapezoid(n)
    h = 1.0 / n
    result = 0.5 * f(0.0) + 0.5 * f(1.0)

    for i in 1:(n - 1)
        result += f(i * h)
    end

    return h * result
end

# 复合辛普森公式，n 必须为偶数
function composite_simpson(n)
    if n % 2 != 0
        error("复合辛普森公式要求 n 为偶数")
    end

    h = 1.0 / n
    result = f(0.0) + f(1.0)

    for i in 1:(n - 1)
        if i % 2 == 1
            result += 4.0 * f(i * h)
        else
            result += 2.0 * f(i * h)
        end
    end

    return h * result / 3.0
end

# 精确积分值与绝对误差
I_exact = -4.0 / 9.0
absolute_error(I_approx) = abs(I_approx - I_exact)

n_values = [4, 8, 16, 32, 64, 128, 256, 512,1024, 2048, 4096, 8192, 16384, 32768]
trap_errors = Float64[]
simpson_errors = Float64[]
h_values = Float64[]

println("精确值 I = ", I_exact)
@printf("%8s %12s %18s %14s %18s %14s\n",
        "n", "h", "梯形近似值", "梯形误差", "辛普森近似值", "辛普森误差")

for n in n_values
    h = 1.0 / n
    I_trap = composite_trapezoid(n)
    I_simpson = composite_simpson(n)
    E_trap = absolute_error(I_trap)
    E_simpson = absolute_error(I_simpson)

    push!(h_values, h)
    push!(trap_errors, E_trap)
    push!(simpson_errors, E_simpson)

    @printf("%8d %12.5e %18.10f %14.5e %18.10f %14.5e\n",
            n, h, I_trap, E_trap, I_simpson, E_simpson)
end

println("\n相邻步长下的实验收敛阶")
@printf("%8s %18s %18s\n", "n", "梯形实验阶", "辛普森实验阶")
for k in 2:length(n_values)
    p_trap = log(trap_errors[k - 1] / trap_errors[k]) / log(2.0)
    p_simpson = log(simpson_errors[k - 1] / simpson_errors[k]) / log(2.0)
    @printf("%8d %18.6f %18.6f\n", n_values[k], p_trap, p_simpson)
end

# 双对数误差图
TyPlot.figure()
TyPlot.loglog(h_values, trap_errors, "o-", label="Composite Trapezoid")
TyPlot.hold("on")
TyPlot.loglog(h_values, simpson_errors, "s-", label="Composite Simpson")
TyPlot.xlabel("Step size h")
TyPlot.ylabel("Absolute error")
TyPlot.title("Quadrature Error versus Step Size")
TyPlot.legend()
TyPlot.grid(true)