import React, { useState, useEffect } from "react";
import { useHistory } from 'react-router-dom';
import "./styles.css";
import { Route, Switch, Redirect } from "react-router-dom";
import AdamantMain from "./pages/AdamantMain";
import "cors";
import packageJson from "../package.json";
import { ToastContainer } from "react-toastify";
import Login from "../src/components/Login";

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false); // State to track login status
  const history = useHistory();

  // check if adamant endpoint exists in the homepage
  const homepage = packageJson["homepage"];
  const adamantEndpoint = homepage.includes("/adamant");

  useEffect(() => {
    const sessionToken = localStorage.getItem('sessionToken');
    if (sessionToken) {
      setLoggedIn(true);
    }
  }, []);

  const handleLoginSuccess = () => {
    setLoggedIn(true);
  };
  // const handleLoginSuccess = async (username, password) => {
  //   try {
  //     const response = await fetch('/api/login', {
  //       method: 'POST',
  //       headers: {
  //         'Content-Type': 'application/json',
  //       },
  //       body: JSON.stringify({ username, password }),
  //     });
      
  //     if (response.ok) {
  //       const data = await response.json();
  //       const token = data.token;

  //       // Set session state to true
  //       setLoggedIn(true);
  //       // Store session token in localStorage
  //       localStorage.setItem('sessionToken', token);
  //     } else {
  //       // Handle error if login fails
  //       console.error('Login failed:', response.statusText);
  //       // You can display an error message to the user
  //     }
  //   } catch (error) {
  //     console.error('Login failed:', error);
  //     // You can display an error message to the user
  //   }
  // };

  const handleLogout = () => {
    // Clear session state
    setLoggedIn(false);
    // Remove session token from localStorage
    localStorage.removeItem('sessionToken');
  };

  if (adamantEndpoint) {
    console.log("/adamant endpoint is detected")
    return (
      /** Use this for if homepage has /adamant endpoint, this is only for deploying on github-page */
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
            <Route exact path="/adamant">
              {loggedIn ? (
                <AdamantMain onLogout={handleLogout} />
              ) : (
                <Redirect to="/" />
              )}
            </Route>
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
