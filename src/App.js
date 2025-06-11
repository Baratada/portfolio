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
      </Routes>
    </AnimatePresence>
  );
}

function App() {
  return (
    <Router>
      <div
        style={{
          backgroundImage: `url(${process.env.PUBLIC_URL}/media/Background.png)`,
        }}
        className="App w-screen min-h-screen bg-cover bg-fixed m-0 p-0"
      >
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

        {/* Routes with animation */}
        <AnimatedRoutes />

        {/* Footer */}
        <footer className="fixed bottom-0 w-full py-6 text-center bg-white/20 shadow-md text-sm font-semibold"></footer>
      </div>
    </Router>
  );
}

export default App;
