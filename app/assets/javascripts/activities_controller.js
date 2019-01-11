$(function() {
  adapt_input_visibility = function() {
    var action = this.value
    var $inputs = $(this)
      .parent()
      .parent()
      .find(".state-mapping-form");
    $inputs.each(function() {
      var $input = $(this);
      if (action  === $input.data("action")) {
        $input.show();
      } else {
        $input.hide();
      }
    });
  };

  $(".state-mapping-action").on("change", adapt_input_visibility);
  $(".state-mapping-action").each(adapt_input_visibility);
});