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

const PSO_D3D, PSO_DEV, PSO_SPRITE, PSO_FONT, PSO_STRING, PSO_STRVBUF = 0:5
const TXSRC, TXDST, VtxGlp = 0:2
const txs = ["_col_4.png", "_D_00.png", "_D_01.dds", "_D_02.png", "_D_go.png"]

type D3DMatrix # (fake to copy and read only access) in dx9adl.h
  aa::Float32; ba::Float32; ca::Float32; da::Float32
  ab::Float32; bb::Float32; cb::Float32; db::Float32
  ac::Float32; bc::Float32; cc::Float32; dc::Float32
  ad::Float32; bd::Float32; cd::Float32; dd::Float32
end

# bitstype (8 * sizeof(D3DMatrix)) D3DMatrixBits # fake real byte size

D3DMatrix() = D3DMatrix(
  1., 0., 0., 0.,
  0., 1., 0., 0.,
  0., 0., 1., 0.,
  0., 0., 0., 1.)

function array_to(m::D3DMatrix, a::Array{Float32,2}) # 4x4 Array{Float32,2}
  m.aa = a[1, 1]; m.ba = a[2, 1]; m.ca = a[3, 1]; m.da = a[4, 1]
  m.ab = a[1, 2]; m.bb = a[2, 2]; m.cb = a[3, 2]; m.db = a[4, 2]
  m.ac = a[1, 3]; m.bc = a[2, 3]; m.cc = a[3, 3]; m.dc = a[4, 3]
  m.ad = a[1, 4]; m.bd = a[2, 4]; m.cd = a[3, 4]; m.dd = a[4, 4]
  m
end

type Q_D3DMatrix # in dx9adl.h
  tmp::Ptr{Void} # D3DMATRIX *
  world::Ptr{Void} # D3DMATRIX *
  view::Ptr{Void} # D3DMATRIX *
  proj::Ptr{Void} # D3DMATRIX *
end

type QQMatrix # in quaternion.h
  transform::Ptr{Void} # QUATERNIONIC_MATRIX *
  rotation::Ptr{Void} # QUATERNIONIC_MATRIX *
  scale::Ptr{Void} # QUATERNIONIC_MATRIX *
  translate::Ptr{Void} # QUATERNIONIC_MATRIX *
end

type VERTEX_GLYPH # in D3DxGlyph.h
  pQQM::Ptr{Void} # QQMATRIX * # in quaternion.h
  ppTexture::Ptr{Ptr{Void}} # LPDIRECT3DTEXTURE9 *
  ppVtxGlyph::Ptr{Ptr{Void}} # LPDIRECT3DVERTEXBUFFER9 *
  szGlyph::UInt32 # size_t
end

bitstype (8 * 4) FT_PosBits # fake real byte size # signed long
bitstype (8 * 4 * 2) FT_VectorBits # fake real byte size # {FT_Pos x, FT_Pos y}

type GLYPH_VTX # in D3DxFT2_types.h
  contour::Ptr{Void} # GLYPH_CONTOUR * # in D3DxFT2_types.h
  cmx::UInt32
  ctc::UInt32
  buf::Ptr{Void} # CUSTOMCUV * # in D3DxFT2_types.h
  bmx::UInt32
  btc::UInt32
  p::FT_VectorBits
  pz::FT_PosBits
  z::FT_PosBits
  col::UInt32
  bgc::UInt32
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
  matrix::Ptr{Void} # QUATERNIONIC_MATRIX * # in quaternion.h
  vtx::Ptr{Void} # GLYPH_VTX * # in D3DxFT2_types.h
  funcs::Ptr{Void} # FT_Outline_Funcs *
  glyphContours::Ptr{Void} # BOOL (*)(GLYPH_TBL *)
  glyphAlloc::Ptr{Void} # BOOL (*)(GLYPH_TBL *)
  glyphFree::Ptr{Void} # BOOL (*)(GLYPH_TBL *)
end

m_transform = D3DMatrix()
m_rotation = D3DMatrix(
  1.0,         0.,         0.,  0.,
   0.,  1./1.4142,  1./1.4142,  0.,
   0., -1./1.4142,  1./1.4142,  0.,
   0.,         0.,         0., 1.0)
