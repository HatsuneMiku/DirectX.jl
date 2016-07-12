# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

export connect, close
export initD3DApp, msgLoop

const D3D9 = :d3d9
const D3DX9 = :d3dx9
const D3DxConsole = :d3dxconsole
const D3DxFreeType2 = :d3dxfreetype2
const Dx9ADL = :dx9adl

type RenderD3DItemsState
  stat::UInt32
  hWnd::UInt32
  ppSprite::Ptr{Ptr{Void}} # LPD3DXSPRITE *
  fps::UInt32
  prevTime::UInt32
  nowTime::UInt32
  width::UInt32
  height::UInt32
end

type Dx9adl
  istat::RenderD3DItemsState

  function Dx9adl()
    return new(RenderD3DItemsState(0, 0, C_NULL, 0, 0, 0, 352, 198))
  end
end

function connect()
  ccall((:debugalloc, D3DxConsole), Void, ()) # needless to call on Julia cons?
  return Dx9adl()
end

function close(d9::Dx9adl)
  ccall((:debugfree, D3DxConsole), Void, ()) # can not call on Julia cons?
  return true
end

function initD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8},), "initD3DItems\n")
  return 1::Cint
end

function cleanupD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8},), "cleanupD3DItems\n")
  return 1::Cint
end

function renderD3DItems(pIS::Ptr{RenderD3DItemsState})
  # ist = pIS[1] # MethodError: `getindex` has no method matching
                 #  getindex(::Ptr{DirectX.RenderD3DItemsState}, ::Int32)
  # ist = unsafe_load(pIS, 1) # ok but curious
  ist = unsafe_pointer_to_objref(pIS) # good
  if ist.nowTime - ist.prevTime < 5
    ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8}, UInt32, UInt32),
      "renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8}, Ptr{RenderD3DItemsState}),
    "adl_test &d9.istat = %08X\n", &d9.istat)
  # dummy hInstance - must create new hInstance ?
  hInst = ccall((:GetModuleHandleA, :kernel32), stdcall,
    UInt32, (Ptr{Void},),
    C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  return ccall((:InitD3DApp, Dx9ADL),
    Cint, (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8}, Ptr{RenderD3DItemsState},
      Ptr{Void}, Ptr{Void}, Ptr{Void}),
    hInst, nShow, className, appName, &d9.istat,
    cfunction(initD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(cleanupD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(renderD3DItems, Cint, (Ptr{RenderD3DItemsState},)))
end

function msgLoop(d9::Dx9adl)
  ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8},), "in\n")
  try # It will quit the process ? must create new hInstance in initD3DApp ?
    r = ccall((:MsgLoop, Dx9ADL),
      Cint, (Ptr{RenderD3DItemsState},),
      &d9.istat)
  catch err
    ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8},), "err\n") # not caught
    println(err)
  finally
    ccall((:debugout, D3DxConsole), Void, (Ptr{UInt8},), "out\n") # not reach
  end
  return r
end

end
