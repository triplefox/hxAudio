package ;

#if flash
import com.ludamix.hxaudio.flash.Visualizer;
import com.ludamix.hxaudio.mock.*;
import com.ludamix.hxaudio.mock.timeline.*;
import com.ludamix.hxaudio.mock.timeline.TimelineEvent;
import flash.display.Bitmap;
import flash.events.DataEvent;
import flash.Lib;
#else
//import js.html.audio.*;
//import js.Lib;
#end

/**
 * ...
 * @author James Hofmann
 */

class Main 
{

	public static var context : AudioContext;
	public static var osc : TestOscillator;
	
	static function onFrame(e : flash.events.Event)
	{
	
	}
	
	static function main() 
	{
		
		context = new AudioContext();
		
		//osc = new TestOscillator();
		//osc.connectNode(context.destination);
		
		//var osc = new OscillatorNode();
		//osc.type = "sine";
		
		//var gain = new AudioGainNode();
		//gain.gain.exponentialRampToValueAtTime(0., 0.5);
		
		//osc.connect(gain, 0, 0);
		//gain.connect(context.destination, 0, 0);
		
		//osc.start(0.);
		//osc.stop(0.25);
		
		//context.startRenderingOnline();
		
		var buf = new ArrayBuffer();
		var timeline = new Timeline(0.);
		
		var vcurve = new ArrayBuffer();
		for (n in 0...100)
			vcurve.set(n, Math.sin(n / 50 * Math.PI) / 2 + 0.5);
		
		var genEvent = function()
		{
			var ev : TimelineEvent = null;
			switch(Std.int(Math.random() * 5))
			{
				case 0: 
					var data = ({ type:"set", t:Math.random() * 110, v:Math.random() * 0.8 + 0.1 });
					trace('pushing set, t=${data.t} v=${data.v}');
					ev = new TimelineEventSet(data.t, data.v);
				case 1: 
					var data = ({ type:"linear", d:Math.random() * 20, v:Math.random() * 0.8 + 0.1 });
					trace('pushing linear, d=${data.d} v=${data.v}');
					ev = new TimelineEventLinear(data.d, data.v);
				case 2:
					var data = ({ type:"exponential", d:Math.random() * 20, v:Math.random() * 0.8 + 0.1 });
					trace('pushing exponential, d=${data.d} v=${data.v}');
					ev = new TimelineEventExponential(data.d, data.v);
				case 3: 
					var data = ({ type:"target", t:Math.random() * 110, v:Math.random() * 0.8 + 0.1, ts:4 });
					trace('pushing target, t=${data.t} target=${data.v} ts=${data.ts}');
					ev = new TimelineEventTargetAtTime(data.t, data.v, data.ts);
				case 4: 
					var t = Math.random() * 110;  
					var data = ({ type:"valuecurve", t:t, e:t+Math.random() * 20, curve:vcurve });
					ev = new TimelineEventValueCurve(
						data.t, data.e, data.curve);
					trace('pushing vcurve, t=${data.t} e=${data.e}');
			}
			if (timeline.invalidEvent(ev)) { trace("push failed"); }
			else timeline.schedule(ev);
		}
		
		/*
		timeline.schedule(new TimelineEventSet(5, 0.5));
		timeline.schedule(new TimelineEventSet(10, 0.2));
		timeline.schedule(new TimelineEventLinear(20, 0.9));
		timeline.schedule(new TimelineEventExponential(40, 0.1));
		timeline.schedule(new TimelineEventTargetAtTime(70, 0.8, 4));
		timeline.schedule(new TimelineEventValueCurve(90, 99, vcurve));
		timeline.schedule(new TimelineEventSet(110, 0.5));
		*/
		
		for (n in 0...10)
			genEvent();
			
		trace("result:");
		trace(timeline.toString());
		
		timeline.generate(0, 100, buf, 100.);
		
		var viz = Visualizer.amplitude(buf, 500, 100, null);
		viz.y = 100;
		Lib.current.addChild(viz);
		
		// Now run tests using randomized permutations of the timeline.
		
		var buf2 = new ArrayBuffer();
		for (n in 0...100)
		{
			timeline.generate(n, n + 1, buf, 100.);
			buf2.set(n, buf.get(0));
		}
		var viz2 = Visualizer.amplitude(buf2, 500, 100, null);
		viz2.x = 0;
		viz2.y = 200;
		Lib.current.addChild(viz2);
		
		for (n in 0...100)
		{
			if (Math.abs(buf.get(n) - buf2.get(n))>0.000001)
			{
				trace('diff n=$n ${buf.get(n)} ${buf2.get(n)}');
				
				for (y in 0...5)
				{
					viz.bitmapData.setPixel(Std.int(n/100*viz.bitmapData.width),y,0xFF00FF);
					viz2.bitmapData.setPixel(Std.int(n/100*viz.bitmapData.width),y,0xFF00FF);
				}
			}
			if (n % 10 == 0)
			{
				for (y in viz.bitmapData.height-5...viz.bitmapData.height)
				{
					viz.bitmapData.setPixel(Std.int(n/100*viz.bitmapData.width),y,0x4444FF);
					viz2.bitmapData.setPixel(Std.int(n/100*viz.bitmapData.width),y,0x4444FF);
				}
			}
		}
		for (e in timeline.events)
		{
			var x = e.beginTime();
			var y = 5;
			viz.bitmapData.setPixel((Std.int(x / 100 * viz.bitmapData.width)), y, 0xFFFFFF);
			viz.bitmapData.setPixel((Std.int(x / 100 * viz.bitmapData.width))-1, y, 0xFFFFFF);
			viz.bitmapData.setPixel((Std.int(x / 100 * viz.bitmapData.width))+1, y, 0xFFFFFF);
			viz.bitmapData.setPixel((Std.int(x / 100 * viz.bitmapData.width)), y-1, 0xFFFFFF);
			viz.bitmapData.setPixel((Std.int(x / 100 * viz.bitmapData.width)), y+1, 0xFFFFFF);
		}
		
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onFrame);
		
	}
	
}