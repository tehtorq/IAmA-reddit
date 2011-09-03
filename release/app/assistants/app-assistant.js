
AppAssistant = Class.create({

  considerForNotification: function(params) {
    if (!params) {
      return;
    }

    if (params.success) {
      new Banner("Action completed.").send();
    }
    else {
      new Banner("Action not completed.").send();
    }
  },
  
  handleLaunch: function(params) {
    if (params.dockMode|| params.touchstoneMode) {
      this.launchDockMode();
    }
    else {
      AppAssistant.cloneCard(null, {name:"frontpage"});
    }
  },
  
  launchDockMode: function() {
    var dockStage = this.controller.getStageController('dock');
    if (dockStage) {
      dockStage.window.focus();
    } else {
      var f = function(stageController) {
        stageController.pushScene('dock', {dockmode:true});
      }.bind(this);
      this.controller.createStageWithCallback({name: 'dock', lightweight: true}, f, "dockMode");	
    }
  }
  
});

AppAssistant.cloneCard = function(assistant, sceneArguments, sceneParameters){
  var samecard = StageAssistant.cookieValue("prefs-samecard", "off");
  
  if ((samecard == "on") && (StageAssistant.stages.length > 0)) {
    assistant.controller.stageController.pushScene(sceneArguments, sceneParameters);
    return;
  }
  
  // only allow one card for prefs
  
  if (sceneArguments && (sceneArguments.name == 'prefs')) {
    var stageController = Mojo.Controller.getAppController().getStageController("prefs");
    
    if (stageController) {
       stageController.activate();
       return;
    }
  }

  var pushCard = function(stageController) {
    if (sceneArguments) {
      stageController.pushScene(sceneArguments, sceneParameters);
    }
    else {
      stageController.pushScene("frontpage");
    }
  };

  var cardname = "NewCardStage" + Math.floor(Math.random()*10000);
  
  if (sceneArguments && (sceneArguments.name == 'prefs')) {
    cardname = "prefs";
  }
  
  StageAssistant.stages.push(cardname);

  var appController = Mojo.Controller.getAppController();
  appController.createStageWithCallback({name: cardname, lightweight: true}, pushCard.bind(this), "card");
};
