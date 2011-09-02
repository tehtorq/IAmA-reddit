var User;
User = (function() {
  function User() {}
  User.prototype.initialize = function(callback) {
    return this.callback = callback;
  };
  User.prototype.create = function(params) {
    return new Request(this.callback).request('http://www.reddit.com/api/register/' + params.user, 'post', params, 'user-create');
  };
  User.prototype.login = function(params) {
    return new Request(this.callback).request('http://www.reddit.com/api/login', 'post', params, 'user-login');
  };
  User.prototype.logout = function(params) {
    var cookie;
    cookie = new Mojo.Model.Cookie("reddit_session");
    cookie.remove();
    return new Banner("Logged out").send();
  };
  User.prototype.comments = function(params) {
    return new Request(this.callback).get('http://reddit.com/user/' + params.user + '.json', {}, 'user-comments');
  };
  User.prototype.about = function(params) {
    return new Request(this.callback).get('http://www.reddit.com/user/' + params.user + '/about.json', {}, 'user-about');
  };
  return User;
})();