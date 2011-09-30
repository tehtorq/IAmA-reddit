
# PowerScrollBase: a Prototype base class to quickly add power scrolling
# to your existing scenes

# Created by Ian Beck <http://beckism.com>
# Released in the public domain

# Many thanks to Jay Canuck and Doug Reeder for the basic idea and code:
# - http://pastebin.com/6JqcQT4a
# - https://gist.github.com/786358

class PowerScrollBase
  
  constructor: ->
    @twoFingerStartBound = @twoFingerStart.bind(@)
    @twoFingerEndBound = @twoFingerEnd.bind(@)
  
  activate: ->
    # Add listeners for two-finger gesture events
    Mojo.Event.listen(@controller.document, "gesturestart", @twoFingerStartBound)
    Mojo.Event.listen(@controller.document, "gestureend", @twoFingerEndBound)

  deactivate: ->
    # Stop listening to two-finger gesture events
    Mojo.Event.stopListening(@controller.document, "gesturestart", @twoFingerStartBound)
    Mojo.Event.stopListening(@controller.document, "gestureend", @twoFingerEndBound)

  twoFingerStart: (event) ->
    @gestureStartY = event.centerY

  twoFingerEnd: (event) ->
    gestureDistanceY = event.centerY - @gestureStartY
    scroller = @controller.getSceneScroller()

    if gestureDistanceY > 0
      scroller.mojo.revealTop()
    else if gestureDistanceY < 0
      scroller.mojo.revealBottom()
