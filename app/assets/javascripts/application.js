// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require sol/sol-2.0.0
//= require mermaid.min
//= require jquery.textcomplete.min
//= require jquery_ujs
//= require jquery-ui/autocomplete
//= require autocomplete-rails
// require turbolinks
//= require bootstrap
//= require bootstrap-datepicker
//= require cocoon
//= require_tree .

$(document).ready(function() {
  mermaid.initialize({
    startOnLoad: true,
    flowchart: {
      useMaxWidth: false,
      htmlLabels: true
    }
  });

  $("a.external").each(function() {
    $(this).append(' <i class="fa fa-external-link external-link"></i> ');
  });

  $("form[data-update-target]").on("ajax:complete", function(
    evt,
    data,
    status,
    xhr
  ) {
    var target = $(this).data("update-target");
    $("#" + target).html(data.responseText);
  });

  $(".popper").popover({
    container: "body",
    html: true,
    content: function() {
      return $(this)
        .find(".popper-content")
        .html();
    }
  });
  // one popover at a time
  $("body").on("click", function(e) {
    $('[data-toggle="popover"]').each(function() {
      //the 'is' for buttons that trigger popups
      //the 'has' for icons within a button that triggers a popup
      if (
        !$(this).is(e.target) &&
        $(this).has(e.target).length === 0 &&
        $(".popover").has(e.target).length === 0
      ) {
        $(this).popover("hide");
      }
    });
  });

  var filter_table = function(field_selector, table_selector) {
    $(field_selector).keyup(function() {
      filter = new RegExp($(this).val(), "i");
      $(table_selector+" tbody tr").filter(function() {
        $(this).each(function() {
          found = false;
          $(this)
            .children()
            .each(function() {
              content = $(this).html();
              if (content.match(filter)) {
                found = true;
              }
            });
          if (!found) {
            $(this).hide();
          } else {
            $(this).show();
          }
        });
      });
    });
 }

  filter_table("#searchEquation","#equationsTable")
  filter_table("#searchMeta","#metaTable")

});
