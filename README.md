# Twitch Chat in Elm

This project was done in order to test whether Elm can be used to replace
certain well established pieces of Javascript. One of these is the Twitch
chat. Recently, Twitch has upgraded their chat servers to also support
WebSockets.


## Features

- [x] Receiving messages
- [x] Sending messages
- [x] Emotes
- [x] Subscriber badges
- [x] Turbo badges
- [x] Mod badges
- [x] Global mod badges
- [x] Admin badges
- [x] Staff badges
- [x] Broadcaster badges
- [x] Bits badges (wrong implementation, will have to use the new [badges.twitch.tv](https://badges.twitch.tv) endpoint)
- [ ] Cheers
- [x] Resubscribe notices
- [x] Subscribe notices
- [ ] Timeout/ban actions
- [ ] `/me` actions
- [ ] Emote picker
- [ ] Viewer list
- [ ] `@` tagging

## JSONP

The recommended way of consuming the Twitch API is JSONP. `elm-http` has no way
of using JSONP. That's why this project includes some Native Elm code to
solve this. See `src/Jsonp.elm` and `src/Native/Jsonp.js`. It returns a `Task` so
it will fit in any `elm-http` workflow.

## Try it out

The whole setup is automated using `npm`. Make sure you have `node` > 4 and `npm` installed.

```
$ git clone https://gitlab.com/paramanders/elm-twitch-chat.git
$ cd elm-twitch-chat
$ npm install
```

If you haven't installed Elm globally yet, make sure to do so 

```
$ npm install -g elm
```

And install this project's Elm dependencies

```
$ elm package install -y
```


## Serve locally

You can serve the application locally using Webpack. But first, you are required
to enter your username, oauth token and the channel you want to connect to into
`src/Twitch.elm`.

To get an oauth token, you can use [https://twitchapps.com/tmi](https://twitchapps.com/tmi).

** The application will NOT compile until you do this! **

After inserting your username, oauth token and channel, run the command to serve
the application on [localhost:8000](http://localhost:8000):

```
$ npm start
```

and it should look like this:

![Preview](http://i.imgur.com/IOuizaV.gif)
