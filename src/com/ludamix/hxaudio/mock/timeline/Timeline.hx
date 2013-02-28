package com.ludamix.hxaudio.mock.timeline;

import com.ludamix.hxaudio.mock.timeline.TimelineEvent;

class Timeline
{

	public var default_value : Float;

	public function new(default_value : Float)
	{
		value = 0.;
		this.default_value = default_value;
		events = [];
	}
	
	public var events : Array<TimelineEvent>;
	public var value : Float;
	
	public function schedule(event : TimelineEvent)
	{
		// where same-type events(linear against linear) overlap and contain the exact same time, old events are replaced.
		// where different-type events overlap, it just inserts after the old ones at the appropriate moment.
		// setValueCurve is an exception to this, you cannot overlap other stuff with it.
		
		event.setTimeline(this);
		
		var i = 0;
		if (event.beginSpecified()) // 
		{
			while (i < events.length) 
			{		
				// Overwrite same event type and time.
				if (events[i].beginTime() == event.beginTime() && events[i].type() == event.type()) {
					events[i] = event;
					return;
				}

				if (events[i].beginTime() > event.beginTime())
					break;
				
				i += 1;
			}
		}
		else
		{
			i = events.length-1;
			if (events[i].endTime() < event.endTime()) i += 1;
		}
		events.insert(i, event);
		
		// Relink events.
		
		events[0].prev_event = null;
		events[0].recalcTime();
		for (n in 1...events.length)
		{
			events[n - 1].next_event = events[n];
			events[n].prev_event = events[n - 1];
			events[n].recalcTime();
		}
		events[events.length-1].next_event = null;
		events[events.length-1].recalcTime();
		
	}
	
	public function reset(startTime : Float)
	{
		var i = 0;
		while(i<events.length)
		{
			if (events[i].beginTime() >= startTime) { events.splice(i, 1); }
			else i+=1;
		}
		if (events.length > 0) events[events.length - 1].next_event = null;
	}
	
	/**
	 * Fill buf with the value v to either the end of the curve or "count" samples, returning the # of samples written.
	 */
	/*
	private inline function fillFlatEvent(
		ev : TimelineEventSet, 
		start_curve : Int, end_curve : Int, 
		position : Int, 
		count : Int, write_offset : Int, buf : ArrayBuffer)
	{
		return fillFlat(ev.value, start_curve, end_curve, position, count, write_offset, buf);
	}
	*/
	
	/**
	 * Internal fillFlat to cover the starts and ends.
	 */
	private inline function fillFlat(
		v : Float,
		start_curve : Int, end_curve : Int, 
		position : Int, 
		count : Int, write_offset : Int, buf : ArrayBuffer)
	{
		
		end_curve -= start_curve;
		count = Std.int(Math.min(end_curve, count));
		
		for (n in write_offset...count+write_offset)
		{
			buf.set(n, v);
		}
		value = v;
		return count;
	}
	
	/**
	 * Lerp buf with the value v to either the end of the curve or "count" samples, returning the # of samples written.
	 */
	/*
	private inline function fillLinear(
		ev : TimelineEventLinear, 
		start_curve : Int, end_curve : Int,
		position : Int, count : Int, write_offset : Int,
		buf : ArrayBuffer)
	{
		var start = ev.beginValue(value);
		var end = ev.endValue();
		
		var inc = (end - start) / count;
		
		position -= start_curve;
		end_curve -= start_curve;
		count = Std.int(Math.min(end_curve, count));
		
		var v = start + inc * position;
		
		for (n in write_offset...count+write_offset)
		{
			buf.set(n, v);
			v += inc;
		}
		
		value = v;
		return count;
	}
	*/
	
	/**
	 * Exponentially multiply buf to either the end of the curve or "count" samples, returning the # of samples written.
	 */
	/*
	private inline function fillExponential(
		ev : TimelineEventExponential, 
		start_curve : Int, end_curve : Int, 
		position : Int, count : Int, write_offset : Int,
		buf : ArrayBuffer)
	{
		var start_val = ev.beginValue(value);
		var end_val = ev.endValue();
		
		// we fallback with the zero or negative value case.
		if (start_val <= 0. || end_val <= 0.)
			return fillFlat(value, start_curve, end_curve, position, count, write_offset, buf);
		else
		{
			position -= start_curve;
			end_curve -= start_curve;
			count = Std.int(Math.min(end_curve, count));
			
			var ratio = end_val / start_val;
			var inc = 1. / (end_curve);
			var multiplier = Math.pow(ratio, inc);
			var v = start_val * Math.pow(ratio, position / end_curve);
			
			for (n in write_offset...count+write_offset)
			{
				buf.set(n, v);
				v *= multiplier;
			}
			
			value = v;
			return count;
		}
	}
	*/

	/*
	private inline function discreteTimeConstantForSampleRate(
		timeConstant : Float, 
		sampleRate : Float) : 
		Float
	{
		return 1 - Math.exp(-1 / (sampleRate * timeConstant));
	}
	*/

	/**
	 * Exponentially multiply buf towards a certain target, using a "time constant" metric.
	 */
	/*
	private inline function fillTarget(
		ev : TimelineEventTargetAtTime, 
		start_curve : Int, end_curve : Int,
		sample_rate : Float, 
		position : Int, count : Int, write_offset : Int,
		buf : ArrayBuffer)
	{
		
		var dct = discreteTimeConstantForSampleRate(ev.time_constant, sample_rate);
		position -= start_curve;
		count = Std.int(Math.min(end_curve-position, count));
		for (n in write_offset...count+write_offset)
		{
			buf.set(n, value);
			value += (ev.target - value) * dct;
		}
		return count;
		
	}
	*/
	
	/**
	 * Nearest-resample the value curve into buf, returning the # of samples written.
	 */
	/*
	private inline function fillValueCurve(
		ev : TimelineEventValueCurve, start_curve : Int, end_curve : Int,
		position : Int, count : Int, write_offset : Int, buf : ArrayBuffer)
	{
		var curve = ev.curve;
		var dist_curve = end_curve - start_curve;
		var inc = curve.length / dist_curve;
		position -= start_curve;
		var curve_p = position * inc;
		for (n in write_offset...count+write_offset)
		{
			buf.set(n, curve.get(Std.int(curve_p + 0.5)));			
			curve_p += inc;
		}
		
		value = buf.get(Std.int(Math.max(0.,count+write_offset-1)));
		return count;
	}
	*/
	
	/**
	 * Fill the buffer with samples generated by the given beginning and ending positions in the timeline.
	 */
	public function generate(begin : Int, end : Int, buf : ArrayBuffer, samplerate : Float)
	{
		var ms_sample_ratio = 100. / samplerate;
			
		var emit = begin;
		var playlength = end - begin;
		var t_start = 0.;
		var t_end = 0.;
		var i = 0;
		
		if (events.length == 0) 
		{
			fillFlat(value, begin, end, emit, playlength, 0, buf);
			return;
		}
		
		events[0].fillFromTime(emit, 0, playlength, buf, samplerate); 
		
		return;
		
	}

}
