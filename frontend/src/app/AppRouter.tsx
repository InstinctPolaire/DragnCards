import React from "react";
import { Switch, Route } from "react-router-dom";
import PrivateRoute from "./PrivateRoute";
import TestMe from "../components/TestMe";
import RoomShow from "../pages/RoomShow";
import LobbyIndex from "../pages/LobbyIndex";
import Home from "../pages/Home";
import Login from "../features/auth/Login";
import Signup from "../features/auth/Signup";

const PrivatePage: React.FC = () => {
  return <div>this is a priv page</div>;
};

const AppRouter: React.FC = () => {
  return (
    <Switch>
      <Route path="/login" component={Login} />
      <Route path="/signup" component={Signup} />
      <Route path="/testme">
        <TestMe />
      </Route>
      <PrivateRoute path="/private" component={PrivatePage} />
      <Route path="/room/:slug" component={RoomShow} />
      <Route path="/lobby" component={LobbyIndex} />
      <Route path="/" component={Home} />
    </Switch>
  );
};
export default AppRouter;