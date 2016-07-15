# -*- coding: utf-8 -*-

# cd ~/.julia/v0.4/DirectX
# julia test/dx9adl_process.jl

import DirectX

println("test dx9adl with relocated dlls")
d9 = DirectX.connect(55 * 16, 55 * 9, "/private/dx9")
DirectX.initD3DApp(d9)
println(DirectX.msgLoop(d9))
DirectX.close(d9)
println("ok")
