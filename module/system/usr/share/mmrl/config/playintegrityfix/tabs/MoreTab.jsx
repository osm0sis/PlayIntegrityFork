import React from "react";
import { Dialog, DialogContent, DialogActions, DialogTitle, Button, List, ListItem, ListItemText, ListItemButton, ListItemIcon } from "@mui/material";
import { Markdown, Page } from "@mmrl/ui";
import { GitHub, RawOn, BugReport } from "@mui/icons-material";
import { useConfig } from "@mmrl/hooks";

const prop = new Map(SuFile.read(modpath("module.prop")).split("\n").map((row) => row.split("=")))

export default () => {
  const [pif] = useConfig();
  const [rawDialogOpen, setRawDialogOpen] = React.useState(false);

  const handleRawDialogClickOpen = () => {
    setRawDialogOpen(true);
  };

  const handleRawDialogClose = () => {
    setRawDialogOpen(false);
  };

  return (
    <Page>
      <List>
        <ListItem disablePadding>
          <ListItemButton onClick={handleRawDialogClickOpen}>
            <ListItemIcon>
              <RawOn />
            </ListItemIcon>
            <ListItemText primary="View Raw JSON" />
          </ListItemButton>
        </ListItem>
        <ListItem disablePadding>
          <ListItemButton onClick={() => window.open("https://github.com/osm0sis/PlayIntegrityFork")}>
            <ListItemIcon>
              <GitHub />
            </ListItemIcon>
            <ListItemText primary="Source" />
          </ListItemButton>
        </ListItem>
        <ListItem disablePadding>
          <ListItemButton onClick={() => window.open("https://github.com/osm0sis/PlayIntegrityFork/issues")}>
            <ListItemIcon>
              <BugReport />
            </ListItemIcon>
            <ListItemText primary="Issues" />
          </ListItemButton>
        </ListItem>
        <ListItem>
          <ListItemText color="text.secondary" primary={`${prop.get("id")} ${prop.get("version")} (${prop.get("versionCode")})`} />
        </ListItem>
      </List>
      <Dialog open={rawDialogOpen} onClose={handleRawDialogClose} aria-labelledby="alert-dialog-title" aria-describedby="alert-dialog-description">
        <DialogTitle id="alert-dialog-title">Raw</DialogTitle>
        <DialogContent>
          <Markdown>{`\`\`\`json\n${JSON.stringify(pif, null, 4)}\n\`\`\``}</Markdown>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleRawDialogClose}>Close</Button>
        </DialogActions>
      </Dialog>
    </Page>
  );
};
