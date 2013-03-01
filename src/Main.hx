package ;

#if flash
import com.ludamix.hxaudio.mock.*;
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
		
		var tt = new com.ludamix.hxaudio.test.TimelineTest();
		tt.run();
		tt.display();
		
		flash.Lib.current.addEventListener(flash.events.Event.ENTER_FRAME, onFrame);
		
	}
	
}