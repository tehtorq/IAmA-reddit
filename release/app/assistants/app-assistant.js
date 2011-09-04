var AppAssistant;
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
AppAssistant = (function() {
  function AppAssistant() {}
  AppAssistant.prototype.considerForNotification = function(params) {
    if (params == null) {
      return;
    }
    if (params.success) {
      return new Banner("Action completed.").send();
    } else {
      return new Banner("Action not completed.").send();
    }
  };
  AppAssistant.prototype.handleLaunch = function(params) {
    if (params.dockMode || params.touchstoneMode) {
      return this.launchDockMode();
    } else {
      return AppAssistant.cloneCard(null, {
        name: "frontpage"
      });
    }
  };
  AppAssistant.prototype.launchDockMode = function() {
    var dockStage, f;
    dockStage = this.controller.getStageController('dock');
    if (dockStage) {
      return dockStage.window.focus();
    } else {
      f = __bind(function(stageController) {
        return stageController.pushScene('dock', {
          dockmode: true
        });
      }, this);
      return this.controller.createStageWithCallback({
        name: 'dock',
        lightweight: true
      }, f, "dockMode");
    }
  };
  return AppAssistant;
})();
AppAssistant.cloneCard = function(assistant, sceneArguments, sceneParameters) {
  var appController, cardname, pushCard, samecard, stageController;
  samecard = StageAssistant.cookieValue("prefs-samecard", "off");
  if ((samecard === "on") && (StageAssistant.stages.length > 0)) {
    assistant.controller.stageController.pushScene(sceneArguments, sceneParameters);
    return;
  }
  if ((sceneArguments != null) && (sceneArguments.name === 'prefs')) {
    stageController = Mojo.Controller.getAppController().getStageController("prefs");
    if (stageController != null) {
      stageController.activate();
      return;
    }
  }
  pushCard = function(stageController) {
    if (sceneArguments != null) {
      return stageController.pushScene(sceneArguments, sceneParameters);
    } else {
      return stageController.pushScene("frontpage");
    }
  };
  cardname = "NewCardStage" + Math.floor(Math.random() * 10000);
  if ((sceneArguments != null) && (sceneArguments.name === 'prefs')) {
    cardname = "prefs";
  }
  StageAssistant.stages.push(cardname);
  appController = Mojo.Controller.getAppController();
  return appController.createStageWithCallback({
    name: cardname,
    lightweight: true
  }, pushCard.bind(this), "card");
};