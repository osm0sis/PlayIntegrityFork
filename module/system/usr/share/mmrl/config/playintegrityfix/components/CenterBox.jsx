import React from "react";
import { Box } from "@mui/material";

export default (props) => {
  return (
    <Box
      component="h4"
      sx={{
        position: "absolute",
        left: "50%",
        top: "calc(50% - 56px)",
        textAlign: "center",
        WebkitTransform: "translate(-50%, -50%)",
        transform: "translate(-50%, -50%)",
      }}
      children={props.children}
    />
  );
};