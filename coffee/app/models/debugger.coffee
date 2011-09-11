class Debugger

  debug: (value) ->
    string = ""

    for key in value
      string += key + " => " + value[key] + "\n"

    Mojo.Log.info(string)