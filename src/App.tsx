import React from "react"
import ReactGodot from "./react-godot/src"

const examplePck = "/index.pck"
const exampleEngine = "/index.js"

function App() {
  return <ReactGodot pck={examplePck} script={exampleEngine} />
}

export default App
