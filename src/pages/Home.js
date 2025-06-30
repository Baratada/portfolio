import React from "react";
import { Link } from "react-router-dom";

const Home = () => (
  <div className="App">
    <div className="justify-center flex gap-3.5 mt-[9%]">
      <h1 
        className="text-[5rem] font-bold text-center mt-5 text-transparent purpl"
        style={{
          WebkitTextStroke: '1px #d8b4fe'
        }}
      >
        Hi, I am
      </h1>
      <h1 className="relative text-[5rem] font-bold text-center mt-5">
        Marko
        <span className="absolute left-1/2 top-full -translate-y-8 -translate-x-[55%] mt-2 w-[150%] h-[20px]">
          <svg
            viewBox="0 0 200 20"
            className="w-full h-full"
            fill="none"
            stroke="#d8b4fe"
            strokeWidth="2"
          >
            <path d="M0 10 Q 50 0, 150 10 T 250 0" />
          </svg>
        </span>
      </h1>
    </div>
    <p className="text-[1.5rem]">I'm an 18 year old Roblox scripter and animator.</p>
    <br/>
    <Link 
      className="block mx-auto text-[1.5rem] w-[12.5rem] rounded-[4rem] bg-purple-300 pl-4 pr-4 pt-2 pb-2 text-black transition hover:scale-105" 
      to="/scripts">
      Scripts
    </Link>

  </div>

);

export default Home;
