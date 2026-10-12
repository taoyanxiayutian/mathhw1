
using TyPlot
using Printf

# ==========================================
# 1. 定义被积函数
# I = integral_0^1 sqrt(x)*ln(x) dx = -4/9
# ==========================================
function f(x)
    if x == 0.0
        return 0.0
    else
        return sqrt(x) * log(x)
    end
end

I_exact = -4.0 / 9.0

# ==========================================
# 2. 复合梯形求积公式
# I_T = h*[f(x0)/2 + sum(f(xi)) + f(xn)/2]
# ==========================================
function composite_trapezoid(n)
    h = 1.0 / n

    result = (f(0.0) + f(1.0)) / 2.0

    for i in 1:(n - 1)
        x = i * h
        result += f(x)
    end

    return h * result
end

# ==========================================
# 3. 复合辛普森求积公式
# 要求 n 为偶数
# ==========================================
function composite_simpson(n)
    if n % 2 != 0
        error("复合辛普森公式要求 n 为偶数")
    end

    h = 1.0 / n
    result = f(0.0) + f(1.0)

    for i in 1:(n - 1)
        x = i * h

        if i % 2 == 1
            result += 4.0 * f(x)
        else
            result += 2.0 * f(x)
        end
    end

    return h * result / 3.0
end

# ==========================================
# 4. 计算绝对误差
# ==========================================
function absolute_error(I_approx)
    return abs(I_approx - I_exact)
end

# ==========================================
# 5. 设置不同的步长
# h = 1/n，n 取偶数
# ==========================================
n_values = [4, 8, 16, 32, 64, 128,
            256, 512, 1024, 2048, 4096]

h_values = Float64[]
trap_values = Float64[]
simpson_values = Float64[]
trap_errors = Float64[]
simpson_errors = Float64[]

# ==========================================
# 6. 计算并输出结果
# ==========================================
println("定积分的精确值 I = ", I_exact)
println()

@printf("%8s %12s %18s %14s %18s %14s\n",
        "n", "h", "梯形近似值", "梯形误差",
        "辛普森近似值", "辛普森误差")

for n in n_values
    h = 1.0 / n

    I_trap = composite_trapezoid(n)
    I_simp = composite_simpson(n)

    E_trap = absolute_error(I_trap)
    E_simp = absolute_error(I_simp)

    push!(h_values, h)
    push!(trap_values, I_trap)
    push!(simpson_values, I_simp)
    push!(trap_errors, E_trap)
    push!(simpson_errors, E_simp)

    @printf("%8d %12.5e %18.10f %14.5e %18.10f %14.5e\n",
            n, h, I_trap, E_trap, I_simp, E_simp)
end

# ==========================================
# 7. 计算实验收敛阶
# p = log(E(h)/E(h/2))/log(2)
# ==========================================
println()
println("相邻步长下的实验收敛阶")
@printf("%8s %18s %18s\n",
        "n", "梯形公式阶数", "辛普森公式阶数")

for k in 2:length(n_values)
    p_trap = log(trap_errors[k - 1] / trap_errors[k]) / log(2.0)
    p_simp = log(simpson_errors[k - 1] / simpson_errors[k]) / log(2.0)

    @printf("%8d %18.6f %18.6f\n",
            n_values[k], p_trap, p_simp)
end

# ==========================================
# 8. 绘制绝对误差曲线
# ==========================================
TyPlot.figure()

TyPlot.loglog(h_values, trap_errors, "o-",
              label="Composite Trapezoid")

TyPlot.hold("on")

TyPlot.loglog(h_values, simpson_errors, "s-",
              label="Composite Simpson")

TyPlot.xlabel("Step size h")
TyPlot.ylabel("Absolute error")
TyPlot.title("Quadrature Error Comparison")
TyPlot.legend()
TyPlot.grid(true)
