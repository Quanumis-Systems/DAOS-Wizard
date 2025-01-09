// frontend/src/App.js
import { BrowserRouter as Router, Route, Switch } from 'react-router-dom';
import {
  Home,
  DAOCreator,
  Governance,
  TokenDesigner,
  Dashboard
} from './pages';
import { Navigation } from './components';
import { Web3Provider } from './context/Web3Context';
import { ThemeProvider } from '@material-ui/core';
import theme from './styles/theme';

function App() {
  return (
    <Web3Provider>
      <ThemeProvider theme={theme}>
        <Router>
          <Navigation />
          <Switch>
            <Route exact path="/" component={Home} />
            <Route path="/create" component={DAOCreator} />
            <Route path="/governance" component={Governance} />
            <Route path="/tokens" component={TokenDesigner} />
            <Route path="/dashboard" component={Dashboard} />
          </Switch>
        </Router>
      </ThemeProvider>
    </Web3Provider>
  );
}

export default App;
