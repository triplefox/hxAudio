package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.IONode;
import com.ludamix.hxaudio.mock.timeline.*;
import com.ludamix.hxaudio.mock.timeline.TimelineEvent;

class AudioParam
{

	public var value (get_value, set_value) : Float;
	public var computedValue(get_computedValue, null) : Float;
	public var minValue(default, null) : Float;
	public var maxValue(default, null) : Float;
	public var defaultValue(default, null) : Float;
	
	@:allow(com.ludamix.hxaudio.mock)
	private var cnx_data : ArrayBuffer;
	@:allow(com.ludamix.hxaudio.mock)
	private var use_cnx_data : Bool;
	@:allow(com.ludamix.hxaudio.mock)
	private var owner : AudioNode;

	@:allow(com.ludamix.hxaudio.mock)
	private var timeline : Timeline;

	private inline function get_value():Float
	{
		return timeline.value;
	}

	private inline function set_value(v : Float):Float	
	{
		if (timeline.events.length == 0)
		{
			timeline.value = v;
		}
		return timeline.value;
	}

	private inline function get_computedValue():Float
	{
		// TODO: this is the part that downmixes to mono and sums against timeline value.
		return timeline.value;
	}
	
	public function setValueAtTime(value : Float, startTime : Float)
	{
		timeline.schedule(new TimelineEventSet(value, startTime));
	}
	
	// TODO: We have to simplify the scheduling API so that it can link as it schedules.
	// Our reasoning is mostly sound, however we just need to fix up the notion of endTime()
	// so that it's always getting a cached value.
	
	public function linearRampToValueAtTime(target : Float, endTime : Float)
	{
		if (timeline.events.length > 0)
		{
			var last = timeline.events[timeline.events.length - 1];
			timeline.schedule(new TimelineEventLinear(endTime, target));
		}
		else
		{
			timeline.schedule(new TimelineEventLinear(endTime, target));
		}
	}

	public function exponentialRampToValueAtTime(target : Float, endTime : Float)
	{
		if (timeline.events.length > 0)
		{
			var last = timeline.events[timeline.events.length - 1];
			timeline.schedule(new TimelineEventExponential(endTime, target));
		}
		else
		{
			timeline.schedule(new TimelineEventExponential(endTime, target));
		}
	}
	
	public function setTargetAtTime(target : Float, startTime : Float, timeConstant : Float)
	{
		// TODO: figure out the true algorithm for this.
		timeline.schedule(new TimelineEventTargetAtTime(
			startTime, 
			target, 
			timeConstant));
	}
	
	public function setValueCurveAtTime(values : ArrayBuffer, startTime : Float, duration : Float)
	{
		timeline.schedule(new TimelineEventValueCurve(startTime, startTime + duration, values));
	}
	
	public function cancelScheduledValues(startTime : Float)
	{
		while (timeline.events[timeline.events.length - 1].endTime() >= startTime)
			timeline.events.pop();
	}
	
	public function new() 
	{	
		
	}
	
	public function disconnect()
	{
		//cnx.
	}
	
}