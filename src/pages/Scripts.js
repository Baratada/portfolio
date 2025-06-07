import React from 'react';
import Preview from '../components/Preview/Preview';

const Scripts = () => (
  <div className="App">
    <h1 className="text-2xl font-bold text-center mt-5">Scripts</h1>
    <p className="text-md font-semibold mb-5">These are some scripts I've made, feel free to look at the code!</p>
    <Preview
        Name="Dumbass cat"
        Description="This is a dumbass cat."
        Image="/defaultImage.jpg"
        CodeName="elementsGame"
        scriptFiles={["MainCastingScript.lua", "TriggerCast.lua","CycleElements.lua", "setElementServer.lua","ElementSettings.lua"]}
    />
    <Preview
        Name="Funny rat"
        Description="This is a funny rat."
        Image="/funnyRat.gif"
        CodeName="elementsGame"
        scriptFiles={["skinCheckerScript.lua", "skinCheckerScript2.lua"]}
    />
  </div>
);

export default Scripts;
