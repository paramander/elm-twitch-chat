//import Dict, List, Maybe, Native.Scheduler //

var jsonpNativeCallback = function () { throw new Exception(); };

elmJsonp = function(content) {
  jsonpNativeCallback(_elm_lang$core$Native_Scheduler.succeed(JSON.stringify(content)));
};

var _paramanders$elm_twitch_chat$Native_Jsonp = function() {

function jsonp(url)
{
  return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
    jsonpNativeCallback = callback;

    var scriptTag = createScript(url);
    document.head.appendChild(scriptTag);
    document.head.removeChild(scriptTag);
  });
}


function createScript(url) {
  var s = document.createElement('script');
  s.type = 'text/javascript';
  s.id = 'dynScript';
  s.src = url + '?callback=elmJsonp';

  return s;
}

return {
  jsonp: jsonp
};

}();
