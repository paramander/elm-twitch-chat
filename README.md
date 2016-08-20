# Twitch Chat in Elm

This project was done in order to test whether Elm can be used to replace
certain well established pieces of Javascript. One of these is the Twitch
chat. Recently, Twitch has upgraded their chat servers to also support
WebSockets.


## Setup

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
