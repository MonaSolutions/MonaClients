package
{
	import flash.utils.ByteArray;

	public class P2PSharedObject
	{
		
		public var name:String;
		public var packetLength:uint = 0;
		public var actualFetchIndex:Number = 0;
		public var data:ByteArray;
		public var chunks:Object = new Object();
		
		public function P2PSharedObject()
		{}
	}
}