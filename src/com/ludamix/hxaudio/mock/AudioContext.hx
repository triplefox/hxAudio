package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.IONode;
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

class AudioContext
{

	public var destination(default, null) : AudioDestinationNode;
	public var sampleRate(default, null) : Float;
	public var currentTime(default, null) : Float;
	public var listener(default, null) : AudioListener;
	public var activeSourceCount(default, null) : Int;
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

	public var bufferSize(null, default) : Int;	
	
	public var BLOCKSIZE : Int;
	
	public function startRenderingOnline()
	{
		// flash stuff...
        sound = new Sound();
		sound.addEventListener(SampleDataEvent.SAMPLE_DATA, onSamples);
		channel = sound.play(); 
	}
	
	private function onSamples(e : SampleDataEvent)
	{
		
		destination.data = e;
		var result = prepGraph(currentTime);
		while (Std.int(destination.data.data.length) < bufferSize)
		{
			for (r in result)
				r.data.process(BLOCKSIZE);
		}
		
	}
	
	private function findSourceNodes(t : IONode<AudioNode, ArrayBuffer>) : Bool
	{
		var n = t.data; 
		return (n.numberOfOutputs == 1 && n.numberOfInputs == 0);
	}
	
	private function prepGraph(current_time : Float)
	{
		/*
		
		TODO: Implement some very simple test nodes so that I can start working against reality.
		FIXME: Detect cycles as they're connected.
		FIXME: Implement all the rules for when nodes should die(the tailtime one is a big one and Chrome doesn't do it yet).
		FIXME: Only rewrite the graph when the situation changes.
		FIXME: AudioParams are NOT correctly handled yet.
		
		*/
		
		// 1. Find all the sources.
		var result = destination.cnx_audio.findNodes(findSourceNodes);
		
		// 2. Populate open nodes with the outputs of the source nodes.
		var open = new Array();
		for (n in result)
		{
			for (o in n.data.cnx_audio.outputs)
			{
				o.data = new ArrayBuffer();
				open.push(o.recieve);
			}
		}
		
		// 3. Expand from sources, until dependencies are encountered.
		// As we do this, assign new buffers as necessary.
		// When deps appear, move to back and continue.
		while (open.length > 0)
		{
			var cur = open.shift();
			if (cur.data.unfinishedDependencies())
				open.push(cur);
			cur.data.current_time = current_time;
			cur.data.assignOutputs(BLOCKSIZE);
			result.push(cur);
		}
		
		return result;
		
	}

	public function startRenderingOffline()
	{
	
	}
	
	public function new(?bufferSize = 2048) 
	{	
		this.bufferSize = bufferSize;
		this.BLOCKSIZE = 128;
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private static var playing_nodes = new Array<AudioNode>();
	@:allow(com.ludamix.hxaudio.mock)
	private static var connected_nodes = new Array<AudioNode>();
	@:allow(com.ludamix.hxaudio.mock)
	private static var tailtime_nodes = new Array<AudioNode>();
	
}