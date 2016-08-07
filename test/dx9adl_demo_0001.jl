# -*- coding: utf-8 -*-
# dx9adl_demo_0001

VERSION >= v"0.4.0-dev+6521" && __precompile__()

import DirectX

function demo_0001(d9)
  DirectX.initD3DApp(d9)
  return DirectX.msgLoop(d9)
end
