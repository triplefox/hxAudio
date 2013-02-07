package com.ludamix.hxaudio.mock;

class TestOscillator extends AudioNode
{

	public var time : Float;
	
	public function new()
	{
		super();
		numberOfInputs = 0;
		numberOfOutputs = 1;
		time = 0.;
	}
	
	private override function assignOutputs(blocksize)
	{
		for (n in cnx_audio.outputs)
		{
			n.data = new ArrayBuffer();
		}
	}
	
	private override function process(blocksize)
	{
		var inc = 44100 / 440.*Math.PI * 2;		
		for (n in cnx_audio.outputs)
		{
			var pos = 0;
			for (pos in 0...blocksize)
			{
				n.data.set(pos, Math.sin(time));
				time += inc;
			}
		}
	}

}