$(document).ready(function() {

  var register_text_autocomplete = function (){
    $(".fomula-editor").textcomplete([
      {
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
      },
      {
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
      }
    ]);
  }

  register_text_autocomplete();

  $("body").on("cocoon:after-insert", function(e) {
    register_text_autocomplete();
  });

});
