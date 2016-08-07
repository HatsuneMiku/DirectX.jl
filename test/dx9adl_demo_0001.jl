# -*- coding: utf-8 -*-
# dx9adl_demo_0001

VERSION >= v"0.4.0-dev+6521" && __precompile__()

include("../src/lib_fnc_defs.jl") # macros/functions with import Relocator: _mf

import WCharUTF8
import DirectX: D3DMatrix, D3DMatrixBits, array_to, Q_D3DMatrix, QQMatrix
import DirectX: VERTEX_GLYPH, FT_PosBits, FT_VectorBits, GLYPH_VTX, GLYPH_TBL
import DirectX: D3DVector, D3DVectorBits, D9F_Vecs, D9Foundation
import DirectX: RenderD3DItemsState, Dx9adl
import DirectX: PSO_SPRITE, PSO_STRING

const TXSRC, TXDST, VtxGlp = 0:2
const txs = ["_col_4.png", "_D_00.png", "_D_01.dds", "_D_02.png", "_D_go.png"]
const face_default = ("mikaP.ttf",)

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

function demo_0001(d9)
  initD3DApp(d9)
  return msgLoop(d9)
end
