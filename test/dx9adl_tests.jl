# -*- coding: utf-8 -*-

import DirectX

println("Testing DirectX")
d9 = DirectX.connect(64 * 16, 64 * 9)
@test d9 != nothing
DirectX.initD3DApp(d9)
@test 0 == DirectX.msgLoop(d9)
@test DirectX.close(d9)
# @test ture != false
@test false != true
println("ok")
