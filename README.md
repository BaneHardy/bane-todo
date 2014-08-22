bane-todo
=========

Install this todo script in five simple steps:

1. Put bane-todo-create-database.tcl and bane-todo.tcl in the eggdrop scripts
   directory.

2. Execute bane-todo-create-database.tcl. This creates an empty sqlite3
   database file bane-todo.db in the current directory. This file is used for
   storing the todos later. Afterwards the tcl file may be deleted.

3. Edit the config block in bane-todo.tcl with your favourite editor.

4. Source bane-todo.tcl in the eggdrop config file:
   source scripts/bane-todo.tcl

5. Rehash or restart the eggdrop.
