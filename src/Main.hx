package ;

#if flash
import com.ludamix.hxaudio.mock.*;
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
	
	static function main() 
	{
		
		var context : AudioContext = new AudioContext();
		
		var osc = new TestOscillator();
		osc.connectNode(context.destination);
		
		//var osc = new OscillatorNode();
		//osc.type = "sine";
		
		//var gain = new AudioGainNode();
		//gain.gain.exponentialRampToValueAtTime(0., 0.5);
		
		//osc.connect(gain, 0, 0);
		//gain.connect(context.destination, 0, 0);
		
		//osc.start(0.);
		//osc.stop(0.25);
		
		context.startRenderingOnline();
		trace("ok");
		
	}
	
}