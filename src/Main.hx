package ;

#if flash
import com.ludamix.hxaudio.flash.Visualizer;
import com.ludamix.hxaudio.mock.*;
import com.ludamix.hxaudio.mock.timeline.*;
import com.ludamix.hxaudio.mock.timeline.TimelineEvent;
import flash.display.Bitmap;
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
		
		timeline.schedule(new TimelineEventSet(5, 0.5));
		timeline.schedule(new TimelineEventSet(10, 0.2));
		timeline.schedule(new TimelineEventLinear(20, 0.9));
		timeline.schedule(new TimelineEventExponential(40, 0.1));
		timeline.schedule(new TimelineEventTargetAtTime(70, 0.8, 4));
		timeline.schedule(new TimelineEventValueCurve(90, 99, vcurve));
		timeline.schedule(new TimelineEventSet(110, 0.5));
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
		
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onFrame);
		
	}
	
}