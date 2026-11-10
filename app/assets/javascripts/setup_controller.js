(function() {
  $(function() {
    var AutocompleteImprover, nothing, update_ui_entities;
    AutocompleteImprover = (function() {
      function AutocompleteImprover() {}

      AutocompleteImprover.prototype.initialize = function(autocomplete_element, update_ui_callback) {
        var id_value;
        if (autocomplete_element.length === 0) {
          return;
        }
        autocomplete_element.bind('railsAutocomplete.select', function(event, data) {
          return update_ui_callback(data);
        });
        id_value = $(autocomplete_element.data('id-element')).val();
        if (id_value !== '') {
          return $.ajax({
            url: autocomplete_element.data('autocomplete'),
            type: 'get',
            data: {
              id: id_value
            },
            success: function(data) {
              update_ui_callback({
                item: data[0]
              });
              return autocomplete_element.val(data[0].value);
            }
          });
        }
      };

      return AutocompleteImprover;

    })();
    update_ui_entities = function(data) {
      var unit_names;
      unit_names = $.map(data.item.organisation_units, function(unit, i) {
        return unit.name;
      });
      $('#organisation_units').empty().html('<li>' + unit_names.join('<li>'));
      return $('#orgunitgroup_message').empty().html([data.item.organisation_units_total, 'entities available -', data.item.organisation_units_count, 'in main target group'].join(' '));
    };
    nothing = function(data) {
      return "";
    };
    $(document).ready(function() {
      return new AutocompleteImprover().initialize($('#organisation_unit_group'), update_ui_entities);
    });
    return $(document).ready(function() {
      return $('.autocomplete-data-element').each(function(index, element) {
        return new AutocompleteImprover().initialize($(element), nothing);
      });
    });
  });

}).call(this);
