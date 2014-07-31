# Hack-skype-day

quick hack on skype chat, grabbing all posted gifs and uploading to a Tumblr Blog.

create a creds.json file with the following vars

* file : `skype databse path`
* chatname : `skype chat id`
* service : `email service`
* user: `email address`
* pass: `email address password`
* to: `email to post on tumblr`

```
{
    "file": "/Users/yourUser/Library/Skype/yourskype/main.db",
    "chatname": "chat id",
    "service": "Gmail",
    "user": "account@gmail.com", 
    "pass": "password", 
    "to": "emailToPost@tumblr.com"
}
```

To run 


```
$ npm install
$ npm start
```

more info about email services [http://www.nodemailer.com/](http://www.nodemailer.com/)

currently live [http://u9-gifchat.tumblr.com/](http://u9-gifchat.tumblr.com/)