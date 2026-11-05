import '@fontsource/poppins/latin-400.css';
import '@fontsource/poppins/latin-500.css';
import '@fontsource/poppins/latin-600.css';
import '@fontsource/poppins/latin-700.css';
import './styles.css';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './App';

const racine = document.getElementById('racine');
if (racine !== null) {
  createRoot(racine).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );
}
