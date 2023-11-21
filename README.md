# Update cloudflare record

This is a simple and ugly script to update a single __cloudflare A record__ and get notified when it happens via email
Use case: home server, raspberry pi open on network...

# ⚠️ WARNING ⚠

Cloudflare up to now does not support record update trough api for following extensions:  .cf, .ga, .gq, .ml, or .tk

## Suppported OS

- Linux
- macOS

## Usage

```
./script.sh [-s config_file.json]
```

## Installing

Just clone it on your machine

```
git clone https://github.com/CatMonster/update-cloudflare-record.git
```

### Install dependencies

#### Linux

Debian or debian based like Ubuntu

```
sudo apt-get install jq mailutils
```

Fedora

```
sudo dnf install jq mailx
```

Archlinux or arch based

```
sudo pacman -Sy jq mailutils
```

#### macOS

```
brew install jq
```

## Configuring

Now you need to retrive all needed data to make work properly the script

### Cloudflare

Api Key
1) Log into your cloudflare account -> [Cloudflare dashboard](https://dash.cloudflare.com/)
2) Go to [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page
3) Create a token with this permissions:
   ![permissions-screen](https://i.imgur.com/qskalEj.png)
4) You can test if your token is working using the following command:
```
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
     -H "Authorization: Bearer your-token" \
     -H "Content-Type:application/json"
```

### Record

1) Select interested zone
2) Under "Overview" menu you can find the zone id
3) To get the interested `id` for the `record` field, you can get it by using [postman](https://www.getpostman.com/apps) or whatever method you prefer, use that API call to get a full list of all records inside the specific zone: `zones/:zone_identifier/dns_records` (more info inside [cloudflare api doc](https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records)), replace `:zone_identifier` and `your-token` with the keys copied previously.
Here is an example code:
```
curl -X GET "https://api.cloudflare.com/client/v4/zones/:zone_identifier/dns_records" \
     -H "Authorization: Bearer your-token" \
     -H "Content-Type:application/json"
```
5) Take the response and copy the interested `id`

Now you can fill out the [config.json](https://github.com/CatMonster/update-cloudflare-record/blob/master/config.json), under cloudflare object you need to put all retrived data until now like in this exaple below

```json
...

"cloudflare" : {
    "token": "your-token",
    "zones": "zone_id",
    "record": "id"
  },

...
```

#### Mailing system

If __ssmtp__ isn't configured yet, you need to find the working config for your mail provider, Google and stackExchange are best your friends :smirk:, I'm using gmail and [this config](https://unix.stackexchange.com/a/381197/325117) works fine for me.
If your google account uses a two factor authentication, you need to create a custom app password to make it work, [here](https://stackoverflow.com/questions/26736062/sending-email-fails-when-two-factor-authentication-is-on-for-gmail) is a great tutorial about it. 
Here is an example of the final __ssmtp.conf__ :
```
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=your_email@gmail.com

# The place where the mail goes. The actual machine name is required no 
# MX records are consulted. Commonly mailhosts are named mail.domain.com
mailhub=smtp.gmail.com:465

# Where will the mail seem to come from?
rewriteDomain=gmail.com

# The full hostname
# hostname=your_email@gmail.com

AuthUser=your_email@gmail.com
AuthPass=your_email_password/custom_app_password
UseTLS=YES
UseSTARTTLS=NO

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES
```

Inside [config.json](https://github.com/CatMonster/update-cloudflare-record/blob/master/config.json), under mail, you can specify the recipient and a custom subject. If you don't need to send a mail, just leave them blank.

```json
...

  "mail" : {
    "recipient": "",
    "subject": ""
  }

...
```

Any modification at the mail body can be done on [mail_template](https://github.com/CatMonster/update-cloudflare-record/blob/master/mail_template) file.

#### Running periodically

Personally for home use I set a cron running every minute, it's pretty safe because Cloudflare api can be called 1200 times in 5 minutes, for [ipfy.org](https://www.ipify.org/) you can do "millions of requests per minute" as they say; keep that in mind if you are planning to conquest the galaxy.

To set a cron, type ```crontab -e``` and you'll get a file like that
![Image of](https://i.imgur.com/UPHlZrog.png)

Make sure to set system variables to get all commands working as well

```
printenv | grep SHELL && printenv | grep PATH
```

otherwise export them:

```
export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
```

and call your script

```
* * * * * cd /home/user/scripts/update-cloudflare-record/ && ./script.sh -s config.json
```

One little trick, if you don't wish to recieve the terminal output in the emails, you can opt out by placing
```
MAILTO=""
```
in the beginning of your cron :wink:

As mentioned above i run that every minute; by replacing __* * * * *__ you can set whatever time you want. If you are cron noob like me take a look at [crontab guru's website](https://crontab.guru/) and all their [examples](https://crontab.guru/examples.html)

## Info and Docs

Cloudflare api doc --> https://api.cloudflare.com/

# Hope you found this script useful :wave:
