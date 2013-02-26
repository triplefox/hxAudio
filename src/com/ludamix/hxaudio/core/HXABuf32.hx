package com.ludamix.hxaudio.core;

/**
 * ...
 * @author James Hofmann
 */

#if flash9
	typedef HXARawBuf32 = flash.Vector<Float>;
#else js
	typedef HXARawBuf32 = js.webgl.Float32Array; // xirsys_stdjs
#end

class HXABuf32
{

	public var inner : HXARawBuf32;
	public var length (get_length, null) : Int;

	public function new()
	{
		inner = new HXARawBuf32();
	}
	
	public inline function set(i : Int, v : Float)
	{
		inner[i] = v;
	}
	
	public inline function get(i : Int)
	{
		return inner[i];
	}
	
	public inline function get_length() : Int
	{
		return inner.length;
	}

}