import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

import {
  StarknetConfig,
  publicProvider,
  argent,
  braavos,
} from '@starknet-react/core'
import { sepolia } from '@starknet-react/chains'

const chains = [sepolia]

const connectors = [argent(), braavos()]

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <StarknetConfig
      chains={chains}
      connectors={connectors}
      provider={publicProvider()}
      autoConnect
    >
      <App />
    </StarknetConfig>
  </React.StrictMode>
)
