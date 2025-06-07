import React from 'react';
import PropTypes from 'prop-types';
import Media from '../Media/Media';
import ShowScriptButton from '../ShowScriptButton/ShowScriptButton';

const Preview = ({ Name, Description, Image, CodeName, scriptFiles }) => (
   <div className="flex flex-col items-center mb-4 bg-white/30 p-4 rounded-xl w-1/2 mx-auto border-t-4 border-b-4 border-white/30 shadow-xl/30">
      <h3 className="text-xl font-bold">{Name}</h3>
      <Media src={process.env.PUBLIC_URL + Image} alt={Name} className="w-64 h-auto rounded-md my-2" />
      <p className="text-md font-semibold">{Description}</p>
      <ShowScriptButton
        previewCodeFolderPath={`${process.env.PUBLIC_URL}/code/${CodeName}`}
        scriptFiles={scriptFiles}
      />
  </div>
);

Preview.propTypes = {
  Name: PropTypes.string.isRequired,
  Description: PropTypes.string.isRequired,
  Image: PropTypes.string.isRequired,
  CodeName: PropTypes.string.isRequired,
  scriptFiles: PropTypes.arrayOf(PropTypes.string).isRequired,
};

Preview.defaultProps = {
  Name: "Default Name",
  Description: "Default Description",
  Image: "/defaultImage.jpg",
};

export default Preview;
