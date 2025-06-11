import React from "react";
import PreviewProject from "../components/PreviewProject/PreviewProject";
const Projects = () => (
  <div className="App">
    <h1 className="text-2xl font-bold text-center mt-5 ">Projects</h1>
    <PreviewProject
      Name="Project E.G.O."
      Description='My main project. A parry based combat "card" game with 20+ abilities, 10+ weapons and one WIP mode, each weapon having its own unique ability, ranging from a simple attack that ragdolls and breaks block to a full on secondary mode which allows for ranged attacks. There are many more features in the game, but this is the core. The game uses DataStore2 and MuchachoHitbox, though I now prefer ProfileStore with Replica instead of DataStore2.'
      Image="/ProjectEGOExample.mp4"
    />
  </div>
);

export default Projects;
