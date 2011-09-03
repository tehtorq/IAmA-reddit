var Banner;
Banner = (function() {
  function Banner(message) {
    this.message = message;
  }
  Banner.prototype.send = function() {
    return Mojo.Controller.getAppController().showBanner(this.message, {
      source: 'notification'
    });
  };
  return Banner;
})();