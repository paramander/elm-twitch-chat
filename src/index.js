'use strict';

// elm-css
require( './Stylesheets' );

// inject bundled Elm app into body
var Elm = require( './Twitch' );

var app = Elm.Twitch.embed( document.getElementById('Twitch') );

app.ports.scrollChat.subscribe(function(_) {
  var chatDiv = document.getElementById('ChatDiv');
  if (chatDiv === null) {
    console.err('cannot find chat div');
    return;
  }

  if (chatDiv.scrollTop > chatDiv.scrollHeight * 0.9 - chatDiv.clientHeight) {
    requestAnimationFrame(function() {
      var messages = chatDiv.getElementsByClassName("twitchChat_Message");
      var lastAdded = messages[messages.length - 1];
      var lastAddedHeight = lastAdded.getBoundingClientRect().height;

      chatDiv.scrollTop = ( chatDiv.scrollHeight - chatDiv.clientHeight ) + lastAddedHeight;
    });
  }
});
