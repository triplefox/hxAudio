package com.ludamix.hxaudio.mock.timeline;
import com.ludamix.hxaudio.mock.ArrayBuffer;

/**
 * Just a simple union of all the event types.
 */
interface TimelineEvent
{

	// I've really had it with the fiddliness.
	// Gap areas would be given a type so that we can deal with them better.
	// Just keep revising the TimelineEvents, those are getting pretty strong.
	// I think if we start by explaining it as an FP system it will grow a lot easier to reason about.
	// OK. So we do a recursive travelTo() through each node.
	// Next let's do a single-point valueAtTime() that is perfectly accurate, and replace the fills with that momentarily.
	// If we can get that right, then we can optimize it!
	
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;

	public function beginTime() : Float;
	public function endTime() : Float;	
	public function duration() : Float;
	public function beginValue() : Float;
	public function endValue() : Float;
	public function valueAtTime(t : Float) : Float;
	public function beginSpecified() : Bool;
	public function type() : Int;
	public function setTimeline(timeline : Timeline):Void;
	public function recalcTime():Void;
	public function travelTo(time : Float):TimelineEvent;

}

class TimelineEventSet implements TimelineEvent
{
	public var time : Float;
	public var value : Float;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	
	public function new(time, value) { this.time = time; this.value = value; }	

	public inline function beginTime() { return this.time; }
	public inline function endTime() { return this.time; }
	public inline function beginValue() { return this.value; }
	public inline function endValue() { return this.value; }
	public inline function duration() { return 0.00001; }
	public inline function valueAtTime(t : Float) : Float { return this.value; }
	
	public static inline var TYPE = 1;
	public inline function type() { return TimelineEventSet.TYPE; }

	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return true; }
	public inline function recalcTime() { }
	
	public function travelTo(time : Float):TimelineEvent
	{
		if (next_event != null && next_event.beginTime() <= time)
		{
			return next_event.travelTo(time);
		}
		else return this;
	}
	
}

class TimelineEventLinear implements TimelineEvent
{
	public var end_time : Float;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	
	public function new(end_time, end_value) 
	{ 
		this.end_time = end_time; 
		this.end_value = end_value; 
	}	

	public inline function beginTime() { return time_cache; }
	public inline function endTime() { return this.end_time; }
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }
	public inline function duration() { return this.end_time - this.beginTime(); }
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var start_value = beginValue();
		var begin_time = beginTime();
		var position = (t - begin_time) / (end_time - begin_time);
		return (end_value - start_value) * position + start_value;
	}

	public static inline var TYPE = 2;
	public inline function type() { return TimelineEventLinear.TYPE; }
	
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return false; }
	
	private var time_cache : Float;
	public inline function recalcTime() 
	{ 
		time_cache = prev_event == null ? 0. : prev_event.beginTime() + prev_event.duration();
		this.begin_value = prev_event == null ? timeline.default_value : prev_event.endValue();
	}
	
	public function travelTo(time : Float):TimelineEvent
	{
		if (next_event != null && next_event.beginTime() <= time)
		{
			return next_event.travelTo(time);
		}
		else return this;
	}
	
}

class TimelineEventExponential implements TimelineEvent
{
	public var end_time : Float;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	
	public function new(end_time, end_value) 
	{ 
		this.end_time = end_time; 
		this.end_value = end_value; 
	}	

	public inline function beginTime() { return time_cache; }
	public inline function endTime() { return this.end_time; }
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }
	public inline function duration() { return this.end_time - this.beginTime(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var start_value = beginValue();
		var begin_time = beginTime();
		var ratio = end_value / start_value;
		var position = (t - begin_time) / (end_time - begin_time);
		return start_value * Math.pow(ratio, position / end_value);
	}
	
	public static inline var TYPE = 3;
	public inline function type() { return TimelineEventExponential.TYPE; }
	
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return false; }
	
	private var time_cache : Float;
	public inline function recalcTime() 
	{ 
		time_cache = prev_event == null ? 0. : prev_event.beginTime() + prev_event.duration();
		this.begin_value = prev_event == null ? timeline.default_value : prev_event.endValue();
	}
	
	public function travelTo(time : Float):TimelineEvent
	{
		if (next_event != null && next_event.beginTime() <= time)
		{
			return next_event.travelTo(time);
		}
		else return this;
	}

}

class TimelineEventValueCurve implements TimelineEvent
{
	public var begin_time : Float;
	public var end_time : Float;
	public var curve : ArrayBuffer;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	
	public function new(begin_time, end_time, curve) 
	{ 
		this.begin_time = begin_time; 
		this.end_time = end_time; 
		this.curve = curve; 
	}

	public inline function beginTime() { return this.begin_time; }
	public inline function endTime() { return this.end_time; }
	public inline function beginValue() { return this.curve.get(0); }
	public inline function endValue() { return this.curve.get(this.curve.length - 1); }
	public inline function duration() { return this.end_time - this.beginTime(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var begin_time = beginTime();
		var position = (t - begin_time) / (end_time - begin_time);
		return curve.get(Std.int(
			Math.min(curve.length-1, position*curve.length + 0.5 + beginValue())));
	}

	public static inline var TYPE = 4;
	public inline function type() { return TimelineEventValueCurve.TYPE; }
	
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return true; }
	public inline function recalcTime() { }
	
	public function travelTo(time : Float):TimelineEvent
	{
		if (next_event != null && next_event.beginTime() <= time)
		{
			return next_event.travelTo(time);
		}
		else return this;
	}
	
}

class TimelineEventTargetAtTime implements TimelineEvent
{

	public var begin_time : Float;
	public var target : Float;
	public var time_constant : Float;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	
	public function new(begin_time, target, time_constant) 
	{ 
		this.begin_time = begin_time; 
		this.target = target; 
		this.time_constant = time_constant; 
	}

	public inline function beginTime() { return this.begin_time; }
	public inline function endTime() 
	{ 
		// we return the time needed to reach within -96dB of the target value(0.00002),
		// approached in steps of 63.2% for each time constant.
		// or we return the beginTime of the next event.
		if (this.next_event == null) return this.begin_time + this.time_constant * 23.58; 
		else return this.next_event.beginTime(); 
	}
	
	public inline function duration() { return 0.00001; }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var begin_time = beginTime();
		var eT = endTime();
		var v0 = beginValue();
		var v1 = target;
		var t0 = begin_time;
		return v1 + (v0 - v1) * Math.exp( -(t - t0) / time_constant);
	}
	
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }

	public static inline var TYPE = 5;
	public inline function type() { return TimelineEventTargetAtTime.TYPE; }
	
	public inline function linkPrev(prev : TimelineEvent):Void { this.prev_event = prev; }
	public inline function linkNext(next : TimelineEvent):Void { this.next_event = next; }
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return true; }
	
	public inline function recalcTime() 
	{ 
		this.begin_value = (prev_event == null) ? timeline.default_value : prev_event.endValue();
		this.end_value = (next_event == null) ? target : valueAtTime(endTime());
	}
	
	public function travelTo(time : Float):TimelineEvent
	{
		if (next_event != null && next_event.beginTime() <= time)
		{
			return next_event.travelTo(time);
		}
		else return this;
	}
	
}
