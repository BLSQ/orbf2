import React from "react";
import Table from "./invoice/table";
import InvoiceHeader from "./invoice/invoice_header";
import TotalItems from "./invoice/total_items";

export const Invoice = function(props) {
  return [
    <InvoiceHeader key="header" invoice={props.invoice} />,
    <Table key="invoice" invoice={props.invoice} />,
    <TotalItems key="total-items" items={props.invoice.total_items} />,
  ];
};
