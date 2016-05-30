// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import {Socket} from "phoenix"
import 'babel-polyfill';
import 'todomvc-common';
import {createHashHistory} from 'history';
import {IndexRoute, Route} from 'react-router';
import React from 'react';
import ReactDOM from 'react-dom';
import {RelayRouter} from 'react-router-relay';
import TodoApp from './components/TodoApp';
import TodoList from './components/TodoList';
import ViewerQueries from './queries/ViewerQueries';

ReactDOM.render(
  <RelayRouter history={createHashHistory({queryKey: false})}>
    <Route
      path="/" component={TodoApp}
      queries={ViewerQueries}>
      <IndexRoute
        component={TodoList}
        queries={ViewerQueries}
        prepareParams={() => ({status: 'any'})}
      />
      <Route
        path=":status" component={TodoList}
        queries={ViewerQueries}
      />
    </Route>
  </RelayRouter>,
  document.getElementById('root')
);
