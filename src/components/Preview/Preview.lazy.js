import React, { lazy, Suspense } from 'react';

const LazyPreview = lazy(() => import('./Preview'));

const Preview = props => (
  <Suspense fallback={null}>
    <LazyPreview {...props} />
  </Suspense>
);

export default Preview;
