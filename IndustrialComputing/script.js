
/***** Socket fonctions ******/

// Start the connection to MonaServer
function startSocket() {
    
    _socket = new WebSocket("ws://" + window.location.host + window.location.pathname);
    _socket.onopen = function(message) {
        document.getElementById("error").value = 'socket opened';
        sendMessage(["initClient"]);  // Ask for current value on Server side
    }
    _socket.onclose = function() { document.getElementById("error").value = 'socket closed'; }
    _socket.onerror = function(event) { document.getElementById("error").value = 'An error occurs'; console.log(event); }
    
    _socket.onmessage = function(msg){
        try { //tente de parser data
            data = JSON.parse(msg.data);
        } catch(exception) {
            data = msg.data;
        }      
        
        switch(data[0]) {
            case "setActuator":
                setActuator(data[1]);
                break;
            case "setPool":
                setPool(data[1]);
                break;
            case "setLamp":
                setLamp(data[1]);
                break;
        }
    }	
}	

// Send an array of arguments to MonaServer
function sendMessage(data) {
	if(typeof data == 'object')
		data = JSON.stringify(data);
	_socket.send(data);
}

/***** Initialisation of elements ******/
function load() {
	
    var svg = document.getElementById("canvassvg");
    var svgDoc = svg.contentDocument;
    svgDoc.onmousemove = mouseMove;
    svgDoc.onmouseup = mouseUp;
    svgDoc.ontouchmove = touchMove;
    svgDoc.ontouchstart = mouseDown;
    svgDoc.ontouchend = mouseUp;
    //svgDoc.addEventListener('MSPointerMove', function() { alert("test 2"); }, false);
    
    // Actuator elements
    _actuator = svgDoc.getElementById("actuator");
    _cursor = svgDoc.getElementById("cursor");
    _minCursor = parseInt(_cursor.getAttribute("x"));
    _maxCursor = _minCursor + 100;
    _cursor.onmousedown = mouseDown;
    _counterActuator = svgDoc.getElementById("couterActuator");
    _actuatorSize = parseInt(_actuator.getAttribute("width"));
    _minActuator = _actuatorSize;
    _counterActuator.textContent = _actuatorSize;
    _cursor.style.cursor = "pointer";
    
    // pool elements
    _counterPool = svgDoc.getElementById("counterPool");
    _pool = svgDoc.getElementById("pool");
    _minPool = parseInt(_pool.getAttribute("height"));
    _poolSize = 0;
    _counterPool.textContent = _poolSize;
    _btPlus = svgDoc.getElementById("btPlus");
    _btPlus.onmousedown = function() { sendMessage(["onPoolAdd", _poolSize]); };
    _btMinus = svgDoc.getElementById("btMinus");
    _btMinus.onmousedown = function() { sendMessage(["onPoolDel", _poolSize]); };
    _btMinus.style.cursor = _btPlus.style.cursor = "pointer";
    
    // lamp elements
    _lamp = svgDoc.getElementById("lamp");
    _btON = svgDoc.getElementById("btON");
    _btON.onmousedown = function() { sendMessage(["onLamp", true]); };
    _btOFF = svgDoc.getElementById("btOFF");
    _btOFF.onmousedown = function() { sendMessage(["onLamp", false]); };
    _btOFF.style.cursor = _btON.style.cursor = "pointer";
    _lampON = true;
    
    startSocket();
}

/***** Pool functions ******/

// Called from Mona
function setPool(value) {
    
    _poolSize = value;
    _pool.setAttribute("height", _minPool + (_poolSize*3));
    _counterPool.textContent = _poolSize;
}

/***** Actuator functions *****/
_control = false; // interaction's flag
function mouseDown() {
	_control = true;
}

_oldValue=0;
function mouseMove(event) {
	if(!_control)
		return;
	var value = event.clientX;
	moveSlider(value);
}

function touchMove(event) {
	var touchList = event.changedTouches;
	if(!_control || touchList.length == 0)
		return;
    var value = parseInt(touchList[0].pageX);
    moveSlider(value);
}

function moveSlider(value) {
    if(value<_minCursor)
		value=_minCursor;
	else if(value>_maxCursor)
		value=_maxCursor;
	if(_oldValue==value) 
		return;
	_oldValue=value;
	_cursor.setAttribute( "x",value);
    _actuatorSize = _minActuator + (value-_minCursor);
    _counterActuator.textContent = _actuatorSize;
    _actuator.setAttribute( "width", _actuatorSize);
}

function mouseUp() {
    if(!_control)
		return;
	_control = false;
    var value = parseInt(_cursor.getAttribute("x"));
	sendMessage(["onCursor",value-_minCursor]);
}

// Called from Mona
function setActuator(value) {
    if (!_control)
        _cursor.setAttribute("x",value+_minCursor);
    _actuatorSize = _minActuator + value;
    _counterActuator.textContent = _actuatorSize;
    _actuator.setAttribute( "width", _actuatorSize);
}

/***** Lamp functions ******/

function setLamp(lampON) {
    
    _btOFF.style.visibility = lampON? "visible" : "hidden";
    _btON.style.visibility = lampON? "hidden" : "visible";
    _lamp.style.fill = lampON? "#ffe680" : "#cccccc";
}



