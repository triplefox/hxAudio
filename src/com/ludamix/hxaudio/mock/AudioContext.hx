package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;

/**
 * ...
 * @author James Hofmann
 */

class AudioContext
{

	public var destination(null, default) : AudioDestinationNode;
	public var sampleRate(null, default) : Float;
	public var currentTime(null, default) : Float;
	public var listener(null, default) : AudioListener;
	public var activeSourceCount(null, default) : Int;

	public function new() 
	{	
		
	}
	
}