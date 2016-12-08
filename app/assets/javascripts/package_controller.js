$(document).ready(function() {
    $('.sol-powered').each(function(i) {
        var $sol_selector = $(this);
        $sol_selector.searchableOptionList({
            data: $sol_selector.data('url'),
            showSelectAll: true,
            allowNullSelection: false,
            maxHeight: '250px',
            selectionDestination: $sol_selector.data('selection'),
            texts: {
                quickDelete: '<i class="fa fa-trash text-danger" aria-hidden="true"></i>',
                searchplaceholder: $sol_selector.data('placeholder')
            }
        });
    });
});
