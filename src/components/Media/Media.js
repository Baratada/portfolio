import React from "react";

const Media = ({ src, alt = "", className = "", text }) => {
  const isVideo = src.match(/\.(mp4|webm|ogg)$/i);
  const isImage = src.match(/\.(jpeg|jpg|png|gif|svg)$/i);

  const mediaClass = `${className} shadow-[0_0_10px_#000]`;

  const renderMedia = () => {
    if (isVideo) {
      return (
        <video src={src} className={mediaClass} controls autoPlay muted loop />
      );
    }

    if (isImage) {
      return (
        <img
          src={src}
          alt={alt}
          className={`${mediaClass} transform transition duration-300 active:scale-[4]`}
        />
      );
    }

    return <p className="text-red-500">Unsupported media type: {src}</p>;
  };

  return (
    <div className="flex flex-col items-center space-y-2 font-bold">
      {renderMedia()}
      {text && <p className="text-white text-sm">{text}</p>}
    </div>
  );
};

export default Media;
