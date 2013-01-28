package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;

/**
 * ...
 * @author James Hofmann
 */

class AudioBuffer
{

	public var sampleRate(null, default) : Float;
	public var length(null, default) : Int; // samples

	public var duration(null, default) : Float; // seconds
	public var numberOfChannels(null, default) : Int;
	
	private var buf : Array<HXABuf32>;
	
	public function getChannelData(channel : Int) : HXABuf32
	{
		return buf[channel];
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	public function new(numberOfChannels : Int, length : Int, sampleRate : Float, ?pre : Array<HXABuf32>)
	{
		this.numberOfChannels = numberOfChannels;
		this.length = length;
		this.sampleRate = sampleRate;
		if (pre == null) { pre = new Array(); for (n in 0...numberOfChannels) {pre.push(new HXABuf32());} }
		this.buf = pre;
		this.duration = length / sampleRate;
	}

}