using LinearAlgebra
using TyPlot

# =========================
# 1. Runge函数
# =========================
function f(x)
    return 1.0 / (1.0 + 25.0 * x^2)
end


# =========================
# 2. 取 n = 10
# =========================
n = 10

# 将 [-1,1] 分成10个区间，共11个节点
nodes = collect(range(-1.0, 1.0, length=n + 1))

# 节点函数值
values = [f(x) for x in nodes]


# =========================
# 3. 三次多项式最小二乘拟合
#
# p(x) = a0 + a1*x + a2*x^2 + a3*x^3
# =========================

A = hcat(
    ones(length(nodes)),
    nodes,
    nodes.^2,
    nodes.^3
)

# 最小二乘求解
a = A \ values

a0 = a[1]
a1 = a[2]
a2 = a[3]
a3 = a[4]


# =========================
# 4. 输出拟合系数
# =========================

println("==============================")
println("Runge函数三次曲线拟合")
println("==============================")

println("a0 = ", a0)
println("a1 = ", a1)
println("a2 = ", a2)
println("a3 = ", a3)

println()
println("拟合曲线方程：")

println(
    "p(x) = $(a0) + ($(a1))x + ($(a2))x^2 + ($(a3))x^3"
)


# =========================
# 5. 定义拟合函数
# =========================

function p(x)
    return a0 + a1*x + a2*x^2 + a3*x^3
end


# =========================
# 6. 生成绘图数据
# =========================

x_plot = collect(range(-1.0, 1.0, length=1001))

# Runge原函数
y_true = [f(x) for x in x_plot]

# 拟合函数
y_fit = [p(x) for x in x_plot]


# =========================
# 7. 绘图
# =========================

TyPlot.figure()

# Runge函数
TyPlot.plot(
    x_plot,
    y_true,
    linewidth=2,
    label="Runge函数"
)

TyPlot.hold("on")

# 三次拟合曲线
TyPlot.plot(
    x_plot,
    y_fit,
    linewidth=2,
    label="三次拟合曲线"
)

# n=10的节点
TyPlot.plot(
    nodes,
    values,
    "o",
    label="拟合节点"
)

TyPlot.title("Runge函数三次曲线拟合，n=10")
TyPlot.xlabel("x")
TyPlot.ylabel("y")
TyPlot.legend()
TyPlot.grid(true)

TyPlot.hold("off")