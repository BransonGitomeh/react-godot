import { FunctionComponent } from "react";
interface Engine {
    isWebGLAvailable: () => boolean;
    setProgressFunc: (cb: any) => boolean;
    startGame: (pck: string) => Promise<void>;
    setCanvas: (canvas: HTMLCanvasElement) => void;
}
interface EngineConstructor {
    new (): Engine;
}
declare type ExtendedEngine = Engine & EngineConstructor;
export declare type ReactEngineProps = {
    engine: ExtendedEngine;
    pck: string;
    width?: number;
    height?: number;
    params?: any;
    resize?: boolean;
};
declare const ReactCanvas: FunctionComponent<ReactEngineProps>;
export default ReactCanvas;
