function ComposeMessageAssistant(action) {
	/* this is the creator function for your scene assistant object. It will be passed all the
	   additional parameters (after the scene name) that were passed to pushScene. The reference
	   to the scene controller (this.controller) has not be established yet, so any initialization
	   that needs the scene controller should be done in the setup function below. */

  this.action = action.action;  
  this.url = 'http://reddit.com' + '/message/compose/';
  
}

ComposeMessageAssistant.prototype.recipientModel = { items : [] };
ComposeMessageAssistant.prototype.subjectModel = { items : [] };
ComposeMessageAssistant.prototype.bodyModel = { items : [] };
ComposeMessageAssistant.prototype.captchaModel = { items : [] };

ComposeMessageAssistant.prototype.setup = function() {
  StageAssistant.setTheme(this);
  
	/* this function is for setup tasks that have to happen when the scene is first created */

	/* use Mojo.View.render to render view templates and add them to the scene, if needed */

	/* setup widgets here */

  this.controller.setupWidget("recipientTextFieldId",
    { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
    this.recipientModel
    );

  this.controller.setupWidget("subjectTextFieldId",
    { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
    this.subjectModel
    );

  this.controller.setupWidget("bodyTextFieldId",
    { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, multiline: true },
    this.bodyModel
    );

  this.controller.setupWidget("captchaTextFieldId",
    { focusMode : Mojo.Widget.focusSelectMode, textCase : Mojo.Widget.steModeLowerCase, maxLength : 30 },
    this.captchaModel
    );

  this.controller.setupWidget("sendButton", {}, { label : "Send"});

	/* add event handlers to listen to events from widgets */

  Mojo.Event.listen(this.controller.get("sendButton"), Mojo.Event.tap, this.sendMessage.bind(this));
 
};

ComposeMessageAssistant.prototype.activate = function(event) {
  StageAssistant.defaultWindowOrientation(this, "up");
	
  this.displayComposeMessage();
};

ComposeMessageAssistant.prototype.deactivate = function(event) {
	/* remove any event handlers you added in activate and do any other cleanup that should happen before
	   this scene is popped or another scene is pushed on top */

};

ComposeMessageAssistant.prototype.cleanup = function(event) {
	/* this function should do any cleanup needed before the scene is destroyed as
	   a result of being popped off the scene stack */
};

ComposeMessageAssistant.prototype.displayComposeMessage = function(object) {
  this.fetchHTMLComposePage();
}

ComposeMessageAssistant.prototype.sendMessage = function() {

  var to = this.recipientModel.value;
  var subject = this.subjectModel.value;
  var body = this.bodyModel.value;
  var captcha = this.captchaModel.value;

  var postdata = {to: to,
                 subject: subject,
                 text: body,
                 captcha: captcha,
                 iden: this.iden,
                 uh: this.modhash};

	new Ajax.Request(		
    'http://www.reddit.com/api/compose',
		{
			method : "post",      
      postBody: postdata,
      parameters: {
        customHttpHeaders: [
                    'Referer: http://www.reddit.com/message/compose/',
                    'x-reddit-version: 1.1'
              ]
      },
      Referer: 'http://www.reddit.com/message/compose?to=' + to,
      onSuccess : function(inTransport) {
                    var responseText = inTransport.responseJSON;

                    var json_string = Object.toJSON(responseText);
                    
                    if (json_string.indexOf('your message has been delivered') != -1) {
                      this.debug('Success!');
                    }
                    else {
                      this.debug('Failure!');
                    }                  
                  }.bind(this),
      onFailure : function(inTransport) {}.bind(this),
      onException : function(inTransport, inException) {}.bind(this)
    }
	);
}

ComposeMessageAssistant.prototype.fetchHTMLComposePage = function() {
	new Ajax.Request(
		this.url,
		{
			method : "get",     
      onSuccess : function(inTransport) {
                    var responseText = inTransport.responseText;

                    // work out captcha

                    var start = responseText.indexOf('src="/captcha/') + 14;
                    var end = responseText.indexOf('.png', start);

                    if ((start === -1) || (end === -1)) {
                      return false;
                    }

                    this.iden = responseText.substr(start, end - start);

                    // work out uh
                    
                    var startx = responseText.lastIndexOf("modhash: '") + 10;
                    var endx = responseText.indexOf(',', startx);

                    if ((startx === -1) || (endx === -1)) {
                      return false;
                    }

                    this.modhash = responseText.substr(startx, endx - startx - 1);



                    var url = 'http://www.reddit.com/captcha/' + this.iden + '.png';

                    this.controller.get('image_id').src = url;
                    
                    //src="/captcha/AA2DptamWVvQre6ajq8QMcd9pXmsg9Ry.png"
                    //this.debug(url2 + "     " + url);
                    //$('image-id').src = url;
                  }.bind(this),
      onFailure : function(inTransport) {$("contentarea").update("Failure");}.bind(this),
      onException : function(inTransport, inException) {$("contentarea").update("Exception");}.bind(this)
    }
	);
}
