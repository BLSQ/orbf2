$(document).ready(function() {
  if ($("select#periods").length === 0) {
    return;
  }

  const updateDisplayedInvoices = function() {
    const periods = $("select#periods").val();
    const orgunits = $("select#orgunits").val();
    const codes = $("select#codes").val();

    $(".invoice-container").each(function() {
      $invoice = $(this);
      const period = $invoice.data("period").toString();
      const visible =
        periods &&
        periods.includes(period) &&
        orgunits &&
        orgunits.includes($invoice.data("orgunit")) &&
        codes &&
        codes.includes($invoice.data("code"));
      if (visible) {
        $invoice.show();
      } else {
        $invoice.hide();
      }
    });
  };
  $("select#periods").on("change", updateDisplayedInvoices);
  $("select#orgunits").on("change", updateDisplayedInvoices);
  $("select#codes").on("change", updateDisplayedInvoices);

  updateDisplayedInvoices();
});
