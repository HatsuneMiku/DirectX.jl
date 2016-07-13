# -*- coding: utf-8 -*-

# cd ~/.julia/v0.4/DirectX
# julia test/dx9adl_process.jl

import DirectX

println("test dx9adl with relocated dlls")
d9 = DirectX.connect()
DirectX.initD3DApp(d9)
println(DirectX.msgLoop(d9))
DirectX.close(d9)
println("ok")
