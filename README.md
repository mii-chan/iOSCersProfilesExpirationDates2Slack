# iOSCersProfilesExpirationDates2Slack

This is the script to post expiration dates of iOS certificates and provisioning profiles to Slack.

## Note
* This script works on Linux. If you would like to run it on your Mac, please ```$ brew install coreutils``` and change all the ```date``` commands to ```gdate``` before execution.

* Please be so careful where you store your .cer and .mobileprovision files. Make sure your files are stored and accessed in a secure way.

* If you do not store your .cer and .mobileprovision files in a git repository, please delete (or comment out) the following lines.
```
cd ${dir_path}
git pull
```

## How to use
### set up variables

```
dir_path="<absolute path to the directory in which your .cer and .mobileprovision files are stored>"

#Slack settings
webhookurl="<Webhook URL>"
channel="<channel name>"
```

### execute
```
./post_ios_cers_and_profiles_expiration_dates_to_slack.sh
```

## License
* MIT License, see LICENSE.txt.

## References
* https://api.slack.com/incoming-webhooks
