# -*- coding: utf-8 -*-
# DirectX

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DirectX

include("lib_fnc_defs.jl") # import DLL_Loader with import Relocator: _mf

import Relocator

export connect, close

const PSO_D3D, PSO_DEV, PSO_SPRITE, PSO_FONT, PSO_STRING, PSO_STRVBUF = 0:5
const res_default = (512, 512, "_string.png", "res")

type D3DMatrix # (fake to copy and read only access) in dx9adl.h
  aa::Float32; ba::Float32; ca::Float32; da::Float32
  ab::Float32; bb::Float32; cb::Float32; db::Float32
  ac::Float32; bc::Float32; cc::Float32; dc::Float32
  ad::Float32; bd::Float32; cd::Float32; dd::Float32
end

bitstype (8 * sizeof(D3DMatrix)) D3DMatrixBits # fake real byte size

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
    d9fnd.imw = res_default[1]
    d9fnd.imh = res_default[2]
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

end
