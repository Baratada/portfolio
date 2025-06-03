import React, { useState, useEffect } from 'react';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { oneDark } from "react-syntax-highlighter/dist/esm/styles/prism";
import { motion, AnimatePresence } from 'framer-motion';

const ShowScriptButton = ({ previewCodePath }) => {
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [visible, setVisible] = useState(false);

  const showCode = () => {
    setVisible(true);
    setError(null);
    setCode('');
    setLoading(true);

    fetch(previewCodePath)
      .then(res => {
        if (!res.ok) throw new Error(`Failed to fetch ${previewCodePath}`);
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

  const closeCode = () => {
    setVisible(false);
    setCode('');
  };

  return (
    <div>
      <button
        className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        onClick={showCode}
      >
        Show Code
      </button>

      <AnimatePresence>
        {visible && (
          <div
            style={{
              position: 'fixed',
              top: '50%',
              left: '50%',
              transform: 'translate(-50%, -50%)',
              zIndex: 9999,
            }}
          >
            <motion.div
              key="code-window"
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.2 }}
              style={{
                backgroundColor: '#1e1e1e',
                padding: '1rem',
                borderRadius: '8px',
                maxWidth: '90vw',
                maxHeight: '80vh',
                overflowY: 'auto',
                boxShadow: '0 0 15px rgba(0,0,0,0.7)',
                position: 'relative',
              }}
            >
              <button
                onClick={closeCode}
                style={{
                  position: 'absolute',
                  top: '0.5rem',
                  right: '0.75rem',
                  fontSize: '1.25rem',
                  fontWeight: 'bold',
                  color: 'white',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                }}
                aria-label="Close"
              >
                ×
              </button>

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
