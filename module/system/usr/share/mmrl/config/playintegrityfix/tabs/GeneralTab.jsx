import React from "react";
import { List, ListItem, ListItemText, ListSubheader, Switch, Divider } from "@mui/material";
import { Page, ListItemDialogEditText } from "@mmrl/ui";
import { useConfig, useNativeStorage } from "@mmrl/hooks";
import FlatList from "flatlist-react";

export default () => {
  const [pif, setPif] = useConfig();
  const [protectFingerprint, setProtectFingerprint] = useNativeStorage("pif_protect_fingerprint", true);

  // create dynamically new fileds
  const items = React.useMemo(() => Object.entries(pif), [pif]);

  return (
    <Page>
      <List subheader={<ListSubheader>Config</ListSubheader>}>
        <ListItem>
          <ListItemText
            primary="Protect fingerprint"
            secondary={
              <>
                Never share your private fingerprints!
                <br />
                <strong>This setting affects only this config page.</strong>
              </>
            }
          />
          <Switch checked={protectFingerprint} onChange={(e) => setProtectFingerprint(e.target.checked)} />
        </ListItem>
      </List>

      <Divider />

      <List subheader={<ListSubheader>Pif</ListSubheader>}>
        <FlatList
          list={items}
          renderItem={(item, keyIdx) => {
            const key = item[0];
            const value = item[1];
            return (
              <ListItemDialogEditText
                key={keyIdx}
                onSuccess={(val) => {
                  if (val) setPif(key, val);
                }}
                inputLabel={key}
                type="text"
                title={key}
                initialValue={value}
              >
                <ListItemText
                  sx={{
                    "& .MuiListItemText-secondary": {
                      WebkitTextSecurity: key === "FINGERPRINT" && protectFingerprint ? "disc" : "none",
                      wordWrap: "break-word",
                    },
                  }}
                  primary={key}
                  secondary={value}
                />
              </ListItemDialogEditText>
            );
          }}
        />
      </List>
    </Page>
  );
};
