package com.ludamix.hxaudio.mock.timeline;

/**
 * Just a simple union of all the event types.
 */
class TimelineEvent
{
	public var begin : Float;
	public var end : Float;
	public var begin_time : Float;
	public var end_time : Float;
	public var type : Int;
	public var buf : ArrayBuffer;
	
	public static inline var SET = 1;
	public static inline var LINEAR = 2;
	public static inline var EXPONENTIAL = 3;
	public static inline var VALUECURVE = 4;
	public static inline var TARGETATTIME = 5;
	
	public function new(begin, end, begin_time, end_time, type, buf)
	{
		this.begin = begin;
		this.end = end;
		this.begin_time = begin_time;
		this.end_time = end_time;
		this.type = type;
		this.buf = buf;
	}
	
}
