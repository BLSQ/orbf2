$(document).ready(function() {
  var state_autocomplete = {
    match: /(^|\b)(\w{2,})$/,
    search: function(term, callback) {
      var words = $("#words").data("dictionary");
      callback(
        $.map(words, function(word) {
          var index = word.indexOf(term);
          if (index === 0) {
            return word;
          }
          return null;
        })
      );
    },
    replace: function(word) {
      return word + " ";
    }
  };

  var values_autocomplete = {
    match: /(%{)([\-+\w]*)$/,
    search: function(term, callback) {
      var words = $("#words").data("dictionary");
      callback(
        $.map(words, function(word) {
          var index = word.indexOf("%{" + term);
          if (index === 0) {
            return word;
          }
          return null;
        })
      );
    },
    replace: function(word) {
      return word;
    }
  };

  var register_text_autocomplete = function() {
    $(".fomula-editor").textcomplete([state_autocomplete, values_autocomplete]);
  };

  register_text_autocomplete();

  $("body").on("cocoon:after-insert", function(e) {
    register_text_autocomplete();
  });
});
