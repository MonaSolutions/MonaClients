package {
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author tj
	 */
	public class FLVContainer extends ByteArray {
	
		private var _startTime:uint = uint.MAX_VALUE;
		
		public function FLVContainer() {
			super();
		}
		
		public function resetTime():void {
			_startTime = uint.MAX_VALUE;
		}
		
		public function writeFLVPacket(isVideo:Boolean,time:uint,data:ByteArray):void {
			writeByte(isVideo ? 0x09 : 0x08);
			
			writeByte((data.length>>16) & 0xFF);
			writeByte((data.length>>8) & 0xFF);
			writeByte(data.length & 0xFF);
			// time on 3 bytes
			if(_startTime>time)
				_startTime=time;
			time -= _startTime;
			writeByte((time>>16)& 0xFF);
			writeByte((time>>8) & 0xFF);
			writeByte(time & 0xFF);
			
			// unknown 4 bytes set to 0
			writeUnsignedInt(0);
			/// payload
			writeBytes(data);
			/// footer
			writeUnsignedInt(11+data.length);
		}
		
	}

}