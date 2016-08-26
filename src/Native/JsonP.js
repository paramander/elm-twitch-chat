var _paramanders$elm_twitch_chat$Native_Jsonp = function() {

  function jsonp(url, callbackName)
  {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      window[callbackName] = function(content)
      {
        callback(_elm_lang$core$Native_Scheduler.succeed(JSON.stringify(content)));
        delete window[callbackName];
      };

      var scriptTag = createScript(url, callbackName);
      document.head.appendChild(scriptTag);
      document.head.removeChild(scriptTag);
    });
  }


  function createScript(url, callbackName)
  {
    var s = document.createElement('script');
    s.type = 'text/javascript';

    if (url.indexOf('?') >= 0)
    {
      s.src = url + '&callback=' + callbackName;
    }
    else {
      s.src = url + '?callback=' + callbackName;
    }

    return s;
  }


  return {
    jsonp: F2(jsonp)
  };

}();
