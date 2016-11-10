'use strict';

// elm-css
require( './Stylesheets' );

// inject bundled Elm app into body
var Elm = require( './Twitch' );

Elm.Twitch.embed( document.getElementById('Twitch') );
