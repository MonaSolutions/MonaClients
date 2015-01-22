/**
 * ADOBE SYSTEMS INCORPORATED
 * Copyright 2010 Adobe Systems Incorporated
 * All Rights Reserved.
 *
 * NOTICE: Adobe permits you to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 * 
 * Author: Jozsef Vass
 */

package
{
	import flash.events.Event;
	
	public class MessageEvent extends Event
	{
		public static const MESSAGE:String = "message";
		
		public function MessageEvent(type:String, from:String, message:String)
		{
			super(type);
			this._from = from;
			this._message = message;
		}
		
		override public function clone():Event
		{
			return new MessageEvent(type, _from, _message);
		}
		
		public function get from():String
		{
			return _from;
		}
		
		public function get message():String
		{
			return _message;
		}
		
		private var _from:String = null;
		private var _message:String = null;
	}
}