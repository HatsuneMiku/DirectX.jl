# -*- coding: utf-8 -*-

# cd ~/.julia/v0.4/DirectX
# julia test/dx9adl_process.jl

include("dx9adl_demo_0001.jl")

println("test dx9adl with relocated dlls")
d9 = DirectX.connect(55 * 16, 55 * 9, "/private/dx9")
println(demo_0001(d9))
DirectX.close(d9)
println("ok")
