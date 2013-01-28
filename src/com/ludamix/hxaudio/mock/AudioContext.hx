package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.events.SampleDataEvent;
import flash.Vector;

/**
 * ...
 * @author James Hofmann
 */

typedef DecodeSuccessCallback = AudioBuffer->Void;
typedef DecodeErrorCallback = Void->Void;
typedef ArrayBuffer = HXABuf32;

class AudioContext
{

	public var destination(null, default) : AudioDestinationNode;
	public var sampleRate(null, default) : Float;
	public var currentTime(null, default) : Float;
	public var listener(null, default) : AudioListener;
	public var activeSourceCount(null, default) : Int;
	private var sources : Array<AudioNode>;
	
	public function createBuffer(numberOfChannels : Int, length : Int, sampleRate : Float) : AudioBuffer
	{
		return null;
	}
	
	public function populateBuffer(buffer : ArrayBuffer, mixToMono : Bool)
	{
		
	}
	
	public function decodeAudioData(audioData : ArrayBuffer, 
		successCallback : DecodeSuccessCallback, 
		errorCallback : DecodeErrorCallback)
	{
	
	}
	
	private var sound : Sound;
	private var channel : SoundChannel;
	
	public function startRenderingOnline()
	{
		// flash stuff...
        sound = new Sound();
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSamples);
		channel = sound.play(); 
	}
	
	private function onSamples(e : SampleDataEvent)
	{
		// we have to start the chain and then propogate the destination back over here.
		// ...writing 128 sample chunks.
		
		// oh. we need to run it like a DAG breadth-first traversal and then:
		
		if (curNode == destination)
		{
			e.data.writeFloat(0.);
		}
		
		var open = new Array<AudioNode>();
		// Now all nodes need registration functions for these keep-alive methods:
		// 1. isPlaying
		// 2. connected
		// 3. tail-time
		
		// These functions are static to all AudioContexts - the specific context doesn't care.
		// And we have to build the graph in reverse from destination to source,
		// but that part can fortunately be done at add time.
		
		// In pre-traverse we check isProcessable() and move the node to the back if it's not ready yet.
		// Then add the outputs and param_outputs to the back of the queue.
		
	}
	
	private function updateSources()
	{
		// Where does this get called?
		// When we connect nodes it has to figure out if a destination is at either end...
		// i.e. connection is a process that always requires graph traversal.
		// either that or we poll it every frame(bad bad bad)
		// OK. Maybe IntHashArray is not "really" the structure we want to use,
		// but instead just a fragment of the whole fanning-graph structure.
		var open = [destination];
		var closed = [];
		var result = [];
		while (open.length > 0)
		{
			var c = open.shift();
			if (c.isSourceNode()) result.push(c);
			closed.push(c);
			for (n in c.inputs)
			{
				if (closed.remove(n)!=null)
					open.push(n);
				closed.push(n);
			}
		}
		sources = result;
		activeSourceCount = sources.length;
	}

	public function startRenderingOffline()
	{
	
	}
	
	public function new() 
	{	
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private static var playing_nodes = new Array<AudioNode>();
	@:allow(com.ludamix.hxaudio.mock)
	private static var connected_nodes = new Array<AudioNode>();
	@:allow(com.ludamix.hxaudio.mock)
	private static var tailtime_nodes = new Array<AudioNode>();
	
}