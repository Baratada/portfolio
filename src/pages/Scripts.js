import React from "react";
import Preview from "../components/Preview/Preview";

const Scripts = () => (
  <div className="App">
    <h1 className="text-2xl font-bold text-center mt-5">Scripts</h1>
    <p className="text-md font-semibold mb-5">
      These are some scripts I've made, feel free to look at the code!
    </p>
    <Preview
      Name="Dungeon Generation Example"
      Description="An extremely modular procedural dungeon generator, made using a grid/subgrid system to allow for all types of room sizes."
      Image="/DungeonGeneration.png"
      CodeName="DungeonGenerator"
      scriptFiles={["GenerateDungeon.lua", "DungeonGenerator.lua"]}
    />
    <Preview
      Name="Elements Game"
      Description="A simple, but programmatically advanced game based on elements, with the elements being able to attach to slopes using raycast normals, hitboxes made manually with shapecast."
      Image="/ElementsGameExample.mp4"
      CodeName="ElementsGame"
      scriptFiles={[
        "MainCastingScript.lua",
        "TriggerCast.lua",
        "CycleElements.lua",
        "SetElementServer.lua",
        "ElementSettings.lua",
      ]}
    />
    <Preview
      Name="Brainrot Clicker Game"
      Description="Using libraries/frameworks like Fusion, Replica and ProfileStore, I made a small, but advanced clicker game based on brainrot (for kids)."
      Image="/ClickerGameExample.mp4"
      CodeName="ClickerGame"
      scriptFiles={["SetupGUI.lua", "TextButton.lua"]}
    />
  </div>
);

export default Scripts;
