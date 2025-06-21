import React from "react";
import Media from "../components/Media/Media";
const Animations = () => (
  <div className="App">
    <h1 className="text-3xl font-bold text-center mt-5">Animations</h1>
    <p className="font-bold ">
      All of my animations are made with blender, then imported into Moon
      Animator for some final touchups.
    </p>
    <div className="flex items-center justify-center gap-6 my-4">
      <Media
        src={process.env.PUBLIC_URL + "/media/BatSwinging.mp4"}
        alt="oopsie"
        className="w-[400px] h-auto rounded-md my-2"
        text={"Bat swinging animation"}
      />
      <Media
        src={process.env.PUBLIC_URL + "/media/MimicryCrit.mp4"}
        alt="oopsie"
        className="w-[400px] h-auto rounded-md my-2"
        text={"Heavy Weapon Combo Attack"}
      />
      <Media
        src={process.env.PUBLIC_URL + "/media/PhoenixAwakening.mp4"}
        alt="oopsie"
        className="w-[400px] h-auto rounded-md my-2"
        text={"Mode Awakening"}
      />
      <Media
        src={process.env.PUBLIC_URL + "/media/MimicryRun.mp4"}
        alt="oopsie"
        className="w-[400px] h-auto rounded-md my-2"
        text={"Heavy Weapon Run"}
      />
    </div>
  </div>
);

export default Animations;
