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

import Relocator: _mf

macro wf(lib, restype, fnc, argtypes)
  local args = [symbol("a", n) for n in 1:length(argtypes.args)]
  quote
    $(esc(fnc))($(args...)) = ccall(
      ($(string(fnc)), $(Expr(:quote, lib))), stdcall, # (:fnc, :lib)
      $restype, $argtypes, $(args...))
  end
end

@wf kernel32 UInt32 GetModuleHandleA (Ptr{Void},)

macro cf(restype, fnc, argtypes)
  local args = [symbol("a", n) for n in 1:length(argtypes.args)]
  quote
    $(esc(fnc))($(args...)) = ccall(
      $(string(fnc)), # :fnc
      $restype, $argtypes, $(args...))
  end
end

@cf Ptr{Void} memcpy (Ptr{Void}, Ptr{Void}, UInt32,)

macro mf(lib, restype, fnc, argtypes)
  local args = [symbol("a", n) for n in 1:length(argtypes.args)]
  quote
    $(esc(fnc))($(args...)) = ccall(
      _mf(symbol($(string(lib))), symbol($(string(fnc)))), # (:lib, :fnc)
      $restype, $argtypes, $(args...))
  end
end

@mf d3dxconsole Void debugalloc ()
@mf d3dxconsole Void debugout (Ptr{UInt8},)
@mf d3dxconsole Void debugout (Ptr{UInt8}, UInt32,)
@mf d3dxconsole Void debugout (Ptr{UInt8}, UInt32, UInt32,)
@mf d3dxconsole Void debugfree ()

@mf d3dxfreetype2 UInt32 D3DXFT2_GlyphOutline (Ptr{GLYPH_TBL},)

@mf d3dxglyph UInt32 D3DXGLP_GlyphContours (Ptr{GLYPH_TBL},)
@mf d3dxglyph UInt32 D3DXGLP_DrawGlyph (Ptr{GLYPH_TBL},)

@mf dx9adl UInt32 ReleaseNil (Ptr{Ptr{Void}},)
@mf dx9adl UInt32 DrawString (Ptr{RenderD3DItemsState},
                    UInt32, Ptr{Cchar}, UInt32,
                    Float32, Float32, Float32, Float32, Float32, Float32,)
@mf dx9adl UInt32 BltString (Ptr{RenderD3DItemsState},
                    UInt32, Ptr{Cchar}, UInt32, UInt32, UInt32, Float32,)
@mf dx9adl UInt32 BltTexture (Ptr{RenderD3DItemsState},
                    UInt32, Ptr{Ptr{Void}}, UInt32, UInt32, UInt32, UInt32,
                    Float64, Float64, Float64, Float64, Float64, Float64,)
@mf dx9adl UInt32 InitD3DApp (UInt32, UInt32, Ptr{UInt8}, Ptr{UInt8},
                    Ptr{RenderD3DItemsState}, Ptr{Void}, Ptr{Void}, Ptr{Void},)
@mf dx9adl UInt32 MsgLoop (Ptr{RenderD3DItemsState},)
