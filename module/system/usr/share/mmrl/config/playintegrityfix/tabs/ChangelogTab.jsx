import React from "react";
import { Markdown, Page } from "@mmrl/ui";

export default () => {
  return (
    <Page sx={{ p: 1 }}>
      <Markdown fetch="https://raw.githubusercontent.com/osm0sis/PlayIntegrityFork/main/CHANGELOG.md" />
    </Page>
  );
};
