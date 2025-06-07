import React, { useState } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from "react-syntax-highlighter/dist/esm/styles/prism";
import { motion, AnimatePresence } from 'framer-motion';

const ShowScriptButton = ({ previewCodeFolderPath, scriptFiles }) => {
  const [code, setCode] = useState('');
  const [activeTab, setActiveTab] = useState(scriptFiles?.[0] || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [visible, setVisible] = useState(false);

  const fetchCode = (filename) => {
    setLoading(true);
    setError(null);
    setCode('');
    fetch(`${previewCodeFolderPath}/${filename}`)
      .then(res => {
        if (!res.ok) throw new Error(`Failed to fetch ${filename}`);
        return res.text();
      })
      .then(text => {
        setCode(text);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  };

  const showCode = () => {
    setVisible(true);
    fetchCode(activeTab);
    document.body.style.overflow = 'hidden'; // Lock scroll
  };

  const closeCode = () => {
    setVisible(false);
    setCode('');
    document.body.style.overflow = ''; // Unlock scroll
  };

  return (
    <div className="mt-4">
      <button
        className="px-4 py-2 bg-white/10 text-white rounded transition hover:bg-white/35"
        onClick={showCode}
      >
        Show Code
      </button>

      <AnimatePresence>
        {visible && (
          <div
            className="fixed top-1/2 left-1/2 z-[9999] -translate-x-1/2 -translate-y-1/2 bg-[#1e1e1e] pt-20"
          >
            <motion.div
              key="code-window"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.2 }}
              className="relative bg-[#1e1e1e] p-4 rounded-lg max-w-[90vw] max-h-[80vh] overflow-y-auto shadow-[0_0_15px_rgba(0,0,0,0.7)]"
            >
              <div className="sticky top-0 bg-[#1e1e1e] z-10 pb-2">
                <button
                  onClick={closeCode}
                  aria-label="Close"
                  className="absolute top-2 right-3 text-white text-xl font-bold bg-none border-none cursor-pointer"
                >
                  ×
                </button>

                {/* Tabs */}
                <div className="flex space-x-2 mb-2">
                  {scriptFiles.map(file => (
                    <button
                      key={file}
                      className={`px-2 py-1 rounded text-sm font-mono ${
                        activeTab === file
                          ? 'bg-white/25 text-white'
                          : 'bg-white/10 text-gray-300'
                      }`}
                      onClick={() => {
                        if (file === activeTab) return;
                        setActiveTab(file);
                        fetchCode(file);
                      }}
                    >
                      {file}
                    </button>
                  ))}
                </div>
              </div>

              {loading && <p className="text-white">Loading code...</p>}
              {error && <p className="text-red-500">Error: {error}</p>}
              {!loading && !error && (
                <SyntaxHighlighter
                  language="lua"
                  style={oneDark}
                  customStyle={{ borderRadius: 6, fontSize: 14 }}
                >
                  {code}
                </SyntaxHighlighter>
              )}
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default ShowScriptButton;
