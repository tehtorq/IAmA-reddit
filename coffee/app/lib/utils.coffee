String.prototype.endsWith = (suffix) ->
  this.indexOf(suffix, this.length - suffix.length) isnt -1
