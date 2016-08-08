# -*- coding: utf-8 -*-

# cd ~/.julia/v0.4/DirectX
# julia test/dx9adl_run_demos.jl

include("dx9adl_demo_0002.jl")

println("test demo_0002")
d9 = DirectX.connect(80 * 16, 80 * 9)
Demo_0002.demo_0002(d9)
DirectX.close(d9)
println("ok")
