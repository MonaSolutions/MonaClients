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
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	
	public class Logger
	{
		public static function setTarget():void
		{
			mTarget = new TraceTarget();
			mTarget.filters = ["*"];
			mTarget.level = LogEventLevel.ALL;
			mTarget.includeTime = true;
			mTarget.includeLevel = true;
			mTarget.includeCategory = true;
		}
		
		public static function getLogger(category:String):ILogger
		{
			if (!mTarget)
			{
				setTarget();
			}
			
			Log.addTarget(mTarget);
			return Log.getLogger(category);
		}
		
		private static var mTarget:TraceTarget = null;
	}
}