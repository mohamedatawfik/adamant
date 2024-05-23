import React, { useState, useEffect } from "react";
import { useHistory } from 'react-router-dom';
import "./styles.css";
import { Route, Switch, Redirect, PrivateRoute } from "react-router-dom";
import AdamantMain from "./pages/AdamantMain";
import "cors";
import packageJson from "../package.json";
import { ToastContainer } from "react-toastify";
import Login from "../src/components/Login";
import Button from "@material-ui/core/Button";

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false); // State to track login status

  // check if adamant endpoint exists in the homepage
  const homepage = packageJson["homepage"];
  const adamantEndpoint = homepage.includes("/adamant");
  const history = useHistory();

  useEffect(() => {
      console.log('refreshed ');
      setLoggedIn(localStorage.getItem('sessionToken') != undefined);
  }, []);

  const handleLoginSuccess = () => {
    console.log('loginSuccessCalled');
    setLoggedIn(true);
    fetchProtectedData();
  };

  const fetchProtectedData = async () => {
    const token = localStorage.getItem('authToken');
    if (!token) {
      console.log('No token found, user is not logged in');
      return;
    }
  
    try {
      const response = await fetch('/api/protected', {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });
  
      if (response.ok) {
        const data = await response.json();
        console.log('Protected data:', data);
      } else {
        console.log('Failed to fetch protected data');
      }
    } catch (error) {
      console.error('Error fetching protected data:', error);
    }
  };

  const handleLogout = (e) => {
    // Clear session state
    setLoggedIn(false);
    // Remove session token from localStorage
    localStorage.removeItem('sessionToken');
  };

  const ProtectedRoute = ({ user, redirectPath = '/login' }) => {
    if (!user == undefined) {
      return <Redirect to={redirectPath} replace />;
    }
  
    return <AdamantMain onLogout={handleLogout} />;
  };

  if (adamantEndpoint) {
    console.log("/adamant endpoint is detected")
    return (
      /** Use this for if homepage has /adamant endpoint, this is only for deploying on github-page */
      <>
        <div className="the_app">
          <Switch>
            <Route exact path="/">
                <Redirect to="/login" />
            </Route>
            <Route exact path="/logout">
                <Redirect to="/" />
            </Route>
            <Route exact path="/login">
                <Login onLoginSuccess={handleLoginSuccess} />
            </Route>
            <Route exact path="/adamant" element={<ProtectedRoute user={localStorage.getItem('sessionToken')} />} />
          </Switch>
        </div>
        <ToastContainer
          position="top-right"
          autoClose={5000}
          hideProgressBar={false}
          closeOnClick={true}
          pauseOnHover={true}
          draggable={false}
          progress={undefined} />
      </>
    );
  } else {
    return (
      <>
        <div className="the_app">
          <Switch>
              <Route exact path="/">
                {loggedIn ? (
                  <Redirect to="/adamant" />
                ) : (
                  <Login onLoginSuccess={handleLoginSuccess} />
                )}
              </Route>
              <Route exact path="/adamant" component={AdamantMain}></Route>
          </Switch>
        </div>
        <ToastContainer
          position="top-right"
          autoClose={5000}
          hideProgressBar={false}
          closeOnClick={true}
          pauseOnHover={true}
          draggable={false}
          progress={undefined} />
      </>
    );
  };
};
