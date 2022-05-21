# ansible-iredmail

A project containing a playbook for deploying [iRedMail](iredmail.org) and managing iRedAPD settings via ansible

## deploy
[iRedMail](iredmail.org) unattended install

#### Usage
[TO-DO]

## iredapd
A simple ansible playbook for updating iRedAPD settings for allow a specific email address to be used as Relay/Smarhost

#### Usage

Setup the list of email addresses (comma separated) that need to be allowed, inside `iredapd-data.yml` ex:
```
---
email_list: "['smartsender@domain.tld', 'smartsender@domain2.tld']"
```

Run the playbook:
```
ansible-playbook update_iredapd_settings.yaml -i mailservers
```