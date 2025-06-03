import React, { lazy, Suspense } from 'react';

const LazyShowScriptButton = lazy(() => import('./ShowScriptButton'));

const ShowScriptButton = props => (
  <Suspense fallback={null}>
    <LazyShowScriptButton {...props} />
  </Suspense>
);

export default ShowScriptButton;
