package com.ludamix.hxaudio.flash;
import com.ludamix.hxaudio.mock.ArrayBuffer;
import flash.display.Bitmap;
import flash.display.BitmapData;

class Visualizer
{

	public static function waveform(wf : ArrayBuffer, 
		display_width : Int, display_height : Int, ?bitmap : Bitmap)
	{
		var H = Std.int(display_height);
		var H1 = H >> 1;
		var LIM = display_height / 2 - 1;
		var spr = { if (bitmap != null) bitmap;
			else new Bitmap(new BitmapData(display_width, H, false, 0));}
		var scaleX = wf.length / display_width;
		for (n in 0...display_width)
		{
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1 - LIM), 0x444400);
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1 + LIM), 0x444400);
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1), 0x444400);
		}
		var last = H1;
		var cur = H1;
		for (n in 0...display_width)
		{
			cur = Std.int(wf.get(Std.int(n*scaleX)) * LIM + H1);
			var top = Std.int(Math.max(cur, last));
			var bot = Std.int(Math.min(cur, last));
			var col = 0x00FF00;
			if (bot < 0) { bot = 0; col = 0xFF0000; }
			if (top > display_height) { top = display_height; col = 0xFF0000; }
			for (z in bot...top)
			{
				spr.bitmapData.setPixel(Std.int(n), z, col);
			}
			spr.bitmapData.setPixel(Std.int(n), cur, 0x008800);
			last = cur;
		}
		return spr;
	}
	
	public static function amplitude(wf : ArrayBuffer, 
		display_width : Int, display_height : Int, ?bitmap : Bitmap)
	{
		var H = Std.int(display_height);
		var H1 = H >> 1;
		var LIM = display_height / 2 - 1;
		var spr = { if (bitmap != null) bitmap;
			else new Bitmap(new BitmapData(display_width, H, false, 0));}
		var scaleX = wf.length / display_width;
		for (n in 0...display_width)
		{
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1 - LIM), 0x444400);
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1 + LIM), 0x444400);
			spr.bitmapData.setPixel(Std.int(n), Std.int(H1), 0x444400);
		}
		var last = H1;
		var cur = H1;
		for (n in 0...display_width)
		{
			cur = Std.int(wf.get(Std.int(n*scaleX)) * -display_height + display_height);
			var top = Std.int(Math.max(cur, last));
			var bot = Std.int(Math.min(cur, last));
			var col = 0x00FF00;
			if (bot < 0) { bot = 0; col = 0xFF0000; }
			if (top > display_height) { top = display_height; col = 0xFF0000; }
			for (z in bot...top)
			{
				spr.bitmapData.setPixel(Std.int(n), z, col);
			}
			spr.bitmapData.setPixel(Std.int(n), cur, 0x008800);
			last = cur;
		}
		return spr;
	}

}
