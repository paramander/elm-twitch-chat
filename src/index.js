'use strict';

// elm-css
require( './Stylesheets' );

// inject bundled Elm app into body
var Elm = require( './Twitch' );

var Flags = {
  username: process.env.TWITCH_USERNAME,
  oauth: process.env.TWITCH_OAUTH_TOKEN,
  channel: process.env.TWITCH_CHANNEL,
}

Elm.Twitch.embed( document.getElementById('Twitch'), Flags );
