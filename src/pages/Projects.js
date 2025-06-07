import React from 'react';
import PreviewProject from '../components/PreviewProject/PreviewProject';
const Projects = () => (
  <div className="App">
    <h1 className="text-2xl font-bold text-center mt-5">Projects</h1>
    <PreviewProject
      Name="Dumbass cat"
      Description="This is a dumbass cat."
      Image="/defaultImage.jpg"
    />
  </div>
);

export default Projects;
