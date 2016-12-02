$ ->

  # generic class to improve the rails/jquery autocomplete behaviors
  class AutocompleteImprover
    initialize: (autocomplete_element, update_ui_callback) ->
      # update the ui change auto select
      autocomplete_element.bind 'railsAutocomplete.select', (event, data) ->
        update_ui_callback data

      # load when id filled is already filled at page loading
      id_value = $(autocomplete_element.data('id-element')).val()
      if  id_value != ''
        $.ajax
          url: autocomplete_element.data('autocomplete')
          type: 'get'
          data: id: id_value
          success: (data) ->
            update_ui_callback item: data[0]
            autocomplete_element.val(data[0].value)

  update_ui_entities = (data) ->
    unit_names = $.map(data.item.organisation_units, (unit, i) -> unit.name )
    $('#organisation_units').empty().html '<li>' + unit_names.join('<li>')
    $('#orgunitgroup_message').empty().html(
      [data.item.organisation_units_total,
       'entities available -',
        data.item.organisation_units_count ,
        'in main target group'].join(' '))

  $(document).ready ->
    new AutocompleteImprover().initialize(
      $('#organisation_unit_group'),
      update_ui_entities)
