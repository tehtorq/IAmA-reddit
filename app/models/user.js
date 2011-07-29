
User = Class.create({

  initialize: function(callback) {
    this.callback = callback;
  },

  create: function(params) {
    new Request(this.callback).request('http://www.reddit.com/api/register/' + params.user, 'post', params, 'user-create');
  },

  login: function(params) {
    new Request(this.callback).request('http://www.reddit.com/api/login', 'post', params, 'user-login');
  },
  
  logout: function(params) {
    var cookie = new Mojo.Model.Cookie("reddit_session");
    cookie.remove();

    new Banner("Logged out").send();
  },

  comments: function(params) {
    new Request(this.callback).get('http://reddit.com/user/' + params.user + '.json', {}, 'user-comments');
  },

  about: function(params) {
    new Request(this.callback).get('http://www.reddit.com/user/' + params.user + '/about.json', {}, 'user-about');
  }

});