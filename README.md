## Contriburator

Transparently handles monetary contributions to open source software.

## Prerequisites

In order to be able to compile the `coffeescript` files into `javascript`
and to then minify those for production releases, you need to install

* [node.js](http://nodejs.org)
* [npm](http://npmjs.org/)
* [coffeescript](http://jashkenas.github.com/coffee-script/)

Install `node.js` by following the [install instructions](https://github.com/joyent/node/wiki/Installation).
With `node.js` installed, go ahead and install `npm` by following their
[install instructions](https://github.com/isaacs/npm#readme).

Once you have `node.js` and `npm` installed you can install `coffeescript` using `npm`.

    npm install coffee-script

Once you have done all the above, you're ready to install `contriburator`.

## Installation

To get the sources and all the needed ruby dependencies you first need
to clone the repository and then run `bundle install`.

    git clone https://github.com/snusnu/contriburator.git
    cd contriburator
    bundle install

Once that's done, make sure to make a copy of the `service.sample.yml`
file and store it as `service.yml`.

    cp service.sample.yml service.yml

Open the `service.yml` using your favorite editor and configure your
database connection and github oauth details as indicated by the sample
config.

With a proper database connection details you're now ready to seed the
database.

    bundle exec rake db:seed

This will make sure that the necessary seed data is imported into the
database. In addition to `db:seed`

    bundle exec rake db:automigrate
    bundle exec rake db:autoupgrade

are also available.

## Building the javascript files during development

Compiling coffeescript and preparing the resulting javascript for a
production ready application is handled by the provided rake tasks
inside the `build` namespace.

The following two tasks work the same wether they are invoked in the
`development` or in the `production` environment.

    rake build:compile  # Compile coffee in 'app' to js in 'public/js'
    rake build:watch    # Continuously compile .coffee in 'public/app' to .js in 'public/js/app'

The next task works differently based on the `RACK_ENV` it is invoked in.
Since the order in which javascript files are referenced from within an
html page is significant, we need to provide the `build` task with enough
information to be able to reference the javascript files in the correct
order.

The [build.yml](https://github.com/snusnu/contriburator/blob/master/build.yml)
file contains a simple structure that defines arrays of names for both
the application's [coffeescript files](https://github.com/snusnu/contriburator/tree/master/app) and [javascript libs](https://github.com/snusnu/contriburator/tree/master/public/js/lib).

### development environment

    rake build  # Compile coffeescript files to javascript files

### production environment

    rake build  # Compile coffeescripts (also combine and minify in production)

## Serving the javascript files in different environments

Depending on the `RACK_ENV` that was used to start the server, the
application will either serve minified or regular javascript files.

Just like the `build` task, the application uses the [build.yml](https://github.com/snusnu/contriburator/blob/master/build.yml) file to figure out the correct order in which to reference the
javascript files from within the html.

### development environment

All regular javascript files (compiled from the [coffescripts](https://github.com/snusnu/contriburator/tree/master/app)) will be
referenced from `<script>` tags within the bottom of [public/app.html](https://github.com/snusnu/contriburator/blob/master/public/app.html).

### production environment

Only the minified javascript (`public/js/lib-min.js` and `public/js/app-min.js`)
files will be referenced from `<script>` tags within [public/app.html](https://github.com/snusnu/contriburator/blob/master/public/app.html).

When the server starts up, the `build` task gets invoked once, in order to
make sure that the most recent minified javascript sources are available.
