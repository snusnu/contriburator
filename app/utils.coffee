# usage: log('inside coolFunc', this, arguments);
# paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
window.log = () ->

  log.history = log.history || []
  log.history.push(arguments)
  console.log( Array.prototype.slice.call(arguments)) if this.console

$.fn.updateTimes = () ->
  Contriburator.Utils.updateTimes(this)

$.fn.readableTime = (attr) ->
  attr ?= 'title'
  for el in $(this)
    $(el).text(Contriburator.Utils.readabeTime(parseInt($(el).attr(attr))))

Contriburator.Utils =

  updateTimes: (element) ->

    element = element ? $('body')
    $('.timeago',  element).timeago()
    $('.duration', element).readableTime()
    this

  readableTime: (duration) ->

    days    = Math.floor(duration / 86400)
    hours   = Math.floor(duration % 86400 / 3600)
    minutes = Math.floor(duration % 3600  / 60)
    seconds = duration % 60

    if days > 0
      'more than 24 hrs'
    else
      result = []
      if hours   > 0 then result.push(hours + ' hrs')
      if minutes > 0 then result.push(minutes + ' min')
      if seconds > 0 then result.push(seconds + ' sec')
      result.join(', ')

  loadTemplates: ->

    templates = {}
    for el in $('script[type="text/x-js-template"]')
      do (el)->
        name = _($(el).attr('name').split('/')).last()
        if name[0] == '_'
          Handlebars.registerPartial(name.replace('/', '_'), source)
        templates[name] = Handlebars.compile($(el).html())
        null

     templates

