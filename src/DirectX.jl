# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

import Base

export connect, close
export initD3DApp, msgLoop

const WIDTH = 880
const HEIGHT = 495

immutable Rel
  sym::Array{Symbol,1}
  dct::Dict{Symbol, Ptr{Void}}

  function Rel(a::Array{Symbol,1}, d=Dict{Symbol, Ptr{Void}}())
    r = new(a, d)
    # finalizer(r, _close) # type must not be immutable / only called by gc() ?
    return r
  end
end

function _init(r::Rel, resdll::AbstractString)
  if isempty(r.dct)
    for s in r.sym
      r.dct[s] = Base.Libdl.dlopen_e(symbol(resdll, "/dll/", string(s)))
      if r.dct[s] == C_NULL
        throw(ArgumentError("not found module ':$(s)'"))
      end
    end
  end
end

function _close(r::Rel)
  for s in keys(r.dct)
    Base.Libdl.dlclose(pop!(r.dct, s))
  end
end

# must load :freetype before :d3dxfreetype2 (or place to current directory)
const _rel = Rel([
  :d3d9, :d3dx9, :d3dxconsole, :freetype, :d3dxfreetype2, :dx9adl])

# without parameter _rel
function relp(md::Symbol, fn::Symbol)
  c = Base.Libdl.dlsym_e(_rel.dct[md], fn)
  if c == C_NULL
    throw(ArgumentError("not found function '$(fn)' in ':$(md)'"))
  end
  return c
end

type RenderD3DItemsState
  stat::UInt32
  mode::UInt32
  hWnd::UInt32
  ppSprite::Ptr{Ptr{Void}} # LPD3DXSPRITE *
  reserved::UInt32
  fps::UInt32
  prevTime::UInt32
  nowTime::UInt32
  width::UInt32
  height::UInt32
end

type Dx9adl
  istat::RenderD3DItemsState

  function Dx9adl()
    # set mode 0 to skip debugalloc/debugfree
    return new(RenderD3DItemsState(0, 0, 0, C_NULL, 0, 0, 0, 0, WIDTH, HEIGHT))
  end
end

function connect(resdll::AbstractString=".")
  _init(_rel, resdll)
# ccall(relp(:d3dxconsole, :debugalloc), Void, ()) # needless to call on Julia?
  return Dx9adl()
end

function close(d9::Dx9adl)
# ccall(relp(:d3dxconsole, :debugfree), Void, ()) # can not call on Julia cons?
  _close(_rel)
  return true
end

function initD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "initD3DItems\n")
  return 1::Cint
end

function cleanupD3DItems(pIS::Ptr{RenderD3DItemsState})
  ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "cleanupD3DItems\n")
  return 1::Cint
end

function renderD3DItems(pIS::Ptr{RenderD3DItemsState})
  # ist = pIS[1] # MethodError: `getindex` has no method matching
                 #  getindex(::Ptr{DirectX.RenderD3DItemsState}, ::Int32)
  # ist = unsafe_load(pIS, 1) # ok but curious
  ist = unsafe_pointer_to_objref(pIS) # good
  if ist.nowTime - ist.prevTime < 5
    ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8}, UInt32, UInt32),
      "renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  ccall(relp(:d3dxconsole, :debugout),
    Void, (Ptr{UInt8}, Ptr{RenderD3DItemsState}),
    "adl_test &d9.istat = %08X\n", &d9.istat)
  hInst = ccall((:GetModuleHandleA, :kernel32), stdcall,
    UInt32, (Ptr{Void},),
    C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  return ccall(relp(:dx9adl, :InitD3DApp),
    Cint, (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8}, Ptr{RenderD3DItemsState},
      Ptr{Void}, Ptr{Void}, Ptr{Void}),
    hInst, nShow, className, appName, &d9.istat,
    cfunction(initD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(cleanupD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(renderD3DItems, Cint, (Ptr{RenderD3DItemsState},)))
end

function msgLoop(d9::Dx9adl)
  r = -1
  ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "in\n")
  try
    r = ccall(relp(:dx9adl, :MsgLoop),
      Cint, (Ptr{RenderD3DItemsState},),
      &d9.istat)
  catch err
    ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "err\n")
    println(err)
  finally
    ccall(relp(:d3dxconsole, :debugout), Void, (Ptr{UInt8},), "out\n")
  end
  return r
end

end
