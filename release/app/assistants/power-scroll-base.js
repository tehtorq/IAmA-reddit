var PowerScrollBase;
PowerScrollBase = (function() {
  function PowerScrollBase() {
    this.twoFingerStartBound = this.twoFingerStart.bind(this);
    this.twoFingerEndBound = this.twoFingerEnd.bind(this);
  }
  PowerScrollBase.prototype.activate = function() {
    Mojo.Event.listen(this.controller.document, "gesturestart", this.twoFingerStartBound);
    return Mojo.Event.listen(this.controller.document, "gestureend", this.twoFingerEndBound);
  };
  PowerScrollBase.prototype.deactivate = function() {
    Mojo.Event.stopListening(this.controller.document, "gesturestart", this.twoFingerStartBound);
    return Mojo.Event.stopListening(this.controller.document, "gestureend", this.twoFingerEndBound);
  };
  PowerScrollBase.prototype.twoFingerStart = function(event) {
    return this.gestureStartY = event.centerY;
  };
  PowerScrollBase.prototype.twoFingerEnd = function(event) {
    var gestureDistanceY, scroller;
    gestureDistanceY = event.centerY - this.gestureStartY;
    scroller = this.controller.getSceneScroller();
    if (gestureDistanceY > 0) {
      return scroller.mojo.revealTop();
    } else if (gestureDistanceY < 0) {
      return scroller.mojo.revealBottom();
    }
  };
  return PowerScrollBase;
})();