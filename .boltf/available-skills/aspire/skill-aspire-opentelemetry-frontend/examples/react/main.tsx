/**
 * React App Entry Point with OpenTelemetry
 *
 * CRITICAL: Initialize telemetry BEFORE rendering React app.
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { initTelemetry } from './telemetry';

// Initialize OpenTelemetry FIRST
initTelemetry();

// Then render React app
ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
