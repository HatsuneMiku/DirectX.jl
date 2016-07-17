# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

import Base
import Relocator
import Relocator: _mf
import WCharUTF8

export connect, close
export initD3DApp, msgLoop

# must load :freetype before :d3dxfreetype2 (or place to current directory)
const _dlls = [:d3d9, :d3dx9, :d3dxconsole, :freetype, :d3dxfreetype2,
  :d3dxglyph, :dx9adl]

const res_default = (512, 512, "_string.png", "res")
const face_default = ("mikaP.ttf",)

type VERTEX_GLYPH # in D3DxGlyph.h
  ppTexture::Ptr{Ptr{Void}} # LPDIRECT3DTEXTURE9 *
  pVtxGlyph::Ptr{Void} # LPDIRECT3DVERTEXBUFFER9
  szGlyph::UInt32 # size_t
end

type GLYPH_TBL # in D3DxFT2_types.h
  pIS::Ptr{Void} # RENDERD3DITEMSSTATE * # in dx9adl.h
  pVG::Ptr{Void} # VERTEX_GLYPH * # in D3DxGlyph.h
  facename::Ptr{Cchar}
  utxt::Ptr{Cwchar_t}
  ratio::Float32
  angle::Float32
  reserved0::UInt32
  reserved1::UInt32
  mode::UInt32
  td::UInt32
  tw::UInt32
  th::UInt32
  rct::Ptr{Void} # CUSTOMRECT * # in D3DxFT2_types.h
  glyphBmp::Ptr{Void} # BOOL (*)(GLYPH_TBL *, FT_Bitmap *, FT_Int, FT_Int)
  matrix::Ptr{Void} # QUOTANIONIC_MATRIX * # in quotanion.h
  vtx::Ptr{Void} # GLYPH_VTX * # in D3DxFT2_types.h
  funcs::Ptr{Void} # FT_Outline_Funcs *
  glyphContours::Ptr{Void} # BOOL (*)(GLYPH_TBL *)
end

vg = VERTEX_GLYPH(C_NULL, C_NULL, 0) # re-set later
gt = GLYPH_TBL(C_NULL, C_NULL, C_NULL, C_NULL, # re-set later
  Float32(6000.), Float32(25.), 0, 0,
  0, 1024, 256, 256, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

type RenderD3DItemsState # in dx9adl.h
  sysChain::Ptr{Void}
  usrChain::Ptr{Void}
  stat::UInt32 # BOOL
  mode::UInt32
  hWnd::UInt32 # HWND
  reserved0::UInt32
  ppDev::Ptr{Ptr{Void}} # LPDIRECT3DDEVICE9 *
  ppSprite::Ptr{Ptr{Void}} # LPD3DXSPRITE *
  parent::Ptr{Void}
  imstring::Ptr{Cchar}
  imw::UInt32
  imh::UInt32
  reserved1::UInt32
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

  function Dx9adl(w::Int, h::Int, bp::AbstractString)
    res = Relocator.searchResDll(bp, res_default[4], true)
    ims = replace(res * "/" * res_default[3], "/", "\\") # only for Windows
    # set mode 0 to skip debugalloc/debugfree
    return new(bp, res, ims, RenderD3DItemsState(C_NULL, C_NULL, 0, 0, 0, 0,
      C_NULL, C_NULL, C_NULL, pointer(ims), 512, 512, 0, 0, 0, 0, w, h))
    # OK pointer(ims) # AbstractString to Cchar
    # OK pointer(ims.data) # Array{UInt8,1} to Cchar
    # BAD pointer_from_objref(ims)
    # BAD pointer_from_objref(ims.data)
    # OK pointer_from_objref(ims.data) + 32 # OK but wrong way
  end
end

function connect(w::Int, h::Int, bp::AbstractString="")
  Relocator._init(_dlls, bp)
# ccall(_mf(:d3dxconsole, :debugalloc), Void, ()) # needless to call on Julia?
  return Dx9adl(w, h, bp)
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
  if ist.ppSprite != C_NULL
    #
  else
    if ist.nowTime - ist.prevTime < 5
      ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8}, UInt32, UInt32,),
        "renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
      t = (75. - 60. * ((ist.nowTime >> 4) % 256) / 256) * pi / 180;
      gt.pIS = pIS
      vg.ppTexture = C_NULL
      ccall(_mf(:dx9adl, :ReleaseNil), UInt8, (Ptr{Ptr{Void}},), &vg.pVtxGlyph)
      vg.szGlyph = 0;
      gt.pVG = pointer_from_objref(vg)
      d9 = unsafe_pointer_to_objref(ist.parent)
      facepath = replace(d9.respath * "/" * face_default[1], "/", "\\")
      if false
        ccall(_mf(:d3dxconsole, :debugout), Void, (Ptr{UInt8}, Ptr{Cchar},),
          "[%s]\n", pointer(facepath.data))
      end
      gt.facename = pointer(facepath.data)
      gt.utxt = pointer(WCharUTF8.UTF8toWCS("3\u30422\u3041\u3045", eos=true))
      gt.ratio = Float32(6000.)
      gt.angle = Float32(25.)
      gt.reserved1 = gt.reserved0 = 0
      gt.mode = ((ist.nowTime >> 12) % 2) != 0 ? 4 : 8
      # gt.mode |= 0x40000000
      gt.td = 32 * (((ist.nowTime >> 4) % 256) + 1) # about 0.8sec
      gt.tw = 256
      gt.th = 256
      gt.rct = C_NULL
      gt.glyphBmp = C_NULL
      gt.matrix = C_NULL
      gt.vtx = C_NULL
      gt.funcs = C_NULL
      gt.glyphContours = _mf(:d3dxglyph, :D3DXGLP_GlyphContours)
      ccall(_mf(:d3dxfreetype2, :D3DXFT2_GlyphOutline), UInt32, (Ptr{Void},),
        pointer_from_objref(gt))
    end
    ccall(_mf(:d3dxglyph, :D3DXGLP_DrawGlyph), UInt32, (Ptr{Void},),
      pointer_from_objref(gt))
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  ccall(_mf(:d3dxconsole, :debugout),
    Void, (Ptr{UInt8}, Ptr{RenderD3DItemsState},),
    "adl_test &d9.istat = %08X\n", &d9.istat)
  hInst = ccall((:GetModuleHandleA, :kernel32), stdcall,
    UInt32, (Ptr{Void},),
    C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  d9.istat.parent = pointer_from_objref(d9)
  return ccall(_mf(:dx9adl, :InitD3DApp),
    Cint, (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8}, Ptr{RenderD3DItemsState},
      Ptr{Void}, Ptr{Void}, Ptr{Void},),
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
