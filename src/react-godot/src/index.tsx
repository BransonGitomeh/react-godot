/**
 * @function ReactGodot
 */

import * as React from "react";
import { FunctionComponent, useEffect, useState } from "react";
import AsyncLoading from "./AsyncLoading";
import ReactCanvas from "./ReactCanvas";

const useScript = (url, onLoad) => {
  useEffect(() => {
    const script = document.createElement("script");

    script.src = url;
    script.async = true;
    script.onload = onLoad;

    document.body.appendChild(script);

    return () => {
      document.body.removeChild(script);
    };
  }, [url]);
};

export type ReactGodotProps = {
  script: EngineLoaderDescription;
  pck: string;
  resize?: boolean;
  width?: number;
  height?: number;
  params?: any;
};

const ReactGodot: FunctionComponent<ReactGodotProps> = (props) => {
  const { script, pck, resize = false, width, height, params } = props;
  const [engine, setEngine] = useState<Engine>(null);
  const [dimensions, setDimensions] = useState([width, height]);

  useScript(script, () => {
    const scope = window as any;
    setEngine(() => scope.Engine);
  });

  const handleResize = () => {
    if (resize) {
      setDimensions([window.innerWidth, window.innerHeight]);
    }
  };

  useEffect(() => {
    handleResize(); // Set initial dimensions

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, [resize]);

  return (
    <div id="wrap">
      <AsyncLoading>
        {engine && (
          <ReactCanvas
            pck={pck}
            engine={engine}
            width={dimensions[0]}
            height={dimensions[1]}
            params={params}
          />
        )}
      </AsyncLoading>
    </div>
  );
};

export default ReactGodot;
