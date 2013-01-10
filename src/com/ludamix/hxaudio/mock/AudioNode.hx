package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.HXABuf32;
import com.ludamix.hxaudio.core.IntHashArray;

/**
 * ...
 * @author James Hofmann
 */

private typedef AudioConnection = { buf:HXABuf32, destination:AudioNode, output:Int, input:Int };
private typedef ParamConnection = { buf:HXABuf32, destination:AudioParam, output:Int };

class AudioNode
{

	@:allow(com.ludamix.hxaudio.mock)
	private var outputs : IntHashArray<AudioConnection>;
	@:allow(com.ludamix.hxaudio.mock)
	private var inputs : IntHashArray<AudioConnection>;
	@:allow(com.ludamix.hxaudio.mock)
	private var param_outputs : IntHashArray<ParamConnection>;
	public var numberOfInputs(default, null) : Int;
	public var numberOfOutputs(default, null) : Int;

	@:allow(com.ludamix.hxaudio.mock)
	private static inline var BLOCKSIZE = 128;

	public function new() 
	{
		outputs = new IntHashArray();
		inputs = new IntHashArray();
		param_outputs = new IntHashArray();
	}
	
	public function connectNode(destination : AudioNode, ?output = 0, ?input = 0):Void 	
	{
		var cnx = { buf:new HXABuf32(), destination:destination, output:output, input:input };
		
		outputs.pushUnique(output, cnx, function(a, b) { return a.output == b.output; } );
		inputs.pushUnique(input, cnx, function(a, b) { return a.input == b.input; } );
	}
	
	public function connectParam(destination : AudioParam, ?output = 0):Void 	
	{
		var cnx = { buf:new HXABuf32(), destination:destination, output:output };
		
		param_outputs.pushUnique(output, cnx, function(a, b) { return a.output == b.output; } );
	}
	
	public function disconnect(?output = 0)
	{
		var outtable;
		if (!outputs.exists(output)) throw "Output does not exist: "+Std.string(output);
		else outtable = outputs.get(output);
		
		for (n in 
			outputs.removeKind(output, function(a, b) { return a.output == b.output; } ))
		{
			cnx.destination.inputs.removeKind(
				cnx.input, function(a, b) { return a.input == b.input; } );
		}
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function allowsCycle()
	{
		return false;
	}
	
	@:allow(com.ludamix.hxaudio.mock)
	private function process()
	{
		// node handling of fanout and fanin is custom per node.
	}
	
}