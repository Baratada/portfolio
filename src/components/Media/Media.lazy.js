import React, { lazy, Suspense } from 'react';

const LazyMedia = lazy(() => import('./Media'));

const Media = props => (
  <Suspense fallback={null}>
    <LazyMedia {...props} />
  </Suspense>
);

export default Media;
