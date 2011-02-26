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

Once that's done, make sure to make a copy of the `config.yml.sample`
file and store it as `config.yml`.

    cp config.yml.sample config.yml

Open the `config.yml` using your favorite editor and configure your
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

    rake build:js     # Compile coffee in 'public/app' to js in 'public/js'
    rake build:watch  # Continuously compile .coffee in 'public/app' to .js in 'public/js/app'
    rake build:all    # Same as running 'build:lib' followed by 'build:app'

The next tasks work differently depending on the `RACK_ENV` they are invoked in.
Since the order in which javascript files are referenced from within an
html page is significant, we need to provide the build tasks with enough
information to be able to reference the javascript files in the correct
order.

The [public/app.json](https://github.com/snusnu/contriburator/blob/master/public/app.json)
file contains a simple structure that defines arrays of names for both
the application's `coffeescript` files at [public/app](https://github.com/snusnu/contriburator/tree/master/public/app) and `javascript` libs at [public/js/lib](https://github.com/snusnu/contriburator/tree/master/public/js/lib).
Note that the names are given without their file extensions. This is because
the build system will use these names for both `.coffee` and `.js` files.

### development environment

    rake build:app     # Compile 'public/app/*.coffee' to 'public/js/app/*.js'
    rake build:lib     # This is a no-op in the development environment

### production environment

    rake build:app     # Compile, combine and minify 'public/app/*.coffee' to 'public/js/app-min.js'
    rake build:lib     # Combine and minify 'public/js/lib/*.js' to 'public/js/lib-min.js'

## Serving the javascript files in different environments

Depending on the `RACK_ENV` you used to start your server, the
application will either serve minified or regular javascript files.

Just like the build tasks, the application uses the [public/app.json](https://github.com/snusnu/contriburator/blob/master/public/app.json) file to figure out the correct order in which to reference the
javascript files from within the html.

### development environment

All regular javascript files (compiled from the [coffescripts](https://github.com/snusnu/contriburator/tree/master/public/app)) will be
referenced from `<script>` tags within the bottom of [public/app.html](https://github.com/snusnu/contriburator/blob/master/public/app.html).

### production environment

Only the minified javascript (`public/js/lib-min.js` and `public/js/app-min.js`)
files will be referenced from `<script>` tags within [public/app.html](https://github.com/snusnu/contriburator/blob/master/public/app.html).

When the server starts up, the `build:all` task will be invoked once, to
make sure that the most recent minified javascript sources are available.
