class FriendAssistant
  
  constructor: (params) ->
    @allow_back = params.allow_back
    @cardname = "card" + Math.floor(Math.random()*10000)
    @listModel =
      items: []

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget(
      "spinner"
      @attributes = {}
      @model = {spinning: true}
    )
    
    @controller.setupWidget("contentarea", {
      itemTemplate: "friend/list-item"
      emptyTemplate: "friend/emptylist"
      nullItemTemplate: "list/null_item_template"
      # swipeToDelete: true
      #addItemLabel: '+ Add'
      }, @listModel)
      
    if Mojo.Environment.DeviceInfo.keyboardAvailable or not @allow_back
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    { label: $L('Friends'), command: 'top', icon: "", width: @controller.window.innerWidth},
                    {}]}
        ]
      }
    else
      @viewMenuModel = {
        visible: true,
        items: [
            {items:[{},
                    {label: $L('Back'), icon:'', command:'back', width:80}
                    { label: $L('Friends'), command: 'top', icon: "", width: @controller.window.innerWidth - 80},
                    {}]}
        ]
      }

    @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    Mojo.Event.listen(@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped)
    Mojo.Event.listen(@controller.get("contentarea"), Mojo.Event.hold, @itemHold)
  
  deactivate: (event) ->
    Mojo.Event.stopListening(@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped)
    Mojo.Event.stopListening(@controller.get("contentarea"), Mojo.Event.hold, @itemHold)
    
  ready: ->
    StageAssistant.defaultWindowOrientation(@, "free")
    @loadFriends()
    
  cleanup: (event) ->
    Request.clear_all(@cardname)
  
  handleCallback: (params) ->
    return params unless params? and params.success

    if params.type is "list-friends"
      @handleFriendsResponse(params.response)
  
  handleDeleteItem: (event) =>
    @removeFriend(event.item)
    @listModel.items.splice(event.index, 1)
    
  removeFriend: (friend) ->
    #id=t2_1tt5n&executed=removed&container=t2_4997w&type=friend&uh=xa4hnfz7th403f9466df9121c1f89a94edd244258facb371bd&renderstyle=html

    new Friend(@).remove
      executed: 'removed'
      id: friend.name #???
      uh: @modhash
      type: 'friend'
  
  loadFriends: ->
    @spinSpinner(true)
    @listModel.items.clear()
    @controller.modelChanged(@listModel)
    
    new Friend(@).list()

  handleFriendsResponse: (response) ->
    return if response.readyState isnt 4
    @spinSpinner(false)
    
    friends = response.responseText.match(/http:\/\/www\.reddit\.com\/user\/([^\/]+)/g)
    return unless friends? and friends.length > 0
    
    # work out uh
              
    startx = response.responseText.lastIndexOf("modhash: '") + 10
    endx = response.responseText.indexOf(',', startx)
    
    return false if (startx is -1) or (endx is -1)

    @modhash = response.responseText.substr(startx, endx - startx - 1)
    
    _.each friends, (friend) =>
      @listModel.items.push({'name': friend.replace(/http:\/\/www\.reddit\.com\/user\//, '').replace(/\//, '')})

    @controller.modelChanged(@listModel)

  itemTapped: (event) =>
    item = event.item
    AppAssistant.cloneCard(@, {name:"user"}, {user:item.name})
    
  itemHold: (event) =>
    event.preventDefault()
    element_tapped = event.target
    thing = event.srcElement.up('.thing-container')    
    friend = thing.id

    @controller.popupSubmenu({
               onChoose: @handleFriendActionSelection,
               placeNear:element_tapped,
               items: [
                 {label: $L("Message"), command: "message-cmd #{friend}"}]
               })
  
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
  
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    params = event.command.split(' ')
    
    switch params[0]
      when 'top'
        @scrollToTop()
      when 'back'
        @controller.stageController.popScene()
        
  handleFriendActionSelection: (command) =>
    return unless command?

    params = command.split(' ')

    switch params[0]
      when 'message-cmd'
        @controller.stageController.pushScene({name:"compose-message"}, {to:params[1],allow_back: true})
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
