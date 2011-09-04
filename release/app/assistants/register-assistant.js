var RegisterAssistant;
RegisterAssistant = (function() {
  function RegisterAssistant() {
    ({
      this.usernameModel: {},
      this.passwordModel: {},
      this.captchaModel: {}
    });
  }
  RegisterAssistant.prototype.setup = function() {
    StageAssistant.setTheme(this);
    this.controller.setupWidget("textFieldId", {
      focusMode: Mojo.Widget.focusSelectMode,
      textCase: Mojo.Widget.steModeLowerCase,
      maxLength: 30
    }, this.usernameModel);
    this.controller.setupWidget("passwordFieldId", {
      focusMode: Mojo.Widget.focusSelectMode,
      textCase: Mojo.Widget.steModeLowerCase,
      maxLength: 30
    }, this.passwordModel);
    this.controller.setupWidget("captchaTextFieldId", {
      focusMode: Mojo.Widget.focusSelectMode,
      textCase: Mojo.Widget.steModeLowerCase,
      maxLength: 30
    }, this.captchaModel);
    this.activityButtonModel = {
      label: "create account"
    };
    this.controller.setupWidget("registerButton", {
      type: Mojo.Widget.activityButton
    }, this.activityButtonModel);
    this.registerBind = this.register.bind(this);
    return Mojo.Event.listen(this.controller.get("registerButton"), Mojo.Event.tap, this.registerBind);
  };
  RegisterAssistant.prototype.activate = function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
    this.usernameModel.value = null;
    this.passwordModel.value = null;
    this.captchaModel.value = null;
    this.iden = null;
    return this.fetchCaptcha();
  };
  RegisterAssistant.prototype.deactivate = function(event) {};
  RegisterAssistant.prototype.cleanup = function(event) {
    return Mojo.Event.stopListening(this.controller.get("registerButton"), Mojo.Event.tap, this.registerBind);
  };
  RegisterAssistant.prototype.displayButtonRegistering = function() {
    this.controller.get('registerButton').mojo.activate();
    this.activityButtonModel.label = "creating account";
    this.activityButtonModel.disabled = true;
    return this.controller.modelChanged(this.activityButtonModel);
  };
  RegisterAssistant.prototype.displayButtonRegister = function() {
    this.controller.get('registerButton').mojo.deactivate();
    this.activityButtonModel.label = "create account";
    this.activityButtonModel.disabled = false;
    return this.controller.modelChanged(this.activityButtonModel);
  };
  RegisterAssistant.prototype.handleCallback = function(params) {
    if (params == null) {
      return params;
    }
    if (params.type === 'user-create') {
      if (params.success) {
        return this.handleRegisterResponse(params.response);
      } else {
        return this.displayButtonRegister();
      }
    } else if (params.type === 'load-captcha') {
      return this.handleCaptchaResponse(params.response);
    }
  };
  RegisterAssistant.prototype.register = function() {
    this.displayButtonRegistering();
    ({
      params: {
        captcha: this.captchaModel.value,
        email: '',
        id: '#login_reg',
        iden: this.iden,
        op: 'reg',
        passwd: this.passwordModel.value,
        passwd2: this.passwordModel.value,
        reason: '',
        renderstyle: 'html',
        user: this.usernameModel.value,
        api_type: 'json'
      }
    });
    return new User(this).create(params);
  };
  RegisterAssistant.prototype.handleRegisterResponse = function(response) {
    var json;
    json = response.responseJSON.json;
    this.displayButtonRegister();
    if (json.data != null) {
      return this.registerSuccess(json);
    } else {
      return this.registerFailure(json);
    }
  };
  RegisterAssistant.prototype.registerSuccess = function(response) {
    var cookie, modhash;
    cookie = response.data.cookie;
    modhash = response.data.modhash;
    new Mojo.Model.Cookie("reddit_session").put(cookie);
    new Banner("Created " + this.usernameModel.value).send();
    return this.menu();
  };
  RegisterAssistant.prototype.registerFailure = function(response) {
    this.fetchCaptcha();
    return new Banner(response.errors[0][1]).send();
  };
  RegisterAssistant.prototype.fetchCaptcha = function() {
    return new Request(this).post('http://www.reddit.com/api/new_captcha', {
      uh: ''
    }, 'load-captcha');
  };
  RegisterAssistant.prototype.handleCaptchaResponse = function(response) {
    var matches, url;
    matches = response.responseText.match(/[0-9A-Za-z]{32}/);
    this.iden = matches[0];
    url = 'http://www.reddit.com/captcha/' + this.iden + '.png';
    return this.controller.get('image_id').src = url;
  };
  RegisterAssistant.prototype.menu = function() {
    return this.controller.stageController.swapScene({
      name: "frontpage",
      transition: Mojo.Transition.crossFade
    });
  };
  return RegisterAssistant;
})();