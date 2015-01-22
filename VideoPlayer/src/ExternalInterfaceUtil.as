package
{
	import flash.external.ExternalInterface;
	import mx.controls.Alert;
	
	public class ExternalInterfaceUtil
	{
		public static function addExternalEventListener( qualifiedEventName:String, callback:Function,callBackAlias:String ):void
		{
			Alert.show(ExternalInterface.objectID);
			// 1. Expose the callback function via the callBackAlias
			ExternalInterface.addCallback( callBackAlias, callback );
			// 2. Build javascript to execute
			var	jsExecuteCallBack:String = "document.getElementsByName('"+ExternalInterface.objectID+"')[0]."+callBackAlias+"()";
			var jsBindEvent:String = "function(){"+qualifiedEventName+"= function(){"+jsExecuteCallBack+"};}";
			// 3. Execute the composed javascript to perform the binding of the external event to the specified callBack function
			ExternalInterface.call( jsBindEvent );
		}
	}
}