
RegisterAssistant = Class.create({

  initialize: function() {},

  usernameModel: { },
  passwordModel: { },
  captchaModel: { },

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

    this.controller.setupWidget("captchaTextFieldId",
      { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
      this.captchaModel
    );

    this.activityButtonModel = {label : "create account"};
    this.controller.setupWidget("registerButton", {type:Mojo.Widget.activityButton}, this.activityButtonModel);

    /* add event handlers to listen to events from widgets */

    this.registerBind = this.register.bind(this);

    Mojo.Event.listen(this.controller.get("registerButton"), Mojo.Event.tap, this.registerBind);
  },

  activate: function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
    this.usernameModel.value = null;
    this.passwordModel.value = null;
    this.captchaModel.value = null;
    this.iden = null;
    
    this.fetchCaptcha();
  },

  deactivate: function(event) {},

  cleanup: function(event) {
    Mojo.Event.stopListening(this.controller.get("registerButton"), Mojo.Event.tap, this.registerBind);
  },

  displayButtonRegistering: function() {
    this.controller.get('registerButton').mojo.activate();
    this.activityButtonModel.label = "creating account";
    this.activityButtonModel.disabled = true;
    this.controller.modelChanged(this.activityButtonModel);
  },

  displayButtonRegister: function() {
    this.controller.get('registerButton').mojo.deactivate();
    this.activityButtonModel.label = "create account";
    this.activityButtonModel.disabled = false;
    this.controller.modelChanged(this.activityButtonModel);
  },

  handleCallback: function(params) {
    if (!params) {
      return params;
    }

    if (params.type == 'user-create' ) {
      if (params.success) {
        this.handleRegisterResponse(params.response);
      }
      else {
        this.displayButtonRegister();
      }
    }
    else if (params.type == 'load-captcha') {
      this.handleCaptchaResponse(params.response);
    }
  },

  register: function() {
    this.displayButtonRegistering();
    
    var params = {
      captcha: this.captchaModel.value,
      email: '',
      id:	'#login_reg',
      iden:	this.iden,
      op:	'reg',
      passwd:	this.passwordModel.value,
      passwd2:	this.passwordModel.value,
      reason: '',
      renderstyle:	'html',
      user:	this.usernameModel.value,
      api_type: 'json'
    };

    new User(this).create(params);
  },

  handleRegisterResponse: function(response) {
    var json = response.responseJSON.json;
    this.displayButtonRegister();

    if (json.data) {
      this.registerSuccess(json);
    }
    else {
      this.registerFailure(json);
    }
  },

  registerSuccess: function(response) {
    var cookie = response.data.cookie;
    var modhash = response.data.modhash;

    new Mojo.Model.Cookie("reddit_session").put(cookie);
    new Banner("Created " + this.usernameModel.value).send();
    this.menu();
  },

  registerFailure: function(response) {
    this.fetchCaptcha();
    new Banner(response.errors[0][1]).send();
  },

  fetchCaptcha: function() {
    new Request(this).post('http://www.reddit.com/api/new_captcha', {uh: ''}, 'load-captcha');
  },

  handleCaptchaResponse: function(response) {
    // eg:  FkSCAzeJOD3NJBLBJavGHhyxbCU3gEoU

    var matches = response.responseText.match(/[0-9A-Za-z]{32}/);
    this.iden = matches[0];

    var url = 'http://www.reddit.com/captcha/' + this.iden + '.png';
    this.controller.get('image_id').src = url;
  },

  menu: function() {
    this.controller.stageController.swapScene({name:"frontpage",transition: Mojo.Transition.crossFade});
  }
  
});
