Contriburator =

  Models: {}
  Views:  {}

  Controllers:

    Application: class extends Backbone.Controller

      initialize: ->
        @templates = Contriburator.Utils.loadTemplates()

      templates: {}

      routes:
        '':        'home'

      home: ->
        $('#main').html(@templates['home'])
        this

      run: ->

  start: ->
    Backbone.history  = new Backbone.History
    Contriburator.app = new Contriburator.Controllers.Application
    Contriburator.app.run()
    this

# Fix for [IE8 AJAX payload caching]
# http://stackoverflow.com/questions/1013637/unexpected-caching-of-ajax-results-in-ie8
$.ajaxSetup(cache: false)

$ ->
  Contriburator.start()
  Backbone.history.start()
  this
