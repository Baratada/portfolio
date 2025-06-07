import React, { lazy, Suspense } from 'react';

const LazyPreviewProject = lazy(() => import('./PreviewProject'));

const PreviewProject = props => (
  <Suspense fallback={null}>
    <LazyPreviewProject {...props} />
  </Suspense>
);

export default PreviewProject;
