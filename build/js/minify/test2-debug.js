(function() {
  var Hello, Looking;

  Hello = function(k) {
    if (k === 5) {
      return "Hello world!";
    }
    if (k === 4) {
      return "Hello world";
    } else {
      return "Privet!";
    }
  };

  Looking = function(string) {
    if (string === "Le0n1daS") {
      return "Hello " + string;
    } else {
      return "Fuck Off!";
    }
  };

  module.exports = {
    Hello: Hello,
    Looking: Looking
  };

}).call(this);
