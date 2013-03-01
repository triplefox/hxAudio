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
	public function window():TimeWindow;
	public function toString():String;

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
	
	public function toString()
	{
		return '(${this.start}, ${this.end})';
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
	
	public inline function window() { return new TimeWindow(this.time, this.time); }

	public inline function beginTime() { return this.time; }
	public inline function endTime() { return this.time; }
	public inline function beginValue() { return this.value; }
	public inline function endValue() { return this.value; }
	public inline function duration() { return 0.; }
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
		var emit_t = (emit - write_ptr + write_end) * ms_sample_ratio;
		var end_t = next_event == null ? emit_t : Math.min(emit_t, next_event.beginTime());
		
		var ptr_start = write_ptr;
		
		while (t < end_t)
		{
			buf.set(write_ptr, this.value);
			write_ptr += 1;
			t += ms_sample_ratio;
		}
		emit += write_ptr - ptr_start;
		if (write_ptr != write_end)
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
	
	public function toString()
	{
		return ('set, t=${this.time} v=${this.value}');
	}
	
}

class TimelineEventLinear implements TimelineEvent
{
	public var time_window : TimeWindow;
	public var distance : Float;
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

	public inline function window() { return new TimeWindow(
		this.time_window.start, 
		this.time_window.end); }
	
	public inline function beginTime() { return this.time_window.start; }
	public inline function endTime() { return this.time_window.end; }
	public inline function beginValue() { return this.begin_value; }
	public inline function endValue() { return this.end_value; }
	public inline function duration() { return this.time_window.distance(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		t = Math.min(endTime(), Math.max(t, beginTime()));
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
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit - write_ptr + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime() );
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			if (use_window.distance() >= ms_sample_ratio)
			{
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

	public function toString()
	{
		return ('linear, t=${this.beginTime()} d=${this.duration()} v=${this.endValue()}');
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

	public inline function window() { return new TimeWindow(
		this.time_window.start, 
		this.time_window.end); }
	
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
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit - write_ptr + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime() );
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			if (use_window.distance() >= ms_sample_ratio)
			{
				var ptr_start = write_ptr;
				var t_dist = use_window.distance();
				var end_t = t + t_dist;
				var value = valueAtTime(t);
				var ratio = end_value / begin_value;
				if (begin_value == end_value) ratio = 1.; // fix some NaN
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

	public function toString()
	{
		return ('exponential, t=${this.beginTime()} d=${this.duration()} v=${this.endValue()}');
	}
	
}

class TimelineEventValueCurve implements TimelineEvent
{
	public var time_window : TimeWindow;
	public var curve : ArrayBuffer;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	
	public function new(begin_time, end_time, curve) 
	{ 
		this.time_window = new TimeWindow(begin_time, end_time); 
		this.curve = curve; 
	}

	public inline function window() { return new TimeWindow(
		this.time_window.start, 
		this.time_window.end); }
	
	public inline function beginTime() { return this.time_window.start; }
	public inline function endTime() { return this.time_window.end; }
	public inline function beginValue() { return this.curve.get(0); }
	public inline function endValue() { return this.curve.get(this.curve.length - 1); }
	public inline function duration() { return this.endTime() - this.beginTime(); }
	
	public inline function valueAtTime(t : Float) : Float 
	{ 
		var position = (t - beginTime()) / (endTime() - beginTime());
		return curve.get(Std.int(
			Math.min(curve.length-1, position*curve.length + 0.5)));
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
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit - write_ptr + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime() );
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			
			var ptr_start = write_ptr;
			var t_dist = use_window.distance();
			var end_t = t + t_dist;
			var c_dist = (endTime() - beginTime());
			var position = (t - beginTime()) / c_dist;
			var inc = ms_sample_ratio / c_dist;
			var p_dist = position + t_dist / c_dist;
			
			var prev_value = (prev_event == null) ? timeline.default_value : prev_event.endValue();
			
			while (position < 0)
			{
				buf.set(write_ptr, prev_value);
				write_ptr += 1;
				position += inc;
			}
			while (position < p_dist)
			{
				buf.set(write_ptr, curve.get(Std.int(position*(curve.length-1) + 0.5)));
				write_ptr += 1;
				position += inc;
			}
			var write_dist = (write_ptr - ptr_start);
			t += ms_sample_ratio * write_dist;
			emit += write_dist;
		}
		
		if (post_window.distance()>0.)
		{	
			var ptr_start = write_ptr;
			var t_dist = post_window.distance();
			var end_t = t + t_dist;
			
			while (t < end_t)
			{
				buf.set(write_ptr, endValue());
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		if (post_window.end < write_window.end)
			event = next_event.fillFromTime(emit, write_ptr, write_end, buf, samplerate);
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
	
	public function toString()
	{
		return ('valuecurve, t=${this.beginTime()} e=${this.endTime()}');
	}
	
}

class TimelineEventTargetAtTime implements TimelineEvent
{

	public var target : Float;
	public var time_constant : Float;
	public var next_event : TimelineEvent;
	public var prev_event : TimelineEvent;
	public var timeline : Timeline;
	public var begin_value : Float;
	public var end_value : Float;
	public var time_window : TimeWindow;
	
	public inline function window() { return new TimeWindow(
		this.time_window.start, 
		this.time_window.end); }
	
	public function new(begin_time, target, time_constant) 
	{ 
		this.time_window = new TimeWindow(begin_time, begin_time);
		this.target = target; 
		this.time_constant = time_constant; 
	}

	public inline function beginTime() { return this.time_window.start; }
	public inline function endTime()  {  return this.time_window.end; }
	
	public inline function duration() { return 0.; }
	
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
		var t = emit * ms_sample_ratio;
		
		var write_window = new TimeWindow(emit * ms_sample_ratio, (emit - write_ptr + write_end) * ms_sample_ratio);
		var curve_window = new TimeWindow(beginTime(), endTime());
		var post_window = new TimeWindow(endTime(), next_event == null ? write_window.end : next_event.beginTime() );
		post_window = post_window.intersection(write_window);
		
		if (write_window.overlaps(curve_window))
		{
			var use_window = write_window.intersection(curve_window);
			
			var ptr_start = write_ptr;
			var t_dist = use_window.distance();
			var end_t = t + t_dist;
			var value = valueAtTime(t);
			var dct = 1 - Math.exp( -1 / (ms_sample_ratio * time_constant));
			
			while (t < end_t)
			{
				buf.set(write_ptr, value);
				value += (target - value) * dct;
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		
		trace([[write_window, curve_window, post_window]]);
		
		if (post_window.distance()>0.)
		{	
			var ptr_start = write_ptr;
			var t_dist = post_window.distance();
			var end_t = t + t_dist;
			var end_v = endValue();
			
			while (t < end_t)
			{
				buf.set(write_ptr, end_v);
				write_ptr += 1;
				t += ms_sample_ratio;
			}
			emit += write_ptr - ptr_start;
		}
		if (post_window.end < write_window.end)
		{
			event = next_event.fillFromTime(emit, write_ptr, write_end, buf, samplerate);
		}
		return event;
		/*while (write_ptr < write_end)
		{
			buf.set(write_ptr, value);
			write_ptr += 1;
			emit += 1;
			event = event.travelTo(t);
		}
		return event;*/
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
		
		if (this.next_event == null) time_window.end = time_window.start;
		else time_window.end = next_event.beginTime();
		
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
	
	public function toString()
	{
		return ('target, t=${this.beginTime()} target=${this.target} ts=${this.time_constant}');
	}
	
}
