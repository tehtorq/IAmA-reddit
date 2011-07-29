
Array.prototype.unique = function() {
  var a = [], i, l = this.length;

  for( i=0; i<l; i++ ) {
    if(a.indexOf(this[i]) < 0 ) { 
      a.push( this[i] );
    }
  }
  return a;
};