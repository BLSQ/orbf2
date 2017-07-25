# Context

![alt text](https://bluesquarehub.files.wordpress.com/2017/01/logo-openrbf.png?w=151&h=147 "OpenRBF 2.0 ")

A rule engine on top of [dhis2](https://www.dhis2.org/) developed by [Bluesquare](https://bluesquarehub.com/), to let power users describe their Results-Based Financing  scheme.

More info about the tool https://bluesquarehub.com/services/openrbf-2-0/

# Contributing

## dependencies and config

pg

```
cp config/database-template.yml config/database.yml
```
edit if necessary


```
cp config/application.template.yml config/application.yml
```

## setup the db and seed program and project

```
rake db:create
rake db:migrate
rake db:seed
```
## Seed a user and program

```
program = Program.create(code: "seria")
program.users.create(   
    password:"password",
    password_confirmation:"password",
    email: "...@bluesquare.org"
)
```

## Seed a project

http://127.0.0.1:3000/setup/seeds


## Restoring a testing or production Environment

get a fresh copy

```
heroku pg:pull DATABASE_URL scorpiocopy --app orbf2-prod
```

note that you need a pg 9.6.1 version
