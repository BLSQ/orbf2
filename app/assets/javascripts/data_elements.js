$(document).ready(function () {

    var adapt_count = function (input) {
        var dhis2_value = input.val();
        var length = input.val().length;
        var maxLength = input.data("maxlength");
        var remaining = maxLength - length;
        input
            .parent()
            .find(".chars-count")
            .text(remaining);
        var messages = [];
        var dhis2_value_lower = dhis2_value.toLowerCase();

        if (remaining < 0) {
            messages.push(
                "too long : should be " + Math.abs(remaining) + " char shorter"
            );
        }
        var error_messages = input.parent().find(".error-messages");

        if (messages.length > 0) {
            error_messages.text(messages.join(", "));
            error_messages.addClass("error-message");
        } else {
            error_messages.text("");
            error_messages.removeClass("error-message");
        }

        if (messages.length > 0) {
            input.addClass("invalid");
        } else {
            input.removeClass("invalid");
        }
    };

    $(".dhis2-name").keyup(function () {
        var input = $(this);
        adapt_count(input);
    });

    $(".dhis2-name").each(function () {
        var input = $(this);
        adapt_count(input);
    });
});