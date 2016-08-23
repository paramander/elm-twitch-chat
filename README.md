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

## Shortcomings

I haven't been able to figure out JSONP requests in Elm. Twitch disallows all origins except `*.twitch.tv` on their servers.
They assume people consuming the API use JSONP to circumvent this. So this means that in order to use this script via `localhost`,

I have tried to implement a VERY HACKY JSONP solution. It uses global three global callbacks so it's very much anti-Elm. It also forced me to go a `Native` direction because you can't pass back a `Task` from ports. It needs to be a `Task`, because it will be chained with other `Task`s.

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
