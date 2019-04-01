const locale = undefined;

// Used for the natural sorting, a collator is suggested to be used for large arrays.
// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/localeCompare#Performance
const sortCollator = new Intl.Collator(locale, {
  numeric: true,
  sensitivity: "base",
});

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/NumberFormat
const numberFormatter = new Intl.NumberFormat(locale, {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
  useGrouping: false,
});

export { sortCollator, numberFormatter };
