
Banner = Class.create({

  initialize: function(message) {
    this.message = message;
  },

  send: function() {
    Mojo.Controller.getAppController().showBanner(this.message, {source: 'notification'});
  }
  
});
