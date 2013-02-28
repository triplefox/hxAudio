package com.ludamix.hxaudio.mock.timeline;
import com.ludamix.hxaudio.mock.ArrayBuffer;

/**
 * Just a simple union of all the event types.
 */
interface TimelineEvent
{
	
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;

	public function beginTime() : Float;
	public function endTime() : Float;	
	public function duration() : Float;
	public function beginValue() : Float;
	public function endValue() : Float;
	public function valueAtTime(t : Float) : Float;
	public function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent;
	public function beginSpecified() : Bool;
	public function type() : Int;
	public function setTimeline(timeline : Timeline):Void;
	public function recalcTime():Void;
	public function travelTo(time : Float):TimelineEvent;

}

class TimeWindow
{
	public var start : Float;
	public var end : Float;
	
	public function new(start, end)
	{
		this.start = start;
		this.end = end;
	}
	
	public inline function intersection(w : TimeWindow)
	{
		var low = Math.max(w.start, this.start);
		var hi = Math.min(w.end, this.end);
		return new TimeWindow(low, hi);
	}
	
	public inline function union(w : TimeWindow)
	{
		var low = Math.min(w.start, this.start);
		var hi = Math.max(w.end, this.end);
		return new TimeWindow(low, hi);
	}
	
	public inline function overlaps(w : TimeWindow)
	{
		return !(this.end < w.start || this.start > w.end);
	}
	
	public inline function distance()
	{
		return this.end - this.start;
	}
	
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
	public inline function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent
	{
		var ms_sample_ratio = 100. / samplerate;
		var event : TimelineEvent = this;
		var t = emit * ms_sample_ratio;
		var end_t = next_event == null ? write_end * ms_sample_ratio : next_event.beginTime();
		
		var ptr_start = write_ptr;
		
		while (t < end_t)
		{
			buf.set(write_ptr, this.value);
			write_ptr += 1;
			t += ms_sample_ratio;
		}
		emit += write_ptr - ptr_start;
		if (write_ptr!=write_end)
			event = next_event.fillFromTime(emit, write_ptr, write_end, buf, samplerate);
		
		return event;
	}
	
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
	public var time_window : TimeWindow;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	
	public function new(end_time, end_value) 
	{ 
		this.time_window = new TimeWindow(0., end_time); 
		this.end_value = end_value; 
	}	

	public inline function beginTime() { return this.time_window.start; }
	public inline function endTime() { return this.time_window.end; }
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }
	public inline function duration() { return this.time_window.distance(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var position = (t - beginTime()) / (endTime() - beginTime());
		return (endValue() - beginValue()) * position + beginValue();
	}
	
	public inline function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent
	{
		var ms_sample_ratio = 100. / samplerate;
		var event : TimelineEvent = this;
		var t = emit * ms_sample_ratio;
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime() );
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			
			var ptr_start = write_ptr;
			var t_dist = use_window.distance();
			var end_t = t + t_dist;
			var value = valueAtTime(t);
			var inc = valueAtTime(beginTime() + ms_sample_ratio) - valueAtTime(beginTime());
			
			while (t < end_t)
			{
				buf.set(write_ptr, value);
				value += inc;
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		
		if (post_window.distance()>0.)
		{	
			var ptr_start = write_ptr;
			var t_dist = post_window.distance();
			var end_t = t + t_dist;
			
			while (t < end_t)
			{
				buf.set(write_ptr, end_value);
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		if (post_window.end < write_window.end)
			event = next_event.fillFromTime(emit, write_ptr, write_end, buf, samplerate);
		return event;
	}
	
	public static inline var TYPE = 2;
	public inline function type() { return TimelineEventLinear.TYPE; }
	
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return false; }
	
	private var time_cache : Float;
	public inline function recalcTime() 
	{ 
		this.time_window.start = prev_event == null ? 0. : prev_event.beginTime() + prev_event.duration();
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
	public var time_window : TimeWindow;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	
	public function new(end_time, end_value) 
	{ 
		this.time_window = new TimeWindow(0., end_time); 
		this.end_value = end_value; 
	}	

	public inline function beginTime() { return this.time_window.start; }
	public inline function endTime() { return this.time_window.end; }
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }
	public inline function duration() { return this.time_window.distance(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{
		t = Math.min(endTime(), Math.max(t, beginTime()));
		return begin_value * Math.pow(end_value / begin_value, (
			(t - beginTime()) / (time_window.end - beginTime())
		));
	}
	
	public inline function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent
	{
		var ms_sample_ratio = 100. / samplerate;
		var event : TimelineEvent = this;
		var t = emit * ms_sample_ratio;
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime() );
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			
			var ptr_start = write_ptr;
			var t_dist = use_window.distance();
			var end_t = t + t_dist;
			var value = valueAtTime(t);
			var ratio = end_value / begin_value;
			var multiplier = Math.pow(ratio, 1./t_dist * ms_sample_ratio);
			
			while (t < end_t)
			{
				buf.set(write_ptr, value);
				value *= multiplier;
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		
		if (post_window.distance()>0.)
		{	
			var ptr_start = write_ptr;
			var t_dist = post_window.distance();
			var end_t = t + t_dist;
			
			while (t < end_t)
			{
				buf.set(write_ptr, end_value);
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		if (post_window.end < write_window.end)
			event = next_event.fillFromTime(emit, write_ptr, write_end, buf, samplerate);
		return event;
	}
	
	public static inline var TYPE = 3;
	public inline function type() { return TimelineEventExponential.TYPE; }
	
	public inline function setTimeline(timeline : Timeline):Void { this.timeline = timeline; }
	public inline function beginSpecified() { return false; }
	
	private var time_cache : Float;
	public inline function recalcTime() 
	{ 
		this.time_window.start = prev_event == null ? 0. : prev_event.beginTime() + prev_event.duration();
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
	public inline function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent
	{
		var ms_sample_ratio = 100. / samplerate;
		var event : TimelineEvent = this;
		while (write_ptr < write_end)
		{
			var t = emit * ms_sample_ratio;
			event = event.travelTo(t);
			buf.set(write_ptr, event.valueAtTime(t));
			write_ptr += 1;
			emit += 1;
		}
		return event;
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
	public inline function fillFromTime(
		emit : Int, 
		write_ptr : Int,
		write_end : Int,
		buf : ArrayBuffer,
		samplerate : Float) : TimelineEvent
	{
		var ms_sample_ratio = 100. / samplerate;
		var event : TimelineEvent = this;
		while (write_ptr < write_end)
		{
			var t = emit * ms_sample_ratio;
			event = event.travelTo(t);
			buf.set(write_ptr, event.valueAtTime(t));
			write_ptr += 1;
			emit += 1;
		}
		return event;
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
