using LinearAlgebra
using Statistics
using TyPlot


# ============================================================
# 1. Runge函数
# ============================================================
function f(x)
    return 1.0 / (1.0 + 25.0 * x^2)
end


# ============================================================
# 2. 生成等距节点
# n表示区间个数，因此共有n+1个节点
# ============================================================
function interpolation_nodes(n)
    return collect(range(-1.0, 1.0, length=n + 1))
end


# ============================================================
# 3. 拉格朗日多项式插值
# ============================================================
function lagrange_interpolation(x, nodes, values)

    N = length(nodes)
    result = 0.0

    for i in 1:N

        Li = 1.0

        for j in 1:N
            if i != j
                Li *= (x - nodes[j]) /
                      (nodes[i] - nodes[j])
            end
        end

        result += values[i] * Li
    end

    return result
end


# ============================================================
# 4. 自然三次样条
#    求各节点处的二阶导数M
# ============================================================
function cubic_spline(nodes, values)

    n = length(nodes) - 1

    h = [
        nodes[i + 1] - nodes[i]
        for i in 1:n
    ]

    A = zeros(n + 1, n + 1)
    b = zeros(n + 1)

    # 自然边界条件
    # S''(-1)=0
    # S''(1)=0
    A[1, 1] = 1.0
    A[n + 1, n + 1] = 1.0

    # 内部节点
    for i in 2:n

        A[i, i - 1] = h[i - 1]

        A[i, i] =
            2.0 * (h[i - 1] + h[i])

        A[i, i + 1] = h[i]

        b[i] =
            6.0 * (
                (values[i + 1] - values[i]) / h[i]
                -
                (values[i] - values[i - 1]) / h[i - 1]
            )
    end

    M = A \ b

    return M
end


# ============================================================
# 5. 计算三次样条插值函数值
# ============================================================
function spline_interpolation(x, nodes, values, M)

    # 找到x所在区间
    i = searchsortedlast(nodes, x)

    # x恰好等于最右端点
    if i == length(nodes)
        i -= 1
    end

    h = nodes[i + 1] - nodes[i]

    term1 =
        M[i] *
        (nodes[i + 1] - x)^3 /
        (6.0 * h)

    term2 =
        M[i + 1] *
        (x - nodes[i])^3 /
        (6.0 * h)

    term3 =
        (
            values[i] / h
            -
            M[i] * h / 6.0
        ) *
        (nodes[i + 1] - x)

    term4 =
        (
            values[i + 1] / h
            -
            M[i + 1] * h / 6.0
        ) *
        (x - nodes[i])

    return term1 + term2 + term3 + term4
end


# ============================================================
# 6. 最大绝对误差
# ============================================================
function max_error(y_true, y_approx)

    return maximum(
        abs.(y_true .- y_approx)
    )

end


# ============================================================
# 7. 均方根误差 RMSE
# ============================================================
function rmse(y_true, y_approx)

    return sqrt(
        mean(
            (y_true .- y_approx).^2
        )
    )

end


# ============================================================
# 8. 主程序
# ============================================================

n = 10

println()
println("============================================")
println("Runge函数插值与拟合比较")
println("n = ", n)
println("============================================")


# ------------------------------------------------------------
# 生成11个等距节点
# ------------------------------------------------------------

nodes = interpolation_nodes(n)

values = [
    f(x)
    for x in nodes
]


# 输出节点
println()
println("插值节点：")

for i in 1:length(nodes)
    println(
        "x = ",
        nodes[i],
        "    f(x) = ",
        values[i]
    )
end


# ============================================================
# 9. 三次多项式最小二乘拟合
#
# Q3(x)=a0+a1*x+a2*x^2+a3*x^3
# ============================================================

A = hcat(
    ones(length(nodes)),
    nodes,
    nodes.^2,
    nodes.^3
)

a = A \ values

a0 = a[1]
a1 = a[2]
a2 = a[3]
a3 = a[4]


println()
println("============================================")
println("三次多项式拟合")
println("============================================")

println("a0 = ", a0)
println("a1 = ", a1)
println("a2 = ", a2)
println("a3 = ", a3)

println()
println("完整拟合方程：")

println(
    "Q3(x) = ",
    a0,
    " + (", a1, ")x",
    " + (", a2, ")x^2",
    " + (", a3, ")x^3"
)

println()
println("忽略浮点误差后的拟合方程：")

