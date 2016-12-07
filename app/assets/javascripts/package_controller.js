$(document).ready(function() {
    $('.sol-powered').each(function(i) {
        var $data_elements_selector = $(this);
        $data_elements_selector.searchableOptionList({
            data: $data_elements_selector.data('url'),
            showSelectAll: true,
            allowNullSelection: false,
            maxHeight: '250px',
            selectionDestination: $data_elements_selector.data('selection'),
            texts: {
                quickDelete: '<i class="fa fa-trash text-danger" aria-hidden="true"></i>',
                searchplaceholder: $data_elements_selector.data('placeholder')
            }
        });
    });
});
