var Debugger;
Debugger = (function() {
  function Debugger() {}
  Debugger.prototype.debug = function(value) {
    var key, string, _i, _len;
    string = "";
    for (_i = 0, _len = value.length; _i < _len; _i++) {
      key = value[_i];
      string += key + " => " + value[key] + "\n";
    }
    return Mojo.Log.info(string);
  };
  return Debugger;
})();