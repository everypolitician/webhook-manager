# EveryPolitician App Manager

[![Build Status](https://travis-ci.org/everypolitician/app-manager.svg?branch=master)](https://travis-ci.org/everypolitician/app-manager)

Listens for events from GitHub and 3rd party apps using [EveryPolitician](http://everypolitician.org) data. Allows apps that use EveryPolitician data to submit updates to the data.

The EveryPolitician Bot has [described how to use this service](https://medium.com/@everypolitician/i-webhooks-pass-it-on-703e35e9ee93).

## Installation

Get the code from GitHub

    git clone https://github.com/everypolitician/app-manager
    cd app-manager

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
