<p align="center"><img alt="Guild Wars 2 RPC" src="https://me.ihlecloud.de/img/logo.png" height="76"></p></img>
<h1 align="center">Icinga2 Discord Notifications</h1>
<p align="center" style="margin-bottom: 0px !important;">
  <img width="400" src="img/example1.png" alt="Example" align="center">
</p>
<br>
<h3 align="center">
    <a href="https://github.com/n1tr0-5urf3r/icinga2-discord-notifications/releases/">Download Latest
    </a>・
    <a href="https://exchange.icinga.com/n1tr0-5urf3r">Other Projects</a>・<a href="https://www.paypal.com/donate/?hosted_button_id=KXMYX49C6MLLN">Donate</a></h3>

---

## Features
This plugin allows you to send your icinga2 notifications to your discord channel.
All the information shown in the email notification will be added to a discord embed.


![example](img/example1.png "Example")
![example](img/example2.png "Example")

---

## How to set up
You can find an example configuration for icinga2 in the `conf.d` folder. Simply append them to your configuration and make sure that you assign the correct host and contact groups. Fill in the webhook URL into the `users.conf` file. You can specify several webhooks via users and groups.

Additionally, copy the contents of the `scripts` folder to your icinga2 installation, e.g. `etc/icinga2/scripts` and make sure that they are executable. Fill out the missing value for `THUMBNAIL_URL`.

---

## Donation
If you like my work please support me with a donation :) 

[![](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=KXMYX49C6MLLN)
