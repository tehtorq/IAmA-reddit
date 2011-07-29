
ReplyAssistant = Class.create({

  initialize: function(reply_data) {
    this.reply_data = reply_data;
  },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.bodyModel = { items : [] };

    this.controller.setupWidget("recipientTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      this.model = {value: this.reply_data.user,disabled: false}
    );

    this.controller.setupWidget("bodyTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, multiline: true },
      this.bodyModel
    );

    this.sendButtonModel = {label : "Send"};
    this.controller.setupWidget("sendButton", {type:Mojo.Widget.activityButton}, this.sendButtonModel);

    /* add event handlers to listen to events from widgets */

    this.sendMessageBind = this.sendMessage.bind(this);
    Mojo.Event.listen(this.controller.get("sendButton"), Mojo.Event.tap, this.sendMessageBind);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
    this.controller.get("bodyTextFieldId").mojo.focus();
  },

  deactivate: function(event) {},

  cleanup: function(event) {
    this.reply_data = null;
    Mojo.Event.stopListening(this.controller.get("sendButton"), Mojo.Event.tap, this.sendMessageBind);
  },

  handleCallback: function(params) {
    if (!params || !params.success) {
      return params;
    }

    if (params.type == "comment-reply") {
      this.displayButtonSent();
      new Banner("Replied to " + this.reply_data.user + ".").send();
      this.controller.stageController.popScene({replied: true, comment_id: this.reply_data.thing_id});
    }
  },

  sendMessage: function() {
    this.displayButtonSending();

    var params = {
                   thing_id: this.reply_data.thing_id,
                   text: this.bodyModel.value,
                   uh: this.reply_data.modhash,
                   id: '#commentreply_' + this.reply_data.thing_id,
                   r: this.reply_data.subreddit
                 };

    new Comment(this).reply(params);
  },
  
  editMessage: function() {
    this.displayButtonSending();

    var params = {
                   thing_id: this.reply_data.thing_id,
                   text: this.bodyModel.value,
                   uh: this.reply_data.modhash,
                   r: this.reply_data.subreddit
                 };

    new Comment(this).edit(params);
  },

  displayButtonSend: function() {
    this.controller.get('sendButton').mojo.deactivate();
    this.sendButtonModel.label = "Send";
    this.sendButtonModel.disabled = false;
    this.controller.modelChanged(this.sendButtonModel);
  },

  displayButtonSending: function() {
    this.controller.get('sendButton').mojo.activate();
    this.sendButtonModel.label = "Sending";
    this.sendButtonModel.disabled = true;
    this.controller.modelChanged(this.sendButtonModel);
  },

  displayButtonSent: function() {
    this.controller.get('sendButton').mojo.deactivate();
    this.sendButtonModel.label = "Sent";
    this.sendButtonModel.disabled = false;
    this.controller.modelChanged(this.sendButtonModel);
  }

});
