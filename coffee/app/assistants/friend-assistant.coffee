class FriendAssistant
  
  constructor: (action) ->
    @listModel =
      items: []

  setup: ->
    StageAssistant.setTheme(@)
    
    @controller.setupWidget(
      "spinner"
      @attributes = {}
      @model = {spinning: true}
    )
    
    # @controller.setupWidget(Mojo.Menu.commandMenu,
    #   { menuClass:'no-fade' },
    #   items:
    #     [
    #       toggleCmd : "friends-cmd",
    #       items: 
    #         [
    #           {}
    #           { label : "Friends", command : "friends-cmd" }
    #           { label : "Submissions", command : "submissions-cmd" }
    #           { label : "Comments", command : "comments-cmd" }
    #           {}
    #         ]
    #     ]
    # )
    
    # @controller.setupWidget 'sub-menu', null, {items: [
    #   {label:$L("all"), command:$L("message inbox")}
    #   {label:$L("unread"), command:$L("message unread")}
    #   {label:$L("messages"), command:$L("message messages")}
    #   {label:$L("comment replies"), command:$L("message comments")}
    #   {label:$L("post replies"), command:$L("message selfreply")}
    #   {label:$L("sent"), command:$L("message sent")}
    # ]}
    
    # @viewMenuModel =
    #   visible: true,
    #   items: [
    #       {items:[{},
    #               { label: 'inbox', command: 'top', icon: "", width: @controller.window.innerWidth - 60},
    #               {icon:'search', submenu: "sub-menu", width: 60},
    #               {}]}
    #   ]
    
    # @controller.setupWidget(Mojo.Menu.viewMenu, { menuClass:'no-fade' }, @viewMenuModel)
    
    @controller.setupWidget("contentarea", {
      itemTemplate: "friend/list-item"
      emptyTemplate: "friend/emptylist"
      nullItemTemplate: "list/null_item_template"
      # swipeToDelete: true
      #addItemLabel: '+ Add'
      }, @listModel)

    @controller.listen("contentarea", Mojo.Event.listTap, @itemTapped)
    # Mojo.Event.listen(@controller.get("contentarea"), Mojo.Event.listDelete, @handleDeleteItem)

  activate: (event) ->
    StageAssistant.defaultWindowOrientation(@, "free")
    @loadFriends()

  deactivate: (event) ->
    
  cleanup: (event) ->
    Mojo.Event.stopListening(@controller.get("contentarea"), Mojo.Event.listTap, @itemTapped)
  
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
  
  scrollToTop: ->
    @controller.getSceneScroller().mojo.scrollTo(0,0, true)
  
  handleCommand: (event) ->
    return if event.type isnt Mojo.Event.command
    
    params = event.command.split(' ')
    
    switch params[0]
      when 'top'
        @scrollToTop()
      #when 'remove-friend'
  
  spinSpinner: (bool) ->
    if bool
      @controller.get('loading').show()
    else
      @controller.get('loading').hide()
