# Notes for SMTP mail

1) run the command in the pull request
- make sure the mail site is the name of your address

2) make sure you update the mail adaptor based on the files changed

3) Emails are instantly sent, but also instantly bounced back. We need
away to halt the emails so that we can see its content, specifically
the URL. How do we do this?

4) run the following two commands which force all emails to be put
into a queue
    - sudo postconf -e "default_transport=hold"
    - sudo postconf -e "local_transport=hold"

5) run: sudo systemctl reload postfix

6) go onto your server and try to login. You should see a BLUE
message that pops up saying something like your email should be 
in our system

7) run: sudo postqueue -p
 - you should see an email that was recently sent

8) run: sudo postcat -vq [QueueID]
 - with QueueID being the email ID from the previous command

9) Huzzah! You should now be able to see the contents of that
specific email, including the URL. Make sure to copy the URL
correctly
    - = symbol at the end of the first line is NOT part of the URL
    - make sure to copy the rest of the URL from the second line
    - =0=0A or whatever is NOT part of the URL

