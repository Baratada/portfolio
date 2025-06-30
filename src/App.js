import "./App.css";
import {
  HashRouter as Router,
  Routes,
  Route,
  Link,
  useLocation,
} from "react-router-dom";
import { AnimatePresence, motion } from "framer-motion";
import Home from "./pages/Home";
import Scripts from "./pages/Scripts";
import Projects from "./pages/Projects";
import Animations from "./pages/Animations";
import About from "./pages/About";

function AnimatedRoutes() {
  const location = useLocation();

  return (
    <AnimatePresence mode="wait">
      <Routes location={location} key={location.pathname}>
        <Route
          path="/"
          element={
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.4 }}
            >
              <Home />
            </motion.div>
          }
        />
        <Route
          path="/scripts"
          element={
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.4 }}
            >
              <Scripts />
            </motion.div>
          }
        />
        <Route
          path="/animations"
          element={
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.4 }}
            >
              <Animations />
            </motion.div>
          }
        />
        <Route
          path="/projects"
          element={
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.4 }}
            >
              <Projects />
            </motion.div>
          }
        />
        <Route
          path="/about"
          element={
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ duration: 0.4 }}
            >
              <About />
            </motion.div>
          }
        />
      </Routes>
    </AnimatePresence>
  );
}

function App() {
  return (
    <Router>
      <div className="App w-screen min-h-screen bg-cover bg-fixed m-0 p-0 pb-24">
        {/* Navigation */}
        <nav className="flex gap-4 pr-5 justify-end py-4 bg-white/20 shadow-md">
          <Link
            to="/"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            Home
          </Link>
          <Link
            to="/scripts"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            Scripts
          </Link>
          <Link
            to="/animations"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            Animations
          </Link>
          <Link
            to="/projects"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            Projects
          </Link>
             <Link
            to="/about"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            About
          </Link>
          <a
            href="https://github.com/baratada/Portfolio"
            className="text-white font-bold transition hover:text-purple-300 active:text-purple-300"
          >
            Source
          </a>
        </nav>

        {/* Routes with animation */}
        <AnimatedRoutes />

      </div>
    </Router>
  );
}

export default App;