m_scale = D3DMatrix(
  1.5,  0.,  0.,  0.,
   0., 1.5,  0.,  0.,
   0.,  0., 1.5,  0.,
   0.,  0.,  0., 1.0)
m_translate = D3DMatrix(
  1.0,  0.,  0.,  0.,
   0., 1.0,  0.,  0.,
   0.,  0., 1.0,  0.,
  -4., -1., -2., 1.0)
qqm = QQMatrix(C_NULL, C_NULL, C_NULL, C_NULL) # re-set later
vg = VERTEX_GLYPH(C_NULL, C_NULL, C_NULL, 0) # re-set later
gv = GLYPH_VTX(C_NULL, 0, 0, C_NULL, 0, 0, # re-set later
  reinterpret(FT_VectorBits, Int32[0, 0])[],
  reinterpret(FT_PosBits, Int32[0])[], reinterpret(FT_PosBits, Int32[0])[],
  0, 0)
gt = GLYPH_TBL(C_NULL, C_NULL, C_NULL, C_NULL, # re-set later
  Float32(6000.), Float32(25.), 0, 0,
  0, 1024, 256, 256, C_NULL, C_NULL,
  C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)

type D3DVector
  x::Float32; y::Float32; z::Float32
end

bitstype (8 * sizeof(D3DVector)) D3DVectorBits # fake real byte size

type D9F_Vecs # (construction values of matrices) in dx9adl.h
  eyePt::D3DVectorBits
  reserved0::UInt32
  lookatPt::D3DVectorBits
  reserved1::UInt32
  upVec::D3DVectorBits
  reserved2::UInt32
  fovY::Float32; aspect::Float32; zn::Float32; zf::Float32

#  function D9F_Vecs(
#    eyePt::D3DVector, reserved0::UInt32,
#    lookatPt::D3DVector, reserved1::UInt32,
#    upVec::D3DVector, reserved2::UInt32,
#    fovY::Float32, aspect::Float32, zn::Float32, zf::Float32
#  )
  function D9F_Vecs(eyePt, reserved0, lookatPt, reserved1, upVec, reserved2,
    fovY, aspect, zn, zf)
    return new(
      (@as_bits D3DVectorBits eyePt), reserved0,
      (@as_bits D3DVectorBits lookatPt), reserved1,
      (@as_bits D3DVectorBits upVec), reserved2,
      fovY, aspect, zn, zf)
  end
end

type D9Foundation # (fake to copy and read only access) in dx9adl.h
  pD3Dpp::Ptr{Ptr{Void}} # D3DPRESENT_PARAMETERS *
  pD3D::Ptr{Void} # LPDIRECT3D9
  pDev::Ptr{Void} # LPDIRECT3DDEVICE9
  pMenv::Ptr{Void} # Q_D3DMATRIX * # in dx9adl.h
  pVecs::Ptr{Void} # D9F_VECS * # in dx9adl.h
  imstring::Ptr{Cchar}
  imw::UInt32
  imh::UInt32

  function D9Foundation()
    return new()
  end
end

type RenderD3DItemsState # in dx9adl.h
  parent::Ptr{Void}
  d9fnd::Ptr{D9Foundation}
  sysChain::Ptr{Ptr{Void}}
  usrChain::Ptr{Ptr{Void}}
  smx::UInt32
  umx::UInt32
  width::UInt32
  height::UInt32
  bgc::UInt32
  fgc::UInt32
  mode::UInt32
  stat::UInt32
  hWnd::UInt32 # HWND
  fps::UInt32
  prevTime::UInt32
  nowTime::UInt32
end

m_tmp = D3DMatrix()
m_world = D3DMatrix()
m_view = D3DMatrix()
m_proj = D3DMatrix()
menv = Q_D3DMatrix(C_NULL, C_NULL, C_NULL, C_NULL) # re-set later
vecs = D9F_Vecs(
  D3DVector(5., 5., -5.), 0,
  D3DVector(0., 0., 0.), 0,
  D3DVector(0., 1., 0.), 0,
  3./4., 1., 1., 100.)
