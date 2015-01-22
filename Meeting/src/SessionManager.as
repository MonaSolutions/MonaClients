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
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamInfo;
	import flash.net.Responder;
	import flash.utils.Timer;
	import mx.logging.ILogger;
	
	[Event(name="topologyChange", type="flash.events.Event")]
	[Event(name="add", type="ParticipantEvent")]
	[Event(name="remove", type="ParticipantEvent")]
	[Event(name="change", type="ParticipantEvent")]
	[Event(name="message", type="MessageEvent")]
	
	public class SessionManager extends EventDispatcher
	{
		public static const MEDIA_DIRECT:String = "media_direct";
		public static const MEDIA_CS:String = "media_cs";
		public static const MEDIA_NONE:String = "media_none";
		
		public static const TOPOLOGY_CHANGE:String = "topologyChange";
		
		public static const MaxDirectPeers:int = 3;
		
		public static const MEDIA_CONNECTING:String = "connecting";
		public static const MEDIA_CONNECTED:String = "connected";
		
		public function SessionManager(meeting:String, user:String):void
		{
			_meeting = meeting;
			_userName = user;
			_connectionTimer = new Timer(MediaConnectionTimeout);
			_connectionTimer.addEventListener(TimerEvent.TIMER, mediaTimeout);
			
			_participants = new Vector.<Participant>();
			
			_settings = new Settings();
		}
		
		public function get settings():Settings {
			return _settings;
		}
		
		public function updateSettings():void {
			if (Settings.SET_MICROPHONE == settings.action) {
				_settings.microphoneIndex = settings.microphoneIndex;
				if (_outgoingStream && _sendAudio){
					refreshMicro();
				}
			}
			else if (Settings.SET_CAMERA == settings.action) {
				_settings.cameraIndex = settings.cameraIndex;
				if (_outgoingStream && _sendVideo)
					_outgoingStream.attachCamera(Camera.getCamera(settings.cameraIndex.toString()));
			}
			else if (Settings.SET_CODEC == settings.action) {
				_settings.codec = settings.codec;
				var microphone:Microphone = getMicrophone();
				if (microphone) {
					microphone.codec = _settings.codec;
					if (SoundCodec.SPEEX == _settings.codec) {
						microphone.framesPerPacket = 1;
						microphone.encodeQuality = _settings.speexQuality;
					}
					else
						microphone.rate = _settings.nellymoserRate;
				}
			}
		}
		
		public function set connection(netConnection:NetConnection):void
		{
			if (!netConnection)
				return;
			
			_netConnection = netConnection;
			var o:Object = new Object();
			o.participantChanged = function():void {
				updateParticipants();
			}
			o.onMessage = function (from:String, message:String):void {
				if (from != _userName) {
					var e:MessageEvent = new MessageEvent(MessageEvent.MESSAGE, from, message);
					dispatchEvent(e);
				}
			}
			_netConnection.client = o;
			
			updateParticipants();
		}
		
		public function get sentAudioRate():int
		{
			var audioRate:int = 0;
			
			if (_outgoingStream)
			{
				var streams:Array = _outgoingStream.peerStreams;
				if (streams.length > 0)
				{
					for each (var n:NetStream in streams)
					{
						var info:NetStreamInfo = n.info;
						audioRate += info.audioBytesPerSecond;
					}
				}
				else
				{
					audioRate = _outgoingStream.info.audioBytesPerSecond;
				}
			}
			
			return audioRate;
		}
		
		public function get sentVideoRate():int
		{
			var videoRate:int = 0;
			
			if (_outgoingStream)
			{
				var streams:Array = _outgoingStream.peerStreams;
				if (streams.length > 0)
				{
					for each (var n:NetStream in streams)
					{
						var info:NetStreamInfo = n.info;
						videoRate += info.videoBytesPerSecond;
					}
				}
				else
				{
					videoRate = _outgoingStream.info.videoBytesPerSecond;
				}
			}
			
			return videoRate;
		}
		
		public function set sendAudio(send:Boolean):void
		{
			_sendAudio = send;
			
			if (_outgoingStream) {
				if (send)
					refreshMicro();
				else
					_outgoingStream.attachAudio(null);
			}
		}
		
		// Refresh settings of microphone
		private function refreshMicro():void {
			var microphone:Microphone = getMicrophone();
			if (microphone) {
				
				microphone.setUseEchoSuppression(_settings.echoSuppression);
				microphone.setSilenceLevel(_settings.silenceLevel);
				microphone.codec = _settings.codec;
				microphone.framesPerPacket = 1;
				microphone.encodeQuality = _settings.speexQuality;
				microphone.rate = _settings.nellymoserRate;
				
				_outgoingStream.attachAudio(microphone);
			}
		}
		
		public function set sendVideo(send:Boolean):void
		{
			_sendVideo = send;
			
			if (_outgoingStream)
			{
				if (send)
				{
					_outgoingStream.attachCamera(Camera.getCamera(_settings.cameraIndex.toString()));
				}
				else
				{
					_outgoingStream.attachCamera(null);
				}
			}
		}
		
		private function updateParticipants():void
		{
			var r:Responder = new Responder(participantsReceived, participantsError);
			_netConnection.call("getParticipants", r, _meeting);
		}
		
		public function getMicrophone():Microphone
		{
			return Microphone.getMicrophone(_settings.microphoneIndex);
		}
		
		private function participantsReceived(participants:Array):void
		{
			_logger.info("Participants: " + participants.length);
			
			var updateMedia:Boolean = false;
			
			// search for new participants
			for each (var p:Object in participants)
			{
				_logger.debug(p.userName);
				
				var exists:Boolean = false;
				for each (var e:Participant in _participants)
				{
					if (p.userName == e.userName)
					{
						exists = true;
						break;
					}
				}
				
				if (!exists)
				{
					// create a new participant
					_logger.info("Participants added: " + p.userName + ": " + p.protocol);
					
					var newParticipant:Participant = new Participant(_netConnection, p.farID, p.userName, p.protocol, p.userName == _userName);
					_participants.push(newParticipant);
					
					dispatchEvent(new ParticipantEvent(ParticipantEvent.ADD, newParticipant));
					
					updateMedia = true;
				}
			}
			
			// search for participants that are removed
			for each (var n:Participant in _participants)
			{	
				exists = false;
				for each (var m:Object in participants)
				{	
					if (n.userName == m.userName)
					{
						exists = true;
						break;
					}
				}
				
				if (!exists)
				{
					_logger.info("Participant removed: " + n.userName);
					
					dispatchEvent(new ParticipantEvent(ParticipantEvent.REMOVE, n));
					
					var index:int = _participants.indexOf(n);
					if (index > -1 )
					{
						_participants.splice(index, 1);
					}
					else
					{
						_logger.error("Participants remove error");
					}
					
					updateMedia = true;
				}
			}
			
			if (updateMedia)
			{
				updateMediaTopology();
			}
		}
		
		private function participantsError():void
		{
			_logger.debug("Error while receiving participants from server");
		}
		
		public function getMediaType():String
		{
			if (1 == _participants.length)
			{
				return MEDIA_NONE;
			}
			
			if ("rtmfp" != _netConnection.protocol)
			{
				return MEDIA_CS;
			}
			
			if (_participants.length - 1 >= MaxDirectPeers)
			{
				return MEDIA_CS;
			}
			
			if (_failedDirect)
			{
				return MEDIA_CS;
			}
			
			for each (var p:Participant in _participants)
			{
				if ("rtmp" == p.protocol)
				{
					return MEDIA_CS;
				}
			}
			
			return MEDIA_DIRECT;
		}
		
		public function close():void
		{
			if (_connectionTimer)
			{
				_connectionTimer.stop();
				_connectionTimer = null;
			}
			
			_participants.splice(0, _participants.length);
		}
		
		public function sendMessage(message:String):void
		{
			_netConnection.call("sendMessage", null, _meeting, _userName, message);
		}
		
		/**
		 * Update sending media type. Must call this function when:
		 *  - start/stop sending audio/video
		 *  - participants joins/leaves to reconfigure connection
		 */
		private function updateSendMedia():void
		{
			// change media type
			if (_currentMediaType != getMediaType())
			{
				if (_outgoingStream)
				{
					_outgoingStream.close();
					_outgoingStream = null;
				}
				
				dispatchEvent(new Event(TOPOLOGY_CHANGE));
			}
			
			_currentMediaType = getMediaType();
			
			if (MEDIA_NONE == _currentMediaType)
			{
				_connectionTimer.stop();
				return;
			}
			
			if (!_outgoingStream)
			{
				_logger.info("Publishing media as: " + _currentMediaType);
				
				// attempt 
				if (MEDIA_DIRECT == _currentMediaType)
				{
					_mediaState = MEDIA_CONNECTING;
					_connectionTimer.start();
				}
				else
				{
					_mediaState = MEDIA_CONNECTED;
				}
				
				if (_currentMediaType == MEDIA_DIRECT)
				{
					_outgoingStream = new NetStream(_netConnection, NetStream.DIRECT_CONNECTIONS);	
				}
				else
				{
					_outgoingStream = new NetStream(_netConnection);
				}	
				
				_outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
				var c:Object = new Object();
				c.onPeerConnect = function(n:NetStream):Boolean
				{
					_logger.debug("Peer stream connected");
					
					_mediaState = MEDIA_CONNECTED;
					_connectionTimer.stop();
					return true;
				}
				_outgoingStream.client = c;
				_outgoingStream.publish(_userName);
			}
			
			sendAudio = _sendAudio;
			sendVideo = _sendVideo;
		}
		
		private function netStatusHandler(e:NetStatusEvent):void
		{
			_logger.debug("Publisher status: " + e.info.code);
		}
		
		private function updateReceiveMedia():void
		{
			for each (var p:Participant in _participants)
			{
				p.topology = _currentMediaType;
			}
		}
		
		private function mediaTimeout(e:TimerEvent):void
		{
			_logger.info("Media timeout");
			
			if (MEDIA_CONNECTING == _mediaState)
			{
				_failedDirect = true;
				updateMediaTopology();
			}
		}
		
		private function updateMediaTopology():void
		{
			updateSendMedia();
			updateReceiveMedia();
		}
		
		private const MediaConnectionTimeout:int = 5000;
		
		private var _netConnection:NetConnection = null;
		private var _participants:Vector.<Participant> = null;
		private var _outgoingStream:NetStream = null;
		private var _meeting:String = null;
		private var _userName:String = null;
		private var _currentMediaType:String = MEDIA_NONE;
		private var _connectionTimer:Timer = null;
		private var _mediaState:String;
		private var _failedDirect:Boolean = false;
		
		private var _sendAudio:Boolean = false;
		private var _sendVideo:Boolean = false;
		
		private var _settings:Settings = null;
		
		private static const _logger:ILogger = Logger.getLogger("SessionManager");
	}
}