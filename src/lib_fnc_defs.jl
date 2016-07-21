# -*- coding: utf-8 -*-
# lib_fnc_defs

VERSION >= v"0.4.0-dev+6521" && __precompile__()
module DLL_Loader

import Relocator

export load, unload

# must load :freetype before :d3dxfreetype2 (or place to current directory)
const _dlls = [:d3d9, :d3dx9, :d3dxconsole, :freetype, :d3dxfreetype2,
  :d3dxglyph, :dx9adl]

function load(bp::AbstractString="")
  Relocator._init(_dlls, bp)
end

function unload()
  Relocator._close()
end

end

import Relocator: _mf, @mf, @cf, @wf

@wf kernel32 UInt32 GetModuleHandleA (Ptr{Void},)

@cf Ptr{Void} memcpy (Ptr{Void}, Ptr{Void}, UInt32,)

@mf d3dxconsole Void debugalloc ()
@mf d3dxconsole Void debugout (Ptr{UInt8},)
@mf d3dxconsole Void debugout (Ptr{UInt8}, UInt32,)
@mf d3dxconsole Void debugout (Ptr{UInt8}, UInt32, UInt32,)
@mf d3dxconsole Void debugfree ()

@mf d3dxfreetype2 UInt32 D3DXFT2_GlyphOutline (Ptr{Void},) # GLYPH_TBL

@mf d3dxglyph UInt32 D3DXGLP_GlyphContours (Ptr{Void},) # GLYPH_TBL
@mf d3dxglyph UInt32 D3DXGLP_DrawGlyph (Ptr{Void},) # GLYPH_TBL

@mf dx9adl UInt32 ReleaseNil (Ptr{Ptr{Void}},)
@mf dx9adl UInt32 DrawString (Ptr{Void}, # RenderD3DItemsState
                    UInt32, Ptr{Cchar}, UInt32,
                    Float32, Float32, Float32, Float32, Float32, Float32,)
@mf dx9adl UInt32 BltString (Ptr{Void}, # RenderD3DItemsState
                    UInt32, Ptr{Cchar}, UInt32, UInt32, UInt32, Float32,)
@mf dx9adl UInt32 BltTexture (Ptr{Void}, # RenderD3DItemsState
                    UInt32, Ptr{Ptr{Void}}, UInt32, UInt32, UInt32, UInt32,
                    Float64, Float64, Float64, Float64, Float64, Float64,)
@mf dx9adl UInt32 InitD3DApp (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8},
                    Ptr{Void}, # RenderD3DItemsState
                    Ptr{Void}, Ptr{Void}, Ptr{Void},) # cfunc, cfunc, cfunc
@mf dx9adl UInt32 MsgLoop (Ptr{Void},) # RenderD3DItemsState
