package {
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.ColorTransform;
	import flash.text.TextField;
	import flash.display.Bitmap;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	[Event(name = "record", type = "flash.events.Event")] 
	[Event(name = "fullscreen", type = "flash.events.Event")] 
	
	/**
	 * ...
	 * @author tj
	 */
	public class ButtonBar extends Sprite {
		
		private const ColorBlue:ColorTransform = new ColorTransform(0, 0, 1);
		private const ColorRed:ColorTransform = new ColorTransform(1, 0, 0);
		private const ColorBlack:ColorTransform = new ColorTransform(0, 0, 0);
		private const ColorWhite:ColorTransform = new ColorTransform(1, 1, 1, 1, 255,255,255);
		private const ColorVisible:ColorTransform = new ColorTransform(1, 1, 1, 1);
		private const ColorInvisible:ColorTransform = new ColorTransform(1, 1, 1, 0);
		
		private var _recordButton:Sprite = new Sprite();
		private var _recordText:TextField = new TextField();
		private var _recordTime:TextField = new TextField();
		
		private var _time:int = 0;
		private var _timer:Timer = new Timer(1000);
		
		[Embed(source = "full-screen-window-icone-4401-32.png")] 
		private var FullScreen:Class;
		private var _btFullscreen:Sprite = new Sprite();
		
		public function ButtonBar(x:int,y:int,w:int,h:int) {
			super();
			
			this.x = x;
			this.y = y;
			graphics.beginFill(0xCCCCCC,0); // transparent for now
			graphics.drawRoundRect(0, 0, w, h, 15, 15);
			graphics.endFill();
			this.height = h;
			this.width = w;
			
			// Button fullscreen
			_btFullscreen.addChild(new FullScreen());
			_btFullscreen.x = w - 120;
			_btFullscreen.y = 5;
			_btFullscreen.width = 40;
			_btFullscreen.height = 40;
			addChild(_btFullscreen);
			
			_btFullscreen.addEventListener(MouseEvent.ROLL_OVER, function onRecordover(e:Event):void { 
				_btFullscreen.transform.colorTransform = ColorBlue; 
			});
			_btFullscreen.addEventListener(MouseEvent.ROLL_OUT, function onRecordOut(e:Event):void { 
				_btFullscreen.transform.colorTransform = ColorVisible; 
			});
			_btFullscreen.addEventListener(MouseEvent.MOUSE_DOWN, function onRecordDown(e:Event):void { dispatchEvent(new Event("fullscreen")); } );
			
			// Button record
			_recordButton.x = w - 60;
			_recordButton.y = 0;
			_recordButton.graphics.beginFill(0xFF0000);
			_recordButton.graphics.drawCircle(20, 25, 20);
			_recordButton.graphics.endFill();
			addChild(_recordButton);
			
			_recordTime.textColor = 0xFFFFFF;
			_recordTime.text = "00:00";
			_recordTime.selectable = false;
			_recordTime.mouseEnabled = false;
			_recordTime.x = w - 55;
			_recordTime.y = 15;
			addChild(_recordTime);
			
			_recordText.textColor = 0xFFFFFF;
			_recordText.alpha = 0;
			_recordText.text = "Record";
			_recordText.x = w - 60;
			_recordText.y = 55;
			addChild(_recordText);
			
			_recordButton.addEventListener(MouseEvent.MOUSE_OVER, function onRecordover(e:Event):void { 
				_recordButton.transform.colorTransform = ColorWhite; 
				_recordTime.transform.colorTransform = ColorBlack;
				_recordText.transform.colorTransform = ColorVisible;
			});
			_recordButton.addEventListener(MouseEvent.MOUSE_OUT, function onRecordOut(e:Event):void { 
				_recordButton.transform.colorTransform = ColorRed; 
				_recordTime.transform.colorTransform = ColorWhite;
				_recordText.transform.colorTransform = ColorInvisible;
			});
			_recordButton.addEventListener(MouseEvent.MOUSE_DOWN, function onRecordDown(e:Event):void { dispatchEvent(new Event("record")); } );
		}
		
		private function onSecondElapsed(event:TimerEvent):void {
			_time++;
			_recordTime.text = (int)(_time / 60) + ":" + (int)(_time % 60);
		}
		
		public function startRecording():void {
			_recordText.text = "Save";
			_time = 0;
			_timer.addEventListener(TimerEvent.TIMER, onSecondElapsed);
			_timer.start();
		}
		
		public function stopRecording():void {
			_recordText.text = "Record";
			_recordTime.text = "00:00";
			_timer.removeEventListener(TimerEvent.TIMER, onSecondElapsed);
			_timer.stop();
		}
		
		public function refreshLayout(x:int, y:int):void {
			this.x = x;
			this.y = y;
		}
	}

}