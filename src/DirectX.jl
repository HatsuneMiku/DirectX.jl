# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

include("lib_fnc_defs.jl") # import DLL_Loader with import Relocator: _mf

import Relocator
import WCharUTF8

export connect, close
export initD3DApp, msgLoop

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

type D3DMatrix # (fake to copy and read only access) in dx9adl.h
  aa::Float32; ba::Float32; ca::Float32; da::Float32
  ab::Float32; bb::Float32; cb::Float32; db::Float32
  ac::Float32; bc::Float32; cc::Float32; dc::Float32
  ad::Float32; bd::Float32; cd::Float32; dd::Float32

  function D3DMatrix()
    return new()
  end
end

bitstype (8 * sizeof(D3DMatrix)) D3DMatrixBits

type D9Foundation # (fake to copy and read only access) in dx9adl.h
  pD3Dpp::Ptr{Ptr{Void}} # D3DPRESENT_PARAMETERS *
  pD3D::Ptr{Void} # LPDIRECT3D9
  pDev::Ptr{Void} # LPDIRECT3DDEVICE9
  pSprite::Ptr{Void} # LPD3DXSPRITE
  pFont::Ptr{Void} # LPD3DXFONT
  pString::Ptr{Void} # LPDIRECT3DTEXTURE9
  pStringVBuf::Ptr{Void} # LPDIRECT3DVERTEXBUFFER9
  reserved0::Ptr{Void} # VOID *
  matTmp::D3DMatrixBits # fake real byte size of D3DMatrix
  matWorld::D3DMatrixBits # fake real byte size of D3DMatrix
  matView::D3DMatrixBits # fake real byte size of D3DMatrix
  matProj::D3DMatrixBits # fake real byte size of D3DMatrix
  reserved1::Ptr{Void} # VOID *
  imstring::Ptr{Cchar}
  imw::UInt32
  imh::UInt32

  function D9Foundation()
    return new()
  end
end

type RenderD3DItemsState # in dx9adl.h
  sysChain::Ptr{Void}
  usrChain::Ptr{Void}
  stat::UInt32
  mode::UInt32
  hWnd::UInt32 # HWND
  reserved0::UInt32
  d9fnd::Ptr{D9Foundation}
  parent::Ptr{Void}
  reserved1::UInt32
  fps::UInt32
  prevTime::UInt32
  nowTime::UInt32
  width::UInt32
  height::UInt32
end

d9fnd = D9Foundation() # holder (must be out of struct Dx9adl ?)
istat = RenderD3DItemsState(C_NULL, C_NULL, 0, 0, 0, 0, # re-set later
  C_NULL, C_NULL, 0, 0, 0, 0, 0, 0)

type Dx9adl
  basepath::AbstractString # base path
  respath::AbstractString # resource path
  ims::AbstractString # to hold the pointer placing dynamic char[] (anti GC)
  d9fnd::D9Foundation # reference
  istat::RenderD3DItemsState # reference

  function Dx9adl(w::Int, h::Int, bp::AbstractString)
    res = Relocator.searchResDll(bp, res_default[4], true)
    ims = replace(res * "/" * res_default[3], "/", "\\") # only for Windows
    # OK pointer(ims) # AbstractString to Cchar
    # OK pointer(ims.data) # Array{UInt8,1} to Cchar
    # BAD pointer_from_objref(ims)
    # BAD pointer_from_objref(ims.data)
    # OK pointer_from_objref(ims.data) + 32 # OK but wrong way
    d9fnd.imstring = pointer(ims)
    d9fnd.imw = 512
    d9fnd.imh = 512
    istat.d9fnd = pointer_from_objref(d9fnd) # or set C_NULL
    istat.width = w
    istat.height = h
    # set mode 0 to skip debugalloc/debugfree
    d = new(bp, res, ims, d9fnd, istat) # set parent later
    d.istat.parent = pointer_from_objref(d)
    return d
  end
end

function connect(w::Int, h::Int, bp::AbstractString="")
  DLL_Loader.load(bp)
# debugalloc() # needless to call on Julia console ?
  return Dx9adl(w, h, bp)
end

function close(d9::Dx9adl)
# debugfree() # can not call on Julia console ?
  DLL_Loader.unload()
  return true
end

function initD3DItems(pIS::Ptr{RenderD3DItemsState})
  debugout("initD3DItems\n")
  return 1::Cint
end

function cleanupD3DItems(pIS::Ptr{RenderD3DItemsState})
  debugout("cleanupD3DItems\n")
  return 1::Cint
end

function renderD3DItems(pIS::Ptr{RenderD3DItemsState})
  # ist = pIS[1] # MethodError: `getindex` has no method matching
                 #  getindex(::Ptr{DirectX.RenderD3DItemsState}, ::Int32)
  # ist = unsafe_load(pIS, 1) # ok but curious
  ist = unsafe_pointer_to_objref(pIS) # good
  if ist.stat & 0x00008000 != 0
    if ist.stat & 0x00000001 != 0 # non Julia structure
      d9f = D9Foundation() # (fake to copy and read only access)
      memcpy(pointer_from_objref(d9f), ist.d9fnd, sizeof(d9f))
    else # Julia structure
      d9f = unsafe_pointer_to_objref(ist.d9fnd) # *BAD* for non Julia structure
    end
    # println("type: ", typeof(d9f))
    # println("size: ", sizeof(d9f))
    # debugout("OK0[%08X]\n", d9f.pSprite)
    pSprite = d9f.pSprite
    # debugout("OK1[%08X]\n", pSprite)
    ppTexture = pointer_from_objref(d9f.pString)
    BltTexture(pIS, 0xFFFFFFFF, ppTexture, 0, 0, 512, 512,
      0., 0., 0., 10., 10., 1.)
    BltString(pIS, 0xFF808080, "BLTSTRING", 2, 192, 32, 0.1)
  else
    if ist.nowTime - ist.prevTime < 5
      debugout("renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
      t = (75. - 60. * ((ist.nowTime >> 4) % 256) / 256) * pi / 180;
      gt.pIS = pIS
      vg.ppTexture = C_NULL
      ReleaseNil(pointer_from_objref(vg.pVtxGlyph))
      vg.szGlyph = 0;
      gt.pVG = pointer_from_objref(vg)
      d9 = unsafe_pointer_to_objref(ist.parent)
      facepath = replace(d9.respath * "/" * face_default[1], "/", "\\")
      # debugout("[%s]\n", pointer(facepath.data))
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
      D3DXFT2_GlyphOutline(pointer_from_objref(gt))
    end
    D3DXGLP_DrawGlyph(pointer_from_objref(gt))
    DrawString(pIS, 0xFFFFFFFF, "DRAWSTRING", 3, 0.5, 0.5, 0.1, -3., 1., -2.)
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  debugout("adl_test &d9.istat = %08X\n", pointer_from_objref(d9.istat))
  hInst = GetModuleHandleA(C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  return InitD3DApp(
    hInst, nShow, className, appName, pointer_from_objref(d9.istat),
    cfunction(initD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(cleanupD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(renderD3DItems, Cint, (Ptr{RenderD3DItemsState},)))
end

function msgLoop(d9::Dx9adl)
  r = -1
  debugout("in\n")
  try
    r = MsgLoop(pointer_from_objref(d9.istat))
  catch err
    debugout("err\n")
    println(err)
  finally
    debugout("out\n")
  end
  return r
end

end
