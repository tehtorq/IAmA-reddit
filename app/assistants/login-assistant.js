
LoginAssistant = Class.create({

  initialize: function() {},

  usernameModel: { },
  passwordModel: { },

  setup: function() {
    StageAssistant.setTheme(this);
    
    this.controller.setupWidget("textFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      this.usernameModel
      );

    this.controller.setupWidget("passwordFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      this.passwordModel
      );

    this.activityButtonModel = {label : "Login"};
    this.controller.setupWidget("loginButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel);

    /* add event handlers to listen to events from widgets */

    this.loginBind = this.login.bind(this);

    Mojo.Event.listen(this.controller.get("loginButton"), Mojo.Event.tap, this.loginBind);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
  },

  deactivate: function(event) {},

  cleanup: function(event) {
    Mojo.Event.stopListening(this.controller.get("loginButton"), Mojo.Event.tap, this.loginBind);
  },

  displayButtonLoggingIn: function() {
    this.controller.get('loginButton').mojo.activate();
    this.activityButtonModel.label = "Logging in";
    this.activityButtonModel.disabled = true;
    this.controller.modelChanged(this.activityButtonModel);
  },

  displayButtonLogin: function() {
    this.controller.get('loginButton').mojo.deactivate();
    this.activityButtonModel.label = "Login";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);
  },

  handleCallback: function(params) {
    if (!params) {
      return params;
    }

    if (params.type == 'user-login' ) {
      if (params.success) {
        this.handleLoginResponse(params.response);
      }
      else {
        this.displayButtonLogin();
      }
    }
  },

  login: function() {
    this.displayButtonLoggingIn();
    
    var params = {
      user: this.usernameModel.value, 
      passwd: this.passwordModel.value, 
      api_type: 'json'
    };

    new User(this).login(params);
  },

  handleLoginResponse: function(response) {
    if (response.readyState != 4) {
      return;
    }
    
    this.displayButtonLogin();
    this.passwordModel.value = '';
    
    if (response.responseJSON) {
      var json = response.responseJSON.json;

      if (json.data) {
        this.loginSuccess(json);
      }
      else {
        this.loginFailure(json);
      }
    }
    else {
      new Banner("Login failure").send();
    }
  },

  loginSuccess: function(response) {
    var cookie = response.data.cookie;
    var modhash = response.data.modhash;

    new Mojo.Model.Cookie("reddit_session").put(cookie);
    new Banner("Logged in as " + this.usernameModel.value).send();
    this.menu();
  },

  loginFailure: function(response) {
    new Banner(response.errors[0][1]).send();
  },

  menu: function() {
    this.controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade});
  }
  
});


//                    http://www.reddit.com/message/inbox/
  //                    http://www.reddit.com/message/sent/
  //                    http://www.reddit.com/message/compose/
  //                    http://www.reddit.com/message/unread/
  //                    http://www.reddit.com/message/messages/
  //                    http://www.reddit.com/message/comments/
  //                    http://www.reddit.com/message/selfreply/
  //
  //                    http://www.reddit.com/user/tehtorq3/
  //                    http://www.reddit.com/user/tehtorq3/comments/
  //                    http://www.reddit.com/user/tehtorq3/submitted/
  //                    http://www.reddit.com/user/tehtorq3/liked/
  //                    http://www.reddit.com/user/tehtorq3/disliked/
  //                    http://www.reddit.com/user/tehtorq3/hidden/
  //
  //                    http://www.reddit.com/prefs/friends/
  //
  //                    http://www.reddit.com/post/friend/
  //                    <input type="hidden" name="type" value="friend"/><input type="text" name="name" id="name"/><button class="btn" type="submit">add</button>
  //
  //                    to view reddit with only submissions from your friends, use reddit.com/r/friends


//json": {
// "errors": [
// [
//"RATELIMIT",
//"you are doing that too much. try again in 14 seconds."
//]
//]
//}
//}

//{
// "json": {
// "errors": [
// [
//"WRONG_PASSWORD",
//"invalid password"
//]
//]
//}
//}

//{
// "json": {
// "errors": [
//],
// "data": {
//"modhash": "cikpd3gbua3c771a044707ad6a61086477f23e4f0f376ece26",
//"cookie": "7150316,2011-04-10T06:18:59,de2e9b1a6df11a251c434887d68a9c309383c2c0"
//}
//}
//}