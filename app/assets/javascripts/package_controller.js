$(document).ready(function() {

    $('.sol-simple').each(function(i) {
        var $sol_selector = $(this);
        // fa5: change to fas and fa-trash-alt
        $sol_selector.searchableOptionList({
            showSelectAll: true,
            selectionDestination: $sol_selector.data('selection'),
            texts: {
                quickDelete: '<i class="fa fa-trash text-danger" aria-hidden="true"></i>',
                searchplaceholder: $sol_selector.data('placeholder')
              }
        });
    });
    $('.sol-powered').each(function(i) {
        var $sol_selector = $(this);
        // fa5: change to fas and fa-trash-alt
        $sol_selector.searchableOptionList({
            data: $sol_selector.data('url'),
            showSelectAll: true,
            allowNullSelection: true,
            maxHeight: '250px',
            selectionDestination: $sol_selector.data('selection'),
            texts: {
                quickDelete: '<i class="fa fa-trash text-danger" aria-hidden="true"></i>',
                searchplaceholder: $sol_selector.data('placeholder')
            },
            converter: function (sol, rawDataFromUrl) {
              // TODO  perhaps no more string index of but hash lookup
                selected_ids = sol.$originalElement.data("selected")
                var arrayLength = rawDataFromUrl.length;
                for (var i = 0; i < arrayLength; i++) {
                  if (selected_ids.indexOf(rawDataFromUrl[i].value) !== -1) {
                    rawDataFromUrl[i].selected = true
                  }
                }

               return rawDataFromUrl;
           }
        });
    });
});
