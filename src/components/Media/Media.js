import React from 'react';

const Media = ({ src, alt = "", className = "" }) => {
  const isVideo = src.match(/\.(mp4|webm|ogg)$/i);
  const isImage = src.match(/\.(jpeg|jpg|png|gif|svg)$/i);

  if (isVideo) {
    return (
      <video
        src={src}
        className={className}
        controls
        autoPlay
        muted
        loop
      />
    );
  }

  if (isImage) {
    return <img src={src} alt={alt} className={className} />;
  }

  return <p className="text-red-500">Unsupported media type: {src}</p>;
};

export default Media;
