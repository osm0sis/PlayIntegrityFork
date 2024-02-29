import React from "react";
import { Toolbar } from "@mmrl/ui";
import { useActivity } from "@mmrl/hooks";

export default () => {
  const { context } = useActivity();
  return (
    <Toolbar modifier="noshadow">
      <Toolbar.Left>
        <Toolbar.BackButton onClick={context.popPage} />
      </Toolbar.Left>
      <Toolbar.Center>Play Integrity Fork</Toolbar.Center>
    </Toolbar>
  );
};
