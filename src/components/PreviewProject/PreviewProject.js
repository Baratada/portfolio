import React from 'react';
import PropTypes from 'prop-types';
import Media from '../Media/Media';

const PreviewProject = ({ Name, Description, Image }) => (
  <div className="flex items-center justify-center gap-6 my-4 shadow-xl bg-white/30 rounded-md p-4 w-1/2 mx-auto border-t-4 border-b-4 border-white/30 shadow-xl/30">
    <Media src={process.env.PUBLIC_URL + Image} alt={Name} className="w-64 h-auto rounded-md my-2" />

    <div className="flex flex-col justify-center">
      <h1 className="text-xl font-bold">{Name}</h1>
      <h2 className="text-md font-medium">{Description}</h2>
    </div>
  </div>
);


PreviewProject.propTypes = {
  Name: PropTypes.string.isRequired,
  Description: PropTypes.string.isRequired,
  Image: PropTypes.string.isRequired,
};

PreviewProject.defaultProps = {};

export default PreviewProject;
