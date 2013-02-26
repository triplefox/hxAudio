package ;

#if flash
import com.ludamix.hxaudio.flash.Visualizer;
import com.ludamix.hxaudio.mock.*;
import com.ludamix.hxaudio.mock.timeline.*;
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
		var timeline = new Timeline();
		timeline.schedule(new TimelineEvent(0.5, 0.5, 10, 10, TimelineEvent.SET, null));
		timeline.schedule(new TimelineEvent(-0.6, 0.5, 20, 40, TimelineEvent.LINEAR, null));
		timeline.schedule(new TimelineEvent(0.3, 0.3, 98, 99, TimelineEvent.SET, null));
		timeline.schedule(new TimelineEvent(0.5, -0.6, 110, 110, TimelineEvent.SET, null));
		timeline.generate(0, 100, buf, 1.);
		var viz = Visualizer.waveform(buf, 500, 100, null);
		viz.y = 100;
		Lib.current.addChild(viz);
		
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onFrame);
		
	}
	
}