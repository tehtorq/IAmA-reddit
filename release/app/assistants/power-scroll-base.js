/*
PowerScrollBase: a Prototype base class to quickly add power scrolling
to your existing scenes

Created by Ian Beck <http://beckism.com>
Released in the public domain

Many thanks to Jay Canuck and Doug Reeder for the basic idea and code:
- http://pastebin.com/6JqcQT4a
- https://gist.github.com/786358
*/
var PowerScrollBase = Class.create({
    // === $SUPER CALLS ===

    initialize: function() {
        this.twoFingerStartBound = this.twoFingerStart.bind(this);
        this.twoFingerEndBound = this.twoFingerEnd.bind(this);
    },

    activate: function() {
        // Add listeners for two-finger gesture events
        Mojo.Event.listen(this.controller.document, "gesturestart", this.twoFingerStartBound);
        Mojo.Event.listen(this.controller.document, "gestureend", this.twoFingerEndBound);
    },

    deactivate: function() {
        // Stop listening to two-finger gesture events
        Mojo.Event.stopListening(this.controller.document, "gesturestart", this.twoFingerStartBound);
        Mojo.Event.stopListening(this.controller.document, "gestureend", this.twoFingerEndBound);
    },

    // === EVENT METHODS ===

    twoFingerStart: function(event) {
        this.gestureStartY = event.centerY;
    },

    twoFingerEnd: function(event) {
      var gestureDistanceY = event.centerY - this.gestureStartY;
      var scroller = this.controller.getSceneScroller();

      if (gestureDistanceY > 0) {
        scroller.mojo.revealTop();
        //scroller.mojo.scrollTo(0,0, true);            
      } 
      else if (gestureDistanceY < 0) {
        scroller.mojo.revealBottom();
        //var state = scroller.mojo.scrollerSize();
        //new Banner(state.height + "").send();
        //scroller.mojo.scrollTo(0,10000, true);
      }
    }
});