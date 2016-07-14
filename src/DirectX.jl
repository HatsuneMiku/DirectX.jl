# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

import Base
import Relocator
import Relocator: _mf

export connect, close
export initD3DApp, msgLoop

# must load :freetype before :d3dxfreetype2 (or place to current directory)
const _dlls = [:d3d9, :d3dx9, :d3dxconsole, :freetype, :d3dxfreetype2, :dx9adl]

const WIDTH = 880
const HEIGHT = 495

const res_default = (512, 512, "_string.png", "res")

type RenderD3DItemsState
  stat::UInt32
  mode::UInt32
  hWnd::UInt32
  ppSprite::Ptr{Ptr{Void}} # LPD3DXSPRITE *
  imstring::Ptr{Cchar}
  imw::UInt32
  imh::UInt32
  fps::UInt32
  prevTime::UInt32
  nowTime::UInt32
  width::UInt32
  height::UInt32
end

type Dx9adl
  basepath::AbstractString # base path
  respath::AbstractString # resource path
  ims::AbstractString # to hold the pointer placing dynamic char[] (anti GC)
  istat::RenderD3DItemsState

  function Dx9adl(bp::AbstractString)
    resdll = Relocator.searchResDll(bp, res_default[4], true)
    ims = replace(resdll * "/" * res_default[3], "/", "\\") # only for Windows
    # set mode 0 to skip debugalloc/debugfree
    return new(bp, resdll, ims, RenderD3DItemsState(0, 0, 0, C_NULL,
      pointer(ims), 512, 512, 0, 0, 0, WIDTH, HEIGHT))
    # OK pointer(ims) # AbstractString to Cchar
    # OK pointer(ims.data) # Array{UInt8,1} to Cchar
    # BAD pointer_from_objref(ims)
    # BAD pointer_from_objref(ims.data)
    # OK pointer_from_objref(ims.data) + 32 # OK but wrong way
  end
end

function connect(bp::AbstractString="")
  Relocator._init(_dlls, bp)
# ccall(_mf(:d3dxconsole, :debugalloc), Void, ()) # needless to call on Julia?
  return Dx9adl(bp)
end

function close(d9::Dx9adl)
# ccall(_mf(:d3dxconsole, :debugfree), Void, ()) # can not call on Julia cons?
  Relocator._close()
  return true
end

function initD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "initD3DItems\n")
  return 1::Cint
end

function cleanupD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "cleanupD3DItems\n")
  return 1::Cint
end

function renderD3DItems(pIS::Ptr{RenderD3DItemsState})
  # ist = pIS[1] # MethodError: `getindex` has no method matching
                 #  getindex(::Ptr{DirectX.RenderD3DItemsState}, ::Int32)
  # ist = unsafe_load(pIS, 1) # ok but curious
  ist = unsafe_pointer_to_objref(pIS) # good
  if ist.nowTime - ist.prevTime < 5
    ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8}, UInt32, UInt32),
      "renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  ccall(_mf(:d3dxconsole, :debugout),
    Void, (Ptr{UInt8}, Ptr{RenderD3DItemsState}),
    "adl_test &d9.istat = %08X\n", &d9.istat)
  hInst = ccall((:GetModuleHandleA, :kernel32), stdcall,
    UInt32, (Ptr{Void},),
    C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  return ccall(_mf(:dx9adl, :InitD3DApp),
    Cint, (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8}, Ptr{RenderD3DItemsState},
      Ptr{Void}, Ptr{Void}, Ptr{Void}),
    hInst, nShow, className, appName, &d9.istat,
    cfunction(initD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(cleanupD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(renderD3DItems, Cint, (Ptr{RenderD3DItemsState},)))
end

function msgLoop(d9::Dx9adl)
  r = -1
  ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "in\n")
  try
    r = ccall(_mf(:dx9adl, :MsgLoop),
      Cint, (Ptr{RenderD3DItemsState},),
      &d9.istat)
  catch err
    ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "err\n")
    println(err)
  finally
    ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "out\n")
  end
  return r
end

end
