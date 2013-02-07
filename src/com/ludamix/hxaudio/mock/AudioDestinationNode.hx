package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;
import flash.events.SampleDataEvent;

/**
 * ...
 * @author James Hofmann
 */

class AudioDestinationNode extends AudioNode
{

	public var maxNumberOfChannels(default, null) : Int;
	public var numberOfChannels : Int;
	
	@:allow(com.ludamix.hxaudio.mock)
	private var data : SampleDataEvent;

}