println(
    "Q3(x) ≈ ",
    round(a0, digits=6),
    " + (",
    round(a2, digits=6),
    ")x^2"
)


# 定义拟合函数
function fit_function(x, a)
    return (
        a[1]
        + a[2] * x
        + a[3] * x^2
        + a[4] * x^3
    )
end


# ============================================================
# 10. 三次样条系数
# ============================================================

M = cubic_spline(
    nodes,
    values
)


# ============================================================
# 11. 生成密集测试点
# ============================================================

x_plot = collect(
    range(
        -1.0,
        1.0,
        length=1001
    )
)


# Runge真实函数
y_true = [
    f(x)
    for x in x_plot
]


# ============================================================
# 12. 拉格朗日插值
# ============================================================

y_lagrange = [
    lagrange_interpolation(
        x,
        nodes,
        values
    )
    for x in x_plot
]


# ============================================================
# 13. 三次样条插值
# ============================================================

y_spline = [
    spline_interpolation(
        x,
        nodes,
        values,
        M
    )
    for x in x_plot
]


# ============================================================
# 14. 三次多项式拟合
# ============================================================

y_fit = [
    fit_function(x, a)
    for x in x_plot
]


# ============================================================
# 15. 计算最大绝对误差
# ============================================================

max_lagrange =
    max_error(
        y_true,
        y_lagrange
    )

max_spline =
    max_error(
        y_true,
        y_spline
    )

max_fit =
    max_error(
        y_true,
        y_fit
    )


# ============================================================
# 16. 计算RMSE
# ============================================================

rmse_lagrange =
    rmse(
        y_true,
        y_lagrange
    )

rmse_spline =
    rmse(
        y_true,
        y_spline
    )

rmse_fit =
    rmse(
        y_true,
        y_fit
    )


# ============================================================
# 17. 输出误差结果
# ============================================================

println()
println("============================================")
println("误差比较")
println("============================================")

println()
println("拉格朗日多项式插值：")
println(
    "最大绝对误差 = ",
    max_lagrange
)
println(
    "RMSE = ",
    rmse_lagrange
)

println()
println("三次样条插值：")
println(
    "最大绝对误差 = ",
    max_spline
)
println(
    "RMSE = ",
    rmse_spline
)

println()
println("三次多项式拟合：")
println(
    "最大绝对误差 = ",
    max_fit
)
println(
    "RMSE = ",
    rmse_fit
)


# ============================================================
# 18. 计算绝对误差曲线
# ============================================================

error_lagrange =
    abs.(y_true .- y_lagrange)

error_spline =
    abs.(y_true .- y_spline)

error_fit =
    abs.(y_true .- y_fit)


# ============================================================
# 19. 图1：原函数与三种方法比较
# ============================================================

TyPlot.figure()

# Runge原函数
TyPlot.plot(
    x_plot,
    y_true,
    linewidth=2,
    label="Runge函数"
)

TyPlot.hold("on")

# 拉格朗日插值
TyPlot.plot(
    x_plot,
    y_lagrange,
    linewidth=2,
    label="拉格朗日插值"
)

# 三次样条插值
TyPlot.plot(
    x_plot,
    y_spline,
    linewidth=2,
    label="三次样条插值"
)

# 三次多项式拟合
TyPlot.plot(
    x_plot,
    y_fit,
    linewidth=2,
    label="三次多项式拟合"
)

# 插值节点
TyPlot.plot(
    nodes,
    values,
    "o",
    label="节点"
)

TyPlot.title(
    "Runge函数插值与拟合比较，n=10"
)

TyPlot.xlabel("x")
TyPlot.ylabel("y")

TyPlot.legend()
TyPlot.grid(true)

TyPlot.hold("off")


# ============================================================
# 20. 图2：三种方法的绝对误差
# ============================================================

TyPlot.figure()

TyPlot.plot(
    x_plot,
    error_lagrange,
    linewidth=2,
    label="拉格朗日插值误差"
)

TyPlot.hold("on")

TyPlot.plot(
    x_plot,
    error_spline,
    linewidth=2,
    label="三次样条插值误差"
)

TyPlot.plot(
    x_plot,
    error_fit,
    linewidth=2,
    label="三次拟合误差"
)

TyPlot.title(
    "三种方法绝对误差比较，n=10"
)

TyPlot.xlabel("x")

TyPlot.ylabel(
    "|f(x) - approximation|"
)

TyPlot.legend()
TyPlot.grid(true)

TyPlot.hold("off")