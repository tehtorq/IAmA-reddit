var ComposeMessageAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
ComposeMessageAssistant = (function() {
  function ComposeMessageAssistant(action) {
    this.action = action.action;
    this.url = 'http://reddit.com' + '/message/compose/';
    this.recipientModel = {
      items: []
    };
    this.subjectModel = {
      items: []
    };
    this.bodyModel = {
      items: []
    };
    this.captchaModel = {
      items: []
    };
    ({
      setup: function() {
        StageAssistant.setTheme(this);
        this.controller.setupWidget("recipientTextFieldId", {
          focusMode: Mojo.Widget.focusSelectMode,
          textCase: Mojo.Widget.steModeLowerCase,
          maxLength: 30
        }, this.recipientModel);
        this.controller.setupWidget("subjectTextFieldId", {
          focusMode: Mojo.Widget.focusSelectMode,
          textCase: Mojo.Widget.steModeLowerCase,
          maxLength: 30
        }, this.subjectModel);
        this.controller.setupWidget("bodyTextFieldId", {
          focusMode: Mojo.Widget.focusSelectMode,
          textCase: Mojo.Widget.steModeLowerCase,
          multiline: true
        }, this.bodyModel);
        this.controller.setupWidget("captchaTextFieldId", {
          focusMode: Mojo.Widget.focusSelectMode,
          textCase: Mojo.Widget.steModeLowerCase,
          maxLength: 30
        }, this.captchaModel);
        this.controller.setupWidget("sendButton", {}, {
          label: "Send"
        });
        return Mojo.Event.listen(this.controller.get("sendButton"), Mojo.Event.tap, this.sendMessage.bind(this));
      }
    });
  }
  ComposeMessageAssistant.prototype.activate = function(event) {
    StageAssistant.defaultWindowOrientation(this, "up");
    return this.displayComposeMessage();
  };
  ComposeMessageAssistant.prototype.deactivate = function(event) {};
  ComposeMessageAssistant.prototype.cleanup = function(event) {};
  ComposeMessageAssistant.prototype.displayComposeMessage = function(object) {
    return this.fetchHTMLComposePage();
  };
  ComposeMessageAssistant.prototype.sendMessage = function() {
    var body, captcha, subject, to;
    to = this.recipientModel.value;
    subject = this.subjectModel.value;
    body = this.bodyModel.value;
    captcha = this.captchaModel.value;
    ({
      postdata: {
        to: to,
        subject: subject,
        text: body,
        captcha: captcha,
        iden: this.iden,
        uh: this.modhash
      }
    });
    return new Ajax.Request('http://www.reddit.com/api/compose', {
      method: "post",
      postBody: postdata,
      parameters: {
        customHttpHeaders: ['Referer: http://www.reddit.com/message/compose/', 'x-reddit-version: 1.1']
      },
      Referer: 'http://www.reddit.com/message/compose?to=' + to,
      onSuccess: __bind(function(inTransport) {
        var json_string, responseText;
        responseText = inTransport.responseJSON;
        json_string = Object.toJSON(responseText);
        if (json_string.indexOf('your message has been delivered') !== -1) {
          return this.debug('Success!');
        } else {
          return this.debug('Failure!');
        }
      }, this),
      onFailure: function(inTransport) {},
      onException: function(inTransport, inException) {}
    });
  };
  ComposeMessageAssistant.prototype.fetchHTMLComposePage = function() {
    return new Ajax.Request(this.url, {
      method: "get",
      onSuccess: __bind(function(inTransport) {
        var end, endx, responseText, start, startx, url;
        responseText = inTransport.responseText;
        start = responseText.indexOf('src="/captcha/') + 14;
        end = responseText.indexOf('.png', start);
        if ((start === -1) || (end === -1)) {
          return false;
        }
        this.iden = responseText.substr(start, end - start);
        startx = responseText.lastIndexOf("modhash: '") + 10;
        endx = responseText.indexOf(',', startx);
        if ((startx === -1) || (endx === -1)) {
          return false;
        }
        this.modhash = responseText.substr(startx, endx - startx - 1);
        url = 'http://www.reddit.com/captcha/' + this.iden + '.png';
        return this.controller.get('image_id').src = url;
      }, this),
      onFailure: __bind(function(inTransport) {
        return $("contentarea").update("Failure");
      }, this),
      onException: __bind(function(inTransport, inException) {
        return $("contentarea").update("Exception");
      }, this)
    });
  };
  return ComposeMessageAssistant;
})();