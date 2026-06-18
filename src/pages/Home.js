import React from "react";
import { Link } from "react-router-dom";

const Home = () => (
  <div className="App">
    <div className="justify-center flex gap-3.5 mt-[9%]">
      <h1
        className="text-[5rem] font-bold text-center mt-5 text-transparent purpl"
        style={{
          color: "transparent",
          WebkitTextStroke: `1px var(--color-dark-cyan-500)`,
        }}
      >
        Hi, I am
      </h1>
      <h1 className="relative text-[5rem] font-bold text-center mt-5">
        Marko{" "}
      </h1>
    </div>
    <p className="text-[1.5rem]">
      I'm a 20 year old Roblox scripter and animator, majoring in Software
      Engineering.
    </p>
    <br />
    <Link
      className="block mx-auto text-[1.5rem] w-[12.5rem] rounded-[4rem] pl-4 pr-4 pt-2 pb-2 primary-btn"
      to="/scripts"
    >
      Scripts
    </Link>
  </div>
);

export default Home;
