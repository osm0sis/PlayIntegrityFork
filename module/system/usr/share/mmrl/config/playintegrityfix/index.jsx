import React from "react";
import { Anchor, Page, Tabbar } from "@mmrl/ui";
import { ConfigProvider } from "@mmrl/providers";

const RenderToolbar = include("components/RenderToolbar.jsx");
const CenterBox = include("components/CenterBox.jsx");

function App() {
  const [index, setIndex] = React.useState(0);
  const handlePreChange = (event) => {
    if (event.index != this.state.index) {
      setIndex(event.index);
    }
  };

  const renderTabs = () => {
    return [
      {
        content: <GeneralTab />,
        tab: <Tabbar.Tab label="General" />,
      },
      {
        content: <ChangelogTab />,
        tab: <Tabbar.Tab label="Changelog" />,
      },
      {
        content: <MoreTab />,
        tab: <Tabbar.Tab label="More" />,
      },
    ];
  };

  return (
    <ConfigProvider loadFromFile={modpath("custom.pif.json")} initialConfig={defConfig} loader="json">
      <Page renderToolbar={RenderToolbar}>
        <Tabbar swipeable={false} position="top" index={index} onPreChange={handlePreChange} renderTabs={renderTabs} />
      </Page>
    </ConfigProvider>
  );
}

const zygiskNext = new SuFile("/sdata/adb/modules/zygisksu/module.prop");
export default () => {
  if (BuildConfig.VERSION_CODE < 21410) {
    return (
      <Page renderToolbar={RenderToolbar}>
        <CenterBox>
          Play Integrity Fork requires MMRL above <strong>2.14.10</strong>!
        </CenterBox>
      </Page>
    );
  }

  switch (Shell.getRootManager()) {
    // todo: detect magisk zygisk enabled
    case "Magisk":
      return <App />;
    case "APatchSU":
    case "KernelSU":
      if (zygiskNext.exist()) {
        return <App />;
      } else {
        return (
          <Page renderToolbar={RenderToolbar}>
            <CenterBox>
              Unable to find{" "}
              <Anchor href="https://github.com/Dr-TSNG/ZygiskNext" noIcon>
                ZygiskNext
              </Anchor>
              (KernelSU) or
              <Anchor href="https://github.com/Yervant7/ZygiskNext" noIcon>
                ZygiskNext MOD
              </Anchor>{" "}
              (APatch)
            </CenterBox>
          </Page>
        );
      }
    default:
      return <App />;
  }
};
