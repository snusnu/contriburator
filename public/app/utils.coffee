###
usage: log('inside coolFunc', this, arguments);
paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
###

window.log = () ->
  log.history = log.history || []
  log.history.push(arguments)
  console.log( Array.prototype.slice.call(arguments)) if this.console

