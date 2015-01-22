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
	import flash.events.EventDispatcher;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamInfo;
	
	import mx.logging.ILogger;

	public class Participant extends EventDispatcher
	{
		public function Participant(nc:NetConnection, id:String, userName:String, protocol:String, self:Boolean):void
		{
			_id = id;
			_userName = userName;
			_protocol = protocol;
			_netConnection = nc;
			_topology = SessionManager.MEDIA_NONE;
			_self = self;
			
			if (!self)
			{
				_video = new Video();
				_video.width = 320;
				_video.height = 240;
			}
		}
		
		public function get self():Boolean
		{
			return _self;
		}
		
		public function get protocol():String
		{
			return _protocol;
		}
		
		public function get id():String
		{
			return _id;
		}
		
		public function get userName():String
		{
			return _userName;
		}
		
		public function get video():Video
		{
			return _video;
		}
		
		public function set receiveAudio(receive:Boolean):void
		{
			_receiveAudio = receiveAudio;
			if (_netStream)
			{
				_netStream.receiveAudio(receive);
			}
		}
		
		public function get receiveAudio():Boolean
		{
			return _self ? false : _receiveAudio;
		}
		
		public function set receiveVideo(receive:Boolean):void
		{
			_receiveVideo = receiveVideo;
			if (_netStream)
			{
				_netStream.receiveVideo(receive);
			}
		}
		
		public function get receiveVideo():Boolean
		{
			return _self ? false : _receiveVideo;
		}
		
		public function get streamInfo():NetStreamInfo
		{
			if (_netStream)
			{
				return _netStream.info;
			}
			
			return null;
		}
		
		public function set topology(topology:String):void
		{
			_logger.debug("Participant: " + _userName + " changing: " + _topology + " -> " + topology);
			
			if (_topology != topology)
			{
				_topology = topology;
				
				if (_self)
				{
					return;
				}
				
				if (_netStream)
				{
					_logger.debug("Closing last stream...");
					_netStream.close();
					_netStream = null;
				}
				
				if (SessionManager.MEDIA_CS == topology)
				{
					_netStream = new NetStream(_netConnection);
				}
				else if (SessionManager.MEDIA_DIRECT == topology)
				{
					_netStream = new NetStream(_netConnection, _id);
				}
				
				_netStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				_netStream.play(_userName);
				_logger.debug("Playing stream '"+_userName+"'");
				
				_video.attachNetStream(_netStream);
			}
		}
		
		private function netStatusHandler(e:NetStatusEvent):void
		{
			_logger.debug("Participants: " + _userName + ": " + e.info.code);
		}
		
		private var _protocol:String  = null;
		private var _userName:String = null;
		private var _id:String = null;
		
		// subscribing stream
		private var _netStream:NetStream = null;
		
		private var _netConnection:NetConnection = null;
		
		private var _video:Video = null;
		
		private var _topology:String;
		
		private var _receiveAudio:Boolean = true;
		private var _receiveVideo:Boolean = true;
		
		private var _self:Boolean = false;
		
		private static const _logger:ILogger = Logger.getLogger("SessionManager");
	}
}