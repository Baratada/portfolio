import React from "react";

const Media = ({ src, alt = "", className = "" }) => {
  const isVideo = src.match(/\.(mp4|webm|ogg)$/i);
  const isImage = src.match(/\.(jpeg|jpg|png|gif|svg)$/i);

  if (isVideo) {
    return (
      <video
        src={src}
        className={`${className} shadow-[0_0_10px_#000]`}
        controls
        autoPlay
        muted
        loop
      />
    );
  }

  if (isImage) {
    return (
      <img
        src={src}
        alt={alt}
        className={`${className} transform transition duration-300 active:scale-[4] shadow-[0_0_10px_#000]`}
        style={{ Hover: "" }}
      />
    );
  }

  return <p className="text-red-500">Unsupported media type: {src}</p>;
};

export default Media;
