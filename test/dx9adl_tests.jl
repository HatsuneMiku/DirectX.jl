# -*- coding: utf-8 -*-

include("dx9adl_demo_0001.jl")

println("Testing DirectX")
d9 = DirectX.connect(64 * 16, 64 * 9)
@test d9 != nothing
@test 0 == Demo_0001.demo_0001(d9)
@test DirectX.close(d9)
# @test ture != false
@test false != true
println("ok")
