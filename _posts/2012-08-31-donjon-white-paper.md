---
layout: post
title: "RFC: Donjon, a credentials server"
published: true
tags: sysops web security
summary: |
  I've been bugged by the fact that everyone seems pretty content with unencrypted credentials lying around in the codebases of their apps.

  To fix this, some rely on delivering sensitive information (certificate files, passwords) via Puppet, which is overly complicated and doesn't specifically address the handling of credentials.

  Others, because they work with a PaaS, work around it by having a few select people push the keys and passwords to their host---as done with [Heroku](https://devcenter.heroku.com/articles/config-vars)) for instance.

  Here's my take of what (my) ideal credentials management solution would look like: a Heroku-like, distributed and secure credential management tool.

  What's you opinion?

---

## Envisionment : *donjon*, a simple, standards-based, and secure credentials store for distributed applications

*donjon* is a secure, low-throughput key-value store, built on top of Git (distribution), OpenSSL (encryption) and OpenSSH (authentication and authorisation).

The original use case is distributing secrets for 3rd-party applications (think AWS S3) to web applications without storing them in the codebase, or anywhere in plain text.

Once *donjon* is set up, running a service with an environment containing your credentials is a one-liner (example of a Rack server):

    env `donjon` bundle exec rackup

*donjon* is written in Ruby annd distributed as a Rubygem, but is entirely framework.


### Issues addressed by *donjon*

The way we manage credentials (S3 keys, MySQL passwords, SSL private keys, etc) tends to be insecure and hard to maintain.

- Codebases are littered with clear-text credentials in configuration files;
- Credentials are repeated in multiple projects;
- Some credentials (SSL certificates for instance) are distributed by a central server (puppet, chef); for "security" these credentials and the corresponding codebase are not versioned;
- Because of the above, it is difficult to update or distribute credentials across a complex system (multiple services, machines, codebases);
- We have no way to prevent credentials from being used by a compromised machine/account.



### Base concepts & guidelines

A credential store is just a key/value store with a few specifics:

- it get read often, by multiple clients services;
- it rarely gets written to, and then only by humans;
- it needs to be security-conscious---authorise only specific actors to read or write.

Several if the underlying technical challenges have been solved elsewhere; we're not trying to reinvent the following wheels:

- **authentication and authorisation**: *donjon* uses SSH and/or the system (i.e. filesystem permissions);
- **privacy**: *donjon* uses OpenSSL public key encryption to encrypt credentials;
- **version control and distribution**. *donjon* uses Git to store and distribute (encrypted) credentials.



## Installation & Usage

*donjon* installs as a Ruby gem. Assuming a fairly standard Ruby installation, just run:

    $ gem install donjon
    
Invoke the provided `donjon init` command once to perform setup:

    $ donjon init
    It appears donjon is not configured yet on this account.
    Please provide the url of your donjon Git repository:
    > git@github.com:example.com/donjon
    Cloning into '/tmp/donjon.rRBngZ3m'...
    Configuring...
    I've detected only one SSH identity ~/.ssh/id_dsa, so we'll use that one.
    Self-testing...
    Done.

`donjon` is then just a command that sets and gets credentials:

    $ donjon set AWS_ACCESS_KEY_ID AKIAJYQR456ZDS7I12AB FOO bar_baz
    Encrypting key/value pairs...
    Committing...
    Pushing...
    Self-testing...
    Done.

Call with `get` to return a credential:

    $ donjon get FOO
    bar_baz

Or on its own to return all credentials:

    $ donjon
    AWS_ACCESS_KEY_ID=AKIAJYQR456ZDS7I12AB
    FOO=bar_baz
    

Use it to run commands with an environment that include credentials:

    $ env $(donjon) bundle exec script/server thin

Use the gem to securely obtain credentials on-demand from application code:

    > require 'donjon'
    > donjon.AWS_ACCESS_KEY_ID
    #=> AKIAJYQR456ZDS7I12AB
    



## *donjon* step-by-step setup


### Setting up the *donjon* repository

Just create your repository at Github (or elsewhere), then run `donjon`.
By default this will clone and use the repository to `~/.donjon`.

Test it by adding a first key.

### Adding and removing developers

Ask the new developer for his or her SSH identity (public key, usually in `~/.ssh/id_dsa`).
If necessary they can generate one with 

    new-dev$ ssh-keygen -t dsa

We strongly recommend protecting your SSH keys with a passphrase.

On your machine (or any account already authenticated with *donjon*), simply

    $ donjon peer add
    Please give me the public key of the writer you'd like to authorise:
    > ssh-rsa AAAAB3NzaC1yc2EcXOSI...OuqV3 alice@example.com
    Please name this user [alice]:
    Encrypting all credential with your private key and alice's public key...
    Adding alice's public key to the repository...
    Committing...
    Pushing...
    alice@example.com is now authorized

Removing someone is just as simple:

    $ donjon peer remove alice
    Are you sure you want to remove alice's authorisation? [y/N] y
    Removing credentials encrypted for alice...
    Removing alice's public key...
    Committing...
    Pushing...
    alice@example.com is no longer authorised
    
Remember to also de-authorise them from your organisation's Github account.


### Setting up the *donjon* server

A donjon server is just another peer, simply one that can't push to your shared repository.

- Set up a `deploy` account on `castle.example.com`, for instance.
- Create an SSH key for it.
- Allow it from your local clone, with `donjon peer add`, as above.
- Allow it to pull from your Github account (but not to push).
- Run `donjon init` on the account.

Remember to set up a `cron(8)` job to update the credentials store regularly:

    $ crontab -e
    # update credentials every 10 minutes
    */10 * * * * donjon update
    


### Setting up a *donjon* client

*donjon* leverages (and trusts) SSH for authentication and authorisation.

If a client doesn't have a repository, it will try to call *donjon* over SSH on another machine.

Calling `donjon get my_gey` from a shell (or `donjon.my_key` in Ruby) behaves mostly like calling

    $ ssh donjon.example.com donjon get my_key

The default server name is `donjon`, in the machine's domain name as provided by Ruby's `Socket.gethostname`.

You can control the host *donjon* will connect to by setting `DONJON_SERVER` in your environment.

Remember to setup your server as above, and to allow your client to connect via SSH (using `~/.ssh/authorized_keys` on the server).



## API documentation

### The *donjon* command

    donjon -- a no-frills credentials store
        
    client ramblings:
        $ donjon                        same as "donjon get"
        $ donjon get                    print all available credentials in a format
                                          suitable for a shell's export and env commands
        $ donjon get <key>              print the value of a single credential
    
    dev/server incantations:
        $ donjon init [url]             clone the repository to ~/.donjon
        $ donjon update                 updates the credential store
        $ donjon set <key> <value>      add a key/value pair to the store ("nil" value deletes)
                                          repeat to store multiple pairs.
        $ donjon peer add [name] [key]  authorise a new (human) user for writing
                
    (the dev commands may commit and push to a Git repository)

### Ruby API

    require 'donjon'
    donjon.get   #=> Hash of all credentials
    donjon[key]  #=> value of a single credential



