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
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.NetConnection;
	import flash.utils.Timer;
	
	import mx.logging.ILogger;

	[Event(name="success", type="flash.evenets.Event")]
	[Event(name="error", type="flash.evenets.Event")]
	[Event(name="failed", type="flash.evenets.Event")]
	[Event(name="change", type="flash.events.Event")]
	
	public class ConnectionManager extends EventDispatcher
	{
		public static const SUCCESS:String = "success";
		public static const FAILED:String = "failed";
		public static const ERROR:String = "error";
		public static const CHANGE:String = "change";
		
		public function set host(host:String):void
		{
			_host = host;
		}
		
		public function set application(application:String):void
		{
			_application = application;
		}
		
		public function set user(user:String):void
		{
			_user = user;
		}
		
		public function set meeting(meeting:String):void
		{
			_meeting = meeting;
		}
		
		public function register(rtmp:Boolean):void
		{
			if (!((_host && _host.length > 0)
				&& (_application && _application.length > 0)
				&& (_user && _user.length > 0)
				&& (_meeting && _meeting.length > 0)))
			{
				dispatchEvent(new Event(ERROR));
				return;
			}
			
			var protocol:String;
			if (rtmp)
			{
				protocol = "rtmp://";
			}
			else
			{
				protocol = "rtmfp://";	
			}
			
			_connection = new NetConnection();
			_connection.addEventListener(NetStatusEvent.NET_STATUS, connectionHandler);
			try
			{
				_connection.connect(protocol + _host + "/" + _application, _user, _meeting);
			}
			catch (e:Error)
			{
				_logger.debug("Argument error");
				dispatchEvent(new Event(ERROR));
				return;
			}
			
			if (!rtmp)
			{
				_rtmfpTimer = new Timer(ConnectTimeout, 1);
				_rtmfpTimer.addEventListener(TimerEvent.TIMER_COMPLETE, rtmfpTimeoutHandler);
				_rtmfpTimer.start();
			}
		}
		
		private function rtmfpTimeoutHandler(e:TimerEvent):void
		{
			_logger.debug("RTMF connection timeout, using RTMP");
			
			dispatchEvent(new Event(CHANGE));
			
			_connection.close();
			_connection = null;
			
			register(true);
		}
		
		public function unregister():void
		{
			// unregister from server
			if (_connection)
			{
				_connection.close();
				_connection = null;
			}
			
			if (_rtmfpTimer)
			{
				_rtmfpTimer.stop();
				_rtmfpTimer = null;
			}
		}
		
		public function get connected():Boolean
		{
			return (_connection && _connection.connected);
		}
		
		public function get neerID():String
		{
			if (connected)
			{
				return _connection.nearID;
			}
			
			return null;
		}
		
		public function isRtmfp():Boolean
		{
			if (connected)
			{
				return "rtmfp" == _connection.protocol;
			}
			
			return false;
		}
		
		public function get connection():NetConnection
		{
			if (connected)
			{
				return _connection;
			}
			
			return null;
		}
		
		private function connectionHandler(e:NetStatusEvent):void
		{	
			_logger.debug("Connection status: " + e.info.code);
			
			if (_rtmfpTimer)
			{
				_rtmfpTimer.stop();
				_rtmfpTimer = null;
			}
			
			if ("NetConnection.Connect.Success" == e.info.code)
			{	
				dispatchEvent(new Event(SUCCESS));
			}
			else if ("NetConnection.Connect.Failed" == e.info.code)
			{
				dispatchEvent(new Event(FAILED));
			}
		}
		
		private const ConnectTimeout:int = 10000;
		
		private var _host:String = null;
		private var _application:String = null;
		private var _user:String = null;
		private var _meeting:String = null;
		
		private var _connection:NetConnection = null;
		
		private var _rtmfpTimer:Timer = null;
		
		private static const _logger:ILogger = Logger.getLogger("ConnectionManager");
	}
}