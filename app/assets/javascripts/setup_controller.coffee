# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  update_ui = (data) ->
    $('#organisation_units').empty()
    $('#orgunitgroup_message').empty()
    list_str = jQuery.map(data.item.organisation_units, (unit, i) ->
      unit.name
    )
    $('#organisation_units').html '<li>' + list_str.join('<li>')
    $('#orgunitgroup_message').html data.item.organisation_units_total + ' entities available - ' + data.item.organisation_units_count + ' in main target group'
    return

  $('#organisation_unit_group').bind 'railsAutocomplete.select', (event, data) ->
    update_ui data
    return
  $(document).ready ->
    if $('#external_reference').val() != ''
      $.ajax
        url: $('#organisation_unit_group').data('autocomplete')
        type: 'get'
        data: id: $('#external_reference').val()
        success: (data) ->
          update_ui item: data[0]
          return
    return
