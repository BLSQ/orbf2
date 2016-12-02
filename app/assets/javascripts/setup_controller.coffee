# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  update_ui = (data) ->
    unit_names = $.map(data.item.organisation_units, (unit, i) -> unit.name )
    $('#organisation_units').empty().html '<li>' + unit_names.join('<li>')
    $('#orgunitgroup_message').empty().html(
      [data.item.organisation_units_total,
       'entities available -',
        data.item.organisation_units_count ,
        'in main target group'].join(' '))
    return

  $org_unit_group = $('#organisation_unit_group')

  $org_unit_group.bind 'railsAutocomplete.select', (event, data) ->
    update_ui data

  $(document).ready ->
    id_value = $($org_unit_group.data('id-element')).val()
    if  id_value != ''
      $.ajax
        url: $org_unit_group.data('autocomplete')
        type: 'get'
        data: id: id_value
        success: (data) ->
          update_ui item: data[0]
