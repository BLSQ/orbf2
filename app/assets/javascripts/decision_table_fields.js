$(document).ready(function () {
  $(".decision-table-content-download").on("click", function(event) {
    const content = event.currentTarget.attributes.data.value
    const blob = new Blob([content], {
      type: 'text/csv;charset=utf-8'
    });
    const csvUrl = URL.createObjectURL(blob);
    const filename = `${event.currentTarget.className}-${event.currentTarget.id}`;
    $(this)
      .attr({
        'download': filename,
        'href': csvUrl
      });
  });
})