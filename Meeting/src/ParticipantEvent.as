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

	public class ParticipantEvent extends Event
	{
		public static const ADD:String = "add";
		public static const REMOVE:String = "remove";
		public static const CHANGE:String = "change";
		
		public function ParticipantEvent(type:String, participant:Participant)
		{
			super(type);
			this._participant = participant;
		}
		
		override public function clone():Event
		{
			return new ParticipantEvent(type, _participant);
		}
		
		public function get participant():Participant
		{
			return _participant;
		}
		
		private var _participant:Participant;
	}
}