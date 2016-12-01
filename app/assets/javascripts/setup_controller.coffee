# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
  update_ui = (data) ->
    $('#organisation_units').empty()
    $('#orgunitgroup_message').empty()
    arr = jQuery.map(data.item.organisation_units, (unit, i) ->
      unit.name
    )
    $('#organisation_units').html '<li>' + arr.join('<li>')
    $('#orgunitgroup_message').html data.item.organisation_units_total + ' entities available - ' + data.item.organisation_units_count + ' in main target group'
  $('#organisation_unit_group').bind 'railsAutocomplete.select', (event, data) ->
    update_ui (data)
    return

  $.ajax $('#organisation_unit_group').data('autocomplete'),
    type: 'get'
    data:
      term: $('#organisation_unit_group').val()
    dataType: 'application/json'
    success: (response) ->
      console.log(response)
      update_ui(JSON.parse(response))
