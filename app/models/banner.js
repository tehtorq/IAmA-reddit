var Banner;
Banner = (function() {
  function Banner() {}
  Banner.prototype.initialize = function(message) {
    return this.message = message;
  };
  Banner.prototype.send = function() {
    return Mojo.Controller.getAppController().showBanner(this.message, {
      source: 'notification'
    });
  };
  return Banner;
})();