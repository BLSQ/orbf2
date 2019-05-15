import React from "react";

function onlyUnique(value, index, self) {
  return self.indexOf(value) === index;
}

const ExplanationStep = props => {
  if (props.expression == undefined) {
    return <span />;
  }
  return (
    <pre style={{ whiteSpace: "pre-wrap" }}>{`${props.variable} = ${
      props.expression
    }`}</pre>
  );
};

const ExplanationSteps = props => {
  const var_name = props.item.formula || props.variable;
  // sometimes there no much steps, remove same expression (eg state eval 15 15 15 15 => 15)
  const steps = [
    props.item.expression,
    props.item.instantiated_expression,
    props.item.substituted,
    props.item.solution,
  ].filter(onlyUnique);

  return (
    <>
      <h5>Step by step explanations:</h5>

      {steps.map((step, index) => (
        <ExplanationStep key={index} variable={var_name} expression={step} />
      ))}
    </>
  );
};

export default ExplanationSteps;
