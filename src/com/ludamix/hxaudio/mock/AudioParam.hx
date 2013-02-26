package com.ludamix.hxaudio.mock;

import com.ludamix.hxaudio.core.IONode;
import com.ludamix.hxaudio.mock.timeline.*;

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
		timeline.schedule(new TimelineEvent(value, value, startTime, startTime, TimelineEvent.SET, null));
	}
	
	public function linearRampToValueAtTime(value : Float, endTime : Float)
	{
		var last = timeline.events[timeline.events.length - 1];
		timeline.schedule(new TimelineEvent(last.end, value, last.end_time, endTime, TimelineEvent.LINEAR, null));
	}

	public function exponentialRampToValueAtTime(value : Float, endTime : Float)
	{
		var last = timeline.events[timeline.events.length - 1];
		timeline.schedule(new TimelineEvent(last.end, value, last.end_time, endTime, TimelineEvent.EXPONENTIAL, null));
	}
	
	public function setTargetAtTime(target : Float, startTime : Float, timeConstant : Float)
	{
		var last = timeline.events[timeline.events.length - 1];
		// TODO: figure out the true algorithm for this.
		timeline.schedule(new TimelineEvent(last.end, 
			value, 
			last.end_time, 
			last.end_time, 
			TimelineEvent.TARGETATTIME, 
			null));
	}
	
	public function setValueCurveAtTime(values : ArrayBuffer, startTime : Float, duration : Float)
	{
		var last = timeline.events[timeline.events.length - 1];
		timeline.schedule(new TimelineEvent(last.end, value, startTime, startTime + duration, 
		TimelineEvent.VALUECURVE, values));
	}
	
	public function cancelScheduledValues(startTime : Float)
	{
		while (timeline.events[timeline.events.length - 1].end_time >= startTime)
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