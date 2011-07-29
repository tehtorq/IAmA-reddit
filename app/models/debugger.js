
Debugger = Class.create({

  debug: function(value) {
    var string = "";

    for (key in value) {
      string += key + " => " + value[key] + "\n";
    }

    Mojo.Log.info(string);
  }

});