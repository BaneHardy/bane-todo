#!/usr/bin/env tclsh

package require sqlite3;

sqlite3 todo "./bane-todo.db"
todo eval {CREATE TABLE todo(todotext text, timestamp text, author text, fixed text)}
todo close
