import './App.css';
import Preview from './components/Preview/Preview';

function App() {
  return (
<div className="App">
      <h1 className="text-3xl font-bold text-center mt-5">Welcome!</h1>
      <br/>
      <p className='font-bold w-1/2 mx-auto bg-white/30 rounded-md'>I'm Marko, a roblox developer. I've been developing for 3 years, and in those 3 years i've made plenty of scripts. These are some of the scripts I think would be able to show my experience with Roblox and the Luau language the best.</p>
      <br/>
      <Preview
        Name="Dumbass cat"
        Description="This is a dumbass cat."
        Image="/defaultImage.jpg"
        CodeName="skinCheckerScript"
      />
      <Preview
        Name="Funny rat"
        Description="This is a funny rat."
        Image="/funnyRat.gif"
        CodeName="skinCheckerScript"
      />
    </div>
  );
}


export default App;