d9fnd = D9Foundation() # holder (must be out of struct Dx9adl ?)
istat = RenderD3DItemsState(C_NULL, C_NULL, C_NULL, C_NULL, # re-set later
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

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
    # BAD @ptr ims
    # BAD @ptr ims.data
    # OK (@ptr ims.data) + 32 # OK but wrong way
    d9fnd.imstring = pointer(ims)
    d9fnd.imw = 512
    d9fnd.imh = 512
    menv.tmp = @ptr m_tmp
    menv.world = @ptr m_world
    menv.view = @ptr m_view
    menv.proj = @ptr m_proj
    d9fnd.pMenv = @ptr menv
    d9fnd.pVecs = @ptr vecs
    istat.d9fnd = @ptr d9fnd # or set C_NULL
    istat.width = w
    istat.height = h
    istat.fgc = 0x80EE66CC
    istat.bgc = 0xFFFF80FF
    istat.mode = 0x0CC00000
    # set mode 0 to skip debugalloc/debugfree
    d = new(bp, res, ims, d9fnd, istat) # set parent later
    d.istat.parent = @ptr d
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
  ist = @juliaobj pIS
  debugout("initD3DItems: %08X\n", ist.stat)
  d9f = @juliaobj ist.d9fnd # expect Julia structure
  d9 = @juliaobj ist.parent # expect Julia structure
  imp = replace(d9.respath * "/" * txs[1], "/", "\\") # only for Windows
  D3DXCreateTextureFromFileA(d9f.pDev, pointer(imp.data), PtrPtrU(pIS, TXSRC))
  D3DXTXB_CreateTexture(d9f.pDev, 256, 256, PtrPtrU(pIS, TXDST))
  debugout("pTexSrc: %08X\n", PtrUO(pIS, TXSRC))
  debugout("pTex: %08X\n", PtrUO(pIS, TXDST))
  if PtrUO(pIS, TXSRC) == C_NULL
    debugout("not found ? [%s]\n", pointer(imp.data))
    return 0::Cint
  end
  return 1::Cint
end

function cleanupD3DItems(pIS::Ptr{RenderD3DItemsState})
  ist = @juliaobj pIS
  debugout("cleanupD3DItems: %08X\n", ist.stat)
  # ReleaseNil(@ptr vg.pVtxGlyph) # *BAD*
  # ReleaseNil((@ptr vg) + 2 * sizeof(Ptr{Void})) # obsoleted another pointer
  # ReleaseNil(vg.ppVtxGlyph) # needless
  debugout("pTex: %08X\n", PtrUO(pIS, TXDST))
  debugout("pTexSrc: %08X\n", PtrUO(pIS, TXSRC))
  return 1::Cint
end

function renderD3DItems(pIS::Ptr{RenderD3DItemsState})
  # ist = pIS[1] # MethodError: `getindex` has no method matching
                 #  getindex(::Ptr{DirectX.RenderD3DItemsState}, ::Int32)
  # ist = unsafe_load(pIS, 1) # ok but curious
  ist = @juliaobj pIS # good
  if ist.stat & 0x00000001 != 0 # non Julia structure
    d9f = D9Foundation() # (fake to copy and read only access)
    memcpy((@ptr d9f), ist.d9fnd, sizeof(d9f))
  else # Julia structure
    d9f = @juliaobj ist.d9fnd # *BAD* for non Julia structure
  end
  if ist.stat & 0x00008000 != 0
    # println("type: ", typeof(d9f))
    # println("size: ", sizeof(d9f))
    # debugout("ppSprite[%08X]\n", PtrPtrS(pIS, PSO_SPRITE))
    pSprite = PtrSO(pIS, PSO_SPRITE)
    # debugout("pSprite[%08X]\n", pSprite)
    D3DXTXB_RewriteTexture(PtrPtrU(pIS, TXDST), PtrPtrU(pIS, TXSRC))
    BltTexture(pIS, 0xFFFFFFFF, PtrPtrU(pIS, TXDST), 0, 0, 256, 256,
      0., 0., 0., 10., 100., 1.)
    # ppTexture = @ptr d9f.pString # ok but obsoleted
    # ppTexture = @ptr PtrSO(pIS, PSO_STRING) # ok but another pointer
    BltTexture(pIS, 0xFFFFFFFF, PtrPtrS(pIS, PSO_STRING), 0, 0, 512, 512,
      0., 0., 0., 10., 10., .5)
    BltString(pIS, 0xFF808080, "BLTSTRING", 2, 192, 32, 0.1)
  else
    menv = @juliaobj d9f.pMenv # expect Julia structure
    D3DXMatrixRotationY(menv.world, ist.nowTime * 0.06 * pi / 180)
    SetupMatrices(pIS)
    DrawAxis(pIS)
    if ist.nowTime - ist.prevTime <= 1000
      if ist.nowTime - ist.prevTime <= 5
        debugout("renderD3DItems %02d %08X\n", ist.fps, ist.nowTime)
      end
      t = (75. - 60. * ((ist.nowTime >> 4) % 256) / 256) * pi / 180;
      gt.pIS = pIS
      qqm.transform = @ptr m_transform
      qqm.rotation = @ptr m_rotation
      qqm.scale = @ptr m_scale
      qqm.translate = @ptr m_translate
      vg.pQQM = @ptr qqm
      vg.ppTexture = PtrPtrU(pIS, TXDST)
      vg.ppVtxGlyph = PtrPtrU(pIS, VtxGlp)
      ReleaseNil(vg.ppVtxGlyph)
      vg.szGlyph = 0;
      gt.pVG = @ptr vg
      d9 = @juliaobj ist.parent
      facepath = replace(d9.respath * "/" * face_default[1], "/", "\\")
      # debugout("[%s]\n", pointer(facepath.data))
      gt.facename = pointer(facepath.data)
      nt = ist.nowTime & 0x0000FFFF
      u8 = @sprintf "%02d%c%04X%s" ist.fps 'ぁ' nt "\u3047\u3046" # UTF-8
      gt.utxt = pointer(WCharUTF8.UTF8toWCS(u8, eos=true))
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
      m_rotation.cc = m_rotation.bb = cos(t)
      m_rotation.bc = - (m_rotation.cb = sin(t))
      @q3m m_transform m_rotation m_scale m_translate
      gt.matrix = qqm.transform
      gv.col = ist.fgc
      gv.bgc = ist.bgc
      gt.vtx = @ptr gv
      gt.funcs = C_NULL
      gt.glyphContours = _mf(:d3dxglyph, :D3DXGLP_GlyphContours)
      gt.glyphAlloc = _mf(:d3dxfreetype2, :D3DXFT2_GlyphAlloc)
      gt.glyphFree = _mf(:d3dxfreetype2, :D3DXFT2_GlyphFree)
      D3DXFT2_GlyphOutline(@ptr gt)
    end
    D3DXGLP_DrawGlyph(@ptr gt)
    DrawString(pIS, ist.fgc, "DRAWSTRING", 2, 0.5, 0.5, 0.1, -3., 1., -2.)
  end
  return 1::Cint
end

function initD3DApp(d9::Dx9adl)
  debugout("adl_test &d9.istat = %08X\n", @ptr d9.istat)
  hInst = GetModuleHandleA(C_NULL)
  nShow = 1 # 1: SW_SHOWNORMAL or 5: SW_SHOW
  className = "juliaClsDx9ADLtest"
  appName = "juliaAppDx9ADLtest"
  return InitD3DApp(
    hInst, nShow, className, appName, (@ptr d9.istat),
    cfunction(initD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(cleanupD3DItems, Cint, (Ptr{RenderD3DItemsState},)),
    cfunction(renderD3DItems, Cint, (Ptr{RenderD3DItemsState},)))
end

function msgLoop(d9::Dx9adl)
  r = -1
  debugout("in\n")
  try
    r = MsgLoop(@ptr d9.istat)
  catch err
    debugout("err\n")
    println(err)
  finally
    debugout("out\n")
  end
  return r
end

end
