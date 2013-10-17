package
{
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	
	/**
	 * 
	 * @author LC
	 */
	public class Test extends Sprite
	{
		
		private var loader:URLLoader;
		
		public function Test()
		{
			super();
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onCompleteHandle);
			loader.load(new URLRequest('art/spaceship.obj'));
		}
		
		private function onCompleteHandle(event:Event):void
		{
			loader.removeEventListener(Event.COMPLETE, onCompleteHandle);
			var ba:ByteArray = loader.data as ByteArray;
			var s:String = ba.readUTFBytes(ba.bytesAvailable);
			
			var lines:Array = s.split("\n");
			var loop:uint=lines.length;
			for (var i:uint=0; i < loop; ++i)
				parseLine(lines[i]);
			
		}
		
		private function parseLine(s:String):void
		{
			var words:Array = s.split(" ");
			trace(">"+words.length);
			
			
		}
	}
}