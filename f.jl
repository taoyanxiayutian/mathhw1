using LinearAlgebra
using TyPlot

# =========================
# 1. Runge函数
# =========================
function f(x)
    return 1.0 / (1.0 + 25.0 * x^2)
end


# =========================
# 2. 生成等距插值节点
# =========================
function interpolation_nodes(n)
    return collect(range(-1.0, 1.0, length=n + 1))
end


# =========================
# 3. 拉格朗日多项式插值
# =========================
function lagrange_interpolation(x, nodes, values)
    N = length(nodes)
    result = 0.0

    for i in 1:N
        Li = 1.0

        for j in 1:N
            if i != j
                Li *= (x - nodes[j]) / (nodes[i] - nodes[j])
            end
        end

        result += values[i] * Li
    end

    return result
end


# =========================
# 4. 求自然三次样条的二阶导数
# =========================
function cubic_spline(nodes, values)

    n = length(nodes) - 1

    h = [
        nodes[i + 1] - nodes[i]
        for i in 1:n
    ]

    # 构造线性方程组 A*M=b
    A = zeros(n + 1, n + 1)
    b = zeros(n + 1)

    # 自然边界条件
    # M_0 = 0, M_n = 0
    A[1, 1] = 1.0
    A[n + 1, n + 1] = 1.0

    # 内部节点
    for i in 2:n

        A[i, i - 1] = h[i - 1]

        A[i, i] = 2.0 * (
            h[i - 1] + h[i]
        )

        A[i, i + 1] = h[i]

        b[i] = 6.0 * (
            (values[i + 1] - values[i]) / h[i]
            -
            (values[i] - values[i - 1]) / h[i - 1]
        )
    end

    # 求解二阶导数 M
    M = A \ b

    return M
end


# =========================
# 5. 计算三次样条插值
# =========================
function spline_interpolation(x, nodes, values, M)

    n = length(nodes) - 1

    # 判断是否在插值区间内
    if x < nodes[1] || x > nodes[end]
        error("x is outside interpolation interval")
    end

    # 找到x所在区间
    i = searchsortedlast(nodes, x)

    if i == length(nodes)
        i -= 1
    end

    h = nodes[i + 1] - nodes[i]

    term1 =
        M[i] * (nodes[i + 1] - x)^3 / (6.0 * h)

    term2 =
        M[i + 1] * (x - nodes[i])^3 / (6.0 * h)

    term3 =
        (values[i] / h - M[i] * h / 6.0) *
        (nodes[i + 1] - x)

    term4 =
        (values[i + 1] / h - M[i + 1] * h / 6.0) *
        (x - nodes[i])

    return term1 + term2 + term3 + term4
end


# =========================
# 6. 计算最大绝对误差
# =========================
function max_error(x, y_true, y_approx)

    return maximum(
        abs.(y_true .- y_approx)
    )

end


# =========================
# 7. 主实验
# =========================

# 绘图使用较密的测试点
x_plot = collect(
    range(-1.0, 1.0, length=1001)
)

y_true = [
    f(x)
    for x in x_plot
]


for n in [10, 20]

    println()
    println("==============================")
    println("n = ", n)
    println("==============================")

    # 生成插值节点
    nodes = interpolation_nodes(n)

    # 节点函数值
    values = [
        f(x)
        for x in nodes
    ]

    # -------------------------
    # 拉格朗日插值
    # -------------------------
    y_lagrange = [
        lagrange_interpolation(
            x,
            nodes,
            values
        )
        for x in x_plot
    ]

    # -------------------------
    # 三次样条插值
    # -------------------------
    M = cubic_spline(
        nodes,
        values
    )

    y_spline = [
        spline_interpolation(
            x,
            nodes,
            values,
            M
        )
        for x in x_plot
    ]

    # -------------------------
    # 最大误差
    # -------------------------
    error_lagrange = max_error(
        x_plot,
        y_true,
        y_lagrange
    )

    error_spline = max_error(
        x_plot,
        y_true,
        y_spline
    )

    println(
        "拉格朗日插值最大绝对误差 = ",
        error_lagrange
    )

    println(
        "三次样条插值最大绝对误差 = ",
        error_spline
    )
    # =========================
# 绘制图像
# =========================
TyPlot.figure()

TyPlot.plot(
    x_plot,
    y_true,
    label="Runge函数 f(x)",
    linewidth=2
)

# 保留已有曲线
TyPlot.hold("on") 

TyPlot.plot(
    x_plot,
    y_lagrange,
    label="拉格朗日插值",
    linewidth=2
)

TyPlot.plot(
    x_plot,
    y_spline,
    label="三次样条插值",
    linewidth=2
)

TyPlot.plot(
    nodes,
    values,
    "o",
    label="插值节点"
)

TyPlot.title("Runge函数插值比较，n = $(n)")
TyPlot.xlabel("x")
TyPlot.ylabel("y")
TyPlot.legend()
TyPlot.grid(true)

end