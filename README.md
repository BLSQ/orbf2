[ ![Codeship Status for BLSQ/orbf2](https://app.codeship.com/projects/e43559e0-5368-0135-125a-62c2a1758ec6/status?branch=master)](https://app.codeship.com/projects/234954) [![Test Coverage](https://codeclimate.com/github/BLSQ/orbf2/badges/coverage.svg)](https://codeclimate.com/github/BLSQ/orbf2/coverage) [![Code Climate](https://codeclimate.com/github/BLSQ/orbf2/badges/gpa.svg)](https://codeclimate.com/github/BLSQ/orbf2)

# About

![OpenRBF 2.0 logo](https://bluesquarehub.files.wordpress.com/2017/01/logo-openrbf.png?w=151&h=147 "OpenRBF 2.0 ")

A rule engine on top of [dhis2](https://www.dhis2.org/) developed by [Bluesquare](https://bluesquarehub.com/), to let power users describe their Results-Based Financing  scheme.

More info about the tool https://bluesquarehub.com/services/openrbf-2-0/

Created with the support of the [World Bank](http://www.worldbank.org/).

![World Bank logo](http://www.worldbank.org/content/dam/wbr/logo/logo-wb-header-en.svg "World Bank ")

Thanks to the [DHIS2](http://dhis2.org) team for their help and support

![DHIS2 logo](https://www.dhis2.org/sites/all/themes/dhis/logo.png)

# Using

A wizard approach guiding you in the setup of projects

![](./doc/steps.png)

With your rules editor and visual explanation

![activity rule dependency graph](./doc/activity-rule.png)

![payment rule  dependency graph](./doc/payment-rule.png)

each formula will be mapped to a dhis2 data element.

You can easily verify your formula with the invoicing simulation form
with a built-in invoice explainer showing you how was this amount/score calculated

![invoicing explainer](./doc/invoicing-explainer.png)

Every change is tracked and you publish your project draft to be used at a given period.

# Contributing

## Dependencies and config

First setup your local database configuration. We advise to use Postgresql as we make use of the built-in UUID format.

```shell
cp config/database-template.yml config/database.yml
```

edit if necessary

```shell
cp config/application.template.yml config/application.yml
```

you can setup the admin password there

## Setup the db and seed program and project

```shell
rake db:create
rake db:migrate
rake db:seed
```

## Seed a user and program

Using the console or the seed file, create a program (a simple name) and a user connected to it:

```ruby
program = Program.create(code: "Sierra Leone")
program.users.create(
    password:"password",
    password_confirmation:"password",
    email: "admin@orbf.org"
)
```

(this is done inside the seed file if you are in development mode)

## Seed a project

We have an example project that can be created using DHIS2 public instance (https://play.dhis2.org/demo/) to showcase a RBF project configuration:

http://127.0.0.1:3000/setup/seeds

This will generate a "typical" RBF project with quality, quantity & payment rules for you to explore and play with.

## Admin interface

You can access any element in the application using the admin interface at 

http://127.0.0.1:3000/admin

# Tests

Run the tests after any change:

    bin/rspec

# Deploying

## Hosting provider

We recommand Heroku to host the application, but any hosting should work as long as it support Rails & Postgresql. On heroku, deploy should be as simple as:

    git push heroku master
    heroku run rake db:create db:migrate db:seed

## Restoring a testing or production Environment

get a fresh copy using Heroku

```
heroku pg:pull DATABASE_URL orbf2 --app yourappname
```

note that you need a pg 9.6.1 version
