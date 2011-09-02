class Linky

Linky.parse = (url) ->
  type = undefined
  url = url.unescapeHTML()

  if ((url.indexOf('.jpg') >= 0) or
   (url.indexOf('.jpeg') >= 0) or
   (url.indexOf('.png') >= 0) or
   (url.indexOf('.gif') >= 0) or
   (url.indexOf('.bmp') >= 0))
    type = 'image';
  else if url.indexOf('http://www.youtube.com/') >= 0
    type = 'youtube_video'  
  else
    # fix for http://imgur.com/a/3Jc87/MP8VI.jpg

    if ((url.indexOf('http://i.imgur.com/') is 0) or (url.indexOf('http://imgur.com/') is 0)) and (url.lastIndexOf('/') < 20)
      if url.indexOf('imgur.com/a/') isnt -1
        type = 'web'
      else
        type = 'image'

        if url.indexOf('?') >= 0
          url = url.replace('?', '.jpg?')
        else
          url += '.jpg'
    else
      type = 'web'
      
      temp_url = url.replace(/^http\:\/\//i, "")
      temp_url = temp_url.replace(/^www\./i, "")
      temp_url = temp_url.replace(/^reddit\.com/i, "")
      temp_url = temp_url.replace(/^file\:\/\//i, "")

      # http://www.reddit.com/r/comics/hgh

      if temp_url.indexOf('/r/') is 0
        temp_url = temp_url.replace(/^\/r\//i, "")
        temp_url = temp_url.replace(/\//, "")

        return {type: type, url: url, subtype: 'reddit', reddit: temp_url}

  {type: type, url: url, subtype: 'none'}

