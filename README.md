# EveryPolitician Webhook Manager

[![Build Status](https://travis-ci.org/everypolitician/webhook-manager.svg?branch=master)](https://travis-ci.org/everypolitician/webhook-manager)

Listens for events from GitHub and 3rd party apps using [EveryPolitician](http://everypolitician.org) data and passes them on as webhooks in the same manner as GitHub's webhooks, featuring:

* JSON payload containing `countries_json_url` and `pull_request_url`
* signed (with the secret you provided) header: `X-EveryPolitician-Signature` 

This is superuseful if you want your app to be alerted whenever the EveryPolitician data changes.
The EveryPolitician Bot has [described how to use this service in more detail](https://medium.com/@everypolitician/i-webhooks-pass-it-on-703e35e9ee93).

We're running this service for you at https://everypolitician-app-manager.herokuapp.com/

## Developers only: Installation

Get the code from GitHub

    git clone https://github.com/everypolitician/webhook-manager
    cd webhook-manager

Configure the environment by copying `.env.example` and following the instructions inside to configure the app.

    cp .env.example .env
    vi .env

Then use vagrant to build a VM with all the dependencies installed:

    vagrant up

## Usage

Log in to the vagrant VM and start the app server and worker with foreman:

    vagrant ssh
    foreman start

Then visit <http://localhost:5000> to view the app.

To run the tests use the following:

    vagrant ssh
    bundle exec rake test
