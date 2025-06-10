import "./App.css";
import { HashRouter as Router, Routes, Route, Link } from "react-router-dom";
import Home from "./pages/Home";
import Scripts from "./pages/Scripts";
import Projects from "./pages/Projects";

function App() {
  return (
    <Router>
      {" "}
      {/* Important for GitHub Pages */}
      <div className="App">
        {/* Navigation */}
        <nav className="flex gap-4 justify-center py-4 bg-white/20 shadow-md">
          <Link
            to="/"
            className="text-blue-500 font-bold hover:underline transition hover:text-blue-300"
          >
            Home
          </Link>
          <Link
            to="/scripts"
            className="text-blue-500 font-bold hover:underline transition hover:text-blue-300"
          >
            Scripts
          </Link>
          <Link
            to="/projects"
            className="text-blue-500 font-bold hover:underline transition hover:text-blue-300"
          >
            Projects
          </Link>
          <a
            href="https://github.com/baratada/Portfolio"
            className="text-blue-500 font-bold hover:underline transition hover:text-blue-300"
          >
            Source
          </a>
        </nav>

        {/* Routes */}
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/scripts" element={<Scripts />} />
          <Route path="/projects" element={<Projects />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
