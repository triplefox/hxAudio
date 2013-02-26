package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;
import com.ludamix.hxaudio.core.IONode;

/**
 * ...
 * @author James Hofmann
 */

class AudioNode
{

	@:allow(com.ludamix.hxaudio.mock)
	private var cnx_audio : IONode<AudioNode, HXABuf32>;
	@:allow(com.ludamix.hxaudio.mock)
	private var cnx_param : IONode<AudioNode, AudioParam>;
	
	/**
	 * current_time is an internal measure of when the node's last been updated.
	 * */
	@:allow(com.ludamix.hxaudio.mock)
	private var current_time : Float;
	
	public var numberOfInputs(default, null) : Int;
	public var numberOfOutputs(default, null) : Int;
	
	public function new() 
	{
		cnx_audio = new IONode();
		cnx_param = new IONode();
		cnx_audio.data = this;
		current_time = -1.;
	}
	
	public function connectNode(destination : AudioNode, ?output = 0, ?input = 0):Void 	
	{
		cnx_audio.connect(destination.cnx_audio, output, input); 
	}
	
	public function connectParam(destination : AudioParam, ?output = 0):Void 	
	{
		cnx_param.connect(destination.owner.cnx_param, output, 0).data = destination;
	}
	
	public function disconnect(?output = 0)
	{
		cnx_audio.disconnectOutput(output);
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function allowsCycle()
	{
		return false;
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function unfinishedDependencies()
	{
		for (i in this.cnx_audio.inputs)
		{
			if (i.recieve.data.current_time != current_time)
				return true;
		}
		for (i in this.cnx_param.inputs)
		{
			if (i.recieve.data.current_time != current_time)
				return true;
		}
		return false;
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function assignOutputs(blocksize : Int)
	{
		// determine how buffers get passed/copied from input to output.
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function process(blocksize : Int)
	{
		// node handling of fanout and fanin is custom per node.
	}
	
}