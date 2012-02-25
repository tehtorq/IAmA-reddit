class FriendAssistant extends BaseAssistant
  
  constructor: (params) ->
    super
    
    @listModel =
      items: []

  setup: ->
    super
    
    @controller.setupWidget "spinner", @attributes = {}, @model = {spinning: true}
    
    @controller.setupWidget("contentarea", {
      itemTemplate: "friend/list-item"
      emptyTemplate: "list/empty_template"
      nullItemTemplate: "list/null_item_template"
      # swipeToDelete: true
      #addItemLabel: '+ Add'
      }, @listModel)
      
    if @showBackNavigation()
      @viewMenuModel = {
        visible: true,
        items: [
          {label: $L('Back'), icon:'', command:'back', width:80}
        ]
      }

      @controller.setupWidget(Mojo.Menu.commandMenu, { menuClass:'no-fade' }, @viewMenuModel)

  activate: (event) ->
    super
    
    @addListeners(
      [@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped]
      [@controller.get("contentarea"), Mojo.Event.hold, @itemHold]
    )
  
  ready: ->
    @loadFriends()
  
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
      uh: @getModHash()
      type: 'friend'
  
  loadFriends: ->
    @spinSpinner(true)
    @listModel.items.clear()
    @controller.modelChanged(@listModel)
    
    new Friend(@).list()

  handleFriendsResponse: (response) ->
    return if response.readyState isnt 4
    @spinSpinner(false)
    
    friends = response.responseText.match(/\.reddit\.com\/user\/([^\/]+)/g)
    Mojo.Log.info(JSON.stringify(friends))
    return unless friends? and friends.length > 0
    
    _.each friends, (friend) =>
      @listModel.items.push({'name': friend.replace(/\.reddit\.com\/user\//, '').replace(/\//, '')})

    @controller.modelChanged(@listModel)

  itemTapped: (event) =>
    item = event.item
    AppAssistant.cloneCard(@controller, {name:"user"}, {user:item.name})
    
  itemHold: (event) =>
    event.preventDefault()
    element_tapped = event.target
    thing = event.srcElement.up('.thing-container')    
    friend = thing.id

    @controller.popupSubmenu({
               onChoose: @handleFriendActionSelection,
               #placeNear:element_tapped,
               items: [
                 {label: $L("Message"), command: "message-cmd #{friend}"}]
               })
  
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
        @controller.stageController.pushScene({name:"compose-message"}, {to:params[1]})
