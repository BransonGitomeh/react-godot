import * as React from "react"
import { FunctionComponent, useEffect, useState } from "react"
import { useLoading } from "./AsyncLoading"

interface Engine {
  isWebGLAvailable: () => boolean
  setProgressFunc: (cb: (current: number, total: number) => void) => boolean
  startGame: (pck: string) => Promise<void>
  setCanvas: (canvas: HTMLCanvasElement) => void
}

interface EngineConstructor {
  new(): Engine;
}

type ExtendedEngine = Engine & EngineConstructor;

export type ReactEngineProps = {
  engine: ExtendedEngine
  pck: string
  width?: number
  height?: number
  params?: any
  resize?: boolean
}

function toFailure(err: any) {
  var msg = err.message || err
  console.error(msg)
  return { msg, mode: "notice", initialized: true }
}

const GODOT_CONFIG = { "args": [], "canvasResizePolicy": 2, "executable": "index", "experimentalVK": false, "fileSizes": { "index.pck": 6720, "index.wasm": 28972640 }, "focusCanvas": false, "gdextensionLibs": [], "serviceWorker": "index.service.worker.js" };

const canvasStyle = {
  position: 'absolute',
  top: '60px', // or 'unset'
  left: '0px',
  width: '100%',
  height: '100%',
  display: 'block',
};

const ReactCanvas: FunctionComponent<ReactEngineProps> = ({
  engine,
  pck,
}) => {
  const [instance, setInstance] = useState<Engine | null>(null)
  const [loadingState, changeLoadingState] = useLoading()

  useEffect(() => {
    if (engine.isWebGLAvailable()) {
      changeLoadingState({ mode: "indeterminate" })
      setInstance(new engine(GODOT_CONFIG))
    } else {
      changeLoadingState(toFailure("WebGL not available"))
    }
  }, [engine])

  useEffect(() => {
    if (instance) {

      const onProgress = (current, total) => {
        if (total > 0) {
          changeLoadingState({ mode: "progress", percent: current / total })
        } else {
          changeLoadingState({ mode: "indeterminate" })
        }
      }

      instance
        .startGame({
          executable:pck,
          onProgress,
        })
        .then(() => {
          changeLoadingState({ mode: "hidden", initialized: true })
        })
        .catch(err => changeLoadingState(toFailure(err)))
    }
  }, [instance, pck, changeLoadingState])

  // useEffect(() => {
  //   if (instance) {
  //     const canvas = document.getElementById("canvas") as HTMLCanvasElement | null;
  //     if (canvas) {
  //       instance.setCanvas(canvas);
  //     }
  //   }
  // }, [instance]);

  return (
    <canvas
      id="canvas"
      style={{ display: loadingState.initializing ? "hidden" : "block", ...canvasStyle }}
    >
      HTML5 canvas appears to be unsupported in the current browser.
      <br />
      Please try updating or use a different browser.
    </canvas>
  );
}

export default ReactCanvas;
