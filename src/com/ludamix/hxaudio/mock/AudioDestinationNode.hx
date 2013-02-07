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
	
	public function new()
	{
		super();
		numberOfInputs = 1;
		numberOfOutputs = 0;
	}
	
	private override function process(blocksize)
	{
		// FIXME: Do we auto-sum the inputs, if there's more than one?
		// FIXME: HANDLE STEREO
		var i = Lambda.array(cnx_audio.getInputs(0))[0].data;
		var buf = data.data;
		for (pos in 0...blocksize)
		{
			buf.writeFloat(i.get(pos));
			buf.writeFloat(i.get(pos));
		}
		data.data = buf;
	}	

